#!/usr/bin/env python3
import os
import json
import time
import urllib.request
import urllib.error
import urllib.parse  # <-- NEU: Für die URL-Codierung
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REQUIRED_ENV = ["MATRIX_HOMESERVER", "MATRIX_ROOM_ID", "MATRIX_TOKEN", "WEBHOOK_TOKEN"]
missing_env = [key for key in REQUIRED_ENV if key not in os.environ]

if missing_env:
    print(f"Fehler: Fehlende Umgebungsvariablen: {', '.join(missing_env)}", flush=True)
    exit(1)

MATRIX_HOMESERVER = os.environ["MATRIX_HOMESERVER"].rstrip("/")
MATRIX_ROOM_ID = os.environ["MATRIX_ROOM_ID"]
MATRIX_TOKEN = os.environ["MATRIX_TOKEN"]
WEBHOOK_TOKEN = os.environ["WEBHOOK_TOKEN"]


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        auth = self.headers.get("Authorization", "")
        if auth != f"Bearer {WEBHOOK_TOKEN}":
            self.send_response(401)
            self.end_headers()
            return

        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length).decode("utf-8", errors="replace")

        try:
            data = json.loads(raw)
            body = data.get("body", raw)
        except Exception:
            body = raw

        if not isinstance(body, str):
            body = json.dumps(body, indent=2)

        txn_id = f"crowdsec-{time.time_ns()}"
        
        # <-- NEU: Raum-ID für URL sicher codieren (! -> %21, : -> %3A)
        safe_room_id = urllib.parse.quote(MATRIX_ROOM_ID, safe="")
        url = f"{MATRIX_HOMESERVER}/_matrix/client/v3/rooms/{safe_room_id}/send/m.room.message/{txn_id}"

        payload = json.dumps({
            "msgtype": "m.notice",
            "body": body
        }).encode("utf-8")

        req = urllib.request.Request(
            url,
            data=payload,
            method="PUT",
            headers={
                "Authorization": f"Bearer {MATRIX_TOKEN}",
                "Content-Type": "application/json",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                self.send_response(resp.status)
                self.end_headers()
                self.wfile.write(resp.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode("utf-8"))

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)


if __name__ == "__main__":
    port = 8080
    print(f"Starte Matrix Webhook Server auf Port {port}...", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
