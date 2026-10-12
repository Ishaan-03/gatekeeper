import ipaddress
import socket
import subprocess

from flask import Flask, jsonify, request

app = Flask(__name__)

CHECK_PORT = 443
CHECK_TIMEOUT_SECONDS = 3


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.get("/ping")
def ping():
    host = request.args.get("host", "")
    out = subprocess.run(f"ping -c 1 {host}", shell=True, capture_output=True, text=True)
    return jsonify(output=out.stdout)


@app.after_request
def add_security_headers(response):
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'; form-action 'none'; base-uri 'none'"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = "no-store"
    return response
