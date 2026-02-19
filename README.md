# Octocore Agent Constellation Welcome

Bootstrap and operations scripts for joining a machine to the **Octocore Agent Constellation**.

Goals:
- Standardize SSH config and reverse tunnels (hub↔spoke)
- Install/configure OpenClaw/Clawdbot on supported hosts
- Autostart + monitor + self-heal tunnel connectivity
- Provide a reproducible onboarding path (so any agent can be rebuilt)

## Quick start (spoke)

```bash
git clone git@github.com:octocore-autonomous-systems/octocore-agent-constellation-welcome.git
cd octocore-agent-constellation-welcome
./scripts/bootstrap.sh
```

## Repo layout
- `scripts/` : bootstrap + diagnostics
- `ssh/` : ssh config snippets + tunnel units/templates
- `docs/` : architecture notes and SOPs (referencing the Constellation Bible)

## Security note
This repo must not contain secrets (API keys, private keys). Use `pass` (password-store) or your org-approved secret manager.
