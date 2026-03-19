#!/bin/bash

set -e

echo ""
echo "================================="
echo "Talos Lab - Creating full cluster"
echo "================================="
echo ""

echo "STEP 1 - Creating master node"
bash "$PWD/bash_cmd/create_master.sh"

echo ""
echo "STEP 2 - Joining all workers"
bash "$PWD/scripts/7_join_all_workers.sh"

echo ""
echo "================================="
echo "Cluster successfully created!"
echo "================================="