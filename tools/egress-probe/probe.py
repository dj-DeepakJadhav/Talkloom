"""Tiny egress probe: does the Meta Model API accept this network?

Deploy as a Render web service in the region under test and set META_KEY.
GET / returns status codes and model ids only; the key is never echoed.
"""
import json
import os
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

BASE = "https://api.meta.ai/v1"


def call(method, path, body=None):
    key = os.environ.get("META_KEY", "")
    req = urllib.request.Request(
        BASE + path,
        method=method,
        data=json.dumps(body).encode() if body else None,
        headers={
            "Authorization": "Bearer " + key,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()
    except Exception as e:  # network failure
        return 0, repr(e)


def report():
    status, text = call("GET", "/models")
    ids = []
    if status == 200:
        ids = [m.get("id") for m in json.loads(text).get("data", [])]
    out = {"key_set": bool(os.environ.get("META_KEY")), "models_status": status, "models": ids}
    for model in ("muse-spark-1.3", "muse-spark-1.3-contributor"):
        s, t = call("POST", "/chat/completions", {
            "model": model,
            "reasoning_effort": "low",
            "messages": [{"role": "user", "content": "Reply with the word ok."}],
            "max_tokens": 64,
        })
        code = None
        if s != 200:
            try:
                code = json.loads(t).get("error", {}).get("code")
            except Exception:
                code = t[:80]
        out["chat_" + model] = {"status": s, "error_code": code}
    try:
        with urllib.request.urlopen("https://api.ipify.org", timeout=10) as r:
            out["egress_ip"] = r.read().decode()
    except Exception as e:
        out["egress_ip"] = repr(e)
    return out


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(report(), indent=2).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
