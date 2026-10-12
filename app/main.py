import ipaddress
import socket

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
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        return jsonify(error="host must be a valid IP address"), 400

    # An IPv4 address written in IPv6 form (::ffff:127.0.0.1) is judged as IPv4.
    if getattr(address, "ipv4_mapped", None):
        address = address.ipv4_mapped

    # Only public addresses: no loopback, private ranges or the cloud metadata service.
    if not address.is_global:
        return jsonify(error="only public IP addresses can be checked"), 400

    try:
        with socket.create_connection((str(address), CHECK_PORT), timeout=CHECK_TIMEOUT_SECONDS):
            reachable = True
    except OSError:
        reachable = False
    return jsonify(host=str(address), port=CHECK_PORT, reachable=reachable)


@app.after_request
def add_security_headers(response):
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'; form-action 'none'; base-uri 'none'"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = "no-store"
    return response
