#!/bin/bash
set -e

# -----------------------------
# GLOBAL INIT
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  export TALOS_LAB_HOME="$(pwd)"
fi

CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

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
# CHECK CONFIG
# -----------------------------
step "Reading configuration"

if [ ! -f "$CONFIG_FILE" ]; then
  fail "servers.json not found at $CONFIG_FILE"
fi

MASTER_IP=$(jq -r '.servers[] | select(.name=="master") | .ip' "$CONFIG_FILE")
MASTER_PASSWORD=$(jq -r '.servers[] | select(.name=="master") | .password' "$CONFIG_FILE")

if [ "$MASTER_IP" == "null" ] || [ -z "$MASTER_IP" ]; then
  fail "Master IP not found in config"
fi

CLUSTER_NAME="talos-lab"

echo "Master IP: $MASTER_IP"
ok "Configuration loaded"

# ------------------------------------------------
# DETECT EXISTING CLUSTER (SMART)
# ------------------------------------------------

step "Checking existing cluster"

if [ -f "$KUBECONFIG_FILE" ]; then
  export KUBECONFIG="$KUBECONFIG_FILE"

  if kubectl get nodes >/dev/null 2>&1; then
    ok "Cluster already exists → skipping master creation"
    exit 0
  else
    echo "[INFO] kubeconfig exists but cluster not reachable → continuing"
  fi
fi

# ------------------------------------------------
# INSTALL TALOS
# ------------------------------------------------

step "Installing Talos on master"

bash "$TALOS_LAB_HOME/scripts/1_install_talos.sh" "$MASTER_IP" "$MASTER_PASSWORD"

ok "Talos installed"

# ------------------------------------------------
# GENERATE CONFIG
# ------------------------------------------------

step "Generating Talos config"

bash "$TALOS_LAB_HOME/scripts/2_generate_config.sh" "$CLUSTER_NAME" "$MASTER_IP"

ok "Talos config generated"

# ------------------------------------------------
# APPLY CONTROL PLANE
# ------------------------------------------------

step "Applying controlplane config"

bash "$TALOS_LAB_HOME/scripts/3_apply_controlplane.sh" "$MASTER_IP"

ok "Controlplane applied"

# ------------------------------------------------
# BOOTSTRAP CLUSTER
# ------------------------------------------------

step "Bootstrapping cluster"

bash "$TALOS_LAB_HOME/scripts/4_bootstrap_cluster.sh" "$MASTER_IP"

ok "Cluster bootstrapped"

# ------------------------------------------------
# WAIT API READY (CRITICAL FIX)
# ------------------------------------------------

step "Waiting for Kubernetes API"

export KUBECONFIG="$KUBECONFIG_FILE"

RETRIES=20
COUNT=0

until kubectl get nodes >/dev/null 2>&1; do
  sleep 5
  COUNT=$((COUNT+1))

  echo "Waiting API... ($COUNT/$RETRIES)"

  if [ $COUNT -ge $RETRIES ]; then
    fail "Kubernetes API not reachable after bootstrap"
  fi
done

ok "API reachable"

# ------------------------------------------------
# INSTALL CILIUM
# ------------------------------------------------

step "Installing Cilium"

bash "$TALOS_LAB_HOME/scripts/5_install_cilium.sh"

ok "Cilium installed"

# ------------------------------------------------
# FINAL CHECK
# ------------------------------------------------

echo ""
step "Cluster status"

kubectl get nodes

echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Master successfully created!  ${NC}"
echo -e "${GREEN}=================================${NC}"