# AGENTS.md — правила для AI-агентов и разработчиков

Краткая шпаргалка по проекту **Personal Finance API**. Подробности — в [README.md](README.md).

## Что это

- REST API для учёта личных финансов
- **Symfony 7.2**, **PHP 8.5**, PostgreSQL 16, Redis 7
- JWT (Lexik), OpenAPI (Nelmio), метрики (Prometheus/Grafana)
- Асинхронные задачи: Symfony Messenger + worker-контейнер

## Критично: только RoadRunner

- HTTP обслуживает **RoadRunner** (`bin/rr serve -c .rr.yaml`), **не nginx + PHP-FPM**
- Контейнер `php` запускает RoadRunner; статика из `public/` через `.rr.yaml`
- Интеграция: `baldinof/roadrunner-bundle`, long-lived Symfony worker
- **Не добавлять nginx**, не возвращать PHP-FPM без явного запроса
- На PHP 8.5 **не** запускать `docker-php-ext-install opcache` (ломает сборку)

## Локальная разработка

Все PHP/Composer-команды — **только в Docker** (`make shell` или цели Makefile).

```bash
make init      # первый запуск: build, composer, JWT, migrate
make up        # поднять стек
make down      # остановить
make restart   # перезапуск
make test      # cs-check + phpstan + phpunit (полный gate)
make fix       # PHP CS Fixer
make stan      # PHPStan
make shell     # bash в php-контейнере
make migrate   # Doctrine migrations
make logs-rr   # логи RoadRunner/PHP
make clean     # контейнеры, volumes, кэши
```

Composer: `make composer-install` / `make composer-update` (не локальный `composer` на хосте).

## Quality gates (обязательно перед PR)

1. `make fix` — PHP CS Fixer (`@Symfony`, `declare_strict_types`, risky rules)
2. `make stan` — PHPStan **level: max** (`bin/`, `config/`, `public/`, `src/`, `tests/`)
3. `make test` — всё вместе + PHPUnit

PR не готов, пока `make test` не проходит.

## Тестирование

- PHPUnit 11, конфиг: `phpunit.dist.xml`
- Тесты в `tests/`, namespace `App\Tests\`
- Запуск: `make test` или `make phpunit`

## API и безопасность

| Что | Путь |
|-----|------|
| API | `http://localhost:8080` |
| Health | `/health` |
| Login (JSON) | `POST /api/login` — `{"email","password"}` |
| Защищённые маршруты | `/api/*` + `Authorization: Bearer <JWT>` |
| OpenAPI UI | `/api/docs` |
| Метрики приложения | `/metrics/prometheus` |

- Префикс **`/api/`** (не `/api/v1` — пока не введён явно)
- Публичные: `/health`, `/api/login`, `/api/docs`, `/metrics/*`
- Новые эндпоинты: PHP-атрибуты `#[Route]`, OpenAPI `#[OA\...]`, `final class`
- Ответы — JSON через `$this->json()`

## Observability

| Сервис | URL |
|--------|-----|
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3000 (admin/admin) |
| RR metrics | `php:2112` (внутри сети Docker) |
| RR status | `php:2114` |

## Структура проекта

```
src/
  Controller/    # HTTP, атрибуты Route + OpenAPI
  Entity/        # Doctrine ORM
  Repository/    # Doctrine repositories
config/          # Symfony, security, packages
tests/           # PHPUnit
docker/          # Dockerfile, prometheus, grafana
.rr.yaml         # конфиг RoadRunner (корень)
```

Паттерны кода: `declare(strict_types=1);`, PSR-4 `App\`, контроллеры — `final`, extends `AbstractController`.

## Секреты и окружение

- `.env` из `.env.example` (`make init` копирует автоматически)
- JWT-ключи: `config/jwt/` (генерируются на `make init`, не в git)
- RoadRunner binary: `bin/rr` (gitignored, скачивается на init)
- **Не коммитить** `.env`, ключи, пароли, токены

## Чего НЕ делать

- Не менять deploy/CI/CD без явного запроса (deploy вне scope bootstrap)
- Не добавлять nginx / PHP-FPM
- Не запускать composer/phpunit/phpstan на хосте — только через Docker/Makefile
- Не раздувать diff: минимальный scope, без рефакторинга «заодно»
- Не добавлять тесты/доки/комментарии без необходимости
- Не создавать коммиты/PR без запроса пользователя

## Полезные команды

```bash
make console CMD="debug:router"   # Symfony console
make migration                    # новая Doctrine migration
make db-shell                     # psql
make redis-cli                    # redis-cli
make status                       # docker-compose ps
```
