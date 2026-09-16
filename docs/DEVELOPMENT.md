# Development

Runtime code is Lua 5.1 compatible. Development uses Python 3.10+ and the dependencies in `requirements-dev.txt`; CI runs Python 3.12. Run these commands from the repository root:

```sh
python -m pip install -r requirements-dev.txt
python tests/run.py
python -m unittest discover -s tests -p 'test_release_tools.py'
python tools/preview.py
python tools/package.py
```

The Lua suite runs simulated client/API configurations with native and fallback dropdown menus. Packaging validates TOC entries, XML, textures, shared header bounds and ZIP integrity. The result is `dist/Soundstone-0.3.2.zip` with one installable `Soundstone/` folder and a SHA-256 file.

`python tools/preview.py` generates a browser preview using production textures and layout metadata. Serve `docs/` locally to inspect `ui-preview.html`, `readme-gallery.html` and `readme-details.html`. See [preview export instructions](screenshots/README.md) to regenerate the README images. Fonts and native controls are approximated; visual changes still need to be checked in game. `tools/export-assets.ps1` exports the artwork.

Pushes and pull requests run **Validate and package** and produce an installable ZIP. A matching version tag builds and publishes a prerelease; a tested release is promoted explicitly. See the [CurseForge release guide](curseforge/README.md) for approved-release uploads and the local multi-client installer.

See the [changelog](../CHANGELOG.md), [validation status](TESTING.md) and [German guide](ANLEITUNG-DE.md) for release history and testing details. Release notes are maintained outside the addon; the version footer has no changelog popup in 0.3.2.
