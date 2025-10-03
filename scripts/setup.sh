#!/bin/bash

set -e

echo "==============setup started=================="

SCRIPT_DIR="$(pwd)"

install_cloudflared_if_missing() {
  if ! command -v cloudflared &> /dev/null; then
    echo "cloudflared not found. Installing..."
    TMP_BIN="$(mktemp)"
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" -o "$TMP_BIN"
    chmod +x "$TMP_BIN"
    if mv "$TMP_BIN" /usr/local/bin/cloudflared 2>/dev/null; then
      echo "Installed to /usr/local/bin/cloudflared"
    else
      echo "Installing to $SCRIPT_DIR/cloudflared (no sudo)" 
      mv "$TMP_BIN" "$SCRIPT_DIR/cloudflared"
      chmod +x "$SCRIPT_DIR/cloudflared"
      export PATH="$SCRIPT_DIR:$PATH"
      echo "Added $SCRIPT_DIR to PATH for this session."
    fi
  fi
}

ensure_logged_in() {
  CRED_FILE="$HOME/.cloudflared/cert.pem"
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "Please login interactively with cloudflared:"
    cloudflared login || { echo "Login failed ❌"; exit 1; }
    echo "Login successful ✅ ($CRED_FILE)"
  else
    echo "cloudflared already logged in ✅ ($CRED_FILE)"
  fi
}

create_tunnel() {
  read -r -p "Enter the subdomain you want to use (default: n8n): " SUBDOMAIN
  SUBDOMAIN=${SUBDOMAIN:-n8n}

  while true; do
  read -r -p "Enter your domain: " DOMAIN
    if [[ -n "$DOMAIN" ]]; then
      break
    else
      echo "Error: Domain is required. Please enter a value."
    fi
  done
  
  read -r -p "Enter local service port (default: 5678): " LOCAL_PORT
  LOCAL_PORT=${LOCAL_PORT:-5678}

  FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
  TUNNEL_NAME="${SUBDOMAIN}_tunnel"

  echo "Creating tunnel $TUNNEL_NAME..."
  TUNNEL_OUTPUT="$(cloudflared tunnel create "$TUNNEL_NAME" 2>&1)"
  echo "$TUNNEL_OUTPUT"

  CREDS_FILE="$(
    printf '%s\n' "$TUNNEL_OUTPUT" \
    | sed -n 's/.*Tunnel credentials written to \(.*\.json\)\..*/\1/p'
  )"

  TUNNEL_ID="$(
    printf '%s\n' "$TUNNEL_OUTPUT" \
    | sed -n 's/.*with id \([a-f0-9-]\{36\}\).*/\1/p; s/.*id: \([a-f0-9-]\{36\}\).*/\1/p' \
    | head -n1
  )"

  if [[ -z "$CREDS_FILE" && -n "$TUNNEL_ID" ]]; then
    CREDS_FILE="$HOME/.cloudflared/$TUNNEL_ID.json"
  fi

  if [[ -z "$TUNNEL_ID" ]]; then
    echo "Could not parse tunnel ID. Aborting."
    exit 1
  fi

  echo "Tunnel ID: $TUNNEL_ID"
  echo "Credentials file: $CREDS_FILE"

  echo "Routing DNS for $FULL_DOMAIN..."
  if ! cloudflared tunnel route dns "$TUNNEL_NAME" "$FULL_DOMAIN"; then
    echo "DNS routing failed. Make sure the domain is in Cloudflare and your account has permissions."
  fi

  CREDS_DIR="$(dirname "$CREDS_FILE")"
  mkdir -p "$CREDS_DIR" 2>/dev/null || mkdir -p "$HOME/.cloudflared"
  CONFIG_PATH="$CREDS_DIR/${TUNNEL_NAME}_config.yml"

  echo "Generating config.yml at $CONFIG_PATH..."
  cat > "$CONFIG_PATH" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDS_FILE

ingress:
  - hostname: $FULL_DOMAIN
    service: http://localhost:$LOCAL_PORT
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF

  echo "Tunnel setup complete!"
  echo "Config: $CONFIG_PATH"
}

