#!/bin/bash
set -e

if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

CLUSTER_NAME=$1
MASTER_IP=$2

if [ -z "$CLUSTER_NAME" ] || [ -z "$MASTER_IP" ]; then
  echo "Usage: ./2_generate_config.sh <CLUSTER_NAME> <MASTER_IP>"
  exit 1
fi

CONFIG_DIR="$TALOS_LAB_HOME/talos-config"

echo "Generating Talos configuration..."

rm -rf "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

talosctl gen config "$CLUSTER_NAME" https://"$MASTER_IP":6443 \
  --output-dir "$CONFIG_DIR" \
  --talos-version v1.11.6 \
  --kubernetes-version 1.29.10

echo "Disabling default Talos CNI..."

yq -i '.cluster.network.cni.name = "none"' "$CONFIG_DIR/controlplane.yaml"
yq -i '.cluster.network.cni.name = "none"' "$CONFIG_DIR/worker.yaml"

echo "Setting master hostname..."

yq -i '.machine.network.hostname = "master-node"' "$CONFIG_DIR/controlplane.yaml"

echo "Talos configuration generated in $CONFIG_DIR"