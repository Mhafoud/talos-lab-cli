#!/bin/bash

set -e

# 🔥 PATH SAFE
CONFIG_FILE="$PWD/config/servers.json"

echo ""
echo "================================="
echo "Validating servers.json"
echo "================================="
echo ""

# ------------------------------------------------
# vérifier fichier
# ------------------------------------------------

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] servers.json not found at $CONFIG_FILE"
    exit 1
fi

echo "[OK] Configuration file found"

# ------------------------------------------------
# vérifier JSON syntax
# ------------------------------------------------

if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo "[ERROR] Invalid JSON syntax"
    exit 1
fi

echo "[OK] JSON syntax valid"

# ------------------------------------------------
# vérifier servers
# ------------------------------------------------

if ! jq -e '.servers' "$CONFIG_FILE" >/dev/null; then
    echo "[ERROR] 'servers' field missing"
    exit 1
fi

SERVER_COUNT=$(jq '.servers | length' "$CONFIG_FILE")

if [ "$SERVER_COUNT" -eq 0 ]; then
    echo "[ERROR] No servers defined"
    exit 1
fi

echo "[OK] Servers list detected ($SERVER_COUNT nodes)"

# ------------------------------------------------
# vérifier master
# ------------------------------------------------

MASTER_COUNT=$(jq '[.servers[] | select(.name=="master")] | length' "$CONFIG_FILE")

if [ "$MASTER_COUNT" -eq 0 ]; then
    echo "[ERROR] No master node defined"
    exit 1
fi

if [ "$MASTER_COUNT" -gt 1 ]; then
    echo "[ERROR] Multiple master nodes defined"
    exit 1
fi

echo "[OK] Exactly one master node defined"

# ------------------------------------------------
# validation nodes
# ------------------------------------------------

declare -A NAMES
declare -A IPS

ERROR=0

echo ""
echo "Checking servers..."
echo ""

while read -r server
do
    NAME=$(echo "$server" | jq -r '.name')
    IP=$(echo "$server" | jq -r '.ip')
    PASSWORD=$(echo "$server" | jq -r '.password')

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

    if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "[ERROR] Invalid IP format: $IP"
        ERROR=1
    fi

done < <(jq -c '.servers[]' "$CONFIG_FILE")

if [ "$ERROR" -eq 1 ]; then
    echo ""
    echo "[ERROR] Configuration validation failed"
    exit 1
fi

echo ""
echo "[SUCCESS] servers.json is valid"
echo ""