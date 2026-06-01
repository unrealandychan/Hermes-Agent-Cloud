#!/usr/bin/env bash
# preflight.sh — Dependency checks for Hermes Agent Cloud

_check_cmd() {
  local name="$1"
  local install_hint="$2"
  if ! command -v "$name" &>/dev/null; then
    echo -e "${RED}✗${RESET}  ${BOLD}${name}${RESET} not found"
    echo    "   ${install_hint}"
    PREFLIGHT_PASS=false
  else
    echo -e "${GREEN}✓${RESET}  ${name} $(command -v "$name")"
  fi
}

preflight_check() {
  local PREFLIGHT_PASS=true

  echo ""
  gum style --bold --foreground 212 "Checking dependencies..."
  echo ""

  # ── Self-update check ────────────────────────────────────────────────────
  local latest_deploy_ver
  latest_deploy_ver=$(curl -fsSL --max-time 5 \
    "https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/hermes-deploy" 2>/dev/null \
    | grep -m1 'HERMES_DEPLOY_VERSION=' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
  if [[ -n "$latest_deploy_ver" && "$latest_deploy_ver" != "$HERMES_DEPLOY_VERSION" ]]; then
    warn "hermes-agent-cloud ${HERMES_DEPLOY_VERSION} is installed but ${latest_deploy_ver} is available."
    warn "  Upgrade: curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash"
  else
    echo -e "${GREEN}✓${RESET}  hermes-agent-cloud ${HERMES_DEPLOY_VERSION} (up-to-date)"
  fi
  echo ""

  _check_cmd "gum" \
    "Install: brew install gum  OR  https://github.com/charmbracelet/gum/releases"
  _check_cmd "terraform" \
    "Install: brew install terraform  OR  https://developer.hashicorp.com/terraform/install"
  _check_cmd "jq" \
    "Install: brew install jq  OR  apt-get install jq"

  # Check hermes-agent version (warn if outdated, Homebrew lags behind PyPI)
  if command -v hermes &>/dev/null; then
    local installed_ver
    installed_ver=$(hermes --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
    local latest_ver
    latest_ver=$(curl -fsSL "https://pypi.org/pypi/hermes-agent/json" 2>/dev/null \
      | grep -o '"version":"[^"]*"' | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)
    if [[ -n "$installed_ver" && -n "$latest_ver" && "$installed_ver" != "$latest_ver" ]]; then
      warn "hermes-agent ${installed_ver} is installed but ${latest_ver} is available."
      warn "  Upgrade: pip install --upgrade hermes-agent"
      warn "  (Homebrew may lag behind — pip install is recommended for the latest version)"
    elif [[ -n "$installed_ver" ]]; then
      echo -e "${GREEN}✓${RESET}  hermes-agent ${installed_ver} (up-to-date)"
    fi
  else
    warn "hermes-agent not found on PATH — it will be installed on the VM during bootstrap."
    warn "  To install locally: pip install hermes-agent  OR  curl -sSL https://hermes-agent.nousresearch.com/install.sh | bash"
  fi

  if [[ "$PREFLIGHT_PASS" == "false" ]]; then
    echo ""
    error "Missing dependencies above. Install them then re-run hermes-agent-cloud."
    exit 1
  fi
  echo ""
}

preflight_check_cloud() {
  local cloud="$1"
  local PREFLIGHT_PASS=true

  echo ""
  gum style --bold --foreground 212 "Checking ${cloud} CLI..."
  echo ""

  case "$cloud" in
    aws)
      _check_cmd "aws" \
        "Install: brew install awscli  OR  https://aws.amazon.com/cli/"
      if command -v aws &>/dev/null; then
        if ! aws sts get-caller-identity &>/dev/null; then
          warn "AWS credentials not configured. Run: aws configure"
          PREFLIGHT_PASS=false
        else
          echo -e "${GREEN}✓${RESET}  AWS credentials valid ($(aws sts get-caller-identity --query Account --output text 2>/dev/null))"
        fi
      fi
      ;;
    azure)
      _check_cmd "az" \
        "Install: brew install azure-cli  OR  https://docs.microsoft.com/cli/azure/install-azure-cli"
      if command -v az &>/dev/null; then
        if ! az account show &>/dev/null; then
          warn "No active Azure session. Run: az login"
          # Non-fatal — the wizard handles az login
        else
          echo -e "${GREEN}✓${RESET}  Azure session active ($(az account show --query name -o tsv 2>/dev/null))"
        fi
      fi
      ;;
    gcp)
      _check_cmd "gcloud" \
        "Install: brew install --cask google-cloud-sdk  OR  https://cloud.google.com/sdk/docs/install"
      if command -v gcloud &>/dev/null; then
        local active_account
        active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
        if [[ -z "$active_account" ]]; then
          warn "No active GCP session. Run: gcloud auth login"
          # Non-fatal — the wizard handles gcloud auth login
        else
          echo -e "${GREEN}✓${RESET}  GCP session active (${active_account})"
        fi
      fi
      ;;
  esac

  if [[ "$PREFLIGHT_PASS" == "false" ]]; then
    echo ""
    error "Missing cloud CLI. Install and authenticate, then re-run."
    exit 1
  fi
  echo ""
}
