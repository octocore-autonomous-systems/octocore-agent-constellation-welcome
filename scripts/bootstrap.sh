#!/usr/bin/env bash
set -euo pipefail

# Octocore Constellation bootstrap
# - Installs prerequisites
# - Places SSH config snippets
# - Optionally installs OpenClaw/Clawdbot

say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

say "[bootstrap] starting"

# Minimal deps
need git
need ssh

say "[bootstrap] OK"

say "Next steps (manual, for now):"
cat <<'EOF'
- Configure SSH key for GitHub (or use `gh auth login`).
- Add tunnel config: see ./ssh/README.md
- Install OpenClaw/Clawdbot: see ./docs/openclaw.md
EOF
