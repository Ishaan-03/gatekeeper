#checkov:skip=CKV_DOCKER_2:Kubernetes ignores Dockerfile HEALTHCHECK; health probes are defined in the pod spec instead
FROM python:3.13-slim@sha256:70729b46c69b4f1e97c4822c1af3df53a1476cf5ddc6c087c0c10bc3a5678c2f AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.13-slim@sha256:70729b46c69b4f1e97c4822c1af3df53a1476cf5ddc6c087c0c10bc3a5678c2f
ENV PYTHONDONTWRITEBYTECODE=1
RUN python -m pip uninstall -y pip
COPY --from=builder /install /usr/local
WORKDIR /app
COPY app/main.py .
USER 10001
EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--worker-tmp-dir", "/tmp", "main:app"]
