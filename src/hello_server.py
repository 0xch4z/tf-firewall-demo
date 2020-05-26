#!/usr/bin/env python3

import http.server
import socketserver
from http import HTTPStatus

ADDR = '0.0.0.0'
PORT = 80


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(HTTPStatus.OK)
        self.end_headers()
        self.wfile.write(b'{"message": "Hello from Linode DX (:"}')

httpd = socketserver.TCPServer((ADDR, PORT), Handler)
httpd.serve_forever()
