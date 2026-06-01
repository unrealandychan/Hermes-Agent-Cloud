#!/usr/bin/env bash
# bootstrap.sh — Hermes Agent installation and configuration script
#
# Runs over SSH after Terraform provisions the VM.
# Expects the profile .env to already exist (written by the CLI via ssh_upload_env).
# Must be run as root (sudo).
#
# Usage: bootstrap.sh [--user <ssh-user>] [--profile <profile-name>] [--web-port <port>] [--api-port <port>] [--webui-port <port>] [--no-webui]
set -euo pipefail

# ── Version pinning ────────────────────────────────────────────────────────
# Allow override via environment; falls back to "latest"
HERMES_VERSION="${HERMES_AGENT_VERSION:-latest}"

# ── Argument parsing ────────────────────────────────────────────────────────
HERMES_USER="ubuntu"
HERMES_PROFILE="default"
export WEB_PORT="9119"
export API_PORT="8080"
export WEBUI_PORT="8787"
INSTALL_WEBUI="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)       HERMES_USER="$2";    shift 2 ;;
    --profile)    HERMES_PROFILE="$2"; shift 2 ;;
    --web-port)   WEB_PORT="$2";       shift 2 ;;
    --api-port)   API_PORT="$2";       shift 2 ;;
    --webui-port) WEBUI_PORT="$2";     shift 2 ;;
    --no-webui)   INSTALL_WEBUI="false"; shift ;;
    *) shift ;;
  esac
done

# ── Constants ──────────────────────────────────────────────────────────────
# Profiles are stored under ~/.hermes-profiles/<name>/
# The "default" profile keeps .env at ~/.hermes/.env for backward compatibility.
HERMES_PROFILES_ROOT="/home/${HERMES_USER}/.hermes-profiles"
if [[ "$HERMES_PROFILE" == "default" ]]; then
  HERMES_HOME="/home/$HERMES_USER/.hermes"
else
  HERMES_HOME="${HERMES_PROFILES_ROOT}/${HERMES_PROFILE}"
fi
HERMES_ENV="$HERMES_HOME/.env"
HERMES_CONFIG="$HERMES_HOME/config.yaml"
SERVICE_NAME="hermes-${HERMES_PROFILE}"
LOG_FILE="/var/log/hermes-bootstrap-${HERMES_PROFILE}.log"
LOG_TAG="hermes-bootstrap[${HERMES_PROFILE}]"

log()  { echo "[$LOG_TAG] $*" | tee -a "$LOG_FILE"; }
fail() { echo "[$LOG_TAG] ERROR: $*" | tee -a "$LOG_FILE" >&2; exit 1; }

exec > >(tee -a "$LOG_FILE") 2>&1
log "Starting Hermes bootstrap"

[[ -f "$HERMES_ENV" ]] || fail "$HERMES_ENV not found — API keys must be deployed before running bootstrap"

# ── 1. System packages ──────────────────────────────────────────────────────
log "Step 1/5: System packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl jq unzip ca-certificates gnupg lsb-release

# ── 2. Install Docker (Hermes sandbox backend) ───────────────────────────────
log "Step 2/5: Installing Docker"
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | bash
fi
usermod -aG docker "$HERMES_USER"
log "  Docker $(docker --version)"

# ── 3. Install Hermes Agent ───────────────────────────────────────────────────
log "Step 3/5: Installing Hermes Agent (version: ${HERMES_VERSION})"
if [[ "$HERMES_VERSION" == "latest" ]]; then
  sudo -u "$HERMES_USER" bash -c \
    'curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash'
else
  sudo -u "$HERMES_USER" bash -c \
    "curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_VERSION}/scripts/install.sh | bash"
fi

# Locate the hermes binary (installer may put it in ~/.local/bin or /usr/local/bin)
HERMES_BIN=$(sudo -u "$HERMES_USER" bash -c \
  "command -v hermes 2>/dev/null || echo /home/${HERMES_USER}/.local/bin/hermes")
log "  Hermes binary: $HERMES_BIN"

# Write Hermes config
mkdir -p "$HERMES_HOME"
cat > "$HERMES_CONFIG" <<YAML
terminal:
  backend: docker
  container_cpu: 1
  container_memory: 5120
  container_disk: 51200
  container_persistent: true

agent:
  max_turns: 90

compression:
  enabled: true
  threshold: 0.50

display:
  tool_progress: all

web:
  enabled: true
  port: ${WEB_PORT}

webui:
  enabled: true
  port: ${WEBUI_PORT}
  host: 127.0.0.1
  chat_backend: gateway
