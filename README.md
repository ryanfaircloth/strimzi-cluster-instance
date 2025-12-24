# Strimzi Cluster Instance

A development environment for deploying and testing Apache Kafka clusters using Strimzi Operator on local Kubernetes clusters with KIND (Kubernetes in Docker).

## Overview

This project provides:
- **Helm Chart**: A comprehensive Helm chart for deploying Kafka clusters using Strimzi Operator
- **Local Development Environment**: Automated KIND cluster setup with integrated container registry
- **Infrastructure as Code**: Terraform-based deployment with Flux for GitOps
- **Complete Stack**: Includes Kafka, cert-manager, trust-manager, and supporting infrastructure

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   KIND Cluster  │    │ Local Registry   │    │  Helm Chart     │
│                 │    │ (localhost:5050) │    │ (Strimzi Kafka) │
│ - Control Plane │◄───┤                  │◄───┤                 │
│ - 3x Workers    │    │ OCI Registry     │    │ - Node Pools    │
│ - Flux GitOps   │    │                  │    │ - Listeners     │
└─────────────────┘    └──────────────────┘    │ - Certificates  │
                                               └─────────────────┘
```

## Prerequisites

Before using this project, ensure you have the following installed:

### Required Tools
- **Docker** or **Podman**: For running KIND and container registry
- **KIND**: For creating local Kubernetes clusters
- **Terraform**: For infrastructure provisioning (>= 1.0.0)
- **Helm**: For package management (>= 3.0)
- **kubectl**: For Kubernetes cluster interaction
- **make**: For build automation

### Installation Commands

Install podman desktop

```bash
# macOS with Homebrew
brew install terraform helm kubectl

# Verify installations
kind version
terraform version
helm version
kubectl version --client
```

## Quick Start

### 1. Create and Deploy Cluster

Build and deploy the complete stack in one command:

```bash
make up
```

This command will:
1. Start a local OCI registry on `localhost:5050`
2. Create a KIND cluster named `strimzi-cluster-instance`
3. Package and push the Helm chart to the local registry
4. Deploy Flux GitOps to manage the cluster
5. Install cert-manager, trust-manager, and Strimzi operator
6. Deploy your Kafka cluster with the configured settings

### 2. Verify Deployment

Check that your cluster is running:

```bash
# Set kubectl context
export KUBECONFIG=.kind/strimzi-cluster-instance-config

# Check cluster status
kubectl get nodes

# Check Kafka cluster status
kubectl get kafka -n kafka

# Check all pods
kubectl get pods -A
```

### 3. Tear Down Cluster

When you're done testing, tear down everything:

```bash
make down
```

This will destroy all Terraform-managed resources, including the KIND cluster and registry.

## Development Workflow

### Iterative Development

For active development, use the individual make targets:

```bash
# Build and push chart only
make dev

# Deploy without rebuilding chart
make up-dev

# Clean up build artifacts
make clean
```

### Customizing the Kafka Cluster

#### 1. Edit Values File

Modify [strimzi-cluster-instance/values.yaml](strimzi-cluster-instance/values.yaml) to customize your Kafka cluster:

```yaml
# Example: Change node pool configuration
nodePools:
  - name: broker
    replicas: 5  # Increase broker count
    resources:
      requests:
        memory: "4Gi"  # Increase memory
        cpu: "2"
```

#### 2. Override with Local Values

Create a `.values.yaml` file in the project root for local overrides:

```bash
cp strimzi-cluster-instance/values.yaml .values.yaml
# Edit .values.yaml with your local customizations
```

#### 3. Apply Changes

After modifying values:

```bash
# Rebuild and redeploy
make up
```

### Working with the Registry

The local OCI registry runs on `localhost:5050` and persists between deployments:

```bash
# List pushed charts
curl http://localhost:5050/v2/_catalog

