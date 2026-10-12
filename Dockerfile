#checkov:skip=CKV_DOCKER_2:Kubernetes ignores Dockerfile HEALTHCHECK; health probes are defined in the pod spec instead
FROM python:3.14-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170 AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.14-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170
ENV PYTHONDONTWRITEBYTECODE=1
RUN python -m pip uninstall -y pip
COPY --from=builder /install /usr/local
WORKDIR /app
COPY app/main.py .
USER 10001
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--worker-tmp-dir", "/tmp", "main:app"]
