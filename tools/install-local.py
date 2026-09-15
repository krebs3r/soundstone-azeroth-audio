"""Install the validated local ZIP, preserving the existing addon in local history."""
import argparse
from datetime import datetime
import hashlib
from pathlib import Path
import re
import shutil
from zipfile import ZipFile

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('destination',type=Path,help='Exact Interface/AddOns/Soundstone directory')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
destination=args.destination.resolve()
if destination.name!='Soundstone' or destination.parent.name!='AddOns' or destination.parent.parent.name!='Interface':
    parser.error('Destination must end in Interface/AddOns/Soundstone')
version=re.search(r'^## Version: ([\d.]+)$',(root/'Soundstone/Soundstone.toc').read_text(encoding='utf-8'),re.M).group(1)
archive=root/'dist'/f'Soundstone-{version}.zip'
expected=(archive.with_name(archive.name+'.sha256')).read_text(encoding='ascii').split()[0]
assert hashlib.sha256(archive.read_bytes()).hexdigest()==expected,'ZIP checksum mismatch'
backup=root/'.local-history/install-backups'/datetime.now().strftime('%Y%m%d-%H%M%S-%f')
if destination.exists():
    shutil.copytree(destination,backup)
verified=0
with ZipFile(archive) as package:
    assert package.testzip() is None
    for entry in package.infolist():
        if entry.is_dir():
            continue
        parts=Path(entry.filename).parts
        assert parts[0]=='Soundstone' and '..' not in parts
        target=(destination/Path(*parts[1:])).resolve()
        assert destination in target.parents
        target.parent.mkdir(parents=True,exist_ok=True)
        payload=package.read(entry)
        target.write_bytes(payload)
        assert hashlib.sha256(target.read_bytes()).digest()==hashlib.sha256(payload).digest()
        verified+=1
print(f'Installed and SHA-256 verified {verified} packaged files: {destination}')
print(f'Previous installation preserved: {backup}')
