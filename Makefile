.PHONY: help init build up down restart logs shell bash test fix cs-fix stan cs-check migrate jwt-keys cache-clear composer-install rr-binary clean

DOCKER_COMPOSE := docker-compose
PHP_SERVICE := php
EXEC := $(DOCKER_COMPOSE) exec -T $(PHP_SERVICE)
RUN := $(DOCKER_COMPOSE) run --rm --no-deps $(PHP_SERVICE)

help: ## Show available commands
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

init: build composer-install env jwt-keys up migrate cache-clear ## First-time setup (build, deps, keys, migrate)
	@echo "Init complete. API: http://localhost:$${APP_PORT:-8080}"

build: ## Build Docker images
	$(DOCKER_COMPOSE) build

up: ## Start all services
	$(DOCKER_COMPOSE) up -d --remove-orphans

down: ## Stop all services
	$(DOCKER_COMPOSE) down

restart: down up ## Restart all services

logs: ## Tail logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-php: ## Tail PHP/RoadRunner container logs
	$(DOCKER_COMPOSE) logs -f $(PHP_SERVICE)

logs-rr: logs-php ## Alias for RoadRunner logs

shell bash: ## Open shell in PHP container
	$(DOCKER_COMPOSE) exec $(PHP_SERVICE) bash

composer-install: ## Install PHP dependencies
	$(RUN) composer install --no-interaction --prefer-dist
	$(RUN) vendor/bin/rr get --location bin/ -n

rr-binary: ## Download RoadRunner binary to bin/rr
	$(RUN) vendor/bin/rr get --location bin/ -n

composer-update: ## Update PHP dependencies
	$(RUN) composer update --no-interaction

env: ## Copy .env.example to .env if missing
	@test -f .env || cp .env.example .env

jwt-keys: env ## Generate JWT key pair
	@mkdir -p config/jwt
	$(RUN) bash -lc 'if [ ! -f config/jwt/private.pem ]; then \
		openssl genpkey -out config/jwt/private.pem -algorithm rsa -pkeyopt rsa_keygen_bits:4096; \
		openssl pkey -in config/jwt/private.pem -out config/jwt/public.pem -pubout; \
		chmod 600 config/jwt/private.pem; \
		echo "JWT keys generated."; \
	else \
		echo "JWT keys already exist."; \
	fi'

migrate: env ## Run database migrations
	$(EXEC) php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

migration: ## Create a new Doctrine migration
	$(EXEC) php bin/console make:migration

cache-clear: ## Clear Symfony cache
	$(RUN) php bin/console cache:clear

test: cs-check stan phpunit ## Run full quality gate (cs-check + phpstan + phpunit)

phpunit: ## Run PHPUnit tests
	$(RUN) php bin/phpunit

stan: ## Run PHPStan static analysis
	$(RUN) vendor/bin/phpstan analyse --memory-limit=1G

cs-check: ## Run PHP CS Fixer in dry-run mode
	$(RUN) vendor/bin/php-cs-fixer fix --dry-run --diff

fix cs-fix: ## Apply PHP CS Fixer fixes
	$(RUN) vendor/bin/php-cs-fixer fix

console: ## Run Symfony console (usage: make console CMD="debug:router")
	$(EXEC) php bin/console $(CMD)

db-shell: ## Open psql shell
	$(DOCKER_COMPOSE) exec postgres psql -U $${POSTGRES_USER:-finance} -d $${POSTGRES_DB:-finance}

redis-cli: ## Open Redis CLI
	$(DOCKER_COMPOSE) exec redis redis-cli

clean: down ## Remove containers, volumes, and caches
	$(DOCKER_COMPOSE) down -v --remove-orphans
	rm -rf var/cache var/log .php-cs-fixer.cache .phpunit.cache

status: ## Show container status
	$(DOCKER_COMPOSE) ps
