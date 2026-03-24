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
CLUSTER_NAME=$1
MASTER_IP=$2

if [ -z "$CLUSTER_NAME" ] || [ -z "$MASTER_IP" ]; then
  fail "Usage: generate_config.sh <CLUSTER_NAME> <MASTER_IP>"
fi

# -----------------------------
# CONFIG
# -----------------------------
CONFIG_DIR="$TALOS_LAB_HOME/talos-config"

# versions (modifiable plus tard via config.json)
TALOS_VERSION="v1.11.6"
K8S_VERSION="1.29.10"

echo ""
echo "================================="
echo "Generating Talos configuration"
echo "================================="
echo ""

# -----------------------------
# CHECK DEPENDENCIES
# -----------------------------
step "Checking dependencies"

command -v talosctl >/dev/null || fail "talosctl not installed"
command -v yq >/dev/null || fail "yq not installed"

ok "Dependencies OK"

# -----------------------------
# CLEAN CONFIG
# -----------------------------
step "Cleaning previous config"

if [ -d "$CONFIG_DIR" ]; then
  rm -rf "$CONFIG_DIR"
fi

mkdir -p "$CONFIG_DIR"

ok "Config directory ready"

# -----------------------------
# GENERATE CONFIG
# -----------------------------
step "Generating Talos config"

talosctl gen config "$CLUSTER_NAME" https://"$MASTER_IP":6443 \
  --output-dir "$CONFIG_DIR" \
  --talos-version "$TALOS_VERSION" \
  --kubernetes-version "$K8S_VERSION"

ok "Talos config generated"

# -----------------------------
# DISABLE CNI
# -----------------------------
step "Disabling default Talos CNI"

yq -i '.cluster.network.cni.name = "none"' "$CONFIG_DIR/controlplane.yaml"
yq -i '.cluster.network.cni.name = "none"' "$CONFIG_DIR/worker.yaml"

ok "CNI disabled (for Cilium)"

# -----------------------------
# SET MASTER HOSTNAME
# -----------------------------
step "Setting master hostname"

yq -i '.machine.network.hostname = "master-node"' "$CONFIG_DIR/controlplane.yaml"

ok "Master hostname configured"

# -----------------------------
# SHOW RESULT
# -----------------------------
echo ""
echo "Generated files:"
ls -l "$CONFIG_DIR"

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Talos config ready              ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""