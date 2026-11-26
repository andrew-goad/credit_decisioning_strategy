"""Build the proposed CDS release downloads from one verified site directory."""
import argparse
import hashlib
from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED, ZIP_STORED

HERE = Path(__file__).resolve().parent
FULL_SITE = 'CDS_Teaching_Explorer.zip'
STANDALONE = 'Credit_Strategy_Explorer.html'
INSTRUCTIONS = """Credit Decisioning Strategy Simulator

Extract the entire ZIP to a folder. On Windows, double-click Open_Preview.cmd.
On macOS or Linux, run python3 serve_preview.py from the extracted folder.
The launcher requires Python 3 and serves the explorer only on this computer.
The console displays the URL. Keep the console open while reading.

Start with the auto loan. Switch from Baseline to Growth, then follow the
same comparison to its 50,000 applications. Explore applicants also accepts
any application ID from 1 through 50,000 across the 39 recorded runs.
The saved decisions and source excerpts work locally. Links to GitHub
and other external sources require internet access.
"""


def put(archive, name, data):
    # Keep downloaded bytes reproducible across checkouts and build dates.
    entry = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    entry.create_system = 3
    entry.external_attr = 0o100644 << 16
    archive.writestr(entry, data, compress_type=ZIP_STORED if name.endswith('.gz') else ZIP_DEFLATED)


def package(site, output):
    site = site.resolve()
    output = output.resolve()
    if output == site or site in output.parents:
        raise ValueError('Use an output folder outside the deployed site.')
    source = site / 'index.html'
    if not source.is_file() or not (site / 'data/full/manifest.json').is_file():
        raise ValueError('The site directory must contain the complete, verified explorer.')
    output.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(dir=output) as tmp:
        stage = Path(tmp)
        with ZipFile(stage / FULL_SITE, 'w') as archive:
            for path in sorted(site.rglob('*')):
                if path.is_file():
                    put(archive, path.relative_to(site).as_posix(), path.read_bytes())
            for filename in ('Open_Preview.cmd', 'serve_preview.py'):
                data = (HERE / filename).read_bytes()
                if filename.endswith('.cmd'):
                    data = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
                put(archive, filename, data)
            put(archive, 'READ_ME_FIRST.txt', INSTRUCTIONS.encode('utf-8'))
        shutil.copyfile(source, stage / STANDALONE)
        with ZipFile(stage / FULL_SITE) as archive:
            bad = archive.testzip()
            if bad or archive.read('index.html') != (stage / STANDALONE).read_bytes():
                raise ValueError(f'Archive verification failed: {bad or "index mismatch"}')
        sums = ''.join(f'{hashlib.sha256((stage / name).read_bytes()).hexdigest()}  {name}\n'
                       for name in (FULL_SITE, STANDALONE))
        (stage / 'SHA256SUMS.txt').write_bytes(sums.encode('ascii'))
        files = (FULL_SITE, STANDALONE, 'SHA256SUMS.txt')
        for name in files:
            dest = output / name
            if dest.exists() and dest.read_bytes() != (stage / name).read_bytes():
                raise FileExistsError(f'Choose a new output folder to keep the earlier edition at {dest}.')
        for name in files:
            (stage / name).replace(output / name)
        print(sums, end='')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site', type=Path, default=HERE.parent / 'site')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    package(args.site, args.output)
