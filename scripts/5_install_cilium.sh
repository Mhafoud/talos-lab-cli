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
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

[ -f "$KUBECONFIG_FILE" ] || fail "kubeconfig not found → run create cluster"

export KUBECONFIG="$KUBECONFIG_FILE"

echo "[INFO] Using kubeconfig: $KUBECONFIG"
echo ""

# -----------------------------
# CHECK DEPENDENCIES
# -----------------------------
step "Checking dependencies"

command -v helm >/dev/null || fail "helm not installed"
command -v kubectl >/dev/null || fail "kubectl not installed"

ok "Dependencies OK"

# -----------------------------
# CLEAN EXISTING CILIUM
# -----------------------------
step "Checking existing Cilium installation"

if helm list -n kube-system | grep -q cilium; then
  echo "[INFO] Existing Cilium detected → removing"

  helm uninstall cilium -n kube-system

  step "Waiting old Cilium pods to terminate"

  kubectl -n kube-system wait --for=delete pod \
    -l app.kubernetes.io/name=cilium-agent \
    --timeout=120s || true

  ok "Old Cilium removed"
else
  ok "No existing Cilium"
fi

# -----------------------------
# HELM REPO
# -----------------------------
step "Preparing Helm repo"

if ! helm repo list | grep -q cilium; then
  helm repo add cilium https://helm.cilium.io/
fi

helm repo update

ok "Helm repo ready"

# -----------------------------
# INSTALL CILIUM
# -----------------------------
step "Installing Cilium"

helm upgrade --install cilium cilium/cilium \
  --version 1.15.6 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set securityContext.privileged=true \
  --set cgroup.autoMount.enabled=false \
  --set cleanState=false \
  --set operator.prometheus.enabled=false

ok "Cilium deployed"

# -----------------------------
# WAIT CILIUM READY
# -----------------------------
step "Waiting for Cilium to be ready"

for i in {1..60}; do

  READY=$(kubectl -n kube-system get pods \
    -l app.kubernetes.io/name=cilium-agent \
    --no-headers 2>/dev/null | grep Running | wc -l)

  TOTAL=$(kubectl -n kube-system get pods \
    -l app.kubernetes.io/name=cilium-agent \
    --no-headers 2>/dev/null | wc -l)

  echo "Cilium: $READY/$TOTAL ready"

  if [ "$READY" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    ok "Cilium is fully ready"
    break
  fi

  sleep 5

  if [ "$i" -eq 60 ]; then
    fail "Cilium did not become ready"
  fi

done

# -----------------------------
# CHECK CLUSTER NETWORK
# -----------------------------
step "Checking cluster health"

kubectl get nodes
echo ""
kubectl get pods -n kube-system

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Cilium network ready            ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""