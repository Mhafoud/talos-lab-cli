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
# CHECK REQUIRED TOOLS
# -----------------------------
echo "[INFO] Checking required tools..."

check_tool () {
  if ! command -v $1 &> /dev/null; then
    echo "[ERROR] $1 is not installed"
    echo "👉 Please install it before continuing"
    exit 1
  else
    echo "[OK] $1 detected"
  fi
}

check_tool git
check_tool go
check_tool jq
check_tool sshpass
check_tool kubectl
check_tool talosctl
check_tool yq

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