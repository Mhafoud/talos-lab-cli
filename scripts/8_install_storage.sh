#!/bin/bash

set -e

# -----------------------------
# KUBECONFIG (CRITIQUE)
# -----------------------------
if [ -z "$TALOS_LAB_HOME" ]; then
  echo "[ERROR] TALOS_LAB_HOME is not set"
  exit 1
fi

export KUBECONFIG="$TALOS_LAB_HOME/kubeconfig"

echo "[INFO] Using kubeconfig: $KUBECONFIG"

# -----------------------------
# COLORS
# -----------------------------
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}Checking existing local-path installation...${NC}"

if kubectl get ns local-path-storage >/dev/null 2>&1; then
  echo -e "${YELLOW}Existing installation detected. Cleaning...${NC}"

  kubectl delete pod test-pod --ignore-not-found
  kubectl delete pvc test-pvc --ignore-not-found

  kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml || true
  kubectl delete ns local-path-storage --ignore-not-found

  echo -e "${GREEN}Cleanup done${NC}"
fi

echo -e "${BLUE}Installing local-path provisioner...${NC}"

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

echo -e "${BLUE}Waiting for namespace...${NC}"
sleep 5

echo -e "${BLUE}Configuring PodSecurity...${NC}"

kubectl label namespace local-path-storage \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged \
  --overwrite

echo -e "${BLUE}Patching config for Talos...${NC}"

kubectl patch configmap local-path-config -n local-path-storage \
  --type merge \
  -p '{"data":{"config.json":"{\"nodePathMap\":[{\"node\":\"DEFAULT_PATH_FOR_NON_LISTED_NODES\",\"paths\":[\"/var/local-path-provisioner\"]}]}"}}'

echo -e "${BLUE}Restarting provisioner...${NC}"

kubectl rollout restart deployment local-path-provisioner -n local-path-storage

echo -e "${BLUE}Waiting for provisioner...${NC}"

kubectl rollout status deployment/local-path-provisioner -n local-path-storage --timeout=120s

echo -e "${BLUE}Verifying provisioner is running...${NC}"

if ! kubectl get pods -n local-path-storage | grep -q "local-path-provisioner.*Running"; then
  echo -e "${RED}ERROR: local-path provisioner is not running${NC}"
  kubectl get pods -n local-path-storage
  exit 1
fi

echo -e "${GREEN}Provisioner is running${NC}"

echo -e "${BLUE}Setting storageclass as default...${NC}"

kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

echo -e "${BLUE}Running storage test...${NC}"

# -----------------------------
# CREATE PVC
# -----------------------------
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  storageClassName: local-path
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# -----------------------------
# CREATE POD
# -----------------------------
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
    - name: app
      image: nginx
      volumeMounts:
        - mountPath: "/data"
          name: storage
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: test-pvc
EOF

echo -e "${BLUE}Waiting for pod to be Running...${NC}"

kubectl wait --for=condition=Ready pod/test-pod --timeout=120s

# -----------------------------
# VALIDATION
# -----------------------------
PVC_STATUS=$(kubectl get pvc test-pvc -o jsonpath='{.status.phase}')
POD_STATUS=$(kubectl get pod test-pod -o jsonpath='{.status.phase}')

echo ""
echo "Validation:"

if [ "$PVC_STATUS" == "Bound" ]; then
  echo -e "${GREEN}PVC is Bound${NC}"
else
  echo -e "${RED}PVC is NOT Bound${NC}"
  exit 1
fi

if [ "$POD_STATUS" == "Running" ]; then
  echo -e "${GREEN}Pod is Running${NC}"
else
  echo -e "${RED}Pod is NOT Running${NC}"
  exit 1
fi

echo -e "${GREEN}Storage test successful${NC}"

# -----------------------------
# CLEAN TEST
# -----------------------------
echo -e "${YELLOW}Cleaning test resources...${NC}"

kubectl delete pod test-pod --ignore-not-found
kubectl delete pvc test-pvc --ignore-not-found

echo -e "${BLUE}Final cluster storage status:${NC}"

kubectl get storageclass
kubectl get pods -n local-path-storage

echo -e "${GREEN}Storage installation completed${NC}"