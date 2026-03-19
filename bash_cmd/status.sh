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
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

echo ""
echo "================================="
echo "Talos Lab Cluster Status"
echo "================================="
echo ""

# -----------------------------
# CHECK CLUSTER
# -----------------------------
if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "[ERROR] Cluster not initialized yet."
  echo "Run: talos-lab create cluster"
  exit 1
fi

# -----------------------------
# STATUS
# -----------------------------
echo "[INFO] Nodes:"
kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes
echo ""

echo "[INFO] System Pods:"
kubectl --kubeconfig "$KUBECONFIG_FILE" -n kube-system get pods
echo ""