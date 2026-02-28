#!/usr/bin/env python3
"""
Dexcom Developer API OAuth2 Setup

One-time script to authorize your Dexcom account.
Opens a browser for login, captures the callback, and stores tokens in ~/.dex-tokens.

Usage: python3 dexcom-auth.py
"""

import http.server
import json
import os
import secrets
import sys
import urllib.parse
import urllib.request
import webbrowser

TOKEN_FILE = os.path.expanduser("~/.dex-tokens")
REDIRECT_PORT = 8642
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}/callback"

# Dexcom US (where developer app is registered)
BASE_URL = "https://api.dexcom.com"

CLIENT_ID = "g35eDqOtMRxAIfxouQHoKWrolUOvNUly"
CLIENT_SECRET = "TBz57qvrrWu4u1B0"


def exchange_code(code):
    """Exchange authorization code for tokens."""
    data = urllib.parse.urlencode({
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": REDIRECT_URI,
    }).encode()

    req = urllib.request.Request(
        f"{BASE_URL}/v3/oauth2/token",
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"Token exchange failed ({e.code}): {body}", file=sys.stderr)
        sys.exit(1)


def save_tokens(token_data):
    """Save tokens to file with restricted permissions."""
    to_save = {
        "access_token": token_data["access_token"],
        "refresh_token": token_data["refresh_token"],
        "base_url": BASE_URL,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }

    fd = os.open(TOKEN_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(to_save, f, indent=2)
    print(f"Tokens saved to {TOKEN_FILE}")


class CallbackHandler(http.server.BaseHTTPRequestHandler):
    """HTTP handler to capture the OAuth2 callback."""

    auth_code = None

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if parsed.path == "/callback" and "code" in params:
            CallbackHandler.auth_code = params["code"][0]
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>Authorization successful!</h1><p>You can close this tab.</p>")
        else:
            error = params.get("error", ["unknown"])[0]
            self.send_response(400)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(f"<h1>Error: {error}</h1>".encode())

    def log_message(self, format, *args):
        pass  # suppress server logs


def main():
    state = secrets.token_urlsafe(16)

    auth_url = (
        f"{BASE_URL}/v3/oauth2/login?"
        f"client_id={CLIENT_ID}&"
        f"redirect_uri={urllib.parse.quote(REDIRECT_URI, safe='')}&"
        f"response_type=code&"
        f"scope=offline_access&"
        f"state={state}"
    )

    print("Opening browser for Dexcom login...")
    print(f"If the browser doesn't open, go to:\n{auth_url}\n")
    webbrowser.open(auth_url)

    server = http.server.HTTPServer(("127.0.0.1", REDIRECT_PORT), CallbackHandler)
    print(f"Waiting for callback on port {REDIRECT_PORT}...")
    server.handle_request()

    if not CallbackHandler.auth_code:
        print("No authorization code received.", file=sys.stderr)
        sys.exit(1)

    print("Got authorization code, exchanging for tokens...")
    token_data = exchange_code(CallbackHandler.auth_code)
    save_tokens(token_data)
    print("Done! The dexcom polybar module should now work.")


if __name__ == "__main__":
    main()
