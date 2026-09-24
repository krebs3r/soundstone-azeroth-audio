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
assert interfaces == ['120100', '50504', '20506', '11509', '16001']
for line in toc.splitlines():
    if line and not line.startswith('#'):
        assert (addon / line).is_file(), f'Missing TOC entry: {line}'
bindings = ET.parse(addon / 'Bindings.xml').getroot()
assert len(bindings.findall('Binding')) == 4
textures = list((addon / 'Media').glob('*.tga'))
asset_names=set(re.findall(r'^    (\w+) = \{', (addon / 'Assets.lua').read_text(encoding='utf-8'), re.M))
assert {p.stem for p in textures} == asset_names, 'Runtime textures must match Assets.lua'
assert {'Expand', 'Collapse', 'EyeOff', 'Heart'} <= asset_names
assert {'ActionNormal', 'ActionHover', 'ActionPressed'} <= asset_names
header_names={'HeaderHide','HeaderCompact','HeaderClose'}
assert header_names <= asset_names
for path in textures:
    texture = path.read_bytes()
    width, height = struct.unpack_from('<HH', texture, 12)
    assert width == height and width in (64, 128, 512), path.name
    assert (texture[2], texture[16], texture[17]) == (2, 32, 40), path.name
    assert len(texture) == 18 + width * height * 4, path.name
    alpha = texture[21::4]
    assert min(alpha) == 0 and max(alpha) == 255, f'Missing transparency: {path.name}'
    assert any(0 < a < 255 for a in alpha), f'Missing antialiasing: {path.name}'
    if path.stem in {'Expand', 'Collapse', 'EyeOff'}:
        opaque = [texture[i:i+4] for i in range(18,len(texture),4) if texture[i+3]>240]
        assert opaque and all(r >= g >= b for b,g,r,a in opaque), f'Expected baked warm material: {path.name}'
        assert max(p[2] for p in opaque)-min(p[2] for p in opaque)>100, f'Missing outline/highlight: {path.name}'
# The three visible frames must be pixel-identical outside their inset symbols.
reference=(addon/'Media/HeaderClose.tga').read_bytes()
for name in header_names:
    texture=(addon/'Media'/f'{name}.tga').read_bytes()
    assert texture[:18]==reference[:18] and texture[21::4]==reference[21::4], 'Header bounds/alpha differ'
    for y in range(128):
        for x in range(128):
            if x<23 or x>=105 or y<23 or y>=105:
                i=18+(y*128+x)*4
                assert texture[i:i+4]==reference[i:i+4], f'Header frame differs: {name}'

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
