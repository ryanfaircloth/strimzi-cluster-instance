#!/bin/sh
set -o errexit


# 1. Detect container runtime (docker or podman)
reg_name='kind-registry'
reg_port="${1:-5050}"

if command -v docker >/dev/null 2>&1; then
  CONTAINER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
  CONTAINER_CMD="podman"
else
  echo "Error: Neither docker nor podman is installed. Please install one to continue." >&2
  exit 1
fi

# 2. Create registry container unless it already exists
if [ "$($CONTAINER_CMD inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  $CONTAINER_CMD run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network kind --name "${reg_name}" \
    registry:3
fi

# 3. Ensure registry is connected to the kind network
if ! $CONTAINER_CMD inspect -f '{{json .NetworkSettings.Networks}}' "${reg_name}" 2>/dev/null | grep -q '"kind"'; then
  $CONTAINER_CMD network connect "kind" "${reg_name}" 2>/dev/null || true
fi
