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
# INPUTS
# -----------------------------
WORKER_IP=$1
WORKER_PASSWORD=$2
MASTER_IP=$3
WORKER_INDEX=$4

if [ -z "$WORKER_IP" ] || [ -z "$WORKER_PASSWORD" ] || [ -z "$MASTER_IP" ] || [ -z "$WORKER_INDEX" ]; then
  fail "Usage: join_worker.sh <IP> <PASSWORD> <MASTER_IP> <INDEX>"
fi

WORKER_NAME="worker-node-$WORKER_INDEX"

# -----------------------------
# PATHS
# -----------------------------
CONFIG_DIR="$TALOS_LAB_HOME/talos-config"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"
WORKER_TEMPLATE="$CONFIG_DIR/worker.yaml"
TMP_CONFIG="$CONFIG_DIR/$WORKER_NAME.yaml"

[ -f "$WORKER_TEMPLATE" ] || fail "worker.yaml not found"
[ -f "$KUBECONFIG_FILE" ] || fail "kubeconfig not found"

export KUBECONFIG="$KUBECONFIG_FILE"

echo ""
echo "================================="
echo "Joining worker: $WORKER_NAME"
echo "================================="
echo ""

# -----------------------------
# STEP 1 - TALOS
# -----------------------------
step "Checking Talos state"

if talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" &>/dev/null; then
  ok "Talos already running"

elif talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" --insecure &>/dev/null; then
  echo "[INFO] Talos in maintenance mode"

  for i in {1..30}; do
    if talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" &>/dev/null; then
      ok "Talos ready"
      break
    fi

    echo "Waiting Talos... ($i/30)"
    sleep 5

    if [ "$i" -eq 30 ]; then
      fail "Talos not ready"
    fi
  done

else
  step "Installing Talos"

  bash "$TALOS_LAB_HOME/scripts/1_install_talos.sh" \
    "$WORKER_IP" \
    "$WORKER_PASSWORD" \
    "$WORKER_NAME"

  ok "Talos installed"
fi

# -----------------------------
# STEP 2 - PREP CONFIG
# -----------------------------
step "Preparing worker config"

cp "$WORKER_TEMPLATE" "$TMP_CONFIG"

yq -i ".machine.network.hostname = \"$WORKER_NAME\"" "$TMP_CONFIG"

ok "Config ready"

# -----------------------------
# STEP 3 - APPLY CONFIG
# -----------------------------
step "Applying worker config"

talosctl apply-config \
  --insecure \
  --nodes "$WORKER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$TMP_CONFIG"

ok "Config applied"

# -----------------------------
# STEP 4 - WAIT JOIN
# -----------------------------
step "Waiting for worker to join cluster"

for i in {1..60}; do

  if kubectl get nodes | grep -q "$WORKER_NAME"; then
    ok "Worker joined"
    break
  fi

  echo "Waiting join... ($i/60)"
  sleep 5

  if [ "$i" -eq 60 ]; then
    fail "Worker never joined cluster"
  fi

done

# -----------------------------
# STEP 5 - WAIT READY
# -----------------------------
step "Waiting for worker Ready"

for i in {1..60}; do

  if kubectl get nodes | grep "$WORKER_NAME" | grep -q Ready; then
    ok "$WORKER_NAME is Ready"
    break
  fi

  echo "Waiting Ready... ($i/60)"
  sleep 5

  if [ "$i" -eq 60 ]; then
    fail "Worker never became Ready"
  fi

done

# -----------------------------
# DEBUG
# -----------------------------
step "Cluster status"

kubectl get nodes

# -----------------------------
# CLEAN
# -----------------------------
rm -f "$TMP_CONFIG"

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Worker successfully joined      ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""