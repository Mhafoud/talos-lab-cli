# 🚀 Talos Lab CLI

A powerful CLI tool to **create, manage and destroy a Talos Kubernetes cluster** automatically on remote servers.

---

## 🎯 Overview

Talos Lab CLI allows you to:

* ✅ Create a full Kubernetes cluster (Talos)
* ✅ Bootstrap control plane automatically
* ✅ Join worker nodes
* ✅ Install Cilium networking
* ✅ Check cluster status
* ✅ Destroy cluster cleanly

Everything is automated via a simple CLI.

---

## ⚙️ Prerequisites

Before using the CLI, make sure you have:

* Linux (Ubuntu/Debian recommended)
* `kubectl`
* `talosctl`
* `jq`
* `yq`
* `helm`
* `sshpass`
* `go` (only for building)

👉 Future versions will install these automatically.

---

## 📦 Installation (Manual)

Clone the repository:

```bash
git clone https://github.com/Mhafoud/talos-lab-cli.git
cd talos-lab-cli
```

Build the CLI:

```bash
go build -o talos-lab
```

Move binary:

```bash
sudo mv talos-lab /usr/local/bin/
```

Set environment variable:

```bash
echo 'export TALOS_LAB_HOME=$(pwd)' >> ~/.bashrc
source ~/.bashrc
```

---

## 🧩 Configuration

Create your cluster configuration:

```bash
cp config/servers.example.json config/servers.json
nano config/servers.json
```

Example:

```json
{
  "servers": [
    {
      "name": "master",
      "ip": "X.X.X.X",
      "password": "root_password"
    },
    {
      "name": "worker1",
      "ip": "X.X.X.X",
      "password": "root_password"
    }
  ]
}
```

---

## 🚀 Usage

### Validate configuration

```bash
talos-lab validate config
```

---

### Create cluster

```bash
talos-lab create cluster
```

This will:

1. Install Talos on nodes
2. Generate configuration
3. Bootstrap Kubernetes
4. Install Cilium
5. Join workers

---

### Check cluster status

```bash
talos-lab status
```

---

### Destroy cluster

```bash
talos-lab destroy
```

---

## 📁 Project Structure

```text
.
├── cmd/                # Go CLI commands
├── bash_cmd/           # High-level orchestration scripts
├── scripts/            # Low-level infrastructure scripts
├── config/             # Cluster configuration
├── main.go             # CLI entrypoint
```

---

## 🧠 How It Works

```text
CLI (Go)
   ↓
Bash orchestration
   ↓
Talos + Kubernetes
```

---

## ⚠️ Notes

* The cluster may take a few minutes to become fully ready
* Workers may appear as `NotReady` temporarily
* Re-running commands is safe (idempotent behavior)

---

## 🧹 Cleanup

Destroy everything:

```bash
talos-lab destroy
```

This will:

* Reset Talos nodes
* Clean SSH known_hosts
* Remove local configs

---

## 🚧 Roadmap

* [ ] Automatic dependency installation
* [ ] Full Go implementation (replace bash)
* [ ] GitHub releases (binary download)
* [ ] Multi-platform support
* [ ] Cluster scaling command

---

## 🤝 Contributing

Feel free to contribute or open issues!

---

## 📄 License

MIT License

---

## 🔥 Author

Built by Issam 🚀