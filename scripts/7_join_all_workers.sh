#!/bin/bash
set -e

# -----------------------------
# CHECK ENV
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

# -----------------------------
# PATHS SAFE
# -----------------------------
CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

echo "Reading configuration..."

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[ERROR] servers.json not found at $CONFIG_FILE"
  exit 1
fi

MASTER_IP=$(jq -r '.servers[] | select(.name=="master") | .ip' "$CONFIG_FILE")

echo "Master IP: $MASTER_IP"
echo ""

# ------------------------------------------------
# Check kubeconfig
# ------------------------------------------------

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "[ERROR] kubeconfig not found at $KUBECONFIG_FILE"
  echo "Run: talos-lab create cluster"
  exit 1
fi

# ------------------------------------------------
# Get workers
# ------------------------------------------------

WORKERS=$(jq -c '.servers[] | select(.name != "master")' "$CONFIG_FILE")

INDEX=1

echo "Processing workers..."

echo "$WORKERS" | while read -r worker
do

  WORKER_IP=$(echo "$worker" | jq -r '.ip')
  WORKER_PASSWORD=$(echo "$worker" | jq -r '.password')
  WORKER_NAME="worker-node-$INDEX"

  echo ""
  echo "-------------------------------------"
  echo "Worker $INDEX → $WORKER_IP"
  echo "-------------------------------------"

  # ------------------------------------------------
  # Skip if already exists
  # ------------------------------------------------

  if kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes | grep -q "$WORKER_NAME"; then

      echo "$WORKER_NAME already exists in cluster → skipping."

  else

      echo "Joining $WORKER_NAME..."

      bash "$TALOS_LAB_HOME/scripts/6_join_worker.sh" \
        "$WORKER_IP" \
        "$WORKER_PASSWORD" \
        "$MASTER_IP" \
        "$INDEX"

  fi

  INDEX=$((INDEX+1))

done

echo ""
echo "All workers processed."

kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes