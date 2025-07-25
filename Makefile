.PHONY: help
.DEFAULT_GOAL := help
include .env
-include .env.local

## Show help
help:
	@echo ""
	@echo ""
	@echo "                           _   _"
	@echo "                          | | | |"
	@echo "  ___ _ __ ___   __ _ _ __| |_| | ___  __ _ _ __ _ __  "
	@echo " / __| '_ \` _ \ / _\` | '__| __| |/ _ \\/ _\` | '__| '_ \\"
	@echo " \__ \ | | | | | (_| | |  | |_| |  __/ (_| | |  | | | |"
	@echo " |___/_| |_| |_|\__,_|_|   \__|_|\___|\__,_|_|  |_| |_|"
	@echo ""
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  %-20s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@echo ""
	@echo ""



#################################################################
# system operations
#################################################################
## install smartlearn with a new database
install:
	composer install
	make db
	frankenphp php-cli bin/console cache:pool:clear
	@echo ""
	@echo "┌──────────────────────────────┐"
	@echo "│   Installation erfolgreich   │"
	@echo "└──────────────────────────────┘"
	@echo ""

## initialize a new bucket
bucket:
	mc alias set smartlearn $(OBJECT_STORAGE_ENDPOINT) $(OBJECT_STORAGE_ACCESS_KEY) $(OBJECT_STORAGE_SECRET_KEY)
	mc rm -r --force smartlearn/$(OBJECT_STORAGE_BUCKET_MEDIA) || true
	mc rb smartlearn/$(OBJECT_STORAGE_BUCKET_MEDIA) || true
	mc mb smartlearn/$(OBJECT_STORAGE_BUCKET_MEDIA)

#################################################################
# database operations
#################################################################
## initialize a new database
db:
	## create default database
	frankenphp php-cli bin/console doctrine:database:create --if-not-exists -n
	frankenphp php-cli bin/console doctrine:schema:drop --full-database --force
	frankenphp php-cli bin/console doctrine:migrations:migrate -n
	frankenphp php-cli bin/console doctrine:fixtures:load -n -v

#################################################################
# JWT
#################################################################
## create jwt token
setup-jwt:
	mkdir -p config/jwt
	openssl genpkey -out config/jwt/private.pem -aes256 -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -pass pass:$(JWT_PASSPHRASE)
	openssl pkey -in config/jwt/private.pem -out config/jwt/public.pem -pubout -passin pass:$(JWT_PASSPHRASE)
	chmod 664 config/jwt/*

## generate jwt token
jwt:
	@bin/console lexik:jwt:generate-token $(user)

## analyse code with phpstan
phpstan:
	vendor/bin/phpstan analyse --memory-limit=2G -v

## run deptrac
deptrac:
	vendor/bin/deptrac analyse --config-file=deptrac.yaml

## run phpunit tests
phpunit: test_unit test_graphql test_integration

## run unit tests
test_unit:
	frankenphp php-cli vendor/bin/phpunit --testdox --testsuite=Unit $(ARGS)

## run graphql tests
test_graphql: phpunit_new_db
	frankenphp php-cli vendor/bin/phpunit --testdox --testsuite=GraphQL $(ARGS)

## run integration tests
test_integration: phpunit_new_db
	make setup-jwt
	frankenphp php-cli vendor/bin/phpunit --testdox --testsuite=Integration $(ARGS)

## resets the test env database
phpunit_new_db:
	frankenphp php-cli bin/console doctrine:database:drop --if-exists --force --env=test
	frankenphp php-cli bin/console doctrine:database:create --env=test
	frankenphp php-cli bin/console doctrine:migrations:migrate -n --env=test
	frankenphp php-cli bin/console doctrine:schema:update --force --complete --env=test
	frankenphp php-cli bin/console doctrine:fixtures:load -n --env=test -vvv

## check phpunit coverage
phpunit-cov:
	phpdbg -qrr bin/phpunit --coverage-html=./coverage

## check code style
ecs:
	vendor/bin/ecs check src tests --fix
	make prettier

## run rector (--dry-run)
rector:
	vendor/bin/rector process --dry-run

## run rector
rector_fix:
	vendor/bin/rector process

## run prettier. Usage: make prettier
prettier:
	npm run prettier:fix

#################################################################
# docs
#################################################################
## dump all workflows to svgs
workflows_dump:
	mkdir -p docs/workflows/
	frankenphp php-cli bin/console workflow:dump network | dot -Tsvg -o docs/workflows/network.svg
	frankenphp php-cli bin/console workflow:dump virtual_environment | dot -Tsvg -o docs/workflows/virtual_environment.svg
	frankenphp php-cli bin/console workflow:dump vm | dot -Tsvg -o docs/workflows/vm.svg
