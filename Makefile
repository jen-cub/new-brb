SHELL := /bin/bash

NAMESPACE ?= nginx-ingress
RELEASE_NAME ?= global-brb
CHART_NAME ?= jencub/static2
CHART_VERSION ?= 0.8.6-new
# add to dev if used:  #		--version "$(CHART_VERSION)" \

DEV_CLUSTER ?= testrc
DEV_PROJECT ?= jendevops1
DEV_ZONE ?= australia-southeast1-c

SED_MATCH ?= [^a-zA-Z0-9._-]
ifeq ($(CIRCLECI)ah dev,true)
# Configure build variables based on CircleCI environment vars
BUILD_NUM = build-$(CIRCLE_BUILD_NUM)
BRANCH_NAME ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_BRANCH)")
BUILD_TAG ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_TAG)")
else
# Not in CircleCI environment, try to set sane defaults
BUILD_NUM = build-local
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD | sed 's/$(SED_MATCH)/-/g')
BUILD_TAG ?= $(shell git tag -l --points-at HEAD | tail -n1 | sed 's/$(SED_MATCH)/-/g')
endif

# If BUILD_TAG is blank there's no tag on this commit
ifeq ($(strip $(BUILD_TAG)),)
# Default to branch name
BUILD_TAG := $(BRANCH_NAME)
else
# Consider this the new :latest image
# FIXME: implement build tests before tagging with :latest
PUSH_LATEST := true
endif

REVISION_TAG = $(shell git rev-parse --short HEAD)


lint: lint-yaml lint-ci

lint-yaml:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

lint-ci:
	@circleci config validate

pull:
	docker pull gcr.io/jendevops1/openresty:latest

build: pull
	docker build \
		--tag=gcr.io/jendevops1/brb:$(BUILD_TAG) \
		--tag=gcr.io/jendevops1/brb:$(BUILD_NUM) \
		--tag=gcr.io/jendevops1/brb:$(REVISION_TAG) \
		.

push: push-tag push-latest

push-tag:
	docker push gcr.io/jendevops1/brb:$(BUILD_TAG)
	docker push gcr.io/jendevops1/brb:$(BUILD_NUM)

push-latest:
	@if [[ "$(PUSH_LATEST)" = "true" ]]; then { \
		docker tag gcr.io/jendevops1/brb:$(REVISION_TAG) gcr.io/jendevops1/brb:latest; \
		docker push gcr.io/jendevops1/brb:latest; \
	}	else { \
		echo "Not tagged.. skipping latest"; \
	} fi

dev:
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	helm init --client-only
	helm repo add jencub https://jen-helm-charts.storage.googleapis.com && \
	helm repo update
	@helm upgrade --install --force --wait $(RELEASE_NAME) $(CHART_NAME) \
		--version $(CHART_VERSION) \
		--namespace=$(NAMESPACE) \
		--values values.yaml \
		--values env/dev/values.yaml \
		--set openresty.geoip.accountid=$(GEOIP_ACCOUNTID) \
		--set openresty.geoip.license=$(GEOIP_LICENSE)

prod:
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	gcloud config set project $(PROD_PROJECT)
	gcloud container clusters get-credentials $(PROD_CLUSTER) --zone $(PROD_ZONE) --project $(PROD_PROJECT)
	helm init --client-only
	helm repo add p4 https://planet4-helm-charts.storage.googleapis.com && \
	helm repo update
	@helm upgrade --install --force --wait $(RELEASE_NAME) $(CHART_NAME) \
		--namespace=$(NAMESPACE) \
		--values values.yaml \
		--values env/prod/values.yaml \
		--set openresty.geoip.accountid=$(GEOIP_ACCOUNTID) \
		--set openresty.geoip.license=$(GEOIP_LICENSE)


history:
	helm history $(RELEASE_NAME) --max=5
