#!/usr/bin/env python3
"""Build the single final-format rule database from repository SQL."""
from contextlib import closing
import argparse
import json
import os
from pathlib import Path
import sqlite3
import tempfile
ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / 'Resources/rule_safety.json'

def validate(db, policy=None):
    policy = policy or json.loads(POLICY.read_text())
    db.row_factory = sqlite3.Row
    if not db.execute('PRAGMA quick_check').fetchone()[0] == 'ok':
        raise ValueError('database_integrity')
    if not not db.execute('PRAGMA foreign_key_check').fetchall():
        raise ValueError('database_references')
    objects = db.execute("SELECT type,name,sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'").fetchall()
    tables = {r['name']: r['sql'] for r in objects if r['type'] == 'table'}
    if not tables == policy['schema']:
        raise ValueError('database_schema')
    if not all((r['type'] == 'table' for r in objects)):
        raise ValueError('database_objects')

    def rows(name):
        return [dict(r) for r in db.execute('SELECT * FROM "' + name + '"')]

    for name in tables:
        values = rows(name)
        if len(values) > 100000 or any(isinstance(value, str) and (len(value.encode()) > 4096 or '\x00' in value) for row in values for value in row.values()):
            raise ValueError('table_resource_limit:' + name)

    def contains(name, required):
        actual = rows(name)
        if not all((r in actual for r in required)):
            raise ValueError('removed_protection:' + name)
    for name, key in [('cm_global_guard', 'requiredGlobalGuards'), ('cm_protected_path', 'requiredProtectedPaths'), ('cm_junk_rule_lock', 'requiredRuleLocks'), ('cm_cache_profile_lock', 'requiredProfileLocks'), ('cm_junk_rule_exclude', 'requiredExclusions')]:
        contains(name, policy[key])
    rules = {r['id']: r for r in rows('cm_junk_rule')}
    rank = {'L1': 1, 'L2': 2, 'L3': 3, 'L4': 4}
    for limit in policy['ruleLimits']:
        r = rules.get(limit['ruleID'])
        if r is None:
            continue
        if not rank[r['tier']] >= rank[limit['minimumTier']]:
            raise ValueError('relaxed_rule:' + r['id'])
        if not r['action'] in limit['allowedActions']:
            raise ValueError('changed_action:' + r['id'])
        if not (limit['activationAllowed'] or r['status'] != 'active'):
            raise ValueError('activated_rule:' + r['id'])
        if not (r['predicate'] or '') == policy['requiredConditions'][r['id']]:
            raise ValueError('changed_condition:' + r['id'])
    canonical_bindings = set()
    for r in rows('cm_discovery_binding'):
        rule = rules[r['rule_id']]
        if not r['scanner_id'] in policy['scanners']:
            raise ValueError('unknown_scanner')
        path = r['path_template']
        identity = (r['rule_id'], path.strip('/'))
        if identity in canonical_bindings:
            raise ValueError('duplicate_binding')
        canonical_bindings.add(identity)
        if not ('\x00' not in path and '..' not in path.split('/') and (len(path) <= 4096)):
            raise ValueError('invalid_path')
        if r['status'] == 'active':
            capability = r['scanner_id'] + ':' + r['discovery_kind']
            allowed = policy['bindingCapabilities'].get(r['rule_id'])
            if (allowed is not None and capability not in allowed) or (allowed is None and r['scanner_id'] not in policy['newRuleScanners']):
                raise ValueError('changed_scanner_capability')
            scopes = policy['pathScopes'][r['scanner_id']]
            if path and not any(path.rstrip('/') == scope or path.startswith(scope+'/') for scope in scopes):
                raise ValueError('expanded_path_scope')
            if not (rule['status'] == 'active' and rule['tier'] in ('L1', 'L2') and (rule['action'] != 'read_only')):
                raise ValueError('active_readonly')
            if not (rule['predicate'] or '') in policy['predicates']:
                raise ValueError('unknown_condition')
            if not r['scanner_id'] not in ('inventoryOnly', 'rejected', 'deferred'):
                raise ValueError('inactive_scanner')
    for r in rules.values():
        if not db.execute('SELECT 1 FROM cm_discovery_binding WHERE rule_id=?', (r['id'],)).fetchone():
            raise ValueError('missing_binding')
    for r in rows('cm_version_cache'):
        if not (r['keep_latest'] >= 2 and r['min_age_hours'] >= 168):
            raise ValueError('relaxed_versions')
        if not r['name_pattern'] == policy['versionPatterns'][r['family']]:
            raise ValueError('version_pattern')
    for name, limits, identity in [('cm_performance_task', policy['maintenanceLimits'], 'task_id'), ('cm_uninstall_template', policy['uninstallLimits'], 'id')]:
        actual = {r[identity]: r for r in rows(name)}
        for floor in limits:
            r = actual.get(floor[identity])
            if r is None:
                continue
            if name == 'cm_performance_task':
                if not r['needs_admin'] == floor['needs_admin']:
                    raise ValueError('changed_privilege')
                if not (floor['status'] == 'allowed' or r['status'] != 'allowed'):
                    raise ValueError('enabled_forbidden_task')
                if not r['default_selected'] <= floor['default_selected']:
                    raise ValueError('automatic_task')
                risk = {'safe': 0, 'caution': 1, 'disruptive': 2, 'forbidden': 3}
                if risk[r['risk']] < risk[floor['risk']] or r['reversible'] > floor['reversible']:
                    raise ValueError('relaxed_task_risk')
            else:
                if not (r['execute'] <= floor['execute'] and r['default_selected'] <= floor['default_selected']):
                    raise ValueError('relaxed_uninstall')
                if not (r['domain'] == floor['domain'] and rank[r['tier']] >= rank[floor['tier']]):
                    raise ValueError('changed_uninstall_scope')
    meta = {r['key']: r['value'] for r in rows('cm_rule_meta')}
    if meta.get('schema_version') != '1' or not 0 < int(meta.get('rule_version', '0')) <= 9223372036854775807:
        raise ValueError('invalid_rule_metadata')
    bounds = policy['projectBounds']
    if int(meta['project_min_age_days']) < bounds['minimumAgeDays'] or not 0 < int(meta['project_max_depth']) <= bounds['maximumScanDepth'] or not 0 < int(meta['project_manifest_search_depth']) <= bounds['maximumManifestSearchDepth']:
        raise ValueError('relaxed_project_bounds')
    artifacts = {r['artifact_name']: r for r in rows('cm_project_artifact')}
    for floor in policy['projectArtifactFloors']:
        row = artifacts.get(floor['artifact_name'])
        if row and (row['proof_kind'] != floor['proof_kind'] or row['candidate'] > floor['candidate'] or row['generic_name'] < floor['generic_name']):
            raise ValueError('relaxed_artifact_proof')
    return {name: db.execute('SELECT count(*) FROM "' + name + '"').fetchone()[0] for name in tables}

def build(sql: Path, output: Path, version: int=1):
    if not 0 < version <= 9223372036854775807:
        raise ValueError('invalid_rule_version')
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.rules-build-', suffix='.tmp', dir=output.parent)
    os.close(fd)
    try:
        with closing(sqlite3.connect(temporary)) as db:
            db.executescript(sql.read_text())
            db.execute("UPDATE cm_rule_meta SET value=? WHERE key='rule_version'", (str(version),))
            db.commit()
            counts = validate(db)
        os.chmod(temporary, 420)
        os.replace(temporary, output)
        return counts
    finally:
        Path(temporary).unlink(missing_ok=True)
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sql', type=Path, default=ROOT / 'Resources/cleanmate_authored_rules.sql')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--version', type=int, default=1)
    args = parser.parse_args()
    print(json.dumps(build(args.sql, args.out, args.version), sort_keys=True))
