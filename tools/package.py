"""Builds the release archive dist/LiberateSpell-<version>.zip.

The mod files sit at the root of the archive, so Mod Organizer 2 and the
OpenMW Launcher both recognize it as a data folder.
"""
import os
import zipfile

VERSION = '1.0.0'
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MOD = os.path.join(ROOT, 'mod')
DIST = os.path.join(ROOT, 'dist')

EXTRA = {
    'README.md': 'Liberate Spell - Readme.md',
    'CHANGELOG.md': 'Liberate Spell - Changelog.md',
    'LICENSE': 'Liberate Spell - License.txt',
}


def main():
    os.makedirs(DIST, exist_ok=True)
    out = os.path.join(DIST, f'LiberateSpell-{VERSION}.zip')
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        for folder, _, files in os.walk(MOD):
            for name in sorted(files):
                path = os.path.join(folder, name)
                z.write(path, os.path.relpath(path, MOD).replace(os.sep, '/'))
        for src, dest in EXTRA.items():
            z.write(os.path.join(ROOT, src), dest)
    print(f'Wrote {out}')
    with zipfile.ZipFile(out) as z:
        for info in z.infolist():
            print(f'  {info.file_size:>7}  {info.filename}')


if __name__ == '__main__':
    main()
