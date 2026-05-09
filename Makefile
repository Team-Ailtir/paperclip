.DEFAULT_GOAL := help

GIT_REPO := $(shell basename -s .git $(shell git config --get remote.origin.url))
GIT_SHA  := $(shell git rev-parse --short HEAD)

define get_aws_repo
  $(shell aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName | startswith("$(GIT_REPO)-")) | .repositoryUri')
endef

.PHONY: docker-init
docker-init: ## Bootstrap the first admin user on the running paperclip instance (prints invite URL)
	scripts/docker-init.sh

.PHONY: nothing-to-commit
nothing-to-commit: ## Fail if the working tree has uncommitted changes
	@git diff --quiet && git diff --cached --quiet || (echo "Error: working tree is not clean. Commit or stash changes before building."; exit 1)
	@test -z "$$(git status --porcelain)" || (echo "Error: untracked files present. Commit or stash before building."; exit 1)

.PHONY: version-stamp
version-stamp: ## Stamp package.json files with <version>-<git-sha>
	scripts/version-stamp.sh

.PHONY: docker-build
docker-build: nothing-to-commit version-stamp ## Build the Docker image
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