# View chart versions
curl http://localhost:5050/v2/dev/charts/strimzi-cluster-instance/tags/list
```

## Project Structure

```
.
├── Makefile                           # Build automation
├── strimzi-cluster-instance/          # Helm chart
│   ├── Chart.yaml                     # Chart metadata
│   ├── values.yaml                    # Default configuration
│   └── templates/                     # Kubernetes manifests
│       ├── kafka.yaml                 # Main Kafka resource
│       ├── kafkanodepools.yaml        # Node pool definitions
│       └── kafkarebalance.yaml        # Cruise Control integration
├── .kind/                             # Terraform infrastructure
│   ├── main.tf                       # Main Terraform config
│   ├── modules/
│   │   ├── kind_cluster/              # KIND cluster module
│   │   │   ├── main.tf                # Cluster definition
│   │   │   └── registry.sh            # Registry setup script
│   │   └── main/                      # Application deployment module
│   │       ├── flux2-manifests/       # Flux HelmRelease definitions
│   │       └── *.tf                   # Terraform resources
└── kafka_2.13-4.0.0/                 # Apache Kafka binaries (optional)
```

## Configuration Reference

### Key Configuration Files

1. **[strimzi-cluster-instance/values.yaml](strimzi-cluster-instance/values.yaml)**: Main Kafka cluster configuration
2. **[.kind/modules/kind_cluster/main.tf](.kind/modules/kind_cluster/main.tf)**: KIND cluster setup
3. **[.kind/modules/main/flux2-manifests/](.kind/modules/main/flux2-manifests/)**: GitOps configurations
4. **[Makefile](Makefile)**: Build and deployment automation

### Kafka Cluster Features

- **KRaft Mode**: Runs without Zookeeper (modern Kafka architecture)
- **Node Pools**: Separate broker and controller node pools
- **TLS Support**: Automated certificate management with cert-manager
- **Cruise Control**: Automated partition rebalancing
- **Multiple Listeners**: Internal plain and TLS listeners
- **Monitoring Ready**: Configured for observability stack integration

### Available Make Targets

| Target | Description |
|--------|-------------|
| `make up` | Complete deployment: build, push, and apply |
| `make down` | Destroy all resources |
| `make dev` | Build and push chart only |
| `make up-dev` | Deploy infrastructure without rebuilding chart |
| `make build-dev` | Package Helm chart |
| `make push-dev` | Push chart to local registry |
| `make clean` | Remove build artifacts |
| `make clean-version` | Remove version file only |

## Troubleshooting

### Common Issues

#### 1. KIND Cluster Won't Start
```bash
# Check Docker/Podman is running
docker ps

# Delete existing cluster
kind delete cluster --name strimzi-cluster-instance

# Recreate
make up
```

#### 2. Registry Connection Issues
```bash
# Check registry is running
docker ps | grep kind-registry

# Restart registry
docker restart kind-registry
```

#### 3. Helm Chart Deploy Failures
```bash
# Check Terraform state
cd .kind && terraform state list

# Check Flux status
kubectl get helmrelease -A

# Check pod logs
kubectl logs -n flux-system -l app=flux
```

#### 4. Kafka Cluster Not Ready
```bash
# Check Strimzi operator
kubectl get pods -n strimzi-operator

# Check Kafka status
kubectl describe kafka -n kafka

# Check node pool status
kubectl get kafkanodepool -n kafka
```

### Reset Everything

If you encounter persistent issues:

```bash
# Full cleanup
make down
make clean
kind delete cluster --name strimzi-cluster-instance
docker stop kind-registry && docker rm kind-registry

# Fresh start
make up
```

## Advanced Usage

### Custom Kafka Configuration

Add custom Kafka broker settings:

```yaml
kafka:
  config:
    num.network.threads: 8
    num.io.threads: 16
    log.retention.hours: 168
    log.segment.bytes: 1073741824
```

### External Access

Configure external listeners for accessing Kafka from outside the cluster:

```yaml
kafka:
  additionalListeners:
  - name: external
    port: 9094
    type: ingress
    tls: true
    configuration:
      bootstrap:
        host: kafka.local
```

### Monitoring Integration

The cluster is configured to work with monitoring stacks. Add Prometheus metrics:

```yaml
kafka:
  metricsConfig:
    type: jmxPrometheusExporter
    valueFrom:
      configMapKeyRef:
        name: kafka-metrics
        key: kafka-metrics-config.yml
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Test your changes with `make up`
4. Commit changes: `git commit -am 'Add my feature'`
5. Push branch: `git push origin feature/my-feature`
6. Submit a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources
- [Strimzi blog that inspired it all](https://strimzi.io/blog/2024/08/16/accessing-kafka-with-gateway-api/)
- [Strimzi Documentation](https://strimzi.io/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Terraform KIND Provider](https://registry.terraform.io/providers/tehcyx/kind/latest/docs)
- [Flux Documentation](https://fluxcd.io/docs/)