"""Versioned GitHub payloads need no signing keys or periodic renewal."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'Tools'))
from build_rule_package import package

class RulePublishTests(unittest.TestCase):
    def test_publish_upgrade_and_reject_without_replacing(self):
        with tempfile.TemporaryDirectory(prefix='cleanmate-publish-case-', dir='/private/tmp') as folder:
            output = Path(folder)
            sql = ROOT/'Resources/cleanmate_authored_rules.sql'
            first = package(sql, output, 2)
            self.assertNotIn('expiresAt', first)
            self.assertNotIn('metadataVersion', first)
            self.assertEqual(set(p.name for p in output.iterdir()), {'cleanmate_rules.db', 'latest.json', 'changes.json'})
            second = package(sql, output, 3, ['JC.CACHE.USER'])
            self.assertEqual(second['ruleVersion'], 3)
            self.assertEqual(second['databaseSHA256'], hashlib.sha256((output/'cleanmate_rules.db').read_bytes()).hexdigest())
            self.assertEqual(second['disabledRuleIDs'], ['JC.CACHE.USER'])
            before = {p.name:p.read_bytes() for p in output.iterdir()}
            for version in [2, 3]:
                with self.assertRaises(ValueError): package(sql, output, version)
            with self.assertRaises(ValueError): package(sql, output, 4, ['JC.UNKNOWN'])
            self.assertEqual(before, {p.name:p.read_bytes() for p in output.iterdir()})
            fourth = package(sql, output, 4)
            self.assertEqual(fourth['disabledRuleIDs'], ['JC.CACHE.USER'])

if __name__ == '__main__': unittest.main()
