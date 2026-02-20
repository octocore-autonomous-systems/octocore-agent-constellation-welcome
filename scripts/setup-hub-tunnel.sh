#!/usr/bin/env bash
#
# setup-hub-tunnel.sh - Set up reverse SSH tunnel to Octocore Constellation Hub
#
# This script configures a persistent reverse SSH tunnel from a spoke (agent)
# to the hub (bot.ericmilgram.com), enabling:
# - Inbound SSH access to the spoke from the hub
# - Inbound gateway access for webhooks
#
# Usage: ./setup-hub-tunnel.sh [--install-systemd|--install-runit]
#

set -euo pipefail

# ============================================================================
# CONFIGURATION - Edit these for your agent
# ============================================================================

# Hub connection
HUB_HOST="${HUB_HOST:-bot.ericmilgram.com}"
HUB_USER="${HUB_USER:-eric_octocore_ai}"

# Your agent's local ports
LOCAL_SSH_PORT="${LOCAL_SSH_PORT:-22}"           # Your local SSH port (22 for Linux, 8022 for Termux)
LOCAL_GATEWAY_PORT="${LOCAL_GATEWAY_PORT:-18789}" # Your OpenClaw gateway port

# Hub-side ports (assigned by hub admin - check the Constellation Bible)
# Port assignments by agent:
#   Envy (Data):    SSH=2222, Gateway=18790
#   JARVIS:         SSH=2223, Gateway=28791
#   Deadpool (Indy): SSH=2224, Gateway=18793
REMOTE_SSH_PORT="${REMOTE_SSH_PORT:-}"
REMOTE_GATEWAY_PORT="${REMOTE_GATEWAY_PORT:-}"

# SSH options for reliability
SSH_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes"

# ============================================================================
# VALIDATION
# ============================================================================

validate_config() {
    local errors=0
    
    if [[ -z "$REMOTE_SSH_PORT" ]]; then
        echo "ERROR: REMOTE_SSH_PORT not set."
        errors=$((errors + 1))
    fi
    
    if [[ -z "$REMOTE_GATEWAY_PORT" ]]; then
        echo "ERROR: REMOTE_GATEWAY_PORT not set."
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "These ports are assigned by the hub admin. Check the Constellation Bible."
        echo ""
        echo "Example for Deadpool:"
        echo "  export REMOTE_SSH_PORT=2224"
        echo "  export REMOTE_GATEWAY_PORT=18793"
        echo "  $0"
        echo ""
        echo "Or pass them inline:"
        echo "  REMOTE_SSH_PORT=2224 REMOTE_GATEWAY_PORT=18793 $0"
        exit 1
    fi
    
    # Check if local SSH is accessible
    if ! nc -z 127.0.0.1 "$LOCAL_SSH_PORT" 2>/dev/null; then
        echo "WARNING: Local SSH port $LOCAL_SSH_PORT does not appear to be listening."
        echo "         Make sure sshd is running before the hub tries to connect."
    fi
    
    # Check if local gateway is accessible
    if ! nc -z 127.0.0.1 "$LOCAL_GATEWAY_PORT" 2>/dev/null; then
        echo "WARNING: Local gateway port $LOCAL_GATEWAY_PORT does not appear to be listening."
        echo "         Make sure OpenClaw/Clawdbot gateway is running."
    fi
}

# ============================================================================
# FUNCTIONS
# ============================================================================

start_tunnel() {
    echo "=============================================="
    echo "Starting reverse SSH tunnel to Constellation Hub"
    echo "=============================================="
    echo ""
    echo "Hub:      ${HUB_USER}@${HUB_HOST}"
    echo "SSH:      localhost:${LOCAL_SSH_PORT} -> hub:${REMOTE_SSH_PORT}"
    echo "Gateway:  localhost:${LOCAL_GATEWAY_PORT} -> hub:${REMOTE_GATEWAY_PORT}"
    echo ""
    echo "Press Ctrl+C to stop the tunnel."
    echo ""
    
    ssh -N \
        -R "127.0.0.1:${REMOTE_SSH_PORT}:127.0.0.1:${LOCAL_SSH_PORT}" \
        -R "127.0.0.1:${REMOTE_GATEWAY_PORT}:127.0.0.1:${LOCAL_GATEWAY_PORT}" \
        ${SSH_OPTS} \
        "${HUB_USER}@${HUB_HOST}"
}

