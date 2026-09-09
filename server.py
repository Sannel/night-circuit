#!/usr/bin/env python3
"""Tiny static server for the Night Circuit 2076 screensaver.

Serves files under ROOT (html/js/css/png). /exit terminates the process so
the runner can tear down chromium. Threading + silent logs.

Usage: python3 server.py <document-root> <port>
"""
import os
import sys
import mimetypes
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 0


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            path = self.path.split("?")[0]
            if path == "/exit":
                self.send_response(204)
                self.end_headers()
                sys.stdout.write(self.path + "\n")
                sys.stdout.flush()
                os._exit(0)
            if path == "/beat":
                self.send_response(204)
                self.end_headers()
                return
            if path in ("/", "/index.html"):
                name = "night-circuit.html"
            else:
                name = path.lstrip("/")
            full = os.path.normpath(os.path.join(ROOT, name))
            if not full.startswith(ROOT) or not os.path.isfile(full):
                self.send_error(404)
                return
            with open(full, "rb") as fh:
                data = fh.read()
            self.send_response(200)
            ctype = mimetypes.guess_type(full)[0] or "application/octet-stream"
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.end_headers()
            self.wfile.write(data)
        except SystemExit:
            raise
        except Exception:
            self.send_error(404)

    def log_message(self, fmt, *args):
        pass


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"listening {server.server_port}", flush=True)
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()