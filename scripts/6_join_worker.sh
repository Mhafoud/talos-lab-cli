#!/bin/bash
set -e

WORKER_IP=$1
WORKER_PASSWORD=$2
MASTER_IP=$3
WORKER_INDEX=$4

if [ -z "$WORKER_IP" ] || [ -z "$WORKER_PASSWORD" ] || [ -z "$MASTER_IP" ] || [ -z "$WORKER_INDEX" ]; then
  echo "Usage: ./6_join_worker.sh <WORKER_IP> <PASSWORD> <MASTER_IP> <INDEX>"
  exit 1
fi

# 🔥 PATH SAFE
KUBECONFIG_FILE="$PWD/kubeconfig"
TALOS_CONFIG_DIR="$PWD/talos-config"
TALOSCONFIG_FILE="$TALOS_CONFIG_DIR/talosconfig"

export TALOSCONFIG="$TALOSCONFIG_FILE"

WORKER_NAME="worker-node-$WORKER_INDEX"
TMP_CONFIG="$TALOS_CONFIG_DIR/worker-$WORKER_INDEX.yaml"

echo "Joining worker: $WORKER_NAME ($WORKER_IP)"

# -------------------------------
# STEP 1 - install Talos
# -------------------------------
echo ""
echo "STEP 1 - Installing Talos on worker"

bash "$PWD/scripts/1_install_talos.sh" "$WORKER_IP" "$WORKER_PASSWORD"

# -------------------------------
# STEP 2 - prepare config
# -------------------------------
echo ""
echo "STEP 2 - Preparing worker configuration"

if [ ! -f "$TALOS_CONFIG_DIR/worker.yaml" ]; then
  echo "[ERROR] worker.yaml not found in talos-config/"
  exit 1
fi

cp "$TALOS_CONFIG_DIR/worker.yaml" "$TMP_CONFIG"

yq -i ".machine.network.hostname = \"$WORKER_NAME\"" "$TMP_CONFIG"

# -------------------------------
# STEP 3 - apply config
# -------------------------------
echo "Applying worker configuration..."

talosctl apply-config \
  --insecure \
  --nodes "$WORKER_IP" \
  --endpoints "$MASTER_IP" \
  --file "$TMP_CONFIG"

echo "Worker configuration applied."

# -------------------------------
# STEP 4 - wait join
# -------------------------------
echo ""
echo "Waiting for node to join cluster..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes | grep -q "$WORKER_NAME"
do
  echo "Worker not joined yet..."
  sleep 5
done

echo ""
echo "Worker joined cluster."

# -------------------------------
# STEP 5 - wait ready
# -------------------------------
echo ""
echo "Waiting for node to become Ready..."

until kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes | grep "$WORKER_NAME" | grep -q Ready
do
  echo "Worker not ready yet..."
  sleep 5
done

echo ""
echo "$WORKER_NAME is Ready!"

kubectl --kubeconfig "$KUBECONFIG_FILE" get nodes

# -------------------------------
# CLEANUP
# -------------------------------
rm -f "$TMP_CONFIG"