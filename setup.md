# ☁️ Cloudflare Tunnel Setup for n8n 🐙

This guide outlines the steps to set up a **Cloudflare Tunnel** for an **n8n** instance running in **Docker**, providing a stable and secure public URL for your webhooks.

---

## 🐋 Docker Setup

First, let's get n8n running in a Docker container.

1.  **Pull the n8n Docker image**:
    `docker pull n8nio/n8n`

2.  **Create and run the n8n container**:
    `docker run -it --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n`

3.  **Manage the container**:
    -   **Stop**: `docker stop n8n`
    -   **Start**: `docker start -ai n8n`

    Now, n8n is running and accessible on `http://localhost:5678`. and later on `https://subdomain.domain.com`

---

## ⚡ Cloudflare Tunnel Configuration

To expose your local n8n instance to the internet with a consistent URL, we'll use a Cloudflare Tunnel.

1.  **Install `cloudflared`**:
windows : 
```bash
winget install --id Cloudflare.cloudflared
```
linux/wsl : 
```bash  
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

2.  **Authenticate `cloudflared`**:
    `cloudflared login` - it will create a `cert.pem`

3.  **Create a Tunnel**:
    `cloudflared tunnel create n8n_tunnel`

4.  **Create the Configuration File**:
    Create a `config.yml` file in your `.cloudflared` directory.

    ```yaml
    # ~/.cloudflared/config.yml

    tunnel: c0a5482a-9a3f-4642-9e62-4ff473312d22 
    credentials-file: /home/vinit/.cloudflared/c0a5482a-9a3f-4642-9e62-4ff473312d22.json 

    ingress:
      - hostname: n8n.vinitngr.xyz
        service: http://localhost:5678
      - service: http_status:404
    ```

5.  **Run the Tunnel**:
    Start the tunnel using the configuration file.
    `cloudflared tunnel run --config ~/.cloudflared/config.yml --protocol (http2 or quic[default]) n8n_tunnel`

    > **Tip**: You can also use the short command `cloudflared tunnel run n8n_tunnel` if the config file is named `config.yml` and is in the default `.cloudflared` directory.

6.  **Add the DNS Record**:
    -   **Type**: `CNAME`
    -   **Name**: `n8n`
    -   **Target**: `<Tunnel_ID>.cfargotunnel.com`
    -   **Proxy status**: `Proxied` (orange cloud)

---

## 🔑 Key Concepts & Other Commands

| Feature | `trycloudflare.com` | `cfargotunnel.com` |
| :--- | :--- | :--- |
| **Purpose** | Temporary public URL for testing | Permanent CNAME target for your domain |
| **Usage** | Quick access, no DNS changes | Used for CNAME records with your custom domain |
| **Lifetime** | Short-lived | Persistent |


* **List all tunnels**:
    `cloudflared tunnel list`

* **Temporary tunnel**:
    `cloudflared tunnel --url http://localhost:5678`
    This provides a temporary URL (e.g., `abcd1234.trycloudflare.com`) for quick testing without a custom domain.