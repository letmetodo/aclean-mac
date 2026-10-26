#!/usr/bin/env python3
"""Remove only a caller-owned temporary build directory (never follow a root symlink)."""
import os
from pathlib import Path
import shutil
import stat
import sys
p = Path(sys.argv[1])
s = p.lstat()
assert p.parent == Path('/private/tmp') and p.name.startswith('cleanmate-build.')
assert stat.S_ISDIR(s.st_mode) and s.st_uid == os.getuid()
shutil.rmtree(p)
