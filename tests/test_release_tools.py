"""Offline regression tests for deployment boundaries and recovery behavior."""
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from release_package import read_package, compare_folder
import publish_curseforge as cf
spec = importlib.util.spec_from_file_location('installer', ROOT/'tools/install-local.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def zip_bytes(entries=None):
    data = io.BytesIO()
    entries = entries or {'Soundstone/Soundstone.toc': '## Version: 0.3.0\nCore.lua\n',
                          'Soundstone/Core.lua': 'return true', 'Soundstone/Bindings.xml': '<Bindings/>',
                          'Soundstone/LICENSE.txt': 'MIT'}
    with ZipFile(data, 'w') as z:
        for name, content in entries.items():
            z.writestr(name, content)
    return data.getvalue()


class PackageTests(unittest.TestCase):
    def test_valid(self):
        data = zip_bytes()
        payload, version = read_package(data, hashlib.sha256(data).hexdigest())
        self.assertEqual(version, '0.3.0')
        self.assertEqual(len(payload), 4)

    def test_checksum(self):
        with self.assertRaisesRegex(ValueError, 'checksum'):
            read_package(zip_bytes(), '0'*64)

    def test_unreadable_folder_fails_closed(self):
        with patch('release_package.os.scandir', side_effect=PermissionError('denied')):
            with self.assertRaises(PermissionError):
                compare_folder(ROOT, {})

    def test_unsafe_paths(self):
        for name in ('../outside', 'Other/thing', 'Soundstone/../outside',
                     'Soundstone/C:stream', 'Soundstone\\x', '/Soundstone/x', 'Soundstone/x. '):
            with self.subTest(name=name):
                data = zip_bytes({name: 'x'})
                with self.assertRaises(ValueError):
                    read_package(data, hashlib.sha256(data).hexdigest())

    def test_missing_module(self):
        data = zip_bytes({'Soundstone/Soundstone.toc': '## Version: 0.3.0\nAbsent.lua',
                          'Soundstone/Bindings.xml': '<Bindings/>', 'Soundstone/LICENSE.txt': 'MIT'})
        with self.assertRaisesRegex(ValueError, 'module'):
            read_package(data, hashlib.sha256(data).hexdigest())


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)/'WoW'
        (self.root/'_retail_').mkdir(parents=True)
        self.backup = Path(self.temp.name)/'backups'
        data = zip_bytes()
        self.payload, _ = read_package(data, hashlib.sha256(data).hexdigest())
        self.target = installer.target_for(self.root, 'retail')

    def install(self, check=lambda root: set()):
        return installer.install(self.root, 'retail', self.payload, self.backup, check)

    def test_first_install_and_idempotence(self):
        self.assertEqual(self.install()['status'], 'installed')
        self.assertTrue(compare_folder(self.target, self.payload)['identical'])
        self.assertEqual(self.install()['status'], 'already-current')

    def test_status_is_read_only(self):
        self.assertFalse(compare_folder(self.target, self.payload)['identical'])
        self.assertFalse(self.target.parent.exists())

    def test_update_removes_stale_files_and_keeps_backup_and_wtf(self):
        self.target.mkdir(parents=True)
        (self.target/'old.lua').write_text('old')
        wtf = self.root/'_retail_'/'WTF'
        wtf.mkdir()
        (wtf/'saved.lua').write_text('settings')
        result = self.install()
        self.assertTrue(compare_folder(self.target, self.payload)['identical'])
        self.assertEqual((Path(result['backup'])/'old.lua').read_text(), 'old')
        self.assertEqual((wtf/'saved.lua').read_text(), 'settings')

    def test_running_client_is_deferred(self):
        self.assertEqual(self.install(lambda root: {'retail'})['status'], 'deferred-running')
        self.assertFalse(self.target.exists())

    def test_explicit_running_update_verifies_and_backs_up(self):
        self.install()
        original = self.payload['Core.lua']
        (self.target/'obsolete.lua').write_text('old')
        self.payload['Core.lua'] = b'return false'
        result = installer.install(self.root, 'retail', self.payload, self.backup,
                                   lambda root: {'retail'}, allow_running=True)
        self.assertEqual(result['status'], 'installed')
        self.assertTrue(result['reload_required'])
        self.assertTrue(compare_folder(self.target, self.payload)['identical'])
        self.assertEqual((Path(result['backup'])/'Core.lua').read_bytes(), original)
        self.assertEqual((Path(result['backup'])/'obsolete.lua').read_text(), 'old')

    def test_running_override_rejects_new_installation(self):
        with self.assertRaisesRegex(ValueError, 'existing Soundstone'):
            installer.install(self.root, 'retail', self.payload, self.backup,
                              lambda root: {'retail'}, allow_running=True)
        self.assertFalse(self.target.exists())

    def test_running_at_commit_is_deferred(self):
        with patch.object(installer, 'running_clients'):
            check = unittest.mock.Mock(side_effect=[set(), {'retail'}])
            self.assertEqual(self.install(check)['status'], 'deferred-running')
            self.assertFalse(self.target.exists())

    def test_failed_swap_restores_previous(self):
        self.target.mkdir(parents=True)
        (self.target/'old.lua').write_text('original')
        real_rename = Path.rename
        def fail_new(path, target):
            if path.name == 'new':
                raise OSError('simulated rename failure')
            return real_rename(path, target)
        with patch.object(Path, 'rename', fail_new):
            with self.assertRaises(OSError):
                self.install()
        self.assertEqual((self.target/'old.lua').read_text(), 'original')
        self.assertFalse((self.target/'Core.lua').exists())

    def test_client_started_during_backup_is_deferred(self):
        self.target.mkdir(parents=True)
        (self.target/'old.lua').write_text('original')
        check = unittest.mock.Mock(side_effect=[set(), set(), {'retail'}])
        result = self.install(check)
        self.assertEqual(result['status'], 'deferred-running')
        self.assertEqual((self.target/'old.lua').read_text(), 'original')
        self.assertEqual((Path(result['backup'])/'old.lua').read_text(), 'original')

    def test_unknown_or_missing_client(self):
        with self.assertRaises(ValueError):
            installer.target_for(self.root, 'era')
        with self.assertRaises(KeyError):
            installer.target_for(self.root, '../outside')

    def test_link_target_rejected(self):
        other = Path(self.temp.name)/'outside'
        other.mkdir()
        self.target.parent.mkdir(parents=True)
        try:
            self.target.symlink_to(other, target_is_directory=True)
        except OSError:
            self.skipTest('Symlink privilege unavailable')
        with self.assertRaises(ValueError):
            self.install()


