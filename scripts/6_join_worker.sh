#!/bin/bash
set -e

if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

WORKER_IP=$1
WORKER_PASSWORD=$2
MASTER_IP=$3
WORKER_INDEX=$4

if [ -z "$WORKER_IP" ] || [ -z "$WORKER_PASSWORD" ] || [ -z "$MASTER_IP" ] || [ -z "$WORKER_INDEX" ]; then
  echo "Usage: join_worker.sh <IP> <PASSWORD> <MASTER_IP> <INDEX>"
  exit 1
fi

KUBECONFIG_FILE="$TALOS_LAB_HOME/kubeconfig"
TALOS_CONFIG_DIR="$TALOS_LAB_HOME/talos-config"

WORKER_NAME="worker-node-$WORKER_INDEX"
TMP_CONFIG="$TALOS_CONFIG_DIR/$WORKER_NAME.yaml"

echo "Joining worker: $WORKER_NAME ($WORKER_IP)"

# -------------------------------
# STEP 1 - CHECK TALOS
# -------------------------------
echo ""
echo "STEP 1 - Checking Talos state"

if talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" &>/dev/null; then
  echo "[INFO] Talos already running"

elif talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" --insecure &>/dev/null; then
  echo "[INFO] Talos in maintenance mode → waiting..."

  until talosctl version --nodes "$WORKER_IP" --endpoints "$WORKER_IP" &>/dev/null
  do
    echo "Talos not ready yet..."
    sleep 5
  done

  echo "[SUCCESS] Talos ready"

else
  echo "[INFO] Installing Talos..."
  bash "$TALOS_LAB_HOME/scripts/1_install_talos.sh" "$WORKER_IP" "$WORKER_PASSWORD"
fi

# -------------------------------
# STEP 2 - CONFIG
# -------------------------------
echo ""
echo "STEP 2 - Preparing config"

cp "$TALOS_CONFIG_DIR/worker.yaml" "$TMP_CONFIG"
yq -i ".machine.network.hostname = \"$WORKER_NAME\"" "$TMP_CONFIG"

# -------------------------------
# STEP 3 - APPLY
# -------------------------------
echo "Applying config..."

talosctl apply-config \
  --insecure \
  --nodes "$WORKER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$TMP_CONFIG"

# -------------------------------
# STEP 4 - WAIT JOIN
# -------------------------------
echo ""
echo "Waiting for join..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes | grep -q "$WORKER_NAME"
do
  echo "Worker not joined yet..."
  sleep 5
done

echo "Worker joined"

# -------------------------------
# STEP 5 - WAIT READY
# -------------------------------
echo ""
echo "Waiting Ready..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes | grep "$WORKER_NAME" | grep -q Ready
do
  echo "Worker not ready yet..."
  sleep 5
done

echo "[SUCCESS] $WORKER_NAME Ready"

rm -f "$TMP_CONFIG"