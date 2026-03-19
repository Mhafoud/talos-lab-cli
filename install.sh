#!/bin/bash

set -e

echo ""
echo "================================="
echo "Installing Talos Lab CLI"
echo "================================="
echo ""

INSTALL_DIR="$HOME/.talos-lab"
REPO_URL="https://github.com/Mhafoud/talos-lab-cli.git"
BINARY_PATH="/usr/local/bin/talos-lab"

# -----------------------------
# CHECK OS
# -----------------------------
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  echo "[ERROR] Only Linux is supported"
  exit 1
fi

# -----------------------------
# INSTALL DEPENDENCIES
# -----------------------------
echo ""
echo "[INFO] Installing dependencies..."

# jq
if ! command -v jq &> /dev/null; then
  echo "[INFO] Installing jq..."
  sudo apt update && sudo apt install -y jq
fi

# sshpass
if ! command -v sshpass &> /dev/null; then
  echo "[INFO] Installing sshpass..."
  sudo apt install -y sshpass
fi

# kubectl (OFFICIAL)
if ! command -v kubectl &> /dev/null; then
  echo "[INFO] Installing kubectl..."

  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# yq
if ! command -v yq &> /dev/null; then
  echo "[INFO] Installing yq..."

  sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
fi

# helm
if ! command -v helm &> /dev/null; then
  echo "[INFO] Installing helm..."

  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# talosctl
if ! command -v talosctl &> /dev/null; then
  echo "[INFO] Installing talosctl..."

  curl -sSL https://talos.dev/install | bash
fi

# git (important pour clone)
if ! command -v git &> /dev/null; then
  echo "[INFO] Installing git..."
  sudo apt install -y git
fi

# go (pour build CLI)
if ! command -v go &> /dev/null; then
  echo "[INFO] Installing Go..."

  wget -q https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
  echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
  export PATH=$PATH:/usr/local/go/bin
fi

# -----------------------------
# VERIFY DEPENDENCIES
# -----------------------------
echo ""
echo "[INFO] Verifying tools..."

check_tool () {
  if ! command -v $1 &> /dev/null; then
    echo "[ERROR] $1 installation failed"
    exit 1
  else
    echo "[OK] $1 installed"
  fi
}

check_tool jq
check_tool sshpass
check_tool kubectl
check_tool yq
check_tool helm
check_tool talosctl
check_tool git
check_tool go

echo ""
echo "[SUCCESS] All dependencies installed"

# -----------------------------
# INSTALL CLI
# -----------------------------
echo ""
echo "[INFO] Installing Talos Lab..."

rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "[INFO] Building CLI..."
go build -o talos-lab

echo "[INFO] Installing binary..."
sudo mv talos-lab "$BINARY_PATH"

# -----------------------------
# ENV CONFIG
# -----------------------------
echo "[INFO] Configuring environment..."

if ! grep -q "TALOS_LAB_HOME" ~/.bashrc; then
  echo "export TALOS_LAB_HOME=$INSTALL_DIR" >> ~/.bashrc
fi

export TALOS_LAB_HOME="$INSTALL_DIR"

# -----------------------------
# FINAL CHECK
# -----------------------------
echo ""
echo "[INFO] Final CLI test..."

if ! command -v talos-lab &> /dev/null; then
  echo "[ERROR] talos-lab not installed correctly"
  exit 1
fi

echo "[SUCCESS] talos-lab is ready"

# -----------------------------
# DONE
# -----------------------------
echo ""
echo "================================="
echo "[SUCCESS] Installation complete!"
echo "================================="
echo ""

echo "👉 Run:"
echo "source ~/.bashrc"
echo ""

echo "👉 Then create your config:"
echo "mkdir -p ~/.talos-lab/config"
echo "nano ~/.talos-lab/config/servers.json"