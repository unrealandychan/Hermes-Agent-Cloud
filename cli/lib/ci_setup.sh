#!/usr/bin/env bash
# ci_setup.sh — Generate GitHub Actions workflow for Hermes Agent Cloud
# shellcheck shell=bash

ci_setup_cmd() {
  hermes_banner

  info "GitHub Actions CI/CD Setup"
  echo ""

  # ── Step 1: Select CI features ──────────────────────────────────────────────
  info "Select CI features to include (space to select, enter to confirm):"
  local selections
  selections="$(gum choose --no-limit \
    "Deploy on PR open (staging)" \
    "Destroy on PR close" \
    "Auto-upgrade on merge to main" \
    "Health check on schedule")"

  if [[ -z "$selections" ]]; then
    warn "No features selected. Exiting."
    return 0
  fi

  local do_deploy=false do_destroy=false do_upgrade=false do_health=false
  while IFS= read -r line; do
    case "$line" in
      "Deploy on PR open (staging)")    do_deploy=true  ;;
      "Destroy on PR close")            do_destroy=true ;;
      "Auto-upgrade on merge to main")  do_upgrade=true ;;
      "Health check on schedule")       do_health=true  ;;
    esac
  done <<< "$selections"

  # ── Step 2: Cloud provider ───────────────────────────────────────────────────
  local cloud
  cloud="$(config_get "cloud" 2>/dev/null || true)"
  if [[ -z "$cloud" ]]; then
    local cloud_choice
    cloud_choice="$(choose_one "Choose your cloud provider" "AWS" "GCP" "Azure")"
    cloud="$(echo "$cloud_choice" | tr '[:upper:]' '[:lower:]')"
  fi

  # ── Step 3: Build the 'on:' block ────────────────────────────────────────────
  local on_block=""

  if "$do_deploy" && "$do_destroy"; then
    on_block="${on_block}  pull_request:
    types: [opened, reopened, closed]
"
  elif "$do_deploy"; then
    on_block="${on_block}  pull_request:
    types: [opened, reopened]
"
  elif "$do_destroy"; then
    on_block="${on_block}  pull_request:
    types: [closed]
"
  fi

  if "$do_upgrade"; then
    on_block="${on_block}  push:
    branches: [main]
"
  fi

  if "$do_health"; then
    on_block="${on_block}  schedule:
    - cron: '0 */6 * * *'
"
  fi

  # ── Step 4: Build jobs block ─────────────────────────────────────────────────
  local jobs_block=""

  if "$do_deploy"; then
    jobs_block="${jobs_block}
  deploy-staging:
    if: github.event_name == 'pull_request' && github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install hermes-deploy
        run: curl -fsSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
      - name: Deploy
        env:
          # AWS
          AWS_ACCESS_KEY_ID: \${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          # GCP
          GOOGLE_CREDENTIALS: \${{ secrets.GOOGLE_CREDENTIALS }}
          # Azure
          ARM_CLIENT_ID: \${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: \${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: \${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: \${{ secrets.ARM_TENANT_ID }}
          HERMES_SSH_KEY: \${{ secrets.HERMES_SSH_KEY }}
        run: hermes-deploy deploy --cloud ${cloud} --non-interactive
"
  fi

  if "$do_destroy"; then
    jobs_block="${jobs_block}
  destroy-staging:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install hermes-deploy
        run: curl -fsSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
      - name: Destroy
        env:
          HERMES_SSH_KEY: \${{ secrets.HERMES_SSH_KEY }}
        run: hermes-deploy destroy --cloud ${cloud} --non-interactive --force
"
  fi

  if "$do_upgrade"; then
    jobs_block="${jobs_block}
  upgrade:
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install hermes-deploy
        run: curl -fsSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
      - name: Upgrade
        env:
          HERMES_SSH_KEY: \${{ secrets.HERMES_SSH_KEY }}
        run: hermes-deploy update
"
  fi

  if "$do_health"; then
    jobs_block="${jobs_block}
  health-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check health
        run: hermes-deploy doctor
"
  fi

  # ── Step 5: Assemble final YAML ──────────────────────────────────────────────
  local yaml_content
  yaml_content="$(cat <<YAML
name: Hermes Agent Cloud

on:
${on_block}
jobs:
${jobs_block}
YAML
)"

  # ── Step 6: Save files ───────────────────────────────────────────────────────
  local ci_dir="${HERMES_DEPLOY_HOME}/ci"
  mkdir -p "${ci_dir}"
  printf '%s\n' "${yaml_content}" > "${ci_dir}/hermes-deploy.yml"
  success "Saved to ${ci_dir}/hermes-deploy.yml"

  local cwd_workflows=".github/workflows"
  if [[ -d "${cwd_workflows}" ]]; then
    printf '%s\n' "${yaml_content}" > "${cwd_workflows}/hermes-deploy.yml"
    success "Saved to ${cwd_workflows}/hermes-deploy.yml"
  fi

  # ── Step 7: Print generated YAML ────────────────────────────────────────────
  echo ""
  gum style --foreground 212 --bold "Generated workflow:"
  echo ""
  echo "${yaml_content}"

  # ── Step 8: GitHub Secrets instructions ─────────────────────────────────────
  echo ""
  gum style --foreground 212 --bold "Required GitHub Secrets"
  echo "Add these in: Settings → Secrets and variables → Actions"
  echo ""
  echo "  HERMES_SSH_KEY           — Private SSH key used to connect to your instance"
  echo ""

  case "$cloud" in
    aws)
      echo "  AWS_ACCESS_KEY_ID        — AWS IAM access key"
      echo "  AWS_SECRET_ACCESS_KEY    — AWS IAM secret key"
      ;;
    gcp)
      echo "  GOOGLE_CREDENTIALS       — GCP service account JSON (base64 or raw)"
      ;;
    azure)
      echo "  ARM_CLIENT_ID            — Azure service principal client ID"
      echo "  ARM_CLIENT_SECRET        — Azure service principal client secret"
      echo "  ARM_SUBSCRIPTION_ID      — Azure subscription ID"
      echo "  ARM_TENANT_ID            — Azure tenant ID"
      ;;
  esac

  echo ""
  info "Tip: Copy the YAML above into .github/workflows/hermes-deploy.yml if it wasn't auto-saved."
}
