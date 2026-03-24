#!/bin/bash

set -e

# -----------------------------
# GLOBAL INIT
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  export TALOS_LAB_HOME="$(pwd)"
fi

CONFIG_FILE="$TALOS_LAB_HOME/config/servers.json"

# -----------------------------
# COLORS
# -----------------------------
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

step() {
  echo -e "${YELLOW}[STEP]${NC} $1"
}

ok() {
  echo -e "${GREEN}[OK]${NC} $1"
}

fail() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

# -----------------------------
# HEADER
# -----------------------------
echo ""
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}Validating servers.json${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# -----------------------------
# FILE CHECK
# -----------------------------
step "Checking config file"

if [ ! -f "$CONFIG_FILE" ]; then
  fail "servers.json not found at $CONFIG_FILE"
fi

ok "Configuration file found"

# -----------------------------
# JSON SYNTAX
# -----------------------------
step "Checking JSON syntax"

if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
  fail "Invalid JSON syntax"
fi

ok "JSON syntax valid"

# -----------------------------
# SERVERS FIELD
# -----------------------------
step "Checking servers field"

if ! jq -e '.servers' "$CONFIG_FILE" >/dev/null; then
  fail "'servers' field missing"
fi

SERVER_COUNT=$(jq '.servers | length' "$CONFIG_FILE")

if [ "$SERVER_COUNT" -eq 0 ]; then
  fail "No servers defined"
fi

ok "Servers detected ($SERVER_COUNT nodes)"

# -----------------------------
# MASTER CHECK
# -----------------------------
step "Checking master node"

MASTER_COUNT=$(jq '[.servers[] | select(.name=="master")] | length' "$CONFIG_FILE")

if [ "$MASTER_COUNT" -eq 0 ]; then
  fail "No master node defined"
fi

if [ "$MASTER_COUNT" -gt 1 ]; then
  fail "Multiple master nodes defined"
fi

ok "Exactly one master node defined"

# -----------------------------
# NODE VALIDATION
# -----------------------------
step "Validating nodes"

declare -A NAMES
declare -A IPS

ERROR=0

while read -r server
do
  NAME=$(echo "$server" | jq -r '.name')
  IP=$(echo "$server" | jq -r '.ip')
  PASSWORD=$(echo "$server" | jq -r '.password')

  # REQUIRED
  if [ -z "$NAME" ] || [ "$NAME" = "null" ]; then
    echo "[ERROR] server without name"
    ERROR=1
  fi

  if [ -z "$IP" ] || [ "$IP" = "null" ]; then
    echo "[ERROR] $NAME has no IP"
    ERROR=1
  fi

  if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
    echo "[ERROR] $NAME has no password"
    ERROR=1
  fi

  # DUPLICATES
  if [[ -n "${NAMES[$NAME]}" ]]; then
    echo "[ERROR] Duplicate server name: $NAME"
    ERROR=1
  fi

  if [[ -n "${IPS[$IP]}" ]]; then
    echo "[ERROR] Duplicate IP address: $IP"
    ERROR=1
  fi

  NAMES[$NAME]=1
  IPS[$IP]=1

  # IP FORMAT
  if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "[ERROR] Invalid IP format: $IP"
    ERROR=1
  fi

  # IP RANGE
  for OCTET in $(echo $IP | tr "." " "); do
    if [ "$OCTET" -gt 255 ]; then
      echo "[ERROR] Invalid IP (out of range): $IP"
      ERROR=1
    fi
  done

done < <(jq -c '.servers[]' "$CONFIG_FILE")

# -----------------------------
# FINAL VALIDATION
# -----------------------------
if [ "$ERROR" -eq 1 ]; then
  echo ""
  fail "Configuration validation failed"
fi

ok "All nodes validated"

# -----------------------------
# DISPLAY PLAN (🔥 Terraform-like)
# -----------------------------
echo ""
echo -e "${CYAN}================= CLUSTER PLAN =================${NC}"
echo ""

printf "%-12s %-16s %-10s\n" "NAME" "IP" "ROLE"
echo "----------------------------------------------"

MASTER_IP=$(jq -r '.servers[] | select(.name=="master") | .ip' "$CONFIG_FILE")

printf "%-12s %-16s %-10s\n" \
  "$(echo -e "${GREEN}master${NC}")" \
  "$MASTER_IP" \
  "$(echo -e "${BLUE}MASTER${NC}")"

echo ""
echo "WORKERS:"
echo "----------------------------------------------"

WORKER_COUNT=0

while read -r server
do
  NAME=$(echo "$server" | jq -r '.name')
  IP=$(echo "$server" | jq -r '.ip')

  if [ "$NAME" != "master" ]; then
    printf "%-12s %-16s %-10s\n" \
      "$(echo -e "${GREEN}$NAME${NC}")" \
      "$IP" \
      "$(echo -e "${YELLOW}WORKER${NC}")"

    WORKER_COUNT=$((WORKER_COUNT+1))
  fi

done < <(jq -c '.servers[]' "$CONFIG_FILE")

echo ""
echo -e "${CYAN}===============================================${NC}"
echo -e "TOTAL: 1 master / $WORKER_COUNT workers"
echo -e "${CYAN}===============================================${NC}"
echo ""