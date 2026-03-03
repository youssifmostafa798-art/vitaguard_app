# VitaGuard Backend Operations

## Architecture

The backend is now started through a single launcher: `scripts/start_server.py`.

- It runs using the virtual environment interpreter directly (`.venv/bin/python` on Linux, `.venv\Scripts\python.exe` on Windows).
- It supports optional Alembic migration on startup (`AUTO_APPLY_MIGRATIONS=true`).
- It starts Uvicorn with environment-controlled host, port, worker count, and log level.
- It does **not** require `activate` scripts.

This gives one runtime contract for all environments:

- local service manager
- Docker container
- production host service

## Recommended Production Strategy

For single-host production:

1. Package backend as a container (`Dockerfile`).
2. Run with `docker-compose` with `restart: unless-stopped` and health checks.
3. Use host startup service (`systemd`) to auto-start Docker/Compose stack on boot.

For VM/bare-metal without Docker:

- Use `systemd` with `.venv` python and `scripts/start_server.py`.

For Windows servers:

- Use NSSM wrapper service (`deploy/windows/install-backend-service.ps1`).

## Implemented Files

- `scripts/start_server.py`
- `Dockerfile`
- `docker-compose.yml`
- `.dockerignore`
- `deploy/systemd/vitaguard-backend.service`
- `deploy/systemd/vitaguard-stack.service`
- `deploy/windows/install-backend-service.ps1`
- `deploy/windows/remove-backend-service.ps1`

## Linux `systemd` install example

```bash
sudo useradd --system --home /opt/vitaguard --shell /usr/sbin/nologin vitaguard
sudo mkdir -p /opt/vitaguard
sudo cp -r backend /opt/vitaguard/backend
sudo cp /opt/vitaguard/backend/deploy/systemd/vitaguard-backend.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable vitaguard-backend.service
sudo systemctl start vitaguard-backend.service
```

## Docker deployment example

```bash
docker compose up -d --build
```

After first provisioning, the host service manager should keep Docker running at boot.

## `systemd` startup for Docker stack

```bash
sudo cp /opt/vitaguard/backend/deploy/systemd/vitaguard-stack.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable vitaguard-stack.service
sudo systemctl start vitaguard-stack.service
```

## Tradeoffs

- `systemd` + `.venv`
  - Pros: simple, native process supervision, minimal moving parts.
  - Cons: host dependency drift unless you manage patching/packaging strictly.

- Docker Compose
  - Pros: reproducible runtime, easy rollback, strong isolation.
  - Cons: extra container runtime dependency, still single-host orchestration.

- Windows service (NSSM)
  - Pros: native startup behavior on Windows, restart on crash, no shell needed.
  - Cons: additional wrapper dependency (`nssm.exe`), Windows-specific.

## Security Recommendations

- Keep `.env` out of source control and inject secrets from a vault/secret manager.
- Set a strong `SECRET_KEY` and rotate it via a managed secret process.
- Run as non-root (already set in Dockerfile).
- Place API behind TLS termination (Nginx/Caddy/cloud LB).
- Restrict CORS and network ingress to trusted origins/subnets.
- Keep `AUTO_APPLY_MIGRATIONS=true` only where rollout policy allows startup migrations.

## Logging and Monitoring

- Emit structured logs (already enabled in production mode).
- Ship stdout/stderr to centralized logging (ELK, Loki, CloudWatch, Datadog).
- Monitor:
  - `/health` liveness
  - `/health/ready` readiness
  - process/container restarts
  - request latency and error rate
- Add uptime alerts and crash-loop alerts from service manager/container platform.

## Real-world Production Rollout

1. Build image in CI and tag with immutable version.
2. Run tests and vulnerability scanning.
3. Deploy image to staging, run migration + smoke tests.
4. Promote to production with rolling/blue-green strategy.
5. Monitor error budget, restart counts, and DB health.
6. Roll back quickly by switching image tag if needed.
