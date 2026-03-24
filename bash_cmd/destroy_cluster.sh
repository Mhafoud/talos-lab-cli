#!/bin/bash

set -e

# -----------------------------
# GLOBAL INIT
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  export TALOS_LAB_HOME="$(pwd)"
fi

CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"
TALOSCONFIG_FILE="$TALOS_LAB_HOME/talos-config/talosconfig"
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

fail() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

echo ""
echo "================================="
echo "Talos Lab - Destroying cluster"
echo "================================="
echo ""

# -----------------------------
# CHECK CONFIG
# -----------------------------
step "Checking configuration"

if [ ! -f "$CONFIG_FILE" ]; then
  fail "servers.json not found at $CONFIG_FILE"
fi

ok "Config file found"

# -----------------------------
# CHECK TALOSCONFIG
# -----------------------------
step "Checking talosconfig"

if [ ! -f "$TALOSCONFIG_FILE" ]; then
  warn "talosconfig not found → cluster may already be destroyed"
  echo "[INFO] Cleaning local files anyway..."
else
  export TALOSCONFIG="$TALOSCONFIG_FILE"

  # -----------------------------
  # RESET NODES
  # -----------------------------
  step "Resetting nodes"

  IPS=$(jq -r '.servers[].ip' "$CONFIG_FILE")

  for IP in $IPS
  do
    echo "[INFO] Resetting node $IP..."

    talosctl reset \
      --nodes "$IP" \
      --endpoints "$IP" \
      --reboot \
      --graceful=false \
      --wait=false || warn "Failed to reset $IP"
  done

  ok "Reset commands sent to all nodes"
fi

# -----------------------------
# CLEAN SSH
# -----------------------------
step "Cleaning SSH known_hosts"

IPS=$(jq -r '.servers[].ip' "$CONFIG_FILE")

for IP in $IPS
do
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" >/dev/null 2>&1 || true
done

ok "SSH cleaned"

# -----------------------------
# CLEAN LOCAL FILES
# -----------------------------
step "Cleaning local configuration"

rm -f "$KUBECONFIG_FILE" || true
rm -rf "$TALOS_LAB_HOME/talos-config" || true

ok "Local files removed"

# -----------------------------
# FINAL MESSAGE
# -----------------------------
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN} Cluster destroyed successfully ${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""