#!/usr/bin/env python3
"""Package original PNG representations in the standard PNG-backed ICNS container."""
from pathlib import Path
import struct
import sys

source, target = map(Path, sys.argv[1:])
representations = [('icp4', 'icon_16x16.png', 16), ('icp5', 'icon_32x32.png', 32),
                   ('icp6', 'icon_32x32@2x.png', 64), ('ic07', 'icon_128x128.png', 128),
                   ('ic08', 'icon_256x256.png', 256), ('ic09', 'icon_512x512.png', 512),
                   ('ic10', 'icon_512x512@2x.png', 1024)]
chunks = []
for kind, name, pixels in representations:
    png = (source / name).read_bytes()
    assert png[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', png[16:24]) == (pixels, pixels)
    chunks.append(kind.encode('ascii') + struct.pack('>I', len(png) + 8) + png)
content = b''.join(chunks)
target.write_bytes(b'icns' + struct.pack('>I', len(content) + 8) + content)
