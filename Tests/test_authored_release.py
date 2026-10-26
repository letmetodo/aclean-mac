#!/usr/bin/env python3
"""Verification of repository-authored release artifacts."""
import os
import sqlite3
import tempfile
import importlib.util
from pathlib import Path
import plistlib

def main():
    root = Path(__file__).resolve().parent.parent
    spec = importlib.util.spec_from_file_location('rule_builder', root / 'Tools/build_authored_rules.py')
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    with tempfile.TemporaryDirectory(prefix='cleanmate-rule-release-') as folder:
        db_path = Path(folder) / 'cleanmate_rules.db'
        builder.build(root / 'Resources/cleanmate_authored_rules.sql', db_path)
        assert db_path.stat().st_mode & 0o777 == 0o644
        with sqlite3.connect(db_path) as db:
            counts = builder.validate(db)
            assert len(counts) == 31
            for table in ['cm_junk_rule', 'cm_protected_path', 'cm_uninstall_template', 'cm_application_identity']:
                assert counts[table] > 0, table
    assert not (root / 'Resources/cleanmate_rules.db').exists(), 'App resources must contain SQL, not a second database'

    info_plist_path = root / "Resources" / "Info.plist"
    assert info_plist_path.exists(), "Info.plist missing"
    with open(info_plist_path, "rb") as f:
        info = plistlib.load(f)
    assert info.get("CFBundleName") == "ACleaner", f"Expected CFBundleName ACleaner, got {info.get('CFBundleName')}"
    assert info.get("CFBundleDisplayName") == "ACleaner", f"Expected CFBundleDisplayName ACleaner, got {info.get('CFBundleDisplayName')}"

    assert info.get("CleanMateRulesBaseURL") == "https://raw.githubusercontent.com/letmetodo/aclean-db/main/"
    assert "CleanMateRulePublicKeys" not in info

    required_lproj = [
        "zh-Hans.lproj", "zh-Hant.lproj", "en.lproj", "ja.lproj", "ko.lproj",
        "fr.lproj", "de.lproj", "es.lproj", "it.lproj", "pt-BR.lproj"
    ]
    for lproj in required_lproj:
        lproj_path = root / "Resources" / lproj
        assert lproj_path.is_dir(), f"Missing localization folder: {lproj}"
        strings = lproj_path / "InfoPlist.strings"
        assert strings.exists(), f"Missing InfoPlist.strings in {lproj}"

    print("✓ All repository-authored release artifacts verified successfully.")

if __name__ == "__main__":
    main()
