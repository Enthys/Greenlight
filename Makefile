include .env
export

# ===================================================================================#
# HELPERS
# ===================================================================================#

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

# ===================================================================================#
# DEVELOPMENT
# ===================================================================================#

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


# ===================================================================================#
# QUALITY CONTROL
# ===================================================================================#

## audit: tidyu dependencies and format, vet and test all code
.PHONY: audit
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies'
	go mod vendor

# ===================================================================================#
# BUILD
# ===================================================================================#

current_time = $(shell date --iso-8601=seconds)
git_description = $(shell git describe --always --dirty)

linker_flags = '-s -X main.buildTime=${current_time} -X main.version=${git_description}'

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api'
	go build -ldflags=${linker_flags} -o=./bin/api ./cmd/api
	GOOS=linux GOARCH=amd64 go build -ldflags=${linker_flags} -o=./bin/linux_amd64/api ./cmd/api
