# Image before / after

BEFORE (python:3.10, full image, root user, no multi-stage)
- Size: 1.11 GB
- Vulnerabilities (HIGH+CRITICAL): 344 (325 HIGH, 19 CRITICAL)

AFTER (python:3.13-slim, multi-stage, non-root, pinned by digest)
- Size: 125 MB (89% smaller)
- Vulnerabilities (HIGH+CRITICAL): 46 (44 HIGH, 0 CRITICAL)
- All remaining findings are Debian OS packages with no fix available yet (util-linux family), not reachable by this app
