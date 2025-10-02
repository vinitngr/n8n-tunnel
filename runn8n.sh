#!/bin/bash

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "==== Docker not found. Install with:"
        echo "  sudo apt update && sudo apt install -y docker.io"
        echo "  sudo systemctl enable --now docker"
        echo "  sudo usermod -aG docker \$USER  # log out/in afterwards"
        echo "See official docs: https://docs.docker.com/engine/install/linux-postinstall/"
        exit 1
    fi
}

check_cloudflared() {
    if ! command -v cloudflared &> /dev/null; then
        echo "cloudflared not found."
        echo "===Linux:===="
        echo "     wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
        echo "     sudo dpkg -i cloudflared-linux-amd64.deb"
        echo "===MacOs:===="
        echo "     brew install cloudflared"
        echo "====Windows:===="
        echo "     winget install --id Cloudflare.cloudflared"
        echo "Full docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
        exit 1
    fi
}

if uname | grep -iq "linux"; then
    echo "running on WSL | Linux"
    DOCKER_DESKTOP="/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe"
else
    echo "running on Window | MinGW"
    DOCKER_DESKTOP="C:/Program Files/Docker/Docker/Docker Desktop.exe"
fi

start_docker_if_needed() {
    docker info >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Docker not running, starting Docker Desktop..."
        nohup "$DOCKER_DESKTOP" >/dev/null 2>&1 &
        echo "Waiting for Docker daemon..."
        while ! docker info >/dev/null 2>&1; do
            sleep 2
        done
        echo "Docker is ready."
    fi
}

start_n8n_container() {
    start_docker_if_needed

    if ! docker ps -a --format "{{.Names}}" | grep -wq "n8n"; then
        echo "Running n8n container..."
        docker run -d -p 5678:5678 \
          -v n8n_data:/home/node/.n8n \
          -e N8N_TRUST_PROXY="true" \
          -e N8N_HOST="n8n.vinitngr.xyz" \
          --name n8n n8nio/n8n
    else
        echo "n8n container already exists, starting..."
        docker start n8n >/dev/null
    fi


    docker logs -f n8n 2>/dev/null | awk -v prefix="===== DOCKER ===== " -v max=90 \
    '{ line = $0; if (length(line) > max) { line = substr(line,1,max) " ..." } print prefix line }' &
    docker_pid=$!

   echo "Waiting for n8n to be ready..."
    until curl -s -o /dev/null http://localhost:5678/; do
        sleep 2
    done
    echo "n8n is ready."
}

start_cloudflared_tunnel() {
    cloudflared tunnel run n8n-tunnel 2>&1 | awk -v prefix="----- TUNNEL ----- " -v max=80 \
    '{ line = $0; if (length(line) > max) { line = substr(line,1,max) " ...=" } print prefix line }' &
    tunnel_pid=$!
}

wait_for_tunnel() {
    local ready=false
    for i in {1..20}; do
        if curl -s -o /dev/null -w "%{http_code}" https://n8n.vinitngr.xyz | grep -q "200"; then
            echo "
/-------------------------------\\
|                               |
|   https://n8n.vinitngr.xyz    |
|                               |
\\-------------------------------/"
            ready=true
            break
        fi
        echo " -------------------------- Waiting for tunnel to be ready... $i/20 --------------------------"
        sleep 1
    done

    if [ "$ready" = false ]; then
        echo "QUIC not working, falling back to HTTP2 protocol"
        kill $tunnel_pid 2>/dev/null
        cloudflared tunnel run --protocol http2 n8n-tunnel 2>&1 | sed 's/^/----- TUNNEL ----- /' &
        tunnel_pid=$!
    fi
}

cleanup() {
    echo "Exiting script..."
    kill $docker_pid 2>/dev/null
    echo "Stopping tunnel... $tunnel_pid" 
    kill $tunnel_pid 2>/dev/null
    echo "Stopping n8n container... "
    docker stop n8n >/dev/null 2>&1
    exit 0
}

# ------------Main Script------------------
check_docker
check_cloudflared
start_n8n_container
start_cloudflared_tunnel
wait_for_tunnel

trap cleanup SIGINT SIGTERM
# -----------------------------------------

while true; do
    read -r cmd
    if [[ "$cmd" == "exit" ]]; then
        cleanup
    fi
done
