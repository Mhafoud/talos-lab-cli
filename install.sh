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
echo "[INFO] Installing dependencies..."

install_if_missing () {
  if ! command -v $1 &> /dev/null; then
    echo "[INFO] Installing $1..."
    eval $2
  else
    echo "[OK] $1 already installed"
  fi
}

install_if_missing jq "sudo apt update && sudo apt install -y jq"
install_if_missing sshpass "sudo apt install -y sshpass"
install_if_missing kubectl "sudo apt install -y kubectl"

# yq (snap)
if ! command -v yq &> /dev/null; then
  echo "[INFO] Installing yq..."
  sudo snap install yq
fi

# helm
if ! command -v helm &> /dev/null; then
  echo "[INFO] Installing helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# talosctl
if ! command -v talosctl &> /dev/null; then
  echo "[INFO] Installing talosctl..."
  curl -sSL https://talos.dev/install | bash
fi

# -----------------------------
# CLONE PROJECT
# -----------------------------
echo ""
echo "[INFO] Installing Talos Lab..."

rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

# -----------------------------
# BUILD CLI
# -----------------------------
echo "[INFO] Building CLI..."
go build -o talos-lab

# -----------------------------
# INSTALL BINARY
# -----------------------------
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
# DONE
# -----------------------------
echo ""
echo "================================="
echo "[SUCCESS] Talos Lab installed!"
echo "================================="
echo ""

echo "👉 Run:"
echo "source ~/.bashrc"
echo ""

echo "👉 Then:"
echo "talos-lab --help"
