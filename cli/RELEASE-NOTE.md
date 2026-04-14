# Release Notes

All notable changes to `Hermes-Easy-Deploy` are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

_Changes staged for the next release will appear here._

---

## [1.0.0] — 2026-04-14

### Overview

Initial release. Full wizard-first CLI to deploy Hermes Agent to AWS, Azure, and GCP
with a single command through a beautiful `gum`-powered TUI.

### Added

#### Core CLI (`Hermes-Easy-Deploy`)
- Subcommand router: `deploy`, `status`, `ssh`, `logs`, `secrets`, `destroy`, `version`, `help`
- Global flags: `--cloud`, `--region`, `--dry-run`, `--no-color`, `--help`
- `--cloud` flag validated against `VALID_CLOUDS` enum on parse — exits with a clear error on invalid value
- Config persistence in `~/.Hermes-Easy-Deploy/config` (key=value store, no external dependencies)

#### TUI (`lib/ui.sh` + Charm `gum`)
- `hermes_banner` — double-bordered Hermes ASCII header with version
- `step_header N total label` — numbered step indicators for multi-step wizards
- `spinner "msg" cmd...` — dot-style spinner wrapping any long-running command
- `masked_input` / `plain_input` — styled `gum input` wrappers
- `choose_one` — `gum choose` single-selection menu used for all enum fields
- `summary_table` — bordered key-value table displayed before every deployment
- `confirm_destructive` — `gum confirm` gate (default=false) on all destroy operations
- `post_deploy_guide` — detailed live access guide printed after deploy with:
  - Instance ID, IP, and cloud-specific access commands
  - Direct SSH, cloud-native shell (SSM / az ssh / gcloud), gateway URL
  - First-boot checklist with exact commands
  - Per-cloud security notes
  - Destroy reminder

#### Enum system (`lib/enums.sh`)
- Single source of truth for all valid values: cloud providers, regions, instance types, LLM providers
- Parallel `*_LABELS` arrays (human-readable wizard display) aligned by index with `VALID_*` arrays
- `API_PROVIDER_ORDER`, `API_PROVIDER_LABELS`, `API_PROVIDER_ENV_VARS`, `API_PROVIDER_AWS_SSM`,
  `API_PROVIDER_AZURE_KV`, `API_PROVIDER_GCP_SECRET` associative arrays for all four LLM providers
- Generic helpers (bash 3.2+ compatible):
  - `enum_contains "value" "${ARRAY[@]}"` — membership test
  - `enum_values_str "sep" "${ARRAY[@]}"` — joins values with separator
- Typed validation functions per resource: `validate_cloud` (fatal), `validate_aws_region`,
  `validate_aws_instance_type`, `validate_azure_location`, `validate_azure_vm_size`,
  `validate_gcp_region`, `validate_gcp_machine_type` (warning-only for non-fatal paths)

#### LLM Provider support
- **OpenRouter** (`OPENROUTER_API_KEY`)
- **OpenAI** (`OPENAI_API_KEY`)
- **Anthropic / Claude** (`ANTHROPIC_API_KEY`)
- **Google Gemini** (`GEMINI_API_KEY`)
- At least one key required; wizard validates before proceeding
- All keys optional individually; only provided keys are created in the cloud vault
- `Hermes-Easy-Deploy secrets` command to rotate any key without re-deploying

#### AWS provider (`lib/aws.sh` + `terraform/aws/`)
- 6-step wizard: region → instance type → SSH key pair → API keys → summary → confirm
- Terraform stack: EC2 (`t3.large` default), Ubuntu 24.04 LTS, 50 GB gp3 encrypted root
- IAM: instance role with `AmazonSSMManagedInstanceCore` + inline SSM read policy for `/hermes/*`
- SSM Parameter Store: four `SecureString` params, count-conditional (only created when key provided)
- Security group: SSH (22) + gateway (8080) restricted to deployer IP; all egress open
- `aws_ssh`: choice of direct SSH or AWS SSM Session Manager
- `aws_logs`: SSH → `journalctl -u hermes-gateway -f`
- `aws_secrets`: `aws ssm put-parameter --overwrite` per provider
- `aws_destroy`: `terraform destroy -auto-approve`

