#!/bin/bash

set -e

echo ""
echo "================================="
echo "Talos Lab - Destroying cluster"
echo "================================="
echo ""

# -----------------------------
# CHECK ENV
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

# -------------------------------
# PATHS SAFE
# -------------------------------
CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"
TALOSCONFIG_FILE="$TALOS_LAB_HOME/talos-config/talosconfig"
KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"

# -------------------------------
# vérifier config
# -------------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "[ERROR] servers.json not found at $CONFIG_FILE"
  exit 1
fi

# -------------------------------
# vérifier talosconfig
# -------------------------------
if [ ! -f "$TALOSCONFIG_FILE" ]; then
  echo "[ERROR] talosconfig not found → cannot destroy cluster"
  exit 1
fi

export TALOSCONFIG="$TALOSCONFIG_FILE"

echo "[INFO] Reading configuration..."
echo ""

IPS=$(jq -r '.servers[].ip' "$CONFIG_FILE")

echo "[INFO] Resetting nodes..."
echo ""

for IP in $IPS
do
  echo "[INFO] Resetting node $IP..."

  talosctl reset \
    --nodes "$IP" \
    --endpoints "$IP" \
    --reboot \
    --graceful=false \
    --wait=false || echo "[WARN] Failed to reset $IP"
done

echo ""
echo "[INFO] Nodes reset triggered"

# -------------------------------
# nettoyage SSH
# -------------------------------
echo ""
echo "[INFO] Cleaning SSH known_hosts..."

for IP in $IPS
do
  ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" >/dev/null 2>&1 || true
done

# -------------------------------
# cleanup local
# -------------------------------
echo ""
echo "[INFO] Cleaning local configuration..."

rm -f "$KUBECONFIG_FILE" || true
rm -rf "$TALOS_LAB_HOME/talos-config" || true

echo ""
echo "[SUCCESS] Cluster destroyed and cleaned"
echo ""