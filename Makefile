.DEFAULT_GOAL := help

GIT_REPO := $(shell basename -s .git $(shell git config --get remote.origin.url))
GIT_SHA  := $(shell git rev-parse --short HEAD)

define get_aws_repo
  $(shell aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName | startswith("$(GIT_REPO)-")) | .repositoryUri')
endef

.PHONY: docker-init
docker-init: ## Bootstrap the first admin user on the running paperclip instance
	cd ../infrastructure && CMD="node --import ./server/node_modules/tsx/dist/loader.mjs node_modules/.bin/paperclipai auth bootstrap-ceo" make exec-paperclip

.PHONY: docker-build
docker-build: ## Build the Docker image
	docker build -t $(GIT_REPO) .
	docker tag $(GIT_REPO):latest $(GIT_REPO):$(GIT_SHA)

.PHONY: docker-down
docker-down: ## Stop and remove containers and volumes
	docker compose down --volumes

.PHONY: docker-push
docker-push: ## Push Docker image to ECR
	$(eval AWS_REPO := $(call get_aws_repo))
	docker tag $(GIT_REPO):latest $(AWS_REPO):$(GIT_SHA)
	docker push $(AWS_REPO):$(GIT_SHA)
	docker tag $(GIT_REPO):latest $(AWS_REPO):latest
	docker push $(AWS_REPO):latest

.PHONY: docker-up
docker-up: ## Start Paperclip in the background
	docker compose up --build --detach

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
