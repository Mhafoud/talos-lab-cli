#!/bin/bash

set -e

MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "Usage: ./3_apply_controlplane.sh <master-ip>"
  exit 1
fi

# 🔥 IMPORTANT : chemins absolus
TALOS_DIR="$PWD/talos-config"
TALOSCONFIG_FILE="$TALOS_DIR/talosconfig"
CONTROLPLANE_FILE="$TALOS_DIR/controlplane.yaml"

echo "Applying controlplane configuration..."

talosctl apply-config \
  --insecure \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$CONTROLPLANE_FILE"

echo "Configuration applied."

# 🔥 IMPORTANT
export TALOSCONFIG="$TALOSCONFIG_FILE"

echo "Waiting for Talos API to come back..."

sleep 5

until talosctl version \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" >/dev/null 2>&1
do
  echo "Talos API not ready yet..."
  sleep 5
done

echo "Talos API is ready."