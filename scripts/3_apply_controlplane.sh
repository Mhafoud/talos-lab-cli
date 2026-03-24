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
  fail "Usage: apply_controlplane.sh <MASTER_IP>"
fi

# -----------------------------
# PATHS
# -----------------------------
CONFIG_DIR="$TALOS_LAB_HOME/talos-config"
TALOSCONFIG_FILE="$CONFIG_DIR/talosconfig"
CONTROLPLANE_FILE="$CONFIG_DIR/controlplane.yaml"

# -----------------------------
# CHECK FILES
# -----------------------------
step "Checking Talos config files"

[ -f "$TALOSCONFIG_FILE" ] || fail "talosconfig not found"
[ -f "$CONTROLPLANE_FILE" ] || fail "controlplane.yaml not found"

ok "Config files OK"

# -----------------------------
# APPLY CONFIG
# -----------------------------
step "Applying controlplane configuration"

talosctl apply-config \
  --insecure \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$CONTROLPLANE_FILE"

ok "Config applied"

# -----------------------------
# EXPORT TALOSCONFIG
# -----------------------------
export TALOSCONFIG="$TALOSCONFIG_FILE"

# -----------------------------
# WAIT API READY
# -----------------------------
step "Waiting for Talos API"

for i in {1..40}; do

  if talosctl version \
    --nodes "$MASTER_IP" \
    --endpoints "$MASTER_IP" >/dev/null 2>&1; then

    ok "Talos API is ready"
    break
  fi

  echo "Waiting Talos API... ($i/40)"
  sleep 5

  if [ "$i" -eq 40 ]; then
    fail "Talos API did not become ready"
  fi

done

# -----------------------------
# DEBUG INFO
# -----------------------------
step "Checking Talos node status"

talosctl get members \
  --nodes "$MASTER_IP" \
  --endpoints "$MASTER_IP" || true

# -----------------------------
# SUCCESS
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Controlplane configured         ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""