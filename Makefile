SHELL := /usr/bin/env bash

MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

msync_args ?=

ifneq "$(shell which docker 2>/dev/null)" ""
	DOCKER_CMD  ?= $(shell which docker)
	DOCKER_ARGS ?=
else
	DOCKER_CMD  ?= podman
	DOCKER_ARGS ?= --userns=keep-id
endif

.PHONY: help
help: ## Show this help
	@grep -E -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "(: ).*?## "}; {gsub(/\\:/,":",$$1)}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: sync\:noop
sync\:noop: ## Syncs the managed modules locally but doesn't create PRs. Requires running SSH agent with access to github.com, ~/.ssh/known_hosts, ~/.gitconfig.
	$(DOCKER_CMD) run --rm -it -u $$(id -u):$$(id -g) $(DOCKER_ARGS) \
		--env SSH_AUTH_SOCK=/tmp/ssh_agent.sock \
		--volume "${SSH_AUTH_SOCK}:/tmp/ssh_agent.sock" \
		--volume "${HOME}/.ssh/known_hosts:/home/msync/.ssh/known_hosts:ro" \
		--volume "${HOME}/.gitconfig:/home/msync/.gitconfig:ro" \
		--volume "${PWD}:/app" docker.io/vshn/modulesync msync update --noop $(msync_args)

.PHONY: sync\:offline
sync\:offline: msync_args = --offline
sync\:offline: sync\:noop ## Same as sync:noop, but doesn't clone/pull from git repos. Use this target to test the modulesync template.
