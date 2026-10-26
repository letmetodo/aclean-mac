#!/usr/bin/env python3
"""Compile the production entry point into a new temporary directory without replacing build/."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--receipt', type=Path, required=True)
args = parser.parse_args()
stage = Path(tempfile.mkdtemp(prefix='cleanmate-native-verification-', dir='/private/tmp'))
shutil.copytree(root / 'Sources', stage / 'Sources')
sources = sorted((stage / 'Sources').rglob('*.swift'))
binary = stage / 'AClean.app/Contents/MacOS/AClean'
binary.parent.mkdir(parents=True)
resources = binary.parents[1] / 'Resources'
resources.mkdir()
shutil.copy2(root / 'Resources/Info.plist', binary.parents[1] / 'Info.plist')
for name in ['cleanmate_authored_rules.sql', 'rule_safety.json']:
    shutil.copy2(root / 'Resources'/name, resources/name)
frameworks = ['SwiftUI', 'AppKit', 'Foundation', 'UniformTypeIdentifiers', 'IOKit', 'CoreWLAN',
              'CoreLocation', 'CoreAudio', 'CoreMediaIO', 'SystemConfiguration', 'Security']
command = ['swiftc', '-O', '-whole-module-optimization', '-parse-as-library', '-swift-version', '6', '-strict-concurrency=complete',
           '-target', 'arm64-apple-macosx13.0', '-module-cache-path', str(stage / 'ModuleCache')]
for framework in frameworks:
    command.extend(['-framework', framework])
command.extend(['-lsqlite3', *map(str, sources), '-o', str(binary)])
subprocess.run(command, check=True)
helper_source = stage / 'MaintenanceHelper.swift'
shutil.copy2(root / 'Tools/MaintenanceHelper.swift', helper_source)
smc_source = stage / 'smchelper.c'
shutil.copy2(root / 'Tools/smchelper.c', smc_source)
smc_object = stage / 'smc.o'
subprocess.run(['clang', '-O2', '-Dmain=aclean_smc_execute', '-target', 'arm64-apple-macosx13.0',
                '-c', str(smc_source), '-o', str(smc_object)], check=True)
helper_binary = binary.parent / 'ACleanMaintenanceHelper'
subprocess.run(['swiftc', '-O', '-parse-as-library', '-swift-version', '6', '-D', 'CLEANMATE_HELPER',
                '-target', 'arm64-apple-macosx13.0', '-module-cache-path', str(stage / 'ModuleCache'),
                '-framework', 'Foundation', '-framework', 'Security', '-framework', 'IOKit', '-framework', 'CoreFoundation',
                str(helper_source), str(stage / 'Sources/Core/PrivilegedMaintenanceProtocol.swift'),
                str(stage / 'Sources/Core/LockedValue.swift'), str(stage / 'Sources/Core/AppConfig.swift'),
                str(smc_object), '-o', str(helper_binary)], check=True)
daemons = binary.parents[1] / 'Library/LaunchDaemons'
daemons.mkdir(parents=True)
shutil.copy2(root / 'Resources/com.personal.aclean.maintenance-helper.plist', daemons)
receipt = {
    'helper_binary': str(helper_binary), 'helper_sha256': hashlib.sha256(helper_binary.read_bytes()).hexdigest(),
    'binary': str(binary), 'source_count': len(sources), 'target': 'arm64-apple-macosx13.0',
    'optimization': '-O -whole-module-optimization',
    'compiler': subprocess.check_output(['swiftc', '--version'], text=True).strip(),
    'binary_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
    'source_sha256': {str(p.relative_to(stage)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
    'rules_sql_sha256': hashlib.sha256((resources / 'cleanmate_authored_rules.sql').read_bytes()).hexdigest(),
    'rules_safety_sha256': hashlib.sha256((resources / 'rule_safety.json').read_bytes()).hexdigest(),
    'note': 'Compile/link only. No app launch, signing, notarization or real data deletion.'
}
args.receipt.parent.mkdir(parents=True, exist_ok=True)
args.receipt.write_text(json.dumps(receipt, ensure_ascii=False, indent=2))
print(f'Production entry point compiled and linked: {binary} ({len(sources)} source files)')
