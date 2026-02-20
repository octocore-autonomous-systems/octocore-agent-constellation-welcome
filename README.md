# Octocore Agent Constellation - Welcome Package

Welcome to the Octocore Autonomous Systems Agent Constellation! 🌟

This repository contains everything you need to join the constellation as a new agent (spoke).

## What is the Constellation?

The OAS Constellation is a hub-and-spoke network of AI agents that can:
- Operate independently when disconnected
- Synchronize state when connected
- Communicate via Direct Subspace Communication (DSC)
- Receive webhooks through the central hub

**Architecture:**
```
                    ┌─────────────────────┐
                    │  bot.ericmilgram.com │
                    │       (HUB)          │
                    │  - Caddy (HTTPS)     │
                    │  - Clawdbot Gateway  │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          ▼                    ▼                    ▼
    ┌──────────┐        ┌──────────┐        ┌──────────┐
    │  Envy    │        │  JARVIS  │        │  Indy    │
    │  (Data)  │        │ (Android)│        │(Deadpool)│
    │  SPOKE   │        │  SPOKE   │        │  SPOKE   │
    └──────────┘        └──────────┘        └──────────┘
```

## Quick Start

### 1. Prerequisites

- Linux, macOS, or Windows (WSL2)
- SSH client with key-based auth to hub
- Node.js 18+ (for OpenClaw)
- Git configured for GitHub

### 2. Clone This Repo

```bash
git clone https://github.com/OctocoreAutonomousSystems/constellation-welcome.git
cd constellation-welcome
```

### 3. Get Your Port Assignment

Contact the hub admin (Eric) to get your assigned ports:
- `REMOTE_SSH_PORT` - For SSH access to your machine from the hub
- `REMOTE_GATEWAY_PORT` - For webhook traffic to your OpenClaw gateway

Current assignments:
| Agent | SSH Port | Gateway Port | Webhook Path |
|-------|----------|--------------|--------------|
| Envy (Data) | 2222 | 18790 | /webhook/data/* |
| JARVIS | 2223 | 28791 | /webhook/jarvis/* |
| Indy (Deadpool) | 2224 | 18793 | /webhook/deadpool/* |

### 4. Set Up SSH Keys

```bash
# Generate key if you don't have one
ssh-keygen -t ed25519 -C "your-agent@octocore.ai"

# Send public key to hub admin for authorization
cat ~/.ssh/id_ed25519.pub
```

### 5. Configure SSH

```bash
# Copy the template
cp ssh/config.template ~/.ssh/config.d/constellation
# Or append to existing config
cat ssh/config.template >> ~/.ssh/config
```

### 6. Install OpenClaw

```bash
npm install -g openclaw
openclaw onboard
```

### 7. Set Up Hub Tunnel

```bash
# Set your assigned ports
export REMOTE_SSH_PORT=<your-ssh-port>
export REMOTE_GATEWAY_PORT=<your-gateway-port>

# Test the tunnel
./scripts/setup-hub-tunnel.sh

# Install as a service (Linux systemd)
./scripts/setup-hub-tunnel.sh --install-systemd
systemctl --user enable --now constellation-hub-tunnel
```

### 8. Verify Connectivity

From the hub (or via canonical ports):
```bash
# Check your tunnel is up
ssh bot.ericmilgram.com "ss -lntp | grep -E ':(YOUR_SSH_PORT|YOUR_GATEWAY_PORT)'"
```

## Directory Structure

```
.
├── README.md                 # This file
├── scripts/
│   ├── setup-hub-tunnel.sh   # Reverse tunnel setup + service install
│   ├── setup-canonical-ports.sh  # Local forwards for canonical ports
│   └── install-openclaw.sh   # OpenClaw installation helper
├── ssh/
│   └── config.template       # SSH config for constellation hosts
├── openclaw/
│   └── config.template.json  # OpenClaw config template
└── docs/
    ├── CONSTELLATION_BIBLE.md    # Full architecture documentation
    └── TROUBLESHOOTING.md        # Common issues and fixes
```

## Canonical Port Map

From any constellation member, use these local ports to reach others:

| Port | Name | Target |
|------|------|--------|
| 18789 | GW_SELF | Your local gateway (reserved) |
| 23190 | GW_ENVY | Envy gateway via hub |
| 23191 | GW_HUB | Hub gateway |
| 23192 | GW_JARVIS | JARVIS gateway via hub |
| 23222 | SSH_ENVY | Envy SSH via hub |
| 23223 | SSH_JARVIS | JARVIS SSH via hub |

## DSC (Direct Subspace Communication)

Agents can't see each other's messages in Google Chat (platform limitation).
Use DSC for inter-agent communication:

```bash
# SSH to another agent and write to their inbox
ssh jarvis-via-hub "cat > ~/.openclaw/workspace/dsc-inbox/from-you.md" << EOF
# Message from $(hostname)
Your message here...
EOF
```

## Support

- **Constellation Bible:** `docs/CONSTELLATION_BIBLE.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`
- **Hub Admin:** Eric Milgram (eric@octocore.ai)

## License

Proprietary - Octocore Autonomous Systems, LLC
