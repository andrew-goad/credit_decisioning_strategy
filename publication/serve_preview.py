"""Serve the extracted CDS explorer on this computer using Python 3."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
from urllib.parse import urlencode
import sys
import webbrowser


def application_id(value):
    match = re.fullmatch(r"(?:APP-)?([0-9]{1,8})", value, flags=re.IGNORECASE)
    if not match or not 1 <= int(match[1]) <= 50_000:
        raise argparse.ArgumentTypeError('Use an applicant ID from 1 to 50,000.')
    return f'APP-{int(match[1]):08d}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=application_id, help='Open a specific applicant.')
    parser.add_argument('--comparison', choices=[f'CG{i:02d}' for i in range(1, 21)],
                        help='Select a recorded policy comparison.')
    args = parser.parse_args()
    folder = Path(__file__).resolve().parent
    if not (folder / 'index.html').is_file() or not (folder / 'data/full/manifest.json').is_file():
        sys.exit('Extract the complete CDS_Teaching_Explorer.zip, then open the launcher from the extracted folder.')
    handler = partial(SimpleHTTPRequestHandler, directory=str(folder))
    with ThreadingHTTPServer(('127.0.0.1', 0), handler) as server:
        url = f'http://127.0.0.1:{server.server_port}/'
        if args.app:
            url += '?' + urlencode({'comparison':args.comparison or 'CG02', 'app':args.app}) + '#paired-case'
        elif args.comparison:
            url += '?' + urlencode({'comparison':args.comparison}) + '#portfolio'
        print(f'Open {url}\nLeave this window open while reading. Press Ctrl+C to close the preview.', flush=True)
        webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()
