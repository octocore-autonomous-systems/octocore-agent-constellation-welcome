#!/usr/bin/env bash
#
# setup-canonical-ports.sh - Set up canonical loopback port forwards to hub
#
# This creates local forwards so you can access any constellation member's
# gateway or SSH from your machine using consistent port numbers.
#
# After running this, from ANY device:
#   curl http://127.0.0.1:23190/...  -> Envy gateway
#   curl http://127.0.0.1:23191/...  -> Hub gateway
#   curl http://127.0.0.1:23192/...  -> JARVIS gateway
#   curl http://127.0.0.1:23193/...  -> Deadpool gateway
#   ssh -p 23222 eric@127.0.0.1      -> Envy SSH
#   ssh -p 23223 u0_a527@127.0.0.1   -> JARVIS SSH
#   ssh -p 23224 indy@127.0.0.1      -> Deadpool SSH
#

set -euo pipefail

HUB_HOST="${HUB_HOST:-bot.ericmilgram.com}"
HUB_USER="${HUB_USER:-eric_octocore_ai}"

# Canonical port mappings (from Constellation Bible - DO NOT CHANGE)
# Format: LOCAL_PORT -> HUB_LOCALHOST_PORT
declare -A PORT_MAP=(
    # Gateway ports
    [23190]="18790"   # GW_ENVY: Envy gateway via hub
    [23191]="18789"   # GW_HUB: Hub gateway
    [23192]="28791"   # GW_JARVIS: JARVIS gateway via hub
    [23193]="18793"   # GW_DEADPOOL: Deadpool gateway via hub
    # SSH ports
    [23222]="2222"    # SSH_ENVY: Envy SSH via hub
    [23223]="2223"    # SSH_JARVIS: JARVIS SSH via hub
    [23224]="2224"    # SSH_DEADPOOL: Deadpool SSH via hub
)

SSH_OPTS="-o ServerAliveInterval=30 -o ServerAliveCountMax=3"

build_forward_args() {
    local args=""
    for local_port in "${!PORT_MAP[@]}"; do
        hub_port="${PORT_MAP[$local_port]}"
        args="$args -L 127.0.0.1:${local_port}:127.0.0.1:${hub_port}"
    done
    echo "$args"
}

start_forwards() {
    echo "=============================================="
    echo "Starting canonical port forwards to Constellation Hub"
    echo "=============================================="
    echo ""
    echo "Gateway mappings:"
    echo "  23190 -> Envy gateway (hub:18790)"
    echo "  23191 -> Hub gateway (hub:18789)"
    echo "  23192 -> JARVIS gateway (hub:28791)"
    echo "  23193 -> Deadpool gateway (hub:18793)"
    echo ""
    echo "SSH mappings:"
    echo "  23222 -> Envy SSH (hub:2222)"
    echo "  23223 -> JARVIS SSH (hub:2223)"
    echo "  23224 -> Deadpool SSH (hub:2224)"
    echo ""
    echo "Press Ctrl+C to stop."
    echo ""
    
    local forward_args
    forward_args=$(build_forward_args)
    
    # shellcheck disable=SC2086
    ssh -N $forward_args $SSH_OPTS "${HUB_USER}@${HUB_HOST}"
}

check_status() {
    echo "Checking canonical port availability..."
    echo ""
    echo "Gateway ports:"
    for port in 23190 23191 23192 23193; do
        if nc -z 127.0.0.1 "$port" 2>/dev/null; then
            echo "  ✅ Port $port is listening"
        else
            echo "  ❌ Port $port is NOT listening"
        fi
    done
    echo ""
    echo "SSH ports:"
    for port in 23222 23223 23224; do
        if nc -z 127.0.0.1 "$port" 2>/dev/null; then
            echo "  ✅ Port $port is listening"
        else
            echo "  ❌ Port $port is NOT listening"
        fi
    done
}

show_help() {
    cat << HELPEOF
Usage: $0 [OPTIONS]

Set up SSH local forwards for canonical constellation ports.

Options:
  --status    Check if canonical ports are already forwarded
  --help, -h  Show this help message

This script creates local port forwards through the hub so you can
reach any constellation member using consistent port numbers.

Port Mappings (from Constellation Bible):
  Local Port  Name          Target
  ----------  ----          ------
  23190       GW_ENVY       Envy gateway
  23191       GW_HUB        Hub gateway
  23192       GW_JARVIS     JARVIS gateway
  23193       GW_DEADPOOL   Deadpool gateway
  23222       SSH_ENVY      Envy SSH
  23223       SSH_JARVIS    JARVIS SSH
  23224       SSH_DEADPOOL  Deadpool SSH

HELPEOF
}

case "${1:-}" in
    --status)
        check_status
        ;;
    --help|-h)
        show_help
        ;;
    *)
        start_forwards
        ;;
esac
