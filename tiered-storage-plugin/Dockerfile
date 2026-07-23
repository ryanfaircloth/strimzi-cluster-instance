# syntax=docker/dockerfile:1
#
# Plugin-only OCI image for Apache Kafka KIP-405 tiered storage.
#
# Contains ONLY the Aiven tiered-storage-for-apache-kafka RemoteStorageManager
# JARs (the core library plus ONE cloud backend) laid out at the image root.
# This is NOT a runnable image: it is mounted read-only into the Strimzi Kafka
# broker pods as a Kubernetes image volume, so the Strimzi operand image stays
# vanilla and keeps tracking upstream.
#
# Built per cloud via a matrix and tagged "<cloud>-<version>" (e.g. aws-1.1.1).
#
# Build args:
#   PLUGIN_VERSION  Aiven plugin release version; the release tag is v<PLUGIN_VERSION>.
#   MODULE          Storage backend module to bundle: s3 (AWS) | azure | gcs.

ARG PLUGIN_VERSION=1.1.1
ARG MODULE=s3

# The extraction is architecture-independent (pure JARs), so pin the build stage
# to the builder's native platform to avoid pointless QEMU emulation. The final
# scratch image is still emitted for every requested target platform.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS build
ARG PLUGIN_VERSION
ARG MODULE
ARG BASE_URL=https://github.com/Aiven-Open/tiered-storage-for-apache-kafka/releases/download
RUN apk add --no-cache curl tar
WORKDIR /plugin
# Extract the core library and the selected backend into ONE directory so a
# single classpath entry ("<mountPath>/*") covers everything. Each archive ships
# a top-level "<name>-<version>/" folder, stripped with --strip-components=1.
# The shared storage-core JAR is identical across archives, so overwrite is safe.
RUN set -eux; \
    for m in core "${MODULE}"; do \
      curl -fsSL "${BASE_URL}/v${PLUGIN_VERSION}/${m}-${PLUGIN_VERSION}.tgz" \
        | tar -xz --strip-components=1 -C /plugin; \
    done

# Bare image: JARs at the root, nothing else.
FROM scratch
ARG PLUGIN_VERSION
ARG MODULE
LABEL org.opencontainers.image.title="kafka-tiered-storage-plugin" \
      org.opencontainers.image.description="Aiven tiered-storage RSM plugin (core + ${MODULE}) for mounting as a Kafka broker image volume" \
      org.opencontainers.image.version="${PLUGIN_VERSION}" \
      org.opencontainers.image.source="https://github.com/Aiven-Open/tiered-storage-for-apache-kafka"
COPY --from=build /plugin/ /
