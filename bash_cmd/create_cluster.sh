#!/bin/bash

set -e

# -----------------------------
# CHECK ENV
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

echo ""
echo "================================="
echo "Talos Lab - Creating full cluster"
echo "================================="
echo ""

echo "STEP 1 - Creating master node"
bash "$TALOS_LAB_HOME/bash_cmd/create_master.sh"

echo ""
echo "STEP 2 - Joining all workers"
bash "$TALOS_LAB_HOME/scripts/7_join_all_workers.sh"

echo ""
echo "================================="
echo "Cluster successfully created!"
echo "================================="