# Talos Lab CLI

A CLI tool to create, manage, and destroy a Talos Kubernetes cluster on remote servers.

---

## Overview

Talos Lab CLI allows you to:

* Create a Kubernetes cluster using Talos
* Bootstrap the control plane automatically
* Join worker nodes
* Install Cilium networking
* Check cluster status
* Destroy the cluster cleanly

The tool combines a Go-based CLI with Bash automation scripts.

---

## Current State

The project is now functional and usable:

* CLI commands are working (create, validate, status, destroy)
* Cluster creation is automated end-to-end
* Worker join logic is stable
* Installation script available via curl
* Supports password-based SSH
* Initial support for SSH key authentication added

---

## Prerequisites

Before installing the CLI, the following tools must already be installed:

* Linux (Ubuntu/Debian recommended)
* kubectl
* talosctl
* jq
* yq
* helm
* sshpass (only if using password authentication)
* git
* go (used to build the CLI)

The install script will verify these dependencies.

---

## Installation

Install the CLI from anywhere:

```bash
curl -sSL https://raw.githubusercontent.com/Mhafoud/talos-lab-cli/main/install.sh | bash
source ~/.bashrc
```

Verify installation:

```bash
talos-lab --help
```

---

## Configuration

The CLI expects the configuration file at:

```bash
~/.talos-lab/config/servers.json
```

Create it:

```bash
mkdir -p ~/.talos-lab/config
nano ~/.talos-lab/config/servers.json
```

### Example (password authentication)

```json
{
  "servers": [
    {
      "name": "master",
      "ip": "IP_MASTER",
      "password": "PASSWORD_MASTER"
    },
    {
      "name": "worker1",
      "ip": "IP_WORKER",
      "password": "PASSWORD_WORKER"
    }
  ]
}
```

### Example (SSH key authentication)

```json

{
  "servers": [
    {
      "name": "master",
      "ip": "IP_MASTER",
      "user": "root"
    },
    {
      "name": "worker1",
      "ip": "IP_WORKER",
      "user": "root"
    }
  ]
}

```

---

## Usage

### Validate configuration

```bash
talos-lab validate config
```

---

### Create cluster

```bash
talos-lab create cluster
```

This process will:

1. Install Talos on nodes
2. Generate Talos configuration
3. Apply control plane configuration
4. Bootstrap Kubernetes
5. Install Cilium
6. Join worker nodes

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

This will:

* Reset all nodes
* Clean SSH known_hosts
* Remove local Talos and kubeconfig files

---

## Project Structure

```
.
├── cmd/                # Go CLI commands
├── bash_cmd/           # High-level orchestration scripts
├── scripts/            # Low-level infrastructure scripts
├── config/             # Example configuration files
├── install.sh          # CLI installer
├── main.go             # CLI entrypoint
```

---

## How It Works

```
CLI (Go)
   ↓
Bash orchestration
   ↓
Talos + Kubernetes
```

---

## Known Limitations

* Networking configuration is currently hardcoded and may not work on all providers
* No automatic detection of cloud-specific networking (Hetzner, AWS, etc.)
* No interactive configuration generation yet
* Requires manual dependency installation

---

## Roadmap

Planned improvements:

* Add `talos-lab init` command to generate configuration automatically
* Improve SSH support (full SSH key + user handling across all scripts)
* Remove dependency on Go (prebuilt binary distribution)
* Replace Bash scripts with full Go implementation
* Add support for multiple cloud providers
* Add cluster scaling command
* Improve error handling and user feedback

---

## Security Notes

* Never commit real credentials to the repository
* Use `servers.example.json` for sharing configuration templates
* Always rotate credentials if exposed

---

## License

MIT License

---

## Author

Issam