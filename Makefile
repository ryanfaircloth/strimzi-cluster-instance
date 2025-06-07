# Makefile for strimzi-cluster-instance Helm chart
#
# Targets:
#   dev          : Build and push the Helm chart (for development)
#   up           : Build, push, and apply the chart using Terraform (for development)
#   build-dev    : Package the Helm chart into .out/ (auto-generates version if needed)
#   push-dev     : Push the packaged chart to the local OCI registry
#   up-dev       : Apply the chart using Terraform (initializes if needed)
#   down         : Destroy the Terraform-managed resources
#   clean        : Remove build artifacts and version file
#   clean-version: Remove only the version file

# Chart and versioning configuration
CHART_NAME    := strimzi-cluster-instance
CHART_PATH    := ./strimzi-cluster-instance
VERSION_FILE  := .version
# Auto-generate version if not present
VERSION       := $(shell (v=0.0.1-$(shell date +%Y%m%d%H%M%S); echo $$v > $(VERSION_FILE); echo $$v))
CHART_OUTPUT  := .out/$(CHART_NAME)-$(VERSION).tgz
CHART_REPO    := oci://localhost:5050/dev/charts/

.PHONY: dev build-dev push-dev up up-dev down clean-version clean

## Build and push the chart (development workflow)
dev: build-dev push-dev

## Build, push, and apply the chart using Terraform (development workflow)
up: build-dev up-dev push-dev

## Package the Helm chart into the .out directory
build-dev:
	mkdir -p .out
	helm package $(CHART_PATH) --version $(VERSION) --destination .out

## Push the packaged chart to the local OCI registry
push-dev:
	helm push $(CHART_OUTPUT) $(CHART_REPO) --plain-http

## Initialize and apply Terraform (for development)
up-dev:
	@if [ ! -f .kind/terraform.tfstate ]; then \
		pushd .kind && TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform init && popd; \
	fi
	pushd .kind && TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform apply -target=module.kind_cluster -auto-approve && popd
	pushd .kind && TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform apply -auto-approve && popd

## Destroy all Terraform-managed resources
down:
	pushd .kind && terraform destroy -auto-approve && popd

## Remove only the version file
clean-version:
	rm -f $(VERSION_FILE)

## Remove build artifacts and version file
clean:
	rm -rf .out $(VERSION_FILE)