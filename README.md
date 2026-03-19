# Talos Lab CLI – README

## 🚀 Overview

**Talos Lab CLI** is a lightweight tool that allows you to **bootstrap, manage, and destroy a Talos Kubernetes cluster** using a simple JSON configuration file.

The goal is to provide a **developer-friendly alternative** to complex Talos workflows.

---

## ⚡ Features

* ✅ Create a full Talos Kubernetes cluster
* ✅ Automatically install Talos on all nodes
* ✅ Bootstrap control plane
* ✅ Install Cilium CNI
* ✅ Join worker nodes automatically
* ✅ Validate configuration
* ✅ View cluster status
* ✅ Destroy cluster via Talos API

---

## 📁 Project Structure

```
project-root
│
├─ kubeconfig
├─ talos-config/
│
├─ talos_lab_cli
│   │
│   ├─ talos-lab
│   │
│   ├─ config
│   │   └─ servers.json
│   │
│   ├─ cmd
│   └─ scripts
```

---

## ⚙️ Prerequisites

Make sure you have installed:

* talosctl
* kubectl
* jq
* yq
* sshpass
* helm

---

## 🧾 Configuration

Create your configuration file:

```
talos_lab_cli/config/servers.json
```

### Example

```json
{
  "servers": [
    {
      "name": "master",
      "ip": "X.X.X.X",
      "password": "password"
    },
    {
      "name": "worker1",
      "ip": "X.X.X.X",
      "password": "password"
    },
    {
      "name": "worker2",
      "ip": "X.X.X.X",
      "password": "password"
    }
  ]
}
```

---

## 🔍 Validate Configuration

```bash
./talos_lab_cli/talos-lab validate config
```

Checks:

* JSON syntax
* required fields
* duplicate IPs / names
* valid structure

---

## 🚀 Create Cluster

```bash
./talos_lab_cli/talos-lab create cluster
```

This will:

1. Install Talos on all nodes
2. Configure control plane
3. Bootstrap Kubernetes
4. Install Cilium
5. Join all workers

---

## 📊 Check Cluster Status

```bash
./talos_lab_cli/talos-lab status
```

Displays:

* Nodes
* kube-system pods

---

## 💥 Destroy Cluster

```bash
./talos_lab_cli/talos-lab destroy cluster
```

### What it does

* Reset all nodes via Talos API
* Remove Kubernetes data
* Delete local files:

  * kubeconfig
  * talos-config/

⚠️ Servers are NOT deleted (only reset)

---

## 🔐 Important Notes

### Talos Modes

| Mode        | Description      |
| ----------- | ---------------- |
| Maintenance | uses --insecure  |
| Secure TLS  | uses talosconfig |

---

### Common Errors

#### TLS error

```
tls: certificate required
```

👉 Node already configured → use talosconfig

---

#### Talos API not ready

```
Talos API not ready yet...
```

👉 Fix:

```bash
export TALOSCONFIG=./talos-config/talosconfig
```

---

## 🧠 How It Works

Cluster lifecycle:

```
Install → Configure → Bootstrap → Join → Ready
```

Destroy:

```
talosctl reset → node wiped → reboot
```

---

## 🧪 Example Result

```bash
kubectl get nodes
```

```
master-node     Ready
worker-node-1   Ready
worker-node-2   Ready
worker-node-3   Ready
```

---

## 🛠️ Available Commands

```bash
./talos_lab_cli/talos-lab create cluster
./talos_lab_cli/talos-lab status
./talos_lab_cli/talos-lab validate config
./talos_lab_cli/talos-lab destroy cluster
```

---

## 🔮 Next Step

This version is **bash-based CLI**.

Next step:

👉 Build a **Go CLI binary** for easier installation and better UX

---

## 🏁 Status

| Feature        | Status |
| -------------- | ------ |
| Cluster create | ✅      |
| Workers join   | ✅      |
| Validation     | ✅      |
| Status         | ✅      |
| Destroy        | ✅      |
| CLI (bash)     | ✅      |

---

🔥 You now have a fully working Talos cluster automation CLI
