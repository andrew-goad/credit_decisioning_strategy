"""Serve the extracted CDS explorer on this computer using Python 3."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sys
import webbrowser


def main():
    folder = Path(__file__).resolve().parent
    if not (folder / 'index.html').is_file() or not (folder / 'data/full/manifest.json').is_file():
        sys.exit('Extract the complete CDS_Teaching_Explorer.zip, then open the launcher from the extracted folder.')
    handler = partial(SimpleHTTPRequestHandler, directory=str(folder))
    with ThreadingHTTPServer(('127.0.0.1', 0), handler) as server:
        url = f'http://127.0.0.1:{server.server_port}/'
        print(f'Open {url}\nLeave this window open while reading. Press Ctrl+C to close the preview.', flush=True)
        webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main()
