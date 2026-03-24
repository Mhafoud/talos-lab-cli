#!/bin/bash

set -e

# -----------------------------
# COLORS
# -----------------------------
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

step() {
  echo -e "${YELLOW}[STEP]${NC} $1"
}

ok() {
  echo -e "${GREEN}[OK]${NC} $1"
}

fail() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# -----------------------------
# CHECK ENV
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  fail "TALOS_LAB_HOME is not set"
fi

# -----------------------------
# PATHS
# -----------------------------
CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

[ -f "$CONFIG_FILE" ] || fail "servers.json not found"
[ -f "$KUBECONFIG_FILE" ] || fail "kubeconfig not found → run create cluster"

export KUBECONFIG="$KUBECONFIG_FILE"

echo "[INFO] Using kubeconfig: $KUBECONFIG"
echo ""

# -----------------------------
# READ MASTER
# -----------------------------
step "Reading configuration"

MASTER_IP=$(jq -r '.servers[] | select(.name=="master") | .ip' "$CONFIG_FILE")

[ -z "$MASTER_IP" ] && fail "Master IP not found"

ok "Master: $MASTER_IP"

# -----------------------------
# PROCESS WORKERS
# -----------------------------
step "Processing workers"

INDEX=1

for row in $(jq -c '.servers[]' "$CONFIG_FILE"); do

  NAME=$(echo "$row" | jq -r '.name')

  if [ "$NAME" = "master" ]; then
    continue
  fi

  WORKER_IP=$(echo "$row" | jq -r '.ip')
  WORKER_PASSWORD=$(echo "$row" | jq -r '.password')
  WORKER_NAME="worker-node-$INDEX"

  echo ""
  echo "-------------------------------------"
  echo "Worker $INDEX → $WORKER_IP"
  echo "-------------------------------------"

  # -----------------------------
  # VALIDATION
  # -----------------------------
  if [ -z "$WORKER_IP" ] || [ -z "$WORKER_PASSWORD" ]; then
    fail "Invalid worker config"
  fi

  # -----------------------------
  # SKIP IF EXISTS
  # -----------------------------
  if kubectl get nodes | grep -q "$WORKER_NAME"; then
    echo "[INFO] $WORKER_NAME already exists → skipping"
  else
    step "Joining $WORKER_NAME"

    bash "$TALOS_LAB_HOME/scripts/6_join_worker.sh" \
      "$WORKER_IP" \
      "$WORKER_PASSWORD" \
      "$MASTER_IP" \
      "$INDEX"

    ok "$WORKER_NAME joined"
  fi

  INDEX=$((INDEX+1))

done

# -----------------------------
# FINAL STATUS
# -----------------------------
step "Final cluster status"

kubectl get nodes

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} All workers processed           ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""