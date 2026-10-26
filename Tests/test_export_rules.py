"""The final builder accepts SQL only and does not consume other databases."""
import importlib.util
from pathlib import Path
import sqlite3
import tempfile
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('authored_builder', root / 'Tools/build_authored_rules.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory(prefix='cleanmate-authored-test-', dir='/private/tmp') as folder:
    folder = Path(folder)
    unrelated = folder / 'untrusted.db'
    unrelated.write_bytes(b'must not be opened')
    output = folder / 'output.db'
    module.build(root / 'Resources/cleanmate_authored_rules.sql', output)
    assert unrelated.read_bytes() == b'must not be opened'
    assert output.stat().st_mode & 0o777 == 0o644
    with sqlite3.connect(output) as db:
        counts = module.validate(db)
        assert len(counts) == 31 and counts['cm_junk_rule'] == 70
        assert db.execute("SELECT value FROM cm_rule_meta WHERE key='schema_version'").fetchone()[0] == '1'
print('Final SQL build, unrelated input isolation and permissions: passed')