install_systemd_service() {
    local service_name="constellation-hub-tunnel"
    local service_dir="$HOME/.config/systemd/user"
    local service_file="${service_dir}/${service_name}.service"
    local script_path
    script_path="$(realpath "$0")"
    
    # Idempotent: create directory if needed
    mkdir -p "$service_dir"
    
    # Check if service already exists
    if [[ -f "$service_file" ]]; then
        echo "Service file already exists: $service_file"
        echo "Updating with current configuration..."
    fi
    
    cat > "$service_file" << SERVICEEOF
[Unit]
Description=Octocore Constellation Hub Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment="HUB_HOST=${HUB_HOST}"
Environment="HUB_USER=${HUB_USER}"
Environment="REMOTE_SSH_PORT=${REMOTE_SSH_PORT}"
Environment="REMOTE_GATEWAY_PORT=${REMOTE_GATEWAY_PORT}"
Environment="LOCAL_SSH_PORT=${LOCAL_SSH_PORT}"
Environment="LOCAL_GATEWAY_PORT=${LOCAL_GATEWAY_PORT}"
ExecStart=${script_path}
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
SERVICEEOF

    echo "Created/updated systemd user service: $service_file"
    echo ""
    echo "To enable and start:"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now ${service_name}"
    echo ""
    echo "To check status:"
    echo "  systemctl --user status ${service_name}"
    echo ""
    echo "To view logs:"
    echo "  journalctl --user -u ${service_name} -f"
}

install_runit_service() {
    # For Termux or other runit-based systems
    local service_name="hub-tunnel"
    local service_dir
    local script_path
    script_path="$(realpath "$0")"
    
    # Determine service directory
    if [[ -n "${PREFIX:-}" ]]; then
        # Termux
        service_dir="${PREFIX}/var/service/${service_name}"
    elif [[ -d "/etc/sv" ]]; then
        # Void Linux or similar
        service_dir="/etc/sv/${service_name}"
    else
        service_dir="${SVDIR:-/var/service}/${service_name}"
    fi
    
    # Idempotent: create directory if needed
    mkdir -p "$service_dir"
    
    cat > "$service_dir/run" << RUNEOF
#!/bin/sh
set -e
export HUB_HOST="${HUB_HOST}"
export HUB_USER="${HUB_USER}"
export REMOTE_SSH_PORT="${REMOTE_SSH_PORT}"
export REMOTE_GATEWAY_PORT="${REMOTE_GATEWAY_PORT}"
export LOCAL_SSH_PORT="${LOCAL_SSH_PORT}"
export LOCAL_GATEWAY_PORT="${LOCAL_GATEWAY_PORT}"
exec ${script_path}
RUNEOF

    chmod +x "$service_dir/run"
    
    echo "Created/updated runit service: $service_dir"
    echo ""
    echo "To start: sv up ${service_name}"
    echo "To check: sv status ${service_name}"
    echo "To stop:  sv down ${service_name}"
}

check_status() {
    echo "Checking tunnel status..."
    echo ""
    
    # Check if tunnel process is running
    if pgrep -f "ssh.*-R.*${REMOTE_SSH_PORT:-NOTSET}" > /dev/null 2>&1; then
        echo "✅ Tunnel process appears to be running"
    else
        echo "❌ No tunnel process found"
    fi
    
    # Check if we can reach the hub
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "${HUB_USER}@${HUB_HOST}" "echo ok" > /dev/null 2>&1; then
        echo "✅ Can connect to hub"
    else
        echo "❌ Cannot connect to hub"
    fi
    
    echo ""
    echo "To verify tunnel is working from the hub, run:"
    echo "  ssh ${HUB_USER}@${HUB_HOST} 'ss -lntp | grep -E \":(${REMOTE_SSH_PORT:-PORT}|${REMOTE_GATEWAY_PORT:-PORT})\"'"
}

show_help() {
    cat << HELPEOF
Usage: $0 [OPTIONS]

Set up a reverse SSH tunnel to the Octocore Constellation Hub.

Options:
  --install-systemd  Install as a systemd user service (Linux)
  --install-runit    Install as a runit service (Termux, Void)
  --status           Check tunnel status
  --help, -h         Show this help message

Environment Variables (required):
  REMOTE_SSH_PORT      Hub-side SSH tunnel port (from Constellation Bible)
  REMOTE_GATEWAY_PORT  Hub-side gateway tunnel port (from Constellation Bible)

Environment Variables (optional):
  HUB_HOST             Hub hostname (default: bot.ericmilgram.com)
  HUB_USER             Hub username (default: eric_octocore_ai)
  LOCAL_SSH_PORT       Local SSH port (default: 22)
  LOCAL_GATEWAY_PORT   Local gateway port (default: 18789)

Port Assignments (from Constellation Bible):
  Agent      SSH Port  Gateway Port
  -----      --------  ------------
  Envy       2222      18790
  JARVIS     2223      28791
  Deadpool   2224      18793

Example:
  # For Deadpool (Indy):
  export REMOTE_SSH_PORT=2224
  export REMOTE_GATEWAY_PORT=18793
  $0

  # Install as systemd service:
  REMOTE_SSH_PORT=2224 REMOTE_GATEWAY_PORT=18793 $0 --install-systemd

HELPEOF
}

# ============================================================================
# MAIN
# ============================================================================

case "${1:-}" in
    --install-systemd)
        validate_config
        install_systemd_service
        ;;
    --install-runit)
        validate_config
        install_runit_service
        ;;
    --status)
        check_status
        ;;
    --help|-h)
        show_help
        ;;
    *)
        validate_config
        start_tunnel
        ;;
esac
