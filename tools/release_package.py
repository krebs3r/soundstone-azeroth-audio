"""Shared strict release package validation; standard library only."""
import hashlib
import io
import os
from pathlib import Path, PurePosixPath
import re
import stat
from zipfile import ZipFile


def tree_paths(folder):
    """Enumerate strictly: pathlib glob can silently suppress permission errors."""
    with os.scandir(folder) as entries:
        for entry in entries:
            path = Path(entry.path)
            yield path
            if entry.is_dir(follow_symlinks=False) and not (hasattr(path, 'is_junction') and path.is_junction()):
                yield from tree_paths(path)


def reject_links(path, recursive=True):
    path = Path(path).absolute()
    candidates = [path, *path.parents]
    if recursive and path.is_dir():
        candidates.extend(tree_paths(path))
    for item in candidates:
        if item.is_symlink() or (hasattr(item, 'is_junction') and item.is_junction()):
            raise ValueError(f'Linked paths are not supported: {item}')


def read_package(data, checksum):
    if not re.fullmatch(r'[0-9a-f]{64}', checksum) or hashlib.sha256(data).hexdigest() != checksum:
        raise ValueError('ZIP checksum mismatch')
    payload, seen = {}, set()
    with ZipFile(io.BytesIO(data)) as archive:
        if sum(e.file_size for e in archive.infolist()) > 50_000_000:
            raise ValueError('Unexpectedly large Soundstone package')
        if archive.testzip() is not None:
            raise ValueError('Corrupt ZIP')
        for entry in archive.infolist():
            path = PurePosixPath(entry.filename)
            parts = path.parts
            if ('\\' in entry.filename or ':' in entry.filename or path.is_absolute()
                    or '..' in parts or not parts or parts[0] != 'Soundstone'
                    or any(p.rstrip(' .') != p for p in parts)
                    or stat.S_ISLNK(entry.external_attr >> 16)):
                raise ValueError(f'Unsafe ZIP entry: {entry.filename}')
            if entry.is_dir():
                continue
            if len(parts) < 2 or path.as_posix() != entry.filename or entry.filename.casefold() in seen:
                raise ValueError(f'Duplicate/noncanonical ZIP entry: {entry.filename}')
            seen.add(entry.filename.casefold())
            payload['/'.join(parts[1:])] = archive.read(entry)
    if not {'Soundstone.toc', 'Bindings.xml', 'LICENSE.txt'} <= payload.keys():
        raise ValueError('Package is missing TOC, bindings, or license')
    toc = payload['Soundstone.toc'].decode('utf-8-sig')
    version = re.search(r'^## Version:\s*(\d+\.\d+\.\d+)\s*$', toc, re.M)
    if not version:
        raise ValueError('Missing semantic TOC version')
    for line in toc.splitlines():
        if line.strip() and not line.startswith('#') and line.strip().replace('\\','/') not in payload:
            raise ValueError(f'Missing TOC module: {line}')
    return payload, version.group(1)


def compare_folder(folder, payload):
    folder = Path(folder)
    reject_links(folder)
    if folder.exists() and not folder.is_dir():
        raise ValueError(f'Expected directory: {folder}')
    actual = {p.relative_to(folder).as_posix(): p for p in tree_paths(folder) if p.is_file()} if folder.exists() else {}
    missing = sorted(payload.keys() - actual.keys())
    extra = sorted(actual.keys() - payload.keys())
    changed = sorted(n for n in payload.keys() & actual.keys() if actual[n].read_bytes() != payload[n])
    return {'exists': folder.is_dir(), 'identical': not (missing or extra or changed),
            'matching_files': len(payload) - len(missing) - len(changed),
            'missing': missing, 'changed': changed, 'extra': extra}
