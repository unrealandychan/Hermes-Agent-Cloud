# Changelog

All notable changes to Hermes Agent Cloud will be documented in this file.

## [Unreleased]

## [1.6.0] - 2026-07-07

### Fixed

- **Profile-aware API key upload**: `ssh_upload_env` now respects the active Hermes profile, writing keys to `~/.hermes/.env` for `default` and `~/.hermes-profiles/<name>/.env` for named profiles instead of always using `~/.hermes/.env`.
- **AWS deploy uploads keys before bootstrap**: the AWS wizard now reads the active profile's local `.env` and uploads it to the VM before running `bootstrap.sh`, preventing the `API keys must be deployed before running bootstrap` error.
- **GCP/Azure deploy uploads keys before bootstrap**: both GCP and Azure deploy wizards now call `ssh_upload_profile_keys` before `ssh_install`, matching the AWS behavior and ensuring the bootstrap `.env` check passes.
- **EBS volume blocks `destroy`**: removed `prevent_destroy = true` from AWS EBS resources and added an explicit confirmation prompt in `aws_destroy()` so `hermes-agent-cloud destroy` can complete cleanly while warning users about data loss.

### Changed

- `ssh_install` signature changed from `<ip> <user> <key> <script>` to `<ip> <user> <key> <profile> <script>` so bootstrap receives the correct `--profile` argument.
- `ssh_upload_env` signature changed from `<ip> <user> <key> <openrouter> <openai> <anthropic> <gemini>` to `<ip> <user> <key> <profile> <openrouter> <openai> <anthropic> <gemini>`.

### Added

- `ssh_upload_profile_keys` helper that reads the active profile's local `.env` and uploads it to the matching remote profile path.
- `_ssh_active_profile` and `_ssh_local_env_file` internal helpers for profile-aware SSH operations.
- README section documenting profile deploy behavior and AWS EBS destroy behavior.

## [1.5.1] - 2026-06-03

### Fixed
- `update-ip` command: macOS BSD `sed -i` now uses `sed -i ''` to avoid "invalid command code" error on macOS 14+

## [1.1.0] - 2026-05-26

### Added
- Support for Hermes Agent v0.14.0 ("Foundation Release")
- `pip install hermes-agent` noted as alternative install method
- NovitaAI provider support (NOVITA_API_KEY)
- xAI SuperGrok provider support (XAI_API_KEY, no API key needed for SuperGrok)
- Windows beta installation notes
- `hermes proxy` command documented
- `hermes setup --portal` one-command setup documented
- `hermes web` built-in dashboard noted (FastAPI + React SPA)
- `--yolo` / HERMES_YOLO_MODE flag documented
- `hermes claw migrate` command documented

### Changed
- README updated with v0.14.0 command reference
- Website version bumped to 1.1.0

## [1.0.0] - 2026-05-01

### Added
- Initial release
- AWS, Azure, GCP deployment via Bash + Terraform
- Wizard-first CLI with `gum` UI
- Multi-profile support
- Zero plaintext secrets (SSM / Key Vault / Secret Manager)
- Web Dashboard on port 9119, API Gateway on port 8080
