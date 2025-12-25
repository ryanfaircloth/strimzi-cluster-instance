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

.PHONY: dev build-dev push-dev up up-dev down clean-version clean hostctl

## Build and push the chart (development workflow)
dev: build-dev push-dev

## Build, push, and apply the chart using Terraform (development workflow)
up: build-dev up-dev push-dev
	@echo ""
	@echo "🎉 Cluster deployment complete!"
	@echo ""
	@echo "📋 Available Services:"
	@echo "====================="
	@echo ""
	@echo "🔐 HTTPS Services (port 9443):"
	@echo "  • TinyOlly Observability UI:"
	@echo "    https://to.strimzi.gateway.api.test:9443/"
	@echo ""
	@echo "📡 Kafka Brokers (port 9094, TLS):"
	@echo "  • broker-0.strimzi.gateway.api.test:9094"
	@echo "  • broker-1.strimzi.gateway.api.test:9094"
	@echo "  • broker-2.strimzi.gateway.api.test:9094"
	@echo "  • bootstrap.strimzi.gateway.api.test:9094 (bootstrap)"
	@echo ""
	@echo "🔑 Authentication:"
	@echo "  • Admin user: admin-user"
	@echo "  • Get password: kubectl get secret admin-user -n kafka -o jsonpath='{.data.password}' | base64 -d"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  • TinyOlly collects Kafka telemetry via OTLP"
	@echo "  • OpAMP server manages collector configuration"
	@echo ""

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
## pushd .kind && TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform apply -target=module.kind_cluster -auto-approve && popd
	pushd .kind && TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform apply -auto-approve || TF_VAR_strimzi_cluster_instance_version=$(VERSION) terraform apply -auto-approve && popd

## Destroy all resources using direct cleanup commands
down:
	@echo "Deleting KIND cluster..."
	-kind delete cluster --name strimzi-cluster-instance
	@echo "Stopping and removing kind-registry container..."
	-podman stop kind-registry
	-podman rm kind-registry
	@echo "Cleaning up terraform state and config files..."
	-rm -f .kind/terraform.tfstate .kind/terraform.tfstate.backup
	-rm -f .kind/strimzi-cluster-instance-config
	@echo "Cleanup complete!"

## Remove only the version file
clean-version:
	rm -f $(VERSION_FILE)

## Remove build artifacts and version file
clean:
	rm -rf .out $(VERSION_FILE)

## Add hostnames to local hosts using hostctl (requires sudo)
hostctl:
	sudo hostctl add domains kafka to.strimzi.gateway.api.test broker-0.strimzi.gateway.api.test broker-1.strimzi.gateway.api.test broker-2.strimzi.gateway.api.test bootstrap.strimzi.gateway.api.test