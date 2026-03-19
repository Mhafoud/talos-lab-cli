#!/bin/bash
set -e

KUBECONFIG_FILE="$PWD/kubeconfig"

echo ""
echo "================================="
echo "Talos Lab Cluster Status"
echo "================================="
echo ""

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "[ERROR] Cluster not initialized yet."
  echo "Run: talos-lab create cluster"
  exit 1
fi

echo "[INFO] Nodes:"
kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes
echo ""

echo "[INFO] System Pods:"
kubectl --kubeconfig "$KUBECONFIG_FILE" -n kube-system get pods
echo ""