import ipaddress
import subprocess
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify(status="ok")

@app.get("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    try:
        ipaddress.ip_address(host)
    except ValueError:
        return jsonify(error="host must be a valid IP address"), 400
    out = subprocess.run(["ping", "-c", "1", host], capture_output=True, text=True, timeout=5)
    return jsonify(output=out.stdout)


@app.after_request
def add_security_headers(response):
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'; form-action 'none'; base-uri 'none'"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = "no-store"
    return response
