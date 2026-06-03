# Changelog

All notable changes to Hermes Agent Cloud will be documented in this file.

## [Unreleased]

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
