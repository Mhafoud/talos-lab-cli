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
MASTER_PASSWORD=$(jq -r '.servers[] | select(.name=="master") | .password' "$CONFIG_FILE")

CLUSTER_NAME="talos-lab"

echo "Master IP: $MASTER_IP"
echo ""

# ------------------------------------------------
# Detect existing cluster
# ------------------------------------------------

if [ -f "$KUBECONFIG_FILE" ]; then
  if kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes &>/dev/null; then
    echo "[INFO] Kubernetes cluster already exists"
    echo "[INFO] Skipping master creation"
    exit 0
  fi
fi

# ------------------------------------------------
# Install Talos
# ------------------------------------------------

echo "STEP 1 - Installing Talos"
bash "$TALOS_LAB_HOME/scripts/1_install_talos.sh" "$MASTER_IP" "$MASTER_PASSWORD"
echo ""

# ------------------------------------------------
# Generate Talos config
# ------------------------------------------------

echo "STEP 2 - Generating Talos config"
bash "$TALOS_LAB_HOME/scripts/2_generate_config.sh" "$CLUSTER_NAME" "$MASTER_IP"
echo ""

# ------------------------------------------------
# Apply controlplane config
# ------------------------------------------------

echo "STEP 3 - Applying controlplane config"
bash "$TALOS_LAB_HOME/scripts/3_apply_controlplane.sh" "$MASTER_IP"
echo ""

# ------------------------------------------------
# Bootstrap cluster
# ------------------------------------------------

echo "STEP 4 - Bootstrapping cluster"
bash "$TALOS_LAB_HOME/scripts/4_bootstrap_cluster.sh" "$MASTER_IP"
echo ""

# ------------------------------------------------
# Install Cilium
# ------------------------------------------------

echo "STEP 5 - Installing Cilium"
bash "$TALOS_LAB_HOME/scripts/5_install_cilium.sh"
echo ""

echo "Cluster ready!"

kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes