#!/bin/bash
set -e

# 🔥 PATH SAFE
KUBECONFIG_FILE="$PWD/kubeconfig"

if [ ! -f "$KUBECONFIG_FILE" ]; then
  echo "kubeconfig not found. Run bootstrap script first."
  exit 1
fi

echo "Checking if Cilium is already installed..."
if helm list -n kube-system --kubeconfig "$KUBECONFIG_FILE" | grep -q cilium; then
  echo "Existing Cilium installation detected. Removing it..."
  helm uninstall cilium \
    -n kube-system \
    --kubeconfig "$KUBECONFIG_FILE"

  echo "Waiting for old Cilium pods to terminate..."
  kubectl --kubeconfig "$KUBECONFIG_FILE" \
    -n kube-system \
    delete pods -l app.kubernetes.io/name=cilium-agent \
    --ignore-not-found=true

  sleep 5
fi

echo "Adding Cilium Helm repository..."
helm repo add cilium https://helm.cilium.io/
helm repo update

echo "Installing Cilium optimized for Talos..."
helm upgrade --install cilium cilium/cilium \
  --version 1.15.6 \
  --namespace kube-system \
  --kubeconfig "$KUBECONFIG_FILE" \
  --set kubeProxyReplacement=true \
  --set securityContext.privileged=true \
  --set cgroup.autoMount.enabled=false \
  --set cleanState=false \
  --set operator.prometheus.enabled=false

echo ""
echo "Checking Cilium status..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" \
  -n kube-system \
  get pods -l app.kubernetes.io/name=cilium-agent \
  --no-headers 2>/dev/null | grep -q Running
do
  echo "Cilium agent not ready yet..."
  sleep 5
done

echo "Cilium agent is running."

PENDING=$(kubectl --kubeconfig "$KUBECONFIG_FILE" \
  -n kube-system get pods | grep Pending | wc -l)

if [ "$PENDING" -gt 0 ]; then
  echo "Warning: Some pods are Pending."
  echo "This is normal on a single-node cluster."
fi

echo ""
echo "Cilium network is ready!"
kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes
echo ""
echo "Cluster network is ready."