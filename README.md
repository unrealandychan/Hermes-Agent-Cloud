<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=160&section=header&text=Hermes--Agent--Cloud&fontSize=38&fontColor=ffffff&fontAlignY=38&desc=Deploy+your+Hermes+Agent+to+Cloud+in+one+command&descAlignY=58&descSize=14" alt="Header"/>

[![Stars](https://img.shields.io/github/stars/unrealandychan/Hermes-Agent-Cloud?style=for-the-badge&logo=github&color=f78166&logoColor=white&labelColor=0d1117)](https://github.com/unrealandychan/Hermes-Agent-Cloud/stargazers)
[![Forks](https://img.shields.io/github/forks/unrealandychan/Hermes-Agent-Cloud?style=for-the-badge&logo=github&color=79c0ff&logoColor=white&labelColor=0d1117)](https://github.com/unrealandychan/Hermes-Agent-Cloud/network/members)
[![Language](https://img.shields.io/badge/Shell-4EAA25?logo=gnubash&style=for-the-badge&logoColor=white&labelColor=0d1117)](https://github.com/unrealandychan/Hermes-Agent-Cloud)
[![AWS](https://img.shields.io/badge/AWS-Powered-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white&labelColor=0d1117)](https://aws.amazon.com/)

</div>

---

# Hermes Agent Cloud

> One command. Three clouds. Six LLM providers.
> Deploy the [Hermes Agent](https://github.com/NousResearch/hermes) to AWS, GCP, or Azure with a beautiful wizard-first CLI — zero plaintext secrets, zero manual infra wiring.

[![License: MIT](https://img.shields.io/badge/license-MIT-amber.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/GitHub-unrealandychan%2FHermes--Agent--Cloud-181717?logo=github)](https://github.com/unrealandychan/Hermes-Agent-Cloud)

---

## Monorepo Structure

```
Hermes-Agent-Cloud/
│
├── cli/                                 # 🖥️  The CLI tool
│   ├── hermes-deploy                    # Main executable (bash, chmod +x)
│   ├── install.sh                       # One-line installer (detects macOS / Linux)
│   │
│   ├── lib/                        # Shared bash libraries
│   │   ├── enums.sh                # ⭐ All valid values + validation functions (extend here)
│   │   ├── ui.sh                   # gum wrappers — wizard, banners, spinners, post-deploy guide
│   │   ├── preflight.sh            # Dependency checks (gum, terraform, jq, cloud CLIs)
│   │   ├── config.sh               # ~/.hermes-agent-cloud/config key-value store
│   │   ├── aws.sh                  # AWS wizard + status/ssh/logs/secrets/destroy
│   │   ├── azure.sh                # Azure wizard + status/ssh/logs/secrets/destroy
│   │   ├── gcp_catalog.sh          # GCP preset / capability-pack registry
│   │   └── gcp.sh                  # GCP wizard + status/ssh/logs/secrets/destroy/doctor
│   │
│   ├── terraform/
│   │   ├── aws/                    # EC2 + Security Group + IAM + SSM Parameter Store
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── security_group.tf
│   │   │   ├── iam.tf
│   │   │   └── ssm.tf
│   │   ├── azure/                  # VM + VNet + NSG + Azure Key Vault + Managed Identity
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── network.tf
│   │   │   └── keyvault.tf
│   │   └── gcp/                    # Core GCP deploy + capability-pack resources
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── firewall.tf
│   │       ├── iam.tf
│   │       ├── network.tf
│   │       ├── packs.tf
│   │       └── services.tf
│   │
│   ├── scripts/
│   │   ├── bootstrap.sh            # VM user-data: installs Docker, Hermes, pulls secrets, sets up systemd
│   │   └── configure.sh            # 7-point on-instance health check
│   │
│   ├── config/
│   │   └── hermes.yaml.tpl         # Hermes Agent config template (rendered at deploy time)
│   │
│   ├── README.md                   # CLI-specific documentation
│   └── RELEASE-NOTE.md             # Changelog
│
├── website/                             # 🌐  Marketing website (Next.js 15)
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx          # Root layout — Geist fonts, metadata
│   │   │   ├── page.tsx            # Page assembly — imports all sections
│   │   │   ├── globals.css         # Design tokens, utility classes
│   │   │   └── error.tsx           # Next.js error boundary
│   │   └── components/
│   │       ├── Navbar.tsx          # Fixed top nav with anchor links
│   │       ├── Hero.tsx            # Full-width hero + animated TerminalDemo
│   │       ├── TerminalDemo.tsx    # Auto-replaying wizard terminal animation
│   │       ├── FeaturesOverview.tsx# 3 pillar cards
│   │       ├── CloudsSection.tsx   # AWS / GCP / Azure detail cards
│   │       ├── ProvidersSection.tsx# 4 LLM provider cards
│   │       ├── FeatureGrid.tsx     # 12-feature grid
│   │       ├── HowItWorks.tsx      # 4-step numbered guide
│   │       ├── SecuritySection.tsx # Security guarantee cards
│   │       ├── InstallSection.tsx  # curl one-liner + commands table
│   │       └── Footer.tsx          # Brand, nav, license
│   ├── next.config.ts
│   ├── postcss.config.mjs
│   ├── tsconfig.json
│   └── package.json
│
├── .gitignore                      # Monorepo-wide ignores
└── README.md                       # This file
```

---

## Packages at a Glance

| Package | Language | Purpose |
|---|---|---|
| `cli/` | Bash + Terraform | CLI that provisions Hermes Agent on cloud VMs |
| `website/` | Next.js 15 / TypeScript | Marketing website |

---

## Quick Start

### Install the CLI

```bash
curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash

> **Security note:** Always verify the script before running it in production.
> SHA-256 checksums for each release are published on the [GitHub Releases](https://github.com/unrealandychan/Hermes-Agent-Cloud/releases) page.
> To verify: `curl -sSL <url> | sha256sum` and compare against the published checksum.
```

```bash
# PyPI — always installs the latest version (recommended)
pip install hermes-agent && hermes
```

> ⚠️ **Homebrew note:** `brew install hermes-agent` may lag behind the latest release by one or more versions.
> Use `pip install --upgrade hermes-agent` or the one-liner above to ensure you have the newest version.

Or manually:

```bash
git clone https://github.com/unrealandychan/Hermes-Agent-Cloud
cd Hermes-Agent-Cloud/cli
./install.sh
```

### Run

```bash
hermes-agent-cloud                          # interactive wizard
hermes-agent-cloud deploy --cloud aws       # flags mode
hermes-agent-cloud status --cloud azure
hermes-agent-cloud open                     # open WebUI in browser (SSH tunnel)
hermes-agent-cloud tunnel                   # foreground SSH tunnel to WebUI
hermes-agent-cloud ssh    --cloud gcp
hermes-agent-cloud logs   --cloud aws
hermes-agent-cloud secrets --cloud azure
hermes-agent-cloud destroy --cloud aws
```

| Command | Description |
|---|---|
| `hermes-deploy deploy --redundant <cloud>` | Multi-cloud redundancy: deploy to 2 clouds simultaneously |
| `hermes-deploy redundancy status\|failover` | Check active cloud + one-command failover |
| `hermes-deploy ci-setup` | Generate GitHub Actions workflow for automated deploy |
| `hermes-deploy backup` | Snapshot skills/memory/config to local + S3/GCS/Azure Blob |
| `hermes-deploy billing alert` | Set USD budget threshold with color-coded spend alerts |
| `hermes-deploy doctor` | On-instance health checks (service, disk, memory, env) |
| `hermes-deploy update` | Upgrade hermes-agent on VM to latest version |

---

## Hermes WebUI

Every cloud deployment automatically installs [hermes-webui](https://github.com/nesquena/hermes-webui) — a lightweight, dark-themed browser interface with full parity to the CLI experience.

### Access

WebUI runs on port `8787` — bound to `127.0.0.1` only (never publicly exposed). Access via SSH tunnel:

```bash
# Open WebUI in browser (auto tunnel + launch browser)
hermes-agent-cloud open

# Foreground port-forward only (e.g. for Tailscale or custom routing)
hermes-agent-cloud tunnel
# Then open: http://127.0.0.1:8787
```

### Customisation

| Flag | Default | Description |
|---|---|---|
| `--webui-port <port>` | `8787` | WebUI port on the server |
| `--no-webui` | — | Skip WebUI installation entirely |

```bash
hermes-agent-cloud deploy --cloud aws --webui-port 9090
hermes-agent-cloud deploy --cloud gcp --no-webui
```

The WebUI service is registered as `hermes-webui-<profile>.service` and starts automatically after the gateway on every reboot.

---

## Multi-Profile Support

Run **multiple isolated Hermes Agent instances** on the same machine — each with its own API keys, config, port, and systemd service.

### Use Cases

- Separate **work** and **personal** profiles with different API keys
- Run **different LLM providers** side-by-side (e.g. OpenRouter vs Anthropic)
- Isolate **projects** that need different agent configurations

### Profile Commands

```bash
# Create a new profile (prompts for API keys)
hermes-agent-cloud profile create work
hermes-agent-cloud profile create personal

# List all profiles and their ports
hermes-agent-cloud profile list

# Switch the active profile
hermes-agent-cloud profile use work

# Show details of a profile
hermes-agent-cloud profile show work

# Remove a profile
hermes-agent-cloud profile remove work
```

### Port Allocation

Each profile gets an automatically assigned port pair:

| Profile  | Web Dashboard | API Gateway |
|----------|---------------|-------------|
| `default` | `9119`       | `8080`      |
| 1st extra | `9120`       | `8081`      |
| 2nd extra | `9121`       | `8082`      |
| …         | …            | …           |

### Profile Storage

```
~/.hermes-profiles/
├── default/          # backward-compatible with v1.x
│   ├── .env          # API keys (chmod 600)
│   └── config.yaml
├── work/
│   ├── .env
│   └── config.yaml
└── personal/
    ├── .env
    └── config.yaml
```

Each profile runs as its own **systemd service** (`hermes-default`, `hermes-work`, `hermes-personal`), so they start independently on reboot.

> **Backward compatibility:** Existing single-instance deployments continue to work unchanged — they are automatically treated as the `default` profile.

---

## Run the Website Locally

```bash
cd website
npm install
npm run dev          # http://localhost:3000
```

---

## Cloud Support

| Cloud | Compute | Core Support | SSH Options |
|---|---|---|---|
| AWS | EC2 (Ubuntu 24.04) | EC2 + Security Group + IAM | Direct SSH · SSM Session Manager |
| Azure | VM Standard_D2s_v3 | VM + VNet + NSG + Managed Identity | Direct SSH · az ssh extension |
| GCP | Compute Engine e2-standard-2 | VM + static IP + custom VPC/subnet + firewall + service account | Direct SSH · gcloud compute ssh |

### GCP capability packs

GCP now supports a **Core Deploy + Capability Packs** model:

- **Core Deploy**: Compute Engine VM, static IP, custom VPC/subnet, locked-down firewall, service account, declarative IAM, labels, and optional budget.
- **Capability Packs**: Secret Manager, KMS, Storage, BigQuery, Pub/Sub, Artifact Registry, plus preview packs for Cloud Run, Vertex AI, Monitoring, Alerts, Scheduler, and Cloud SQL.

Use-case presets are built in: `minimal`, `dev-agent`, `data-agent`, `ai-agent`, and `full-ops`.

## Kubernetes / Helm

Deploy to existing EKS, AKS, or GKE clusters:

```bash
helm install hermes-agent ./k8s \
  --set env.OPENROUTER_API_KEY=your-key \
  --set persistence.enabled=true
```

See [k8s/README.md](k8s/README.md) for full values reference.

## Terraform Registry Modules

Use Hermes Agent as a Terraform module in your existing IaC:

```hcl
module "hermes_agent" {
  source  = "unrealandychan/hermes-agent/aws"
  version = "1.5.0"
  instance_type = "t3.medium"
  key_name      = "my-key"
}
```

Modules for AWS, GCP, and Azure are in [`modules/`](modules/).

## Web Dashboard

Hermes Agent ships with a built-in web dashboard (v1.0.2+) that provides a browser-based UI for managing and interacting with the agent.

| Endpoint | Port | Description |
|---|---|---|
| Web Dashboard | `9119` | Browser UI — [docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard) |
| API Gateway | `8080` | REST/WebSocket API endpoint |

Both ports are **restricted to your deployer IP** at provision time. To access the dashboard after deployment:

```
http://<instance-ip>:9119
```

## LLM Providers

| Provider | Env Var | Notes |
|---|---|---|
| OpenRouter | `OPENROUTER_API_KEY` | 600+ models, recommended |
| OpenAI | `OPENAI_API_KEY` | GPT-5, GPT-5.4, GPT-4.1, o3 |
| Anthropic | `ANTHROPIC_API_KEY` | Claude 4.6 Sonnet, Claude 4.6 Haiku |
| Google Gemini | `GEMINI_API_KEY` | Gemini 2.5 Flash / Pro |
| NovitaAI | `NOVITA_API_KEY` | Llama, Qwen, DeepSeek hosting |
| xAI SuperGrok | `XAI_API_KEY` | No API key needed with SuperGrok OAuth; 1M context |

At least one provider required. Mixed-provider setups fully supported.

---

## New in v0.15.x

| What | Description |
|------|-------------|
| **Kanban Multi-Agent** | `hermes kanban swarm` — parallel workers + gated verifier + synthesizer |
| **Promptware Defense** | Brainworm/C2 attack patterns blocked at 3 chokepoints |
| **Bitwarden Secrets Manager** | One `BWS_ACCESS_TOKEN` replaces all per-provider API keys |
| **Session Orchestrator** | Multi-session switcher in TUI — list/switch/close live sessions |
| **`/yolo` mid-session** | Enable per-session bypass without restarting |
| **ntfy push notifications** | 23rd messaging platform — self-hostable, no account/API key needed |
| **xAI SuperGrok deep integration** | Web Search plugin, 1M context, `hermes migrate xai` |
| **Faster cold start** | `hermes --version` 701ms → 258ms (-63%) |

## New in v0.14.0

| Command | Description |
|---------|-------------|
| `hermes proxy` | Start OpenAI-compatible local proxy — lets Codex CLI, Aider, Cline use your Claude Pro/ChatGPT Pro/SuperGrok subscription |
| `hermes setup --portal` | One-command Nous Portal setup wizard |
| `hermes web` | Launch built-in web dashboard (FastAPI + React SPA) |
| `hermes claw migrate` | Migrate from OpenClaw |

**Flags:**
- `--yolo` / `HERMES_YOLO_MODE=1` — bypass all approval prompts (useful for CI/non-interactive deployments)

**Windows Beta:** Hermes Agent v0.14.0 runs natively on Windows (cmd.exe / PowerShell) without WSL.

---

All valid option values live in a single file — **`cli/lib/enums.sh`**.
To add a new cloud region, instance type, or LLM provider, edit only that file.

---

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit your changes
4. Open a Pull Request against `main`

---

## License

MIT © [unrealandychan](https://github.com/unrealandychan)