#!/usr/bin/env python3
"""App mínima de la AMI: página con versión + endpoint /health (HTTP 200)."""
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = os.environ.get("APP_VERSION", "dev")
HOSTNAME = socket.gethostname()
PORT = int(os.environ.get("APP_PORT", "8080"))

# El color del fondo depende de la versión: en la demo del rolling update
# se ve a simple vista cuándo una instancia nueva reemplaza a una vieja.
HUE = sum(ord(c) for c in VERSION) * 37 % 360

PAGE = f"""<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Mi App - v{VERSION}</title>
  <style>
    body {{ margin:0; min-height:100vh; display:grid; place-items:center;
           font-family: system-ui, sans-serif; color:#fff;
           background: hsl({HUE}, 60%, 35%); }}
    main {{ text-align:center; padding:2rem; }}
    h1 {{ font-size:3rem; margin:0 0 .5rem; }}
    code {{ background:rgba(0,0,0,.25); padding:.2rem .5rem; border-radius:.4rem; }}
  </style>
</head>
<body>
  <main>
    <h1>Infraestructura Inmutable</h1>
    <p>Versión de la app: <code>{VERSION}</code></p>
    <p>Servida por la instancia: <code>{HOSTNAME}</code></p>
  </main>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/health":
            self._send(200, "ok", "text/plain; charset=utf-8")
        elif path == "/":
            self._send(200, PAGE, "text/html; charset=utf-8")
        else:
            self._send(404, "not found", "text/plain; charset=utf-8")


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