class FakeGitHub:
    token = 'test'
    def __init__(self):
        self.assets = {}
    def asset(self, release, name):
        return json.dumps(self.assets[name]).encode()
    def save(self, release, name, value):
        self.assets[name] = value
        release['assets'].append({'name': name})


class FakeCF:
    token, project_id = 'test', '123'
    def __init__(self):
        self.calls = 0
    def upload(self, filename, data, metadata):
        self.calls += 1
        return {'id': 456}


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.release = {'id': 7, 'tag_name': 'v0.3.0', 'draft': False, 'prerelease': False, 'assets': []}
        self.record = {'tag': 'v0.3.0', 'commit': 'a'*40, 'sha256': 'b'*64}
        self.gh, self.cf = FakeGitHub(), FakeCF()
        self.metadata = {'gameVersions': [22]}

    def publish(self, upload=False):
        return cf.publish(self.gh, self.cf, self.release, self.record, b'zip', self.metadata, upload)

    def test_dry_run_never_writes(self):
        self.assertEqual(self.publish()['status'], 'dry-run')
        self.assertEqual(self.cf.calls, 0)
        self.assertFalse(self.gh.assets)

    def test_regular_release_gate(self):
        cf.validate_release(self.release, 'v0.3.0')
        for key in ('draft', 'prerelease'):
            with self.subTest(key=key), self.assertRaises(ValueError):
                cf.validate_release({**self.release, key: True}, 'v0.3.0')
        with self.assertRaises(ValueError):
            cf.validate_release(self.release, 'v0.3.0-beta')

    def test_cached_preflight_requires_remote_digest_and_never_uploads(self):
        data = zip_bytes()
        record = {**self.record, 'sha256': hashlib.sha256(data).hexdigest()}
        release = {**self.release, 'assets': [{'name': 'Soundstone-0.3.0.zip',
                    'digest': 'sha256:' + record['sha256']}]}
        with tempfile.TemporaryDirectory() as temp:
            archive = Path(temp)/'release.zip'
            archive.write_bytes(data)
            self.assertEqual(cf.get_package(self.gh, release, record, archive)[2], '0.3.0')
            with self.assertRaisesRegex(ValueError, 'read-only'):
                cf.get_package(self.gh, release, record, archive, upload=True)
            release['assets'][0]['digest'] = 'sha256:' + '0'*64
            with self.assertRaisesRegex(ValueError, 'digest'):
                cf.get_package(self.gh, release, record, archive)

    def test_receipt_prevents_duplicate(self):
        self.assertEqual(self.publish(True)['file_id'], 456)
        self.assertEqual(self.publish(True)['status'], 'already-uploaded')
        self.assertEqual(self.cf.calls, 1)

    def test_uncertain_upload_blocks_retry(self):
        with patch.object(self.cf, 'upload', side_effect=TimeoutError('uncertain')):
            with self.assertRaises(TimeoutError):
                self.publish(True)
        with self.assertRaisesRegex(ValueError, 'Pending'):
            self.publish(True)

    def test_failed_receipt_save_blocks_retry(self):
        real_save = self.gh.save
        def save(release, name, value):
            if name == cf.RECEIPT:
                raise OSError('failed receipt')
            return real_save(release, name, value)
        with patch.object(self.gh, 'save', side_effect=save), self.assertRaises(OSError):
            self.publish(True)
        with self.assertRaisesRegex(ValueError, 'Pending'):
            self.publish(True)
        self.assertEqual(self.cf.calls, 1)

    def test_missing_credentials_do_not_create_intent(self):
        self.cf.token = ''
        with self.assertRaises(ValueError):
            self.publish(True)
        self.assertFalse(self.gh.assets)

    def test_conflicting_receipt(self):
        self.publish(True)
        self.record['sha256'] = 'c'*64
        with self.assertRaisesRegex(ValueError, 'conflicts'):
            self.publish(True)

    def test_client_evidence_and_version_resolution(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root/'test.md').write_text('v0.3.0\n'+'b'*64+'\n12.1.0.69814')
            client = {'client': 'retail', 'game_version': '12.1.0', 'build': '12.1.0.69814',
                      'status': 'passed', 'tested_by': 'tester', 'tested_at': '2026-09-15', 'evidence': 'test.md'}
            record = {**self.record, 'confirmed_clients': [client]}
            versions = [{'name': '12.1.0', 'gameVersionTypeID': 517, 'id': 22}]
            self.assertEqual(cf.resolve_versions(record, versions, root), [22])
            for bad in ([], versions*2, [{**versions[0], 'gameVersionTypeID': 67408}]):
                with self.assertRaises(ValueError):
                    cf.resolve_versions(record, bad, root)
            with self.assertRaises(ValueError):
                cf.resolve_versions({**record, 'confirmed_clients': []}, versions, root)
            client['status'] = 'pending'
            with self.assertRaises(ValueError):
                cf.resolve_versions(record, versions, root)


if __name__ == '__main__':
    unittest.main()