creatingRunN8n(){
  mkdir -p "$HOME/.cloudflared"
  TARGET="$HOME/.cloudflared/runN8N.sh"
 
  cat > "$TARGET" << EOF
#!/bin/bash

set -e

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "==== Docker not found. Install with:"
        echo "  sudo apt update && sudo apt install -y docker.io"
        echo "  sudo systemctl enable --now docker"
        echo "  sudo usermod -aG docker \$USER  # log out/in afterwards"
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
    if [ \$? -ne 0 ]; then
        echo "Docker not running, starting Docker Desktop..."
        nohup "\$DOCKER_DESKTOP" >/dev/null 2>&1 &
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
          -e N8N_HOST="$FULL_DOMAIN" \
          --name n8n n8nio/n8n
    else
        echo "n8n container already exists, starting..."
        docker start n8n >/dev/null
    fi


    docker logs -f n8n 2>/dev/null | awk -v prefix="===== DOCKER ===== " -v max=90 \
    '{ line = \$0; if (length(line) > max) { line = substr(line,1,max) " ..." } print prefix line }' &
    docker_pid=\$!

   echo "Waiting for n8n to be ready..."
    until curl -s -o /dev/null http://localhost:5678/; do
        sleep 2
    done
    echo "n8n is ready."
}


start_cloudflared_tunnel() {
    cloudflared tunnel --config "$CONFIG_PATH" run "$TUNNEL_NAME" 2>&1 | \
    awk -v prefix="----- TUNNEL ----- " -v max=80 \
    '{ line = $0; if (length(line) > max) { line = substr(line,1,max) " ..." } print prefix line }' &
    tunnel_pid=$!
}

wait_for_tunnel() {
    local ready=false
    for i in {1..20}; do
        if curl -s -o /dev/null -w "%{http_code}" https://$FULL_DOMAIN | grep -q "200"; then
            echo "╭───────────────────────────────────────────────╮"
            echo "│                                               │"
            echo "│        Your n8n instance is ready at:         │"
            echo "│         https://$FULL_DOMAIN                  │"
            echo "│                                               │"
            echo "╰───────────────────────────────────────────────╯"

            ready=true
            break
        fi
        sleep 1
    done

    if [ "\$ready" = false ]; then
        echo "QUIC not working, falling back to HTTP2 protocol"
        kill \$tunnel_pid 2>/dev/null
        cloudflared tunnel run --config "$CONFIG_PATH" --protocol http2 "$TUNNEL_NAME" 2>&1 | sed 's/^/----- TUNNEL ----- /' &
        tunnel_pid=\$!
    fi
}


cleanup() {
    echo "Exiting script..."
    kill \$docker_pid 2>/dev/null
    echo "Stopping tunnel... $tunnel_pid" 
    kill \$tunnel_pid 2>/dev/null
    echo "Stopping n8n container... "
    docker stop n8n >/dev/null 2>&1
    exit 0
}

# ------------Main Script------------------
check_docker
start_n8n_container
start_cloudflared_tunnel
wait_for_tunnel

trap cleanup SIGINT SIGTERM
# -----------------------------------------

while true; do
    read -r cmd
    if [[ "\$cmd" == "exit" ]]; then
        cleanup
    fi
done
EOF

  chmod +x "$TARGET"
  echo "Created $TARGET (executable)."
}

debug_variables() {
  echo "===== DEBUG VARIABLES ====="
  echo "SCRIPT_DIR: $SCRIPT_DIR"
  echo "SUBDOMAIN: $SUBDOMAIN"
  echo "DOMAIN: $DOMAIN"
  echo "FULL_DOMAIN: $FULL_DOMAIN"
  echo "LOCAL_PORT: $LOCAL_PORT"
  echo "TUNNEL_NAME: $TUNNEL_NAME"
  echo "TUNNEL_ID: $TUNNEL_ID"
  echo "CREDS_FILE: $CREDS_FILE"
  echo "CONFIG_PATH: $CONFIG_PATH"
  echo "TARGET: $TARGET"
  echo "==========================="
}

skip_glue=false
for arg in "$@"; do
    if [[ "$arg" == "--noglue" ]]; then
        skip_glue=true
        break
    fi
done

install_cloudflared_if_missing
ensure_logged_in
create_tunnel
if $skip_glue; then
    echo "Skipping creatingRunN8n"
else
    creatingRunN8n
fi
debug_variables

echo "==============setup completed=================="
echo "Setup complete ✅. Run './$TARGET' to start n8n with the tunnel."
