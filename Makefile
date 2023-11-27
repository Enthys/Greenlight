include .env
export

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

## run/setup: run required commands in order to start development
.PHONY: run/setup
run/setup:
	@if [ ! -e ".env" ]; then echo 'Copying .env.default under name .env.' && cp .env.default .env; fi

## run/db: starts the development database 
.PHONY: run/db
run/db: 
	docker compose up -d

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api

## db/connect: connecto to the development database using psql
.PHONY: db/connect
db/connect: run/db 
	@docker container exec -it greenlight-database-1 psql ${GREENLIGHT_DB_DSN}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: confirm
	@echo 'Running up migrations...'
	@migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up


## db/migrations/new name=$1: create a new database migration
.PHONY: db/migrations/new
db/migratios/new:
	@echo 'Creating migration files for ${name}'
	migrate create -seq -ext=.sql -dir=./migrations ${name}


