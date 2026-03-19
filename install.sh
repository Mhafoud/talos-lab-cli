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
else
  echo "[OK] jq already installed"
fi

# sshpass
if ! command -v sshpass &> /dev/null; then
  echo "[INFO] Installing sshpass..."
  sudo apt install -y sshpass
else
  echo "[OK] sshpass already installed"
fi

# kubectl (OFFICIAL)
if ! command -v kubectl &> /dev/null; then
  echo "[INFO] Installing kubectl..."

  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
else
  echo "[OK] kubectl already installed"
fi

# yq (binary)
if ! command -v yq &> /dev/null; then
  echo "[INFO] Installing yq..."

  sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
  sudo chmod +x /usr/local/bin/yq
else
  echo "[OK] yq already installed"
fi

# helm
if ! command -v helm &> /dev/null; then
  echo "[INFO] Installing helm..."

  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "[OK] helm already installed"
fi

# talosctl
if ! command -v talosctl &> /dev/null; then
  echo "[INFO] Installing talosctl..."

  curl -sSL https://talos.dev/install | bash
else
  echo "[OK] talosctl already installed"
fi

# git
if ! command -v git &> /dev/null; then
  echo "[INFO] Installing git..."
  sudo apt install -y git
else
  echo "[OK] git already installed"
fi

# go
if ! command -v go &> /dev/null; then
  echo "[INFO] Installing Go..."

  wget -q https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz

  if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
  fi

  export PATH=$PATH:/usr/local/go/bin
else
  echo "[OK] go already installed"
fi

# -----------------------------
# VERIFY
# -----------------------------
echo ""
echo "[INFO] Verifying tools..."

for tool in jq sshpass kubectl yq helm talosctl git go
do
  if ! command -v $tool &> /dev/null; then
    echo "[ERROR] $tool installation failed"
    exit 1
  else
    echo "[OK] $tool installed"
  fi
done

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
# ENV
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
echo "[INFO] Final check..."

if ! command -v talos-lab &> /dev/null; then
  echo "[ERROR] talos-lab install failed"
  exit 1
fi

echo ""
echo "================================="
echo "[SUCCESS] Installation complete!"
echo "================================="
echo ""

echo "👉 Run:"
echo "source ~/.bashrc"
echo ""

echo "👉 Then:"
echo "talos-lab --help"