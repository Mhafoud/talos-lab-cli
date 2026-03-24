#!/bin/bash

set -e

VM_IP=$1
VM_PASSWORD=$2
VM_USER="root"
NODE_HOSTNAME="master-node"

if [ -z "$VM_IP" ] || [ -z "$VM_PASSWORD" ]; then
  echo "[ERROR] Usage: install_talos.sh <IP> <PASSWORD>"
  exit 1
fi

echo ""
echo "================================="
echo "Checking Talos state"
echo "================================="
echo ""

# ---------------------------------------
# CHECK TALOS READY
# ---------------------------------------
if talosctl version --nodes "$VM_IP" --endpoints "$VM_IP" &>/dev/null; then
  echo "[INFO] Talos already running on $VM_IP"
  exit 0
fi

# ---------------------------------------
# CHECK MAINTENANCE MODE
# ---------------------------------------
if talosctl version --nodes "$VM_IP" --endpoints "$VM_IP" --insecure &>/dev/null; then
  echo "[INFO] Talos in maintenance mode"

  until talosctl version --nodes "$VM_IP" --endpoints "$VM_IP" &>/dev/null
  do
    echo "Talos not ready yet..."
    sleep 5
  done

  echo "[SUCCESS] Talos ready"
  exit 0
fi

# ---------------------------------------
# INSTALL TALOS
# ---------------------------------------
echo "[INFO] Installing Talos on $VM_IP"
echo ""

sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no \
  -o ServerAliveInterval=5 \
  -o ServerAliveCountMax=3 \
  $VM_USER@$VM_IP << EOF || true

set -e

sysctl -w net.ipv6.conf.all.disable_ipv6=1

curl -4 -sSL https://github.com/cozystack/boot-to-talos/raw/refs/heads/main/hack/install.sh | sh

INTERFACE=\$(ip -o -4 route show to default | awk '{print \$5}')
IP=\$(hostname -I | awk '{print \$1}')
GATEWAY=\$(ip route | grep default | awk '{print \$3}')
NETMASK="255.255.254.0"

boot-to-talos \
  -mode install \
  -disk /dev/sda \
  -yes \
  -extra-kernel-arg "ip=\${IP}::\${GATEWAY}:\${NETMASK}:${NODE_HOSTNAME}:\${INTERFACE}:none"

reboot -f

EOF

echo "Waiting reboot..."

for i in {1..30}; do
  if ! sshpass -p "$VM_PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=3 \
    $VM_USER@$VM_IP "true" &>/dev/null; then
    echo "Node rebooted"
    break
  fi
  sleep 3
done

echo "Waiting Talos maintenance mode..."

until talosctl version \
  --nodes "$VM_IP" \
  --endpoints "$VM_IP" \
  --insecure 2>&1 | grep -q "maintenance mode"
do
  echo "Talos not ready..."
  sleep 5
done

echo "[SUCCESS] Talos ready for config"