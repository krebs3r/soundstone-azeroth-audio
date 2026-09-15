"""Status/dry-run or transactional installation of a validated Soundstone release ZIP."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from release_package import read_package, compare_folder, reject_links, tree_paths

ROOT = Path(__file__).resolve().parents[1]
CLIENTS = {'retail': '_retail_', 'mists': '_classic_', 'anniversary': '_anniversary_', 'era': '_classic_era_'}
DEFAULT_WOW = Path(r'E:\Battle.net\World of Warcraft')


def target_for(wow_root, client):
    root = Path(wow_root).absolute()
    reject_links(root, recursive=False)
    target = root / CLIENTS[client] / 'Interface' / 'AddOns' / 'Soundstone'
    reject_links(target)
    if not (root / CLIENTS[client]).is_dir():
        raise ValueError(f'Client not installed: {client}')
    if target.resolve() != target or target.resolve().parents[3] != root.resolve():
        raise ValueError('Destination escaped the selected WoW root')
    return target


def running_clients(wow_root):
    if os.name != 'nt':
        raise RuntimeError('Live installation requires Windows process detection')
    command = ("$ErrorActionPreference='Stop'; @(Get-CimInstance Win32_Process | "
               "Where-Object { $_.Name -match '^Wow.*\\.exe$' } | "
               "Select-Object Name,ExecutablePath) | ConvertTo-Json -Compress")
    result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', command],
                            capture_output=True, text=True, check=True)
    rows = json.loads(result.stdout) if result.stdout.strip() else []
    if isinstance(rows, dict):
        rows = [rows]
    active = set()
    for row in rows:
        if not row.get('ExecutablePath'):
            raise RuntimeError('Cannot locate a running WoW process; close WoW and retry')
        exe = Path(row['ExecutablePath']).resolve()
        for client, directory in CLIENTS.items():
            if exe.is_relative_to((Path(wow_root) / directory).resolve()):
                active.add(client)
    return active


def install(wow_root, client, payload, backup_root, process_check=running_clients, *, allow_running=False):
    destination = target_for(wow_root, client)
    result = {'client': client, 'destination': str(destination)}
    if allow_running and not (destination / 'Soundstone.toc').is_file():
        raise ValueError('--allow-running is only supported for an existing Soundstone installation')
    def must_defer():
        running = client in process_check(wow_root)
        if running and allow_running:
            result['reload_required'] = True
        return running and not allow_running
    if must_defer():
        return {**result, 'status': 'deferred-running'}
    if compare_folder(destination, payload)['identical']:
        return {**result, 'status': 'already-current'}
    destination.parent.mkdir(parents=True, exist_ok=True)
    transaction = Path(tempfile.mkdtemp(prefix='.Soundstone-install-', dir=destination.parent))
    stage, previous = transaction / 'new', transaction / 'previous'
    backup, committed, moved_old = None, False, False
    try:
        stage.mkdir()
        for name, data in payload.items():
            target = stage / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        if not compare_folder(stage, payload)['identical']:
            raise RuntimeError('Staged installation verification failed')
        if must_defer():
            return {**result, 'status': 'deferred-running'}
        target_for(wow_root, client)
        if destination.exists():
            stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
            backup = Path(backup_root).absolute() / f'{stamp}-{client}'
            reject_links(backup)
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(destination, backup)
            original = {p.relative_to(destination).as_posix(): p.read_bytes()
                        for p in tree_paths(destination) if p.is_file()}
            if not compare_folder(backup, original)['identical']:
                raise RuntimeError('Backup verification failed')
            if must_defer():
                return {**result, 'status': 'deferred-running', 'backup': str(backup)}
            target_for(wow_root, client)
            destination.rename(previous)
            moved_old = True
        installed_new = False
        try:
            stage.rename(destination)
            installed_new = True
            if not compare_folder(destination, payload)['identical']:
                raise RuntimeError('Installed files differ from package')
        except Exception:
            if installed_new:
                destination.rename(transaction / 'failed')
            if moved_old:
                previous.rename(destination)
                moved_old = False
            raise
        committed = True
        return {**result, 'status': 'installed', 'files': len(payload), 'backup': str(backup) if backup else None}
    finally:
        # Preserve the transaction if rollback failed. Never remove the only recovery copy.
        if not committed and moved_old:
            raise RuntimeError(f'Recovery required; preserved installation at {previous}')
        reject_links(transaction)
        if transaction.resolve().parent != destination.parent.resolve() or not transaction.name.startswith('.Soundstone-install-'):
            raise RuntimeError('Refusing cleanup outside the installation transaction')
        shutil.rmtree(transaction)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', nargs='?', type=Path, help='Exact Soundstone path; --install is required to write')
    parser.add_argument('--root', type=Path, default=DEFAULT_WOW)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument('--client', choices=CLIENTS, action='append')
    selection.add_argument('--all', action='store_true')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--install', action='store_true')
    mode.add_argument('--dry-run', action='store_true')
    mode.add_argument('--status', action='store_true')
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--allow-running', action='store_true',
                        help='Update an existing addon while WoW runs; use /reload only after installation finishes')
    args = parser.parse_args()
    if args.allow_running and not args.install:
        parser.error('--allow-running requires --install')
    if args.destination:
        target = args.destination.absolute()
        if target.parts[-3:] != ('Interface', 'AddOns', 'Soundstone'):
            parser.error('Destination must end in Interface/AddOns/Soundstone')
        args.root = target.parents[3]
        args.client = [k for k, v in CLIENTS.items() if v == target.parents[2].name]
        if not args.client:
            parser.error('Unknown WoW client directory')
    version = re.search(r'^## Version: ([\d.]+)$', (ROOT/'Soundstone/Soundstone.toc').read_text(), re.M).group(1)
    archive = args.archive or ROOT / 'dist' / f'Soundstone-{version}.zip'
    checksum = archive.with_name(archive.name + '.sha256').read_text().split()[0]
    payload, version = read_package(archive.read_bytes(), checksum)
    clients = args.client or [k for k,v in CLIENTS.items() if (args.root/v).is_dir()]
    if not clients:
        parser.error('No installed WoW clients found')
    results = []
    for client in clients:
        if args.install:
            result = install(args.root, client, payload, ROOT/'.local-history/install-backups',
                             allow_running=args.allow_running)
        else:
            target = target_for(args.root, client)
            result = {'client': client, 'destination': str(target), **compare_folder(target, payload)}
        results.append(result)
    report = {'version': version, 'sha256': checksum, 'mode': 'install' if args.install else 'read-only', 'clients': results}
    print(json.dumps(report, indent=2))
    if args.install:
        output = ROOT/'.local-history/last-install.json'
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    return 2 if any(r.get('status') == 'deferred-running' for r in results) else 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error))
