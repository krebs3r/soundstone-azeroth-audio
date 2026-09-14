"""Validate and build the single-folder WoW package (Python standard library)."""
import hashlib
import re
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
addon = root / 'Soundstone'
toc = (addon / 'Soundstone.toc').read_text(encoding='utf-8')
version = re.search(r'^## Version: ([\d.]+)$', toc, re.M).group(1)
interfaces = re.search(r'^## Interface: (.+)$', toc, re.M).group(1).split(', ')
assert interfaces == ['120100', '50504', '20506', '11509']
for line in toc.splitlines():
    if line and not line.startswith('#'):
        assert (addon / line).is_file(), f'Missing TOC entry: {line}'
bindings = ET.parse(addon / 'Bindings.xml').getroot()
assert len(bindings.findall('Binding')) == 4
textures = list((addon / 'Media').glob('*.tga'))
assert len(textures) == 14, 'Unexpected runtime texture set'
for path in textures:
    texture = path.read_bytes()
    width, height = struct.unpack_from('<HH', texture, 12)
    assert width == height and width in (64, 128, 512), path.name
    assert (texture[2], texture[16], texture[17]) == (2, 32, 40), path.name
    assert len(texture) == 18 + width * height * 4, path.name
    alpha = texture[21::4]
    assert min(alpha) == 0 and max(alpha) == 255, f'Missing transparency: {path.name}'
    assert any(0 < a < 255 for a in alpha), f'Missing antialiasing: {path.name}'
dest = root / 'dist'
dest.mkdir(exist_ok=True)
output = dest / f'Soundstone-{version}.zip'
with ZipFile(output, 'w', ZIP_DEFLATED) as package:
    for path in sorted(addon.rglob('*')):
        if path.is_file():
            package.write(path, path.relative_to(root).as_posix())
    package.write(root / 'LICENSE', 'Soundstone/LICENSE.txt')
    package.write(root / 'docs/ANLEITUNG-DE.md', 'Soundstone/ANLEITUNG-DE.md')
with ZipFile(output) as package:
    assert package.testzip() is None
    assert all(name.startswith('Soundstone/') and '..' not in name for name in package.namelist())
    assert 'Soundstone/Soundstone.toc' in package.namelist()
digest = hashlib.sha256(output.read_bytes()).hexdigest()
(dest / (output.name + '.sha256')).write_text(f'{digest}  {output.name}\n', encoding='ascii')
print(f'Validated package: {output}\nSHA-256: {digest}')
