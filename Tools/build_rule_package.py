#!/usr/bin/env python3
"""Build one fixed-path GitHub release. Never retain versioned database copies."""
from contextlib import closing
import argparse
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import tempfile
from build_authored_rules import build, validate, ROOT

def inventory(path):
    if not path.exists():
        return {}
    with closing(sqlite3.connect(f'file:{path}?mode=ro', uri=True)) as db:
        validate(db)
        names = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'cm_%' ORDER BY name")]
        result = {}
        for name in names:
            if not name.replace('_', '').isalnum():
                raise ValueError('invalid_table_name')
            columns = [r[1] for r in db.execute('PRAGMA table_info('+name+')')]
            result[name] = [dict(zip(columns, r)) for r in db.execute('SELECT * FROM '+name+' ORDER BY 1')]
        return result

def package(sql, output, version, disabled_rule=(), revoked_hash=()):
    if not 0 < version <= 9223372036854775807:
        raise ValueError('invalid_version')
    output.mkdir(parents=True, exist_ok=True)
    database = output/'cleanmate_rules.db'
    prior = inventory(database)
    metadata = output/'latest.json'
    old = json.loads(metadata.read_text()) if metadata.exists() else None
    if old and version <= old['ruleVersion']:
        raise ValueError('rule_version_must_increase')
    with tempfile.TemporaryDirectory(prefix='.rules-release-', dir=output) as temporary:
        stage = Path(temporary)
        build(sql, stage/database.name, version)
        data = (stage/database.name).read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        disabled = set(disabled_rule) | set(old.get('disabledRuleIDs', []) if old else [])
        revoked = set(revoked_hash) | set(old.get('revokedDatabaseHashes', []) if old else [])
        if any(len(h) != 64 or any(c not in '0123456789abcdef' for c in h) for h in revoked):
            raise ValueError('invalid_revoked_hash')
        if digest in revoked:
            raise ValueError('published_database_is_revoked')
        after = inventory(stage/database.name)
        known = {r['id'] for r in after['cm_junk_rule']} | {'maint:'+r['task_id'] for r in after['cm_performance_task']}
        if not disabled <= known:
            raise ValueError('unknown_disabled_rule')
        for rows in after.values():
            for row in rows:
                if any(isinstance(value, str) and any(marker in value for marker in ['/Users/', '/private/tmp/', '/var/folders/']) for value in row.values()):
                    raise ValueError('machine_specific_path_in_public_rules')
        manifest = dict(formatVersion=1, ruleVersion=version, databasePath=database.name,
                        databaseBytes=len(data), databaseSHA256=digest,
                        disabledRuleIDs=sorted(disabled), revokedDatabaseHashes=sorted(revoked))
        changes = {name: {'before': prior.get(name, []), 'after': rows} for name, rows in after.items() if prior.get(name) != rows}
        (stage/'changes.json').write_text(json.dumps(changes, ensure_ascii=False, indent=2)+'\n')
        (stage/'latest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
        for name in [database.name, 'changes.json', 'latest.json']:
            os.replace(stage/name, output/name)
    return manifest

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sql', type=Path, default=ROOT/'Resources/cleanmate_authored_rules.sql')
    parser.add_argument('--version', type=int, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--disabled-rule', action='append', default=[])
    parser.add_argument('--revoked-hash', action='append', default=[])
    args = parser.parse_args()
    print(json.dumps(package(args.sql, args.output, args.version, args.disabled_rule, args.revoked_hash), sort_keys=True))

if __name__ == '__main__':
    main()
