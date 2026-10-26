"""Small final-format build cases; select one unittest by name while developing."""
from contextlib import closing
import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('rule_builder', ROOT / 'Tools/build_authored_rules.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)

class RuleBuildTests(unittest.TestCase):
    def test_final_database(self):
        with tempfile.TemporaryDirectory(prefix='cleanmate-rule-case-') as folder:
            output = Path(folder) / 'cleanmate_rules.db'
            counts = builder.build(ROOT / 'Resources/cleanmate_authored_rules.sql', output, 4)
            self.assertEqual(counts['cm_junk_rule'], 70)
            self.assertEqual(counts['cm_discovery_binding'], 202)
            with closing(sqlite3.connect(output)) as db:
                self.assertEqual(db.execute("SELECT value FROM cm_rule_meta WHERE key='rule_version'").fetchone()[0], '4')
                self.assertFalse(db.execute("SELECT name FROM sqlite_master WHERE name='General'").fetchall())
            self.assertEqual([p.name for p in Path(folder).iterdir()], ['cleanmate_rules.db'])

    def test_reject_relaxed_rule(self):
        with tempfile.TemporaryDirectory(prefix='cleanmate-rule-case-') as folder:
            output = Path(folder) / 'cleanmate_rules.db'
            builder.build(ROOT / 'Resources/cleanmate_authored_rules.sql', output)
            with closing(sqlite3.connect(output)) as db:
                db.execute("UPDATE cm_junk_rule SET tier='L2',action='trash' WHERE id='JC.DEV.XCODE.ARCHIVES'")
                with self.assertRaises(ValueError):
                    builder.validate(db)

if __name__ == '__main__':
    unittest.main()
