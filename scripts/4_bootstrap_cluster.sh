#!/bin/bash
set -e

# -----------------------------
# CHECK ENV
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "Usage: ./4_bootstrap_cluster.sh <MASTER_IP>"
  exit 1
fi

# -----------------------------
# PATHS SAFE
# -----------------------------
TALOSCONFIG_FILE="$TALOS_LAB_HOME/talos-config/talosconfig"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

export TALOSCONFIG="$TALOSCONFIG_FILE"

echo "Bootstrapping Kubernetes cluster..."

talosctl bootstrap \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP"

echo "Cluster bootstrapped."

echo "Retrieving kubeconfig..."

# 🔥 CORRECTION ICI
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