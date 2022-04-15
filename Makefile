
  
# Parameters
SHELL          = bash
PHP_CONTAINER  = web

# Executables
EXEC_PHP       = php
COMPOSER       = composer

# Executables (local only)
DOCKER        = docker
DOCKER_COMP   = docker-compose

# Alias
DOCKER_EXEC   = docker-compose exec
DOCKER_EXEC_CONTAINER = $(DOCKER_EXEC) $(PHP_CONTAINER)
SYMFONY       = $(EXEC_PHP) bin/console
PHPSTAN		  = $(EXEC_PHP) -d memory_limit=512M vendor/bin/phpstan
PHPUNIT		  = $(EXEC_PHP) vendor/bin/phpunit

help: ## List all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

## —— Composer 🧙‍♂️ ————————————————————————————————————————————————————————————
install: composer.lock ## Install vendors according to the current composer.lock file
	$(DOCKER_EXEC) $(PHP_CONTAINER) $(COMPOSER) install --no-progress --prefer-dist --optimize-autoloader
	## $(DOCKER_EXEC) $(PHP_CONTAINER) $(COMPOSER) install --working-dir tools/php-cs-fixer --no-progress --prefer-dist --optimize-autoloader

## —— React JS ———————————————————————————————————————————————————————————————
watch: ## Watch for changes on JS files
	yarn encore dev --watch

install-js: ## Yarn install
	yarn install

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
exec: ## Execute bash on php container
	$(DOCKER_EXEC_CONTAINER) bash

sf: ## List all Symfony commands
	$(DOCKER_EXEC_CONTAINER) $(SYMFONY)

cc: ## Clear the cache. DID YOU CLEAR YOUR CACHE????
	$(DOCKER_EXEC_CONTAINER) $(SYMFONY) c:c

fix-perms: ## Fix permissions of all var files
	chmod -R 777 var/*

assets: purge ## Install the assets with symlinks in the public folder
	$(DOCKER_EXEC_CONTAINER) $(SYMFONY) assets:install public/ --symlink --relative

purge: ## Purge cache and logs
	rm -rf var/cache/* var/logs/*

env:
	cp .env.dist .env

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
up: ## Start the docker hub (MySQL,redis,adminer,elasticsearch,head,Kibana)
	$(DOCKER_COMP) up -d

down: ## Stop the docker hub
	$(DOCKER_COMP) down --remove-orphans

build:
	$(DOCKER_COMP) build

ps: ## List containers status
	$(DOCKER_COMP) ps

## —— Tests ————————————————————————————————————————————————————————————————
verify: ## Run phpstan and symfony check:security
	#$(PHPSTAN) analyse -c phpstan.neon && symfony check:security
	$(DOCKER_EXEC_CONTAINER) bash -c "symfony check:security ; $(PHPSTAN)"

phpunit: ## Run phpunit, option -> file = (root is tests/)
	$(eval file ?= 'tests/')
	$(DOCKER_EXEC_CONTAINER) $(PHPUNIT) $(file)

csfixer: ## Run CS Fixer
	$(DOCKER_EXEC_CONTAINER) tools/php-cs-fixer/vendor/bin/php-cs-fixer fix --config .php-cs-fixer.php
