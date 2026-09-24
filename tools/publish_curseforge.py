"""Publish an approved GitHub release asset, never a rebuilt or untested archive.

Default is a read-only dry run. A persistent intent asset prevents blind retries
after a timeout; see docs/curseforge/README.md for manual reconciliation.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
from release_package import read_package

ROOT = Path(__file__).resolve().parents[1]
REPO = 'krebs3r/soundstone-azeroth-audio'
CF_API = 'https://wow.curseforge.com/api'
# CurseForge WoW version families, also used by BigWigsMods/packager.
# 'forever' taken from CurseForge's WoW Forever search filter; resolve_versions still requires a unique API match.
FAMILIES = {'retail': 517, 'mists': 79434, 'anniversary': 73246, 'era': 67408, 'forever': 88568}
RECEIPT = 'curseforge-upload.json'
INTENT = 'curseforge-upload-pending.json'


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request(url, token=None, method='GET', data=None, content_type='application/json', cf=False):
    headers = {'User-Agent': 'Soundstone-release', 'Accept': 'application/json'}
    if token:
        headers['X-Api-Token' if cf else 'Authorization'] = token if cf else f'Bearer {token}'
    if data is not None:
        headers['Content-Type'] = content_type
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.build_opener(NoRedirect).open(req, timeout=90) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Never print response bodies, tokens, or signed URLs.
        raise RuntimeError(f'{"CurseForge" if cf else "GitHub"} request failed: HTTP {error.code}') from None
    except urllib.error.URLError:
        raise RuntimeError('Network request failed; inspect pending upload state before retrying') from None


class GitHub:
    def __init__(self, token):
        self.token = token
        self.base = f'https://api.github.com/repos/{REPO}'

    def release(self, tag):
        release = request(f'{self.base}/releases/tags/{urllib.parse.quote(tag, safe="")}', self.token)
        assets = []
        page = 1
        while True:
            batch = request(f'{self.base}/releases/{release["id"]}/assets?per_page=100&page={page}', self.token)
            assets.extend(batch)
            if len(batch) < 100:
                break
            page += 1
        release['assets'] = assets
        return release

    def asset(self, release, name):
        matches = [a for a in release['assets'] if a['name'] == name]
        if len(matches) != 1:
            raise ValueError(f'Expected exactly one GitHub release asset: {name}')
        # Public asset download: no credential is forwarded to redirect hosts.
        url = matches[0]['browser_download_url']
        prefix = f'https://github.com/{REPO}/releases/download/'
        if not url.startswith(prefix):
            raise ValueError('Unexpected GitHub asset URL')
        with urllib.request.urlopen(url, timeout=90) as response:
            data = response.read(50_000_001)
        if len(data) > 50_000_000:
            raise ValueError('Release asset too large')
        return data

    def save(self, release, name, value):
        return request(f'https://uploads.github.com/repos/{REPO}/releases/{release["id"]}/assets?name={name}',
                       self.token, 'POST', json.dumps(value, indent=2).encode())


class CurseForge:
    def __init__(self, token, project_id):
        self.token, self.project_id = token, project_id

    def versions(self):
        return request(f'{CF_API}/game/wow/versions', self.token, cf=True)

    def upload(self, filename, data, metadata):
        boundary = 'Soundstone' + uuid.uuid4().hex
        parts = [f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\nContent-Type: application/json\r\n\r\n'.encode(),
                 json.dumps(metadata).encode(),
                 f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\nContent-Type: application/zip\r\n\r\n'.encode(),
                 data, f'\r\n--{boundary}--\r\n'.encode()]
        return request(f'{CF_API}/projects/{self.project_id}/upload-file', self.token, 'POST',
                       b''.join(parts), f'multipart/form-data; boundary={boundary}', cf=True)


def validate_release(release, tag):
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
        raise ValueError('Expected a stable vX.Y.Z tag')
    if release['tag_name'] != tag or release['draft'] or release['prerelease']:
        raise ValueError('CurseForge requires a published regular GitHub release')


def load_record(tag, records=ROOT/'docs/curseforge/releases'):
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
        raise ValueError('Invalid release tag')
    record = json.loads((records/f'{tag}.json').read_text(encoding='utf-8'))
    if record['tag'] != tag or not re.fullmatch(r'[0-9a-f]{40}', record['commit']):
        raise ValueError('Invalid release record')
    changelog = records / record['changelog']
    if changelog.resolve().parent != records.resolve():
        raise ValueError('Changelog must be next to the release record')
    record['changelog_text'] = changelog.read_text(encoding='utf-8')
    return record


def get_package(gh, release, record, cached_archive=None, upload=False):
    name = f'Soundstone-{record["tag"][1:]}.zip'
    if cached_archive:
        if upload:
            raise ValueError('A cached archive is allowed only for a read-only preflight')
        matches = [a for a in release['assets'] if a['name'] == name]
        if len(matches) != 1 or matches[0].get('digest') != 'sha256:' + record['sha256']:
            raise ValueError('Cached archive cannot be verified against the GitHub asset digest')
        archive, checksum = Path(cached_archive).read_bytes(), record['sha256']
    else:
        archive = gh.asset(release, name)
        checksum = gh.asset(release, name + '.sha256').decode('ascii').split()[0]
    if checksum != record['sha256']:
        raise ValueError('Release checksum differs from the acceptance record')
    payload, version = read_package(archive, checksum)
    return archive, payload, version


def resolve_versions(record, versions, evidence_root=ROOT/'docs/curseforge'):
    clients = record['confirmed_clients']
    if not clients:
        raise ValueError('No clients have passed documented in-game acceptance yet')
    selected, seen = [], set()
    for client in clients:
        family = client['client']
        if family not in FAMILIES or family in seen or client.get('status') != 'passed':
            raise ValueError('Unknown, duplicate, or unconfirmed client')
        seen.add(family)
        if not client.get('build') or not client.get('tested_by') or not client.get('tested_at'):
            raise ValueError('Missing in-game test details')
        evidence = (evidence_root / client['evidence']).resolve()
        if not evidence.is_relative_to(evidence_root.resolve()) or not evidence.is_file():
            raise ValueError('Missing in-game acceptance document')
        text = evidence.read_text(encoding='utf-8')
        if record['sha256'] not in text or record['tag'] not in text or client['build'] not in text:
            raise ValueError('Acceptance evidence does not identify this release and client build')
        matches = [v for v in versions if v['name'] == client['game_version']
                   and v['gameVersionTypeID'] == FAMILIES[family]]
        if len(matches) != 1:
            raise ValueError(f'No unique CurseForge version for {family} {client["game_version"]}')
        selected.append(matches[0]['id'])
    return selected


def validate_source(payload, version, record, source):
    commit = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if commit != record['commit']:
        raise ValueError('Source checkout does not match the accepted commit')
    status = subprocess.check_output(['git', '-C', str(source), 'status', '--porcelain', '--untracked-files=no'], text=True)
    if status.strip():
        raise ValueError('Source checkout has modified tracked files')
    paths = subprocess.check_output(['git', '-C', str(source), 'ls-files', 'Soundstone'], text=True).splitlines()
    expected = {name.split('/', 1)[1]: source/name for name in paths}
    expected.update({'LICENSE.txt': source/'LICENSE', 'ANLEITUNG-DE.md': source/'docs/ANLEITUNG-DE.md'})
    if set(expected) != set(payload):
        raise ValueError('ZIP contents differ from the tagged source manifest')
    for name, file in expected.items():
        actual, wanted = payload[name], file.read_bytes()
        if file.suffix.lower() in {'.lua', '.toc', '.xml', '.md', '.txt'} or file.name == 'LICENSE':
            actual, wanted = actual.replace(b'\r\n', b'\n'), wanted.replace(b'\r\n', b'\n')
        if actual != wanted:
            raise ValueError(f'ZIP file differs from the tagged source: {name}')
    if record['tag'] != 'v' + version:
        raise ValueError('Tag and packaged TOC version differ')
    subprocess.run([sys.executable, 'tests/run.py'], cwd=source, check=True)
    # Run existing texture/package validation in isolation; never replace release assets.
    import shutil
    with tempfile.TemporaryDirectory(prefix='soundstone-package-check-') as temp:
        temp = Path(temp)
        for name in ('Soundstone', 'tools'):
            shutil.copytree(source/name, temp/name)
        (temp/'docs').mkdir()
        shutil.copy2(source/'LICENSE', temp/'LICENSE')
        shutil.copy2(source/'docs/ANLEITUNG-DE.md', temp/'docs/ANLEITUNG-DE.md')
        subprocess.run([sys.executable, 'tools/package.py'], cwd=temp, check=True)


def publish(gh, cf, release, record, archive, metadata, upload=False):
    identity = {'tag': record['tag'], 'commit': record['commit'], 'sha256': record['sha256'],
                'project_id': cf.project_id, 'release_id': release['id']}
    names = {a['name'] for a in release['assets']}
    if RECEIPT in names:
        receipt = json.loads(gh.asset(release, RECEIPT))
        if any(receipt.get(k) != v for k,v in identity.items()) or not receipt.get('file_id'):
            raise ValueError('Existing CurseForge receipt conflicts with this release')
        return {'status': 'already-uploaded', **receipt}
    if INTENT in names:
        raise ValueError('Pending upload exists: reconcile its outcome in CurseForge before retrying')
    if not upload:
        return {'status': 'dry-run', **identity, 'metadata': metadata}
    if not gh.token or not cf.token or not str(cf.project_id).isdigit():
        raise ValueError('GH_TOKEN, CF_API_TOKEN and numeric CF_PROJECT_ID are required')
    gh.save(release, INTENT, {**identity, 'started_at': datetime.now(timezone.utc).isoformat()})
    # Deliberately no automatic POST retry: a timeout may mean the upload succeeded.
    result = cf.upload(f'Soundstone-{record["tag"][1:]}.zip', archive, metadata)
    if not isinstance(result.get('id'), int) or result['id'] <= 0:
        raise ValueError('Upload outcome is unknown; reconcile the pending upload')
    receipt = {**identity, 'file_id': result['id'], 'uploaded_at': datetime.now(timezone.utc).isoformat(),
               'game_versions': metadata['gameVersions'], 'moderation': 'not-verified'}
    gh.save(release, RECEIPT, receipt)
    return {'status': 'uploaded-awaiting-moderation', **receipt}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--source', type=Path, required=True, help='Clean checkout of the release tag')
    parser.add_argument('--upload', action='store_true', help='Actually upload; default is dry-run')
    parser.add_argument('--archive', type=Path, help='Read-only preflight with a cached ZIP; requires matching GitHub asset digest')
    parser.add_argument('--output', type=Path, default=ROOT/'dist/curseforge-result.json')
    args = parser.parse_args()
    record = load_record(args.tag)
    gh = GitHub(os.environ.get('GH_TOKEN', ''))
    cf = CurseForge(os.environ.get('CF_API_TOKEN', ''), os.environ.get('CF_PROJECT_ID', ''))
    release = gh.release(args.tag)
    validate_release(release, args.tag)
    version = args.tag[1:]
    archive, payload, packaged_version = get_package(gh, release, record, args.archive, args.upload)
    validate_source(payload, packaged_version, record, args.source.resolve())
    if not record['confirmed_clients']:
        raise ValueError('Technical checks passed; in-game acceptance is still missing')
    if not cf.token or not str(cf.project_id).isdigit():
        raise ValueError('Set CF_API_TOKEN and numeric CF_PROJECT_ID for the full API dry-run')
    game_versions = resolve_versions(record, cf.versions())
    metadata = {'displayName': f'Soundstone {version}', 'changelog': record['changelog_text'],
                'changelogType': 'markdown', 'releaseType': 'release', 'gameVersions': game_versions,
                'isMarkedForManualRelease': False}
    result = publish(gh, cf, release, record, archive, metadata, args.upload)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error))
