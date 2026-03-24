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
# INPUT
# -----------------------------
MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  fail "Usage: bootstrap_cluster.sh <MASTER_IP>"
fi

# -----------------------------
# PATHS
# -----------------------------
CONFIG_DIR="$TALOS_LAB_HOME/talos-config"
TALOSCONFIG_FILE="$CONFIG_DIR/talosconfig"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

# -----------------------------
# CHECK FILES
# -----------------------------
step "Checking required files"

[ -f "$TALOSCONFIG_FILE" ] || fail "talosconfig not found"

ok "Files OK"

# -----------------------------
# EXPORT TALOSCONFIG
# -----------------------------
export TALOSCONFIG="$TALOSCONFIG_FILE"

# -----------------------------
# BOOTSTRAP CLUSTER
# -----------------------------
step "Bootstrapping Kubernetes cluster"

talosctl bootstrap \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP"

ok "Cluster bootstrapped"

# -----------------------------
# GET KUBECONFIG
# -----------------------------
step "Retrieving kubeconfig"

talosctl kubeconfig "$KUBECONFIG_FILE" \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" \
  --force

ok "kubeconfig saved at $KUBECONFIG_FILE"

# -----------------------------
# EXPORT KUBECONFIG (IMPORTANT)
# -----------------------------
export KUBECONFIG="$KUBECONFIG_FILE"

# -----------------------------
# WAIT K8S API
# -----------------------------
step "Waiting for Kubernetes API"

for i in {1..60}; do

  if kubectl get --raw='/readyz' >/dev/null 2>&1; then
    ok "Kubernetes API is ready"
    break
  fi

  echo "Waiting Kubernetes API... ($i/60)"
  sleep 5

  if [ "$i" -eq 60 ]; then
    fail "Kubernetes API never became ready"
  fi

done

# -----------------------------
# DEBUG CLUSTER
# -----------------------------
step "Cluster status"

kubectl get nodes

echo ""
kubectl get pods -n kube-system

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Kubernetes cluster ready        ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""