# kafka-tiered-storage-plugin (OCI image)

A **plugin-only** OCI image carrying the [Aiven tiered-storage-for-apache-kafka](https://github.com/Aiven-Open/tiered-storage-for-apache-kafka)
`RemoteStorageManager` JARs. It is **not runnable** — it is mounted read-only
into the Strimzi Kafka broker pods as a Kubernetes [image volume](https://kubernetes.io/docs/tasks/configure-pod-container/image-volumes),
so the Strimzi Kafka operand image stays vanilla and keeps tracking upstream.

See the [`strimzi-cluster-instance` chart](../strimzi-cluster-instance) —
`kafka.tieredStorage.plugin.image` wires this image onto the brokers.

## Contents

Each image bundles the plugin **core** library plus **one cloud backend**, laid
out at the image root (single classpath entry `<mountPath>/*`):

| Image tag | Backend module | `storage.backend.class` |
|-----------|----------------|-------------------------|
| `aws-<version>` | `s3` (AWS SDK v2 bundled) | `io.aiven.kafka.tieredstorage.storage.s3.S3Storage` |
| `azure-<version>` | `azure` (Azure Blob SDK bundled) | `io.aiven.kafka.tieredstorage.storage.azure.AzureBlobStorage` |
| `gcs-<version>` | `gcs` (Google SDK bundled) | `io.aiven.kafka.tieredstorage.storage.gcs.GcsStorage` |

`<version>` is the Aiven plugin release, pinned in [`PLUGIN_VERSION`](./PLUGIN_VERSION).

## Building & publishing

Published to `ghcr.io/<owner>/kafka-tiered-storage-plugin` by
[`.github/workflows/release-tiered-storage-plugin.yml`](../.github/workflows/release-tiered-storage-plugin.yml).
The workflow builds **only when the pinned version changes** (it runs on pushes
touching this directory and skips any tag already present in the registry).
Renovate keeps `PLUGIN_VERSION` (and the chart default) in sync with upstream
releases.

Only **AWS** is built today. To add a cloud, uncomment its row in the workflow's
build matrix — no other change is required.

Local build (single arch, for testing):

```sh
docker build \
  --build-arg PLUGIN_VERSION="$(grep -v '^#' PLUGIN_VERSION | tr -d '[:space:]')" \
  --build-arg MODULE=s3 \
  -t kafka-tiered-storage-plugin:aws-local .
```

> The published GHCR package must be pullable by the cluster's nodes — make the
> package public, or configure image-pull credentials — since the kubelet pulls
> it to populate the image volume.
