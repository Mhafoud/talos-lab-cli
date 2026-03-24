#!/bin/bash

set -e

# -----------------------------
# GLOBAL INIT
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  export TALOS_LAB_HOME="$(pwd)"
fi

KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

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

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

# -----------------------------
# HEADER
# -----------------------------
echo ""
echo "================================="
echo "Talos Lab Cluster Status"
echo "================================="
echo ""

# -----------------------------
# CHECK CONFIG
# -----------------------------
step "Checking configuration"

if [ ! -f "$KUBECONFIG_FILE" ]; then
  warn "No kubeconfig found → cluster not created"
  echo ""
  echo "👉 Run: talos-lab create cluster"
  exit 0
fi

ok "kubeconfig detected"

export KUBECONFIG="$KUBECONFIG_FILE"

# -----------------------------
# CHECK API (SMART)
# -----------------------------
step "Checking cluster access"

if ! kubectl get nodes >/dev/null 2>&1; then
  warn "Cluster exists but API not reachable"
  echo ""
  echo "Possible reasons:"
  echo "- Cluster is starting"
  echo "- Network issue"
  echo "- Wrong kubeconfig"
  echo ""
  echo "Try:"
  echo "kubectl get nodes"
  exit 0
fi

ok "Cluster reachable"

# -----------------------------
# SHOW STATUS
# -----------------------------
echo ""
info "Nodes:"
kubectl get nodes
echo ""

info "System Pods:"
kubectl -n kube-system get pods
echo ""

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Cluster is RUNNING              ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""