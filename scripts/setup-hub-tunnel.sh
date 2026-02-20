#!/usr/bin/env bash
#
# setup-hub-tunnel.sh - Set up reverse SSH tunnel to Octocore Constellation Hub
#
# Goals:
# - One-command, idempotent installation of a systemd *user* service on a spoke
# - Reverse SSH tunnel (hub can reach spoke SSH)
# - Reverse gateway tunnel (hub can reach spoke gateway for webhooks)
#
# Source of truth for port assignments: Constellation Bible.
#
# Typical usage (Deadpool):
#   ./scripts/setup-hub-tunnel.sh --agent deadpool --install-systemd --enable-now
#

set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 2; }

# ---------------------------------------------------------------------------
# Defaults (can be overridden by flags)
# ---------------------------------------------------------------------------
HUB_HOST="bot.ericmilgram.com"
HUB_USER="eric_octocore_ai"

LOCAL_SSH_PORT=22
LOCAL_GATEWAY_PORT=18789

REMOTE_SSH_PORT=""
REMOTE_GATEWAY_PORT=""
AGENT_NAME=""

ACTION="run"          # run|install-systemd|status
ENABLE_NOW=0

SSH_OPTS=(
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o ExitOnForwardFailure=yes
  -o BatchMode=yes
)

# ---------------------------------------------------------------------------
# Agent presets (update only in accordance with the Constellation Bible)
# ---------------------------------------------------------------------------
apply_agent_preset() {
  case "$1" in
    envy|data)
      REMOTE_SSH_PORT=2222
      REMOTE_GATEWAY_PORT=18790
      ;;
    jarvis|phone)
      REMOTE_SSH_PORT=2223
      REMOTE_GATEWAY_PORT=28791
      # If running on Termux, local ssh is often 8022. Caller may override.
      ;;
    deadpool|indy)
      REMOTE_SSH_PORT=2224
      REMOTE_GATEWAY_PORT=18793
      ;;
    *)
      die "unknown agent preset: $1 (expected: deadpool|jarvis|envy)"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
show_help() {
  cat <<HELP
USAGE:
  setup-hub-tunnel.sh --agent deadpool --install-systemd --enable-now
  setup-hub-tunnel.sh --agent deadpool            # run tunnel in foreground

OPTIONS:
  --agent <deadpool|jarvis|envy>      Apply Constellation Bible port preset
  --hub-host <host>                   Default: bot.ericmilgram.com
  --hub-user <user>                   Default: eric_octocore_ai

  --local-ssh-port <port>             Default: 22
  --local-gateway-port <port>         Default: 18789

  --remote-ssh-port <port>            Override hub listener port (ssh)
  --remote-gateway-port <port>        Override hub listener port (gateway)

  --install-systemd                   Write/update systemd *user* service file
  --enable-now                        When installing, also daemon-reload + enable --now
  --status                            Basic checks
  -h, --help                          Help

NOTES:
- This script avoids requiring env vars; pass flags instead.
- Systemd unit will restart the tunnel if it drops.
HELP
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT_NAME="${2:-}"; [[ -n "$AGENT_NAME" ]] || die "--agent requires a value"; apply_agent_preset "$AGENT_NAME"; shift 2 ;;
    --hub-host)
      HUB_HOST="${2:-}"; [[ -n "$HUB_HOST" ]] || die "--hub-host requires a value"; shift 2 ;;
    --hub-user)
      HUB_USER="${2:-}"; [[ -n "$HUB_USER" ]] || die "--hub-user requires a value"; shift 2 ;;

    --local-ssh-port)
      LOCAL_SSH_PORT="${2:-}"; shift 2 ;;
    --local-gateway-port)
      LOCAL_GATEWAY_PORT="${2:-}"; shift 2 ;;

    --remote-ssh-port)
      REMOTE_SSH_PORT="${2:-}"; shift 2 ;;
    --remote-gateway-port)
      REMOTE_GATEWAY_PORT="${2:-}"; shift 2 ;;

    --install-systemd)
      ACTION="install-systemd"; shift ;;
    --enable-now)
      ENABLE_NOW=1; shift ;;
    --status)
      ACTION="status"; shift ;;

    -h|--help)
      show_help; exit 0 ;;
    *)
      die "unknown arg: $1" ;;
  esac
