# Termux (Android) Spoke Setup

## Prerequisites
- Android device with Termux installed (F-Droid version recommended)
- Termux:Boot add-on for auto-start

## Battery Optimization (CRITICAL)
OEM Android builds aggressively kill background apps.

You MUST set:
- Settings → Apps → Termux → Battery → *Unrestricted*
- Settings → Apps → Termux:Boot → Battery → *Unrestricted*

Without this, tunnels won’t reliably auto-start on boot.

## Bootstrap

```bash
git clone git@github.com:octocore-autonomous-systems/octocore-agent-constellation-welcome.git
cd octocore-agent-constellation-welcome
bash scripts/termux-bootstrap.sh
bash scripts/termux-tunnels.sh
```

## Notes
- Termux typically cannot write to `/tmp`. Prefer `$TMPDIR`.
- After `npm update -g openclaw`, re-check any hardcoded `/tmp` paths.
