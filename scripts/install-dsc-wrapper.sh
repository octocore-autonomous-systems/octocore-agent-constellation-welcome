#!/usr/bin/env bash
set -euo pipefail

# Installs openclaw-agent-wrapper (DSC convenience script)
# NOTE: canonical version currently lives on the hub; this script is a placeholder.

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

cat > "${INSTALL_DIR}/openclaw-agent-wrapper" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

echo "openclaw-agent-wrapper is not yet embedded in this repo."
echo "For now, copy it from the hub canonical location." >&2
exit 2
WRAPPER

chmod +x "${INSTALL_DIR}/openclaw-agent-wrapper"
echo "Installed placeholder: ${INSTALL_DIR}/openclaw-agent-wrapper"
