# Starting n8n with Cloudflare Tunnel

## Overview
This guide helps you set up n8n using a Cloudflare Tunnel for secure remote access.

## Prerequisites
- [Cloudflared CLI](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Quick Start

1. **Run setup directly via curl:**

```bash
# Run full setup including glue code
curl -fsSL https://raw.githubusercontent.com/vinitngr/n8n-tunnel/refs/heads/main/scripts/setup.sh | bash

# OR run setup without glue runN8N generation
curl -fsSL https://raw.githubusercontent.com/vinitngr/n8n-tunnel/refs/heads/main/scripts/setup.sh | bash -s -- --noglue
```
or
```bash
curl -fsSL -o setup.sh https://raw.githubusercontent.com/vinitngr/n8n-tunnel/refs/heads/main/scripts/setup.sh
chmod +x setup.sh

./setup.sh # or
./setup.sh --noglue
```

## Configuration Notes
- Falls back to HTTP/2 if QUIC protocol fails
- Works on both MinGW and WSL Linux environments

## WSL Integration
If you encounter this error:
```
$ docker info
The command 'docker' could not be found in this WSL 2 distro.
```

Enable WSL integration in Docker Desktop settings:
1. Open Docker Desktop
2. Go to Settings > Resources > WSL Integration
3. Enable integration for your distro

For more information, visit: https://docs.docker.com/go/wsl2/

## Setup Instructions
setup.md => [setup guide](docs/setup.md).

## also a way ( ⚠️ deprecated)
- step 1: [setup guide](docs/setup.md). create tunnel , DNS record and all
- step 2: 
```bash
# download and run 
curl -fsSL -o runn8n.sh https://raw.githubusercontent.com/vinitngr/n8n-tunnel/main/scripts/runn8n.sh

#change the variables
#grant executable permission

chmod +x runn8n.sh

./runn8n.sh
```

**Note**: The `runn8n.sh` script uses specific configurations. You may need to modify variables to match your setup before running it.
``` bash 
curl -fsSL https://raw.githubusercontent.com/vinitngr/n8n-tunnel/main/scripts/runn8n.sh | bash
```
