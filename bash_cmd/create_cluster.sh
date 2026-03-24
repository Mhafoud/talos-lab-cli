#!/bin/bash

set -e

# -----------------------------
# GLOBAL INIT
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  export TALOS_LAB_HOME="$(pwd)"
fi

export KUBECONFIG="$TALOS_LAB_HOME/kubeconfig"

CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"

# -----------------------------
# COLORS
# -----------------------------
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
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
# CHECK FILES
# -----------------------------
echo ""
echo "================================="
echo "Talos Lab - Creating full cluster"
echo "================================="
echo ""

if [ ! -f "$CONFIG_FILE" ]; then
  fail "Missing config file: $CONFIG_FILE"
fi

ok "Config file found"

# -----------------------------
# CHECK KUBECTL ACCESS
# -----------------------------
step "Checking kubectl access"

if ! kubectl version --client >/dev/null 2>&1; then
  fail "kubectl not installed"
fi

ok "kubectl available"

# -----------------------------
# MASTER
# -----------------------------
step "STEP 1 - Creating master node"

bash "$TALOS_LAB_HOME/bash_cmd/create_master.sh"

# -----------------------------
# WORKERS
# -----------------------------
step "STEP 2 - Joining all workers"

bash "$TALOS_LAB_HOME/scripts/7_join_all_workers.sh"

# -----------------------------
# WAIT CLUSTER READY (ROBUST)
# -----------------------------
step "Waiting for Kubernetes API"

RETRIES=10
COUNT=0

until kubectl get nodes >/dev/null 2>&1; do
  sleep 3
  COUNT=$((COUNT+1))

  echo "Waiting API... ($COUNT/$RETRIES)"

  if [ $COUNT -ge $RETRIES ]; then
    fail "Kubernetes API not reachable"
  fi
done

ok "API reachable"

step "Waiting for all nodes to be Ready"

kubectl wait --for=condition=Ready nodes --all --timeout=180s

ok "All nodes Ready"

# -----------------------------
# STORAGE
# -----------------------------
step "STEP 3 - Installing storage"

bash "$TALOS_LAB_HOME/scripts/8_install_storage.sh"

# -----------------------------
# FINAL STATUS
# -----------------------------
echo ""
step "Cluster status"

kubectl get nodes

echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Cluster successfully created!  ${NC}"
echo -e "${GREEN}=================================${NC}"