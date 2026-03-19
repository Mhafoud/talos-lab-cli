#!/bin/bash

set -e

VM_IP=$1
VM_PASSWORD=$2
VM_USER="root"
NODE_HOSTNAME="master-node"

if [ -z "$VM_IP" ] || [ -z "$VM_PASSWORD" ]; then
  echo "Usage: install_talos.sh <IP> <PASSWORD>"
  exit 1
fi

echo ""
echo "================================="
echo "Checking if Talos is already installed"
echo "================================="
echo ""

if talosctl version --nodes "$VM_IP" --endpoints "$VM_IP" &>/dev/null; then
  echo "[INFO] Talos already installed on $VM_IP"
  echo "[INFO] Skipping installation"
  exit 0
fi

echo "[INFO] Talos not detected, proceeding with installation"
echo ""

echo "Connecting to $VM_IP..."

sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no \
  -o ServerAliveInterval=5 \
  -o ServerAliveCountMax=3 \
  $VM_USER@$VM_IP << EOF || true

set -e

echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1

echo "Installing boot-to-talos..."
curl -4 -sSL https://github.com/cozystack/boot-to-talos/raw/refs/heads/main/hack/install.sh | sh

INTERFACE=\$(ip -o -4 route show to default | awk '{print \$5}')
IP=\$(hostname -I | awk '{print \$1}')
GATEWAY=\$(ip route | grep default | awk '{print \$3}')
NETMASK="255.255.254.0"

echo "Starting Talos installation..."

boot-to-talos \
  -mode install \
  -disk /dev/sda \
  -yes \
  -extra-kernel-arg "ip=\${IP}::\${GATEWAY}:\${NETMASK}:${NODE_HOSTNAME}:\${INTERFACE}:none"

echo "Rebooting system..."
reboot -f

EOF

echo "SSH session closed (reboot in progress)"

echo ""
echo "Waiting for node to go down..."

for i in $(seq 1 30); do

  if ! sshpass -p "$VM_PASSWORD" ssh \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=3 \
    $VM_USER@$VM_IP "true" &>/dev/null; then

    echo "Node is down, reboot confirmed."
    break
  fi

  echo "Still reachable, waiting... ($i/30)"
  sleep 3

done

echo ""
echo "Waiting for Talos maintenance mode..."

until talosctl version \
  --nodes "$VM_IP" \
  --endpoints "$VM_IP" \
  --insecure 2>&1 | grep -q "maintenance mode"
do
  echo "Talos not ready yet..."
  sleep 5
done

echo "Talos is in maintenance mode, ready for configuration!"