#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Termux bootstrap for Octocore Agent Constellation
# - installs required packages
# - prepares ssh
# - installs openclaw + helper wrapper

pkg update -y
pkg upgrade -y

pkg install -y openssh autossh git nodejs-lts curl jq

# Prepare SSH
mkdir -p "$HOME/.ssh" "$HOME/.local/bin"
chmod 700 "$HOME/.ssh"

echo "[termux-bootstrap] Installed deps."
echo "Next: ensure an SSH key exists and is authorized for the hub + GitHub."
echo "Then run: bash scripts/termux-tunnels.sh"