#### Azure provider (`lib/azure.sh` + `terraform/azure/`)
- 6-step wizard: region → VM size → SSH public key → API keys → summary → confirm
- Terraform stack: `Standard_D2s_v3`, Ubuntu 24.04, 50 GB Premium_LRS encrypted disk
- System-assigned Managed Identity for Key Vault access (no credentials on instance)
- Azure Key Vault (standard SKU, soft-delete 7 days) with deployer access policy + VM accessor policy
- NSG: rules for SSH + gateway from deployer IP; VNet + Public IP (static, Standard SKU)
- `az ssh` extension auto-installed if missing on `Hermes-Easy-Deploy ssh`
- `azure_secrets`: `az keyvault secret set`

#### GCP provider (`lib/gcp.sh` + `terraform/gcp/`)
- 6-step wizard: project + region → machine type → API keys → summary → confirm
- Auto-enables `compute.googleapis.com` and `secretmanager.googleapis.com` before apply
- Terraform stack: `e2-standard-2`, Ubuntu 24.04, 50 GB pd-ssd, dedicated service account
- Secret Manager: `for_each` over active providers, IAM `secretAccessor` binding per secret
- Firewall: separate rules for SSH and gateway, both restricted to deployer IP, tagged `hermes-agent`
- `gcp_ssh`: choice of `gcloud compute ssh` or direct SSH
- `gcp_secrets`: `gcloud secrets versions add` via stdin piping

#### Bootstrap script (`scripts/bootstrap.sh`)
- Terraform `templatefile` — cloud identity injected at plan time via `${HERMES_CLOUD}` etc.
- Steps: system packages → cloud CLI install (if needed) → secret fetch → Docker install → Hermes install → systemd service registration
- Per-cloud secret-fetch strategies using only IAM-native APIs (no credentials hardcoded):
  - AWS: `aws ssm get-parameter --with-decryption`
  - Azure: IMDS Managed Identity token → Key Vault REST API
  - GCP: Metadata server OAuth token → Secret Manager REST API
- Writes all present keys to `~ubuntu/.hermes/.env` (mode 600)
- Registers `hermes-gateway.service` with `Restart=on-failure` and `EnvironmentFile`
- Full log at `/var/log/hermes-bootstrap.log`

#### Post-deploy verification (`scripts/configure.sh`)
- 7-point health check: hermes binary, `.env` keys, `config.yaml`, Docker, systemd service,
  `hermes doctor`, gateway reachability on `:8080`
- Color-coded pass/fail/warn output; actionable fix hints on every failure

#### Installer (`install.sh`)
- Detects macOS (brew) vs Linux (apt / binary download)
- Installs `gum` (Charm apt repo on Debian/Ubuntu, binary on others, brew on macOS)
- Installs `terraform` (HashiCorp releases)
- Installs `jq`
- Copies project to `/usr/local/lib/Hermes-Easy-Deploy`, symlinks binary to `/usr/local/bin`
- Works from local clone or remote archive download

### Security

- API keys never appear in Terraform state, `user_data`, `custom_data`, or instance metadata
- `secrets.auto.tfvars` is `chmod 600` and gitignored
- All inbound ports restricted to deployer IP at deploy time
- IAM roles follow least-privilege principle (read-only on secrets, SSM core for management only)
- Hermes runs in a Docker container sandbox (no direct host access from agent tools)

---

## Upgrade Guide

### From scratch (first install)

Follow the [Installation section in README.md](./README.md#installation).

### Future minor / patch upgrades (1.x.x)

```bash
curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Easy-Deploy/main/cli/install.sh | bash
```

Re-running the installer overwrites the CLI files only. Existing `~/.Hermes-Easy-Deploy/` state
(config, Terraform state) is preserved.

### Breaking changes

None in 1.0.0 (initial release).

---

## Roadmap

Items under consideration for future releases:

- `Hermes-Easy-Deploy update` — pull latest Hermes Agent version on the running instance
- Remote Terraform state backend support (S3 / Azure Storage / GCS)
- `Hermes-Easy-Deploy firewall --update-ip` — update security rules when deployer IP changes
- VPC/subnet selection for AWS (currently uses default VPC)
- Multi-instance support (name flag to manage several deployments per cloud)
- DigitalOcean and Hetzner provider support
- Shell completions (`bash`, `zsh`, `fish`)
