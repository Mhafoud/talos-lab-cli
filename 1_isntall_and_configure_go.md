# 🚀 Talos Lab CLI

> A lightweight CLI to bootstrap and manage Talos Kubernetes clusters using a simple JSON configuration.

---

# 📌 Overview

**Talos Lab CLI** is a developer-friendly tool that allows you to:

* 🚀 Bootstrap a full Talos Kubernetes cluster
* ⚡ Use a simple JSON inventory (no Terraform required)
* 🔁 Re-run safely (idempotent)
* 🔍 Validate configuration
* 📊 Check cluster status
* 💣 Destroy cluster cleanly

Inspired by tools like:

* k3sup
* talhelper
* clusterctl

---

# 🎯 Goal

Simplify Talos cluster creation to a single command:

```bash
talos-lab create cluster
```

Using only:

```json
{
  "servers": [
    { "name": "master", "ip": "X.X.X.X", "password": "password" },
    { "name": "worker1", "ip": "X.X.X.X", "password": "password" },
    { "name": "worker2", "ip": "X.X.X.X", "password": "password" }
  ]
}
```

---

# 🧱 Architecture

## 1. Go CLI (User Interface)

Handles:

* command parsing
* validation trigger
* execution orchestration

```
talos_cli_go/
├── cmd/
├── main.go
```

---

## 2. Bash Automation (Core Logic)

Handles:

* Talos installation
* Kubernetes bootstrap
* Cilium installation
* Worker join
* Cluster destroy

```
talos_lab_cli/
├── cmd/
├── scripts/
```

---

# 📂 Project Structure

```
talos_lab_cli/
├── config/
│   └── servers.json
│
├── cmd/
│   ├── create_cluster.sh
│   ├── create_master.sh
│   ├── destroy_cluster.sh
│   ├── status.sh
│   └── validate_config.sh
│
├── scripts/
│   ├── 1_install_talos.sh
│   ├── 2_generate_config.sh
│   ├── 3_apply_controlplane.sh
│   ├── 4_bootstrap_cluster.sh
│   ├── 5_install_cilium.sh
│   ├── 6_join_worker.sh
│   └── 7_join_all_workers.sh
│
└── talos_cli_go/
    ├── cmd/
    ├── main.go
    └── go.mod
```

---

# ⚙️ Installation

## 1. Install Go

```bash
sudo apt update
sudo apt install -y golang-go
```

Verify installation:

```bash
go version
```

---

## 2. Configure PATH

```bash
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## 3. Install Cobra

```bash
go install github.com/spf13/cobra-cli@latest
```

---

# 🚀 Usage

## ▶️ Create Full Cluster

```bash
go run main.go create cluster
```

What happens:

1. Validate config
2. Install Talos on master
3. Bootstrap Kubernetes
4. Install Cilium
5. Join all workers

---

## 🧠 Create Master Only

```bash
go run main.go create master
```

---

## 🔍 Validate Configuration

```bash
go run main.go validate config
```

Checks:

* JSON syntax
* required fields
* duplicate IPs
* duplicate names
* master presence

---

## 📊 Cluster Status

```bash
go run main.go status
```

Displays:

* nodes
* kube-system pods

---

## 💣 Destroy Cluster

```bash
go run main.go destroy
```

What it does:

1. Uses `talosctl reset` on all nodes
2. Reboots machines
3. Removes:

   * kubeconfig
   * talos-config
4. Cleans SSH known_hosts

---

# 🔄 Execution Flow

```text
talos-lab create cluster
 → validate_config.sh
 → create_cluster.sh
   → create_master.sh
   → install Talos
   → bootstrap cluster
   → install Cilium
   → join workers
```

---

# ✅ Expected Result

```bash
kubectl get nodes --kubeconfig ./kubeconfig
```

```
master-node     Ready
worker-node-1   Ready
worker-node-2   Ready
worker-node-3   Ready
```

---

# 🧠 Key Features

### ✔ Idempotent

* Skips existing master
* Skips already joined workers

---

### ✔ Minimal Config

* Single `servers.json`

---

### ✔ Full Lifecycle

```
Create → Validate → Status → Destroy
```

---

### ✔ No Terraform Required

---

# ⚠️ Known Behaviors

### Worker temporarily NotReady

Normal during startup.

---

### Talos version mismatch

```bash
WARNING: server version older than client
```

Safe to ignore.

---

### Cilium Pending pods (single node)

Expected behavior.

---

# 🧪 Troubleshooting

## Kill stuck processes

```bash
pkill -9 -f create_cluster
pkill -9 -f talos
pkill -9 -f ssh
```

---

## Talos API not ready

```bash
export TALOSCONFIG=./talos-config/talosconfig
```

---

# 🛠️ Development Notes

## CLI → Bash Integration

Example:

```go
exec.Command("bash", "../cmd/create_cluster.sh")
```

---

## Dynamic Paths (IMPORTANT)

Always use:

```bash
$PWD/kubeconfig
$PWD/talos-config
```

---

# 🔥 Current Status

| Feature          | Status |
| ---------------- | ------ |
| Cluster creation | ✅      |
| Worker join      | ✅      |
| Validation       | ✅      |
| Status           | ✅      |
| Destroy          | ✅      |
| Go CLI           | ✅      |

---

# 🚀 Roadmap

## Short Term

* Better logs ([INFO], [ERROR])
* `--yes` flag
* Retry logic

---

## Medium Term

* Parallel worker provisioning
* Signal handling (Ctrl+C)
* Config flags

---

## Long Term

* Full Go implementation (remove Bash)
* Binary distribution
* Multi-cluster support

---

# 💡 Vision

Provide a simple developer experience:

```bash
talos-lab create cluster
```

→ and get a production-ready Kubernetes cluster in minutes.

---

# ⭐ Final Note

This tool is already:

```
✔ functional
✔ reliable
✔ extensible
✔ production-capable (lab environments)
```
