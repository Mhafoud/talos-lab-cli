#!/bin/bash

set -e

MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "Usage: ./4_bootstrap_cluster.sh <MASTER_IP>"
  exit 1
fi

# 🔥 PATHS SAFE
TALOS_DIR="$PWD/talos-config"
TALOSCONFIG_FILE="$TALOS_DIR/talosconfig"
KUBECONFIG_FILE="$PWD/kubeconfig"

export TALOSCONFIG="$TALOSCONFIG_FILE"

echo "Bootstrapping Kubernetes cluster..."

talosctl bootstrap \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP"

echo "Cluster bootstrapped."

echo "Retrieving kubeconfig..."

talosctl kubeconfig "$KUBECONFIG_FILE" \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" \
  --force

echo "Waiting for Kubernetes API..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" get --raw='/readyz' >/dev/null 2>&1
do
  echo "Kubernetes API not ready yet..."
  sleep 5
done

echo "Kubernetes API is ready!"