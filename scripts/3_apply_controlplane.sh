#!/bin/bash
set -e

if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "Usage: ./3_apply_controlplane.sh <master-ip>"
  exit 1
fi

TALOSCONFIG_FILE="$TALOS_LAB_HOME/talos-config/talosconfig"

echo "Applying controlplane configuration..."

talosctl apply-config \
  --insecure \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$TALOS_LAB_HOME/talos-config/controlplane.yaml"

export TALOSCONFIG="$TALOSCONFIG_FILE"

echo "Waiting for Talos API..."

sleep 5

until talosctl version \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" >/dev/null 2>&1
do
  echo "Talos API not ready yet..."
  sleep 5
done

echo "Talos API is ready."