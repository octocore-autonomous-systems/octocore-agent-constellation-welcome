#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Termux reverse tunnels to hub
# NOTE: Requires Termux:Boot for autostart and battery optimizations set to Unrestricted.

HUB_HOST="bot.ericmilgram.com"
HUB_USER="eric_octocore_ai"

# Update these per-spoke (see Constellation Bible)
# Example for JARVIS (phone):
HUB_LISTEN_GW=28791
HUB_LISTEN_SSH=2223
LOCAL_GW=18789
LOCAL_SSH=8022

mkdir -p "$HOME/.ssh"

echo "Starting reverse tunnels to ${HUB_USER}@${HUB_HOST} ..."

autossh -M 0 -f -N \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  -R 127.0.0.1:${HUB_LISTEN_GW}:127.0.0.1:${LOCAL_GW} \
  -R 127.0.0.1:${HUB_LISTEN_SSH}:127.0.0.1:${LOCAL_SSH} \
  ${HUB_USER}@${HUB_HOST}

echo "Tunnels started. Verify on hub: ss -lntp | egrep '(:${HUB_LISTEN_GW}|:${HUB_LISTEN_SSH})\\b'"