done

validate() {
  [[ -n "$REMOTE_SSH_PORT" ]] || die "REMOTE_SSH_PORT unset (use --agent or --remote-ssh-port)"
  [[ -n "$REMOTE_GATEWAY_PORT" ]] || die "REMOTE_GATEWAY_PORT unset (use --agent or --remote-gateway-port)"
}

start_tunnel_fg() {
  validate

  say "=============================================="
  say "Starting reverse SSH tunnel to Constellation Hub"
  say "=============================================="
  say "Hub:      ${HUB_USER}@${HUB_HOST}"
  say "SSH:      localhost:${LOCAL_SSH_PORT} -> hub:${REMOTE_SSH_PORT}"
  say "Gateway:  localhost:${LOCAL_GATEWAY_PORT} -> hub:${REMOTE_GATEWAY_PORT}"
  say ""

  # Warn only; do not fail.
  if command -v nc >/dev/null 2>&1; then
    if ! nc -z 127.0.0.1 "$LOCAL_SSH_PORT" 2>/dev/null; then
      say "WARNING: Local SSH port ${LOCAL_SSH_PORT} is not listening (is sshd running?)"
    fi
    if ! nc -z 127.0.0.1 "$LOCAL_GATEWAY_PORT" 2>/dev/null; then
      say "WARNING: Local gateway port ${LOCAL_GATEWAY_PORT} is not listening (start gateway later)"
    fi
  fi

  exec ssh -N \
    -R "127.0.0.1:${REMOTE_SSH_PORT}:127.0.0.1:${LOCAL_SSH_PORT}" \
    -R "127.0.0.1:${REMOTE_GATEWAY_PORT}:127.0.0.1:${LOCAL_GATEWAY_PORT}" \
    "${SSH_OPTS[@]}" \
    "${HUB_USER}@${HUB_HOST}"
}

install_systemd_user_service() {
  validate

  local service_name="constellation-hub-tunnel"
  local service_dir="$HOME/.config/systemd/user"
  local service_file="${service_dir}/${service_name}.service"
  local script_path
  script_path="$(realpath "$0")"

  mkdir -p "$service_dir"

  cat > "$service_file" <<SERVICEEOF
[Unit]
Description=Octocore Constellation Hub Tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${script_path} \
  --hub-host ${HUB_HOST} \
  --hub-user ${HUB_USER} \
  --local-ssh-port ${LOCAL_SSH_PORT} \
  --local-gateway-port ${LOCAL_GATEWAY_PORT} \
  --remote-ssh-port ${REMOTE_SSH_PORT} \
  --remote-gateway-port ${REMOTE_GATEWAY_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
SERVICEEOF

  say "Wrote systemd user service: ${service_file}"

  if [[ "$ENABLE_NOW" -eq 1 ]]; then
    systemctl --user daemon-reload
    systemctl --user enable --now "${service_name}"
    say "Enabled+started: ${service_name}"
    systemctl --user --no-pager status "${service_name}" || true
  else
    say "Next: systemctl --user daemon-reload && systemctl --user enable --now ${service_name}"
  fi
}

status() {
  validate
  say "Tunnel desired ports: SSH=${REMOTE_SSH_PORT}, GW=${REMOTE_GATEWAY_PORT}"

  if pgrep -f "ssh.*-R.*127\.0\.0\.1:${REMOTE_SSH_PORT}" >/dev/null 2>&1; then
    say "OK: tunnel process appears running"
  else
    say "WARN: tunnel process not detected via pgrep"
  fi

  if ssh -o ConnectTimeout=5 -o BatchMode=yes "${HUB_USER}@${HUB_HOST}" "echo ok" >/dev/null 2>&1; then
    say "OK: can connect to hub"
  else
    say "WARN: cannot connect to hub (auth or network)"
  fi
}

case "$ACTION" in
  install-systemd) install_systemd_user_service ;;
  status) status ;;
  run) start_tunnel_fg ;;
  *) die "unknown action: $ACTION" ;;
esac
