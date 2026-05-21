# Personal Finance API

Symfony 7.2 REST API bootstrap for personal finance management. Local development runs entirely in Docker.

## Stack

- **PHP 8.5** (CLI) + **RoadRunner** + **Symfony 7.2**
- **PostgreSQL 16**, **Redis 7**
- **JWT** authentication (LexikJWTAuthenticationBundle)
- **OpenAPI** docs (NelmioApiDocBundle) at `/api/docs`
- **Prometheus** metrics at `/metrics/prometheus`
- **Grafana** dashboards (provisioned)
- **PHPUnit**, **PHPStan** (max level), **PHP CS Fixer** (Symfony rules)

## Prerequisites

- Docker & Docker Compose
- Make

## Quick start

```bash
cp .env.example .env   # optional — `make init` copies it automatically
make init              # build images, install deps, JWT keys, migrations
make up                # start all services
```

### Service URLs

| Service    | URL                          |
|------------|------------------------------|
| API        | http://localhost:8080        |
| Health     | http://localhost:8080/health |
| OpenAPI UI | http://localhost:8080/api/docs |
| Metrics    | http://localhost:8080/metrics/prometheus |
| RR metrics | internal `php:2112` (Prometheus job `roadrunner`) |
| RR status  | internal `php:2114` (RoadRunner health) |
| Prometheus | http://localhost:9090        |
| Grafana    | http://localhost:3000 (admin/admin) |

## Makefile commands

```bash
make help        # list all targets
make init        # first-time setup
make up          # start containers
make down        # stop containers
make restart     # restart stack
make test        # cs-check + phpstan + phpunit
make fix         # apply PHP CS Fixer
make stan        # run PHPStan
make shell       # bash into PHP container
make logs        # tail all logs
make logs-rr     # tail RoadRunner/PHP logs
make rr-binary   # download RoadRunner binary
make migrate     # run Doctrine migrations
make clean       # remove containers, volumes, caches
```

## Authentication

Login with JSON credentials:

```bash
curl -X POST http://localhost:8080/api/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","password":"secret"}'
```

Use the returned JWT as `Authorization: Bearer <token>` for protected `/api/*` routes.

> Create users via Doctrine fixtures or `make shell` + `bin/console` once user management endpoints are added.

## RoadRunner vs nginx + PHP-FPM

HTTP is served by **RoadRunner** instead of nginx + PHP-FPM:

| Aspect | nginx + PHP-FPM | RoadRunner |
|--------|-----------------|------------|
| Process model | New PHP bootstrap per request | Long-lived Symfony worker, kernel reused |
| Web server | nginx terminates HTTP | RoadRunner (Go) handles HTTP + static files |
| Static files | nginx `root` / `try_files` | RoadRunner `http.static` in `.rr.yaml` |
| Metrics | Symfony `/metrics/prometheus` | Same route **plus** RR metrics on `:2112` |
| Health | Symfony `/health` | Symfony `/health` **plus** RR status on `:2114` |

Configuration: `.rr.yaml` at project root. Integration via [`baldinof/roadrunner-bundle`](https://github.com/Baldinof/roadrunner-bundle) (Symfony Runtime worker). The `php` container runs `bin/rr serve`.

Prometheus scrapes:

- `php:8080/metrics/prometheus` — application metrics (Artprima bundle)
- `php:2112` — RoadRunner runtime metrics

## Development notes

- All PHP/Composer commands run inside Docker — use `make shell` or `make test`.
- JWT keys are generated into `config/jwt/` on `make init`.
- RoadRunner binary is downloaded to `bin/rr` on `make init` (gitignored).
- Deploy is out of scope for this bootstrap.

## PHP version

This project targets **PHP 8.5** (`php:8.5-cli` Docker image). HTTP is served by **RoadRunner** (`bin/rr serve -c .rr.yaml`). OPcache is bundled in the base image — do not run `docker-php-ext-install opcache` on 8.5 (it breaks the build). If 8.5 is unavailable, switch the Dockerfile base image to `php:8.4-cli`.