YAML
chown -R "$HERMES_USER":"$HERMES_USER" "$HERMES_HOME"
log "  Hermes config written to $HERMES_CONFIG"

# ── 4. Install Hermes WebUI ───────────────────────────────────────────────────
log "Step 4/5: Installing Hermes WebUI"
if [[ "$INSTALL_WEBUI" == "true" ]]; then
  WEBUI_DIR="/home/${HERMES_USER}/hermes-webui"
  WEBUI_SERVICE="hermes-webui-${HERMES_PROFILE}"

  if [[ -d "$WEBUI_DIR" ]]; then
    log "  hermes-webui already cloned — pulling latest"
    sudo -u "$HERMES_USER" git -C "$WEBUI_DIR" pull --ff-only origin main || true
  else
    sudo -u "$HERMES_USER" git clone --depth 1 \
      https://github.com/nesquena/hermes-webui.git "$WEBUI_DIR"
  fi

  # Locate the hermes-agent venv (installer puts it in ~/.hermes/venv or ~/.local/share/hermes/venv)
  HERMES_VENV=""
  for candidate in \
      "/home/${HERMES_USER}/.hermes/venv" \
      "/home/${HERMES_USER}/.local/share/hermes/venv"; do
    if [[ -d "$candidate" ]]; then
      HERMES_VENV="$candidate"
      break
    fi
  done

  if [[ -z "$HERMES_VENV" ]]; then
    log "  hermes venv not found — creating standalone venv for webui"
    sudo -u "$HERMES_USER" python3 -m venv "$WEBUI_DIR/.venv"
    HERMES_VENV="$WEBUI_DIR/.venv"
  fi

  # Install WebUI deps from its own requirements.txt
  if [[ -f "$WEBUI_DIR/requirements.txt" ]]; then
    log "  Installing hermes-webui requirements"
    sudo -u "$HERMES_USER" "$HERMES_VENV/bin/pip" install --quiet -r "$WEBUI_DIR/requirements.txt"
  fi

  # Locate hermes-agent dir (the checkout, not the state dir)
  HERMES_AGENT_DIR=$(sudo -u "$HERMES_USER" bash -c \
    "dirname \$(command -v hermes 2>/dev/null || echo /home/${HERMES_USER}/.local/bin/hermes) 2>/dev/null || echo ''")
  # Fallback: use the state dir — webui will auto-discover
  [[ -z "$HERMES_AGENT_DIR" ]] && HERMES_AGENT_DIR="/home/${HERMES_USER}/.hermes"

  cat > "/etc/systemd/system/${WEBUI_SERVICE}.service" <<EOF
[Unit]
Description=Hermes WebUI
Documentation=https://github.com/nesquena/hermes-webui
After=network.target ${SERVICE_NAME}.service
Wants=${SERVICE_NAME}.service

[Service]
Type=simple
User=$HERMES_USER
WorkingDirectory=$WEBUI_DIR
Environment=HERMES_WEBUI_PORT=${WEBUI_PORT}
Environment=HERMES_WEBUI_HOST=127.0.0.1
Environment=HERMES_WEBUI_STATE_DIR=/home/${HERMES_USER}/.hermes/webui
Environment=HERMES_WEBUI_AGENT_DIR=${HERMES_AGENT_DIR}
Environment=HERMES_WEBUI_CHAT_BACKEND=gateway
Environment=HERMES_WEBUI_GATEWAY_BASE_URL=http://127.0.0.1:${API_PORT}
EnvironmentFile=$HERMES_ENV
ExecStart=${HERMES_VENV}/bin/python ${WEBUI_DIR}/server.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$WEBUI_SERVICE"
  systemctl start  "$WEBUI_SERVICE"
  log "  hermes-webui service started on port ${WEBUI_PORT}"
else
  log "  Skipping WebUI installation (--no-webui)"
fi
# ── 5. Register hermes-gateway systemd service ───────────────────────────────
log "Step 5/5: Registering systemd service (${SERVICE_NAME})"
cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Hermes Agent Gateway
Documentation=https://hermes-agent.nousresearch.com
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$HERMES_USER
WorkingDirectory=/home/$HERMES_USER
EnvironmentFile=$HERMES_ENV
ExecStart=$HERMES_BIN gateway serve
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"
log "  hermes-gateway service started"

log "Bootstrap complete."
log "  Gateway:  journalctl -u ${SERVICE_NAME} -f"
if [[ "$INSTALL_WEBUI" == "true" ]]; then
  log "  WebUI:    journalctl -u hermes-webui-${HERMES_PROFILE} -f"
  log "  Access:   ssh tunnel → http://127.0.0.1:${WEBUI_PORT}"
fi
