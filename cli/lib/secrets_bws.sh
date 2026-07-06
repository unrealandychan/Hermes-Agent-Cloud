#!/usr/bin/env bash
# lib/secrets_bws.sh — Bitwarden Secrets Manager integration for hermes-deploy
# shellcheck shell=bash

# ─── Check bws CLI installation ─────────────────────────────────────────────
bws_check() {
  if command -v bws &>/dev/null; then
    return 0
  fi
  error "bws CLI is not installed."
  echo ""
  gum style --bold --foreground 212 "Install Bitwarden Secrets Manager CLI:"
  echo ""
  gum style --foreground 245 "  macOS:   brew install bitwarden/tools/bws"
  gum style --foreground 245 "  Cargo:   cargo install bws"
  gum style --foreground 245 "  Other:   https://github.com/bitwarden/sdk/releases"
  echo ""
  return 1
}

# ─── Load secrets from BWS into shell exports ────────────────────────────────
# Requires BWS_ACCESS_TOKEN to be set in the environment.
# Outputs eval-able lines: export KEY=VALUE  (only for hermes-relevant keys)
bws_load_secrets() {
  if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    error "BWS_ACCESS_TOKEN is not set."
    return 1
  fi

  local json
  if ! json=$(BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" bws secret list --output json 2>&1); then
    error "bws secret list failed: $json"
    return 1
  fi

  # Filter for relevant keys and emit export lines.
  # jq: select keys matching our known names or starting with HERMES_
  echo "$json" | jq -r '
    .[] |
    select(
      .key == "OPENROUTER_API_KEY" or
      .key == "OPENAI_API_KEY" or
      .key == "ANTHROPIC_API_KEY" or
      .key == "GEMINI_API_KEY" or
      (.key | startswith("HERMES_"))
    ) |
    "export " + .key + "=" + (.value | @sh)
  '
}

# ─── Interactive BWS wizard ──────────────────────────────────────────────────
cmd_secrets_bws() {
  config_load
  [[ -z "${CLOUD:-}" ]] && CLOUD="$(config_get "cloud")"
  [[ -z "${CLOUD:-}" ]] && { error "No deployment found. Run: hermes-agent-cloud deploy"; exit 1; }

  gum style --bold --foreground 212 "Bitwarden Secrets Manager — Sync API Keys"
  echo ""

  # ── 1. Get BWS_ACCESS_TOKEN ──────────────────────────────────────────────
  if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    # Try saved token from config
    local saved_token
    saved_token="$(config_get "bws_access_token" 2>/dev/null || true)"
    if [[ -n "$saved_token" ]]; then
      info "Using saved BWS_ACCESS_TOKEN from config."
      BWS_ACCESS_TOKEN="$saved_token"
    else
      BWS_ACCESS_TOKEN=$(gum input \
        --placeholder "Paste your BWS_ACCESS_TOKEN here" \
        --password \
        --prompt "  Token › " \
        --header "Enter your Bitwarden Service Account Token:" \
        --header.foreground 245)
      [[ -z "$BWS_ACCESS_TOKEN" ]] && { warn "No token provided. Aborted."; return 1; }
    fi
  fi

  export BWS_ACCESS_TOKEN

  # ── 2. Check bws is installed ────────────────────────────────────────────
  bws_check || return 1

  # ── 3. Fetch secrets from the vault ─────────────────────────────────────
  info "Fetching secrets from Bitwarden vault..."
  local json
  if ! json=$(BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" bws secret list --output json 2>&1); then
    error "Failed to list secrets: $json"
    return 1
  fi

  # Build an array of available secret keys
  local -a all_keys
  while IFS= read -r k; do
    all_keys+=("$k")
  done < <(echo "$json" | jq -r '.[].key' | sort)

  if [[ ${#all_keys[@]} -eq 0 ]]; then
    warn "No secrets found in the vault."
    return 1
  fi

  echo ""
  gum style --foreground 245 "Available secrets in vault (${#all_keys[@]} total):"
  echo ""

  # ── 4. Let user pick which secrets to sync ───────────────────────────────
  local chosen
  chosen=$(printf '%s\n' "${all_keys[@]}" | gum choose \
    --no-limit \
    --header "Select secrets to sync to your VM (space to toggle, enter to confirm):" \
    --header.foreground 245 \
    --cursor.foreground 212 \
    --selected.foreground 212)

  if [[ -z "$chosen" ]]; then
    warn "No secrets selected. Aborted."
    return 1
  fi

  # ── 5. Save token to local config for future runs ────────────────────────
  config_set "bws_access_token" "$BWS_ACCESS_TOKEN"
  success "BWS_ACCESS_TOKEN saved to local config."

  # ── 6. Extract values for the selected keys ──────────────────────────────
  local openrouter_key="" openai_key="" anthropic_key="" gemini_key=""
  local -a extra_pairs=()  # for HERMES_* and any other selected keys

  while IFS= read -r key; do
    local val
    val=$(echo "$json" | jq -r --arg k "$key" '.[] | select(.key == $k) | .value')
    case "$key" in
      OPENROUTER_API_KEY) openrouter_key="$val" ;;
      OPENAI_API_KEY)     openai_key="$val"     ;;
      ANTHROPIC_API_KEY)  anthropic_key="$val"  ;;
      GEMINI_API_KEY)     gemini_key="$val"     ;;
      *)                  extra_pairs+=("$key" "$val") ;;
    esac
  done <<< "$chosen"

  # ── 7. Get VM connection info ─────────────────────────────────────────────
  local ip ssh_key ssh_user="ubuntu"
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"

  [[ -z "$ip" ]]      && { error "Cannot determine VM IP from config."; return 1; }
  [[ -z "$ssh_key" ]] && { error "Cannot determine SSH key from config."; return 1; }

  # ─── 8. Push the four standard keys via ssh_upload_env ────────────────
  if [[ -n "$openrouter_key" || -n "$openai_key" || -n "$anthropic_key" || -n "$gemini_key" ]]; then
    local active_profile
    active_profile="$(_ssh_active_profile)"
    ssh_upload_env "$ip" "$ssh_user" "$ssh_key" "$active_profile" \
      "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key"
  fi

  # ── 9. Push HERMES_* and extra keys individually ──────────────────────────
  local i
  for (( i=0; i<${#extra_pairs[@]}; i+=2 )); do
    local ekey="${extra_pairs[$i]}"
    local eval="${extra_pairs[$((i+1))]}"
    ssh_update_key "$ip" "$ssh_user" "$ssh_key" "$ekey" "$eval"
  done

  # ── 10. Save BWS_ACCESS_TOKEN to the VM's ~/.hermes/.env ─────────────────
  info "Saving BWS_ACCESS_TOKEN to VM ~/.hermes/.env ..."
  ssh_update_key "$ip" "$ssh_user" "$ssh_key" "BWS_ACCESS_TOKEN" "$BWS_ACCESS_TOKEN"

  echo ""
  success "Bitwarden secrets synced to VM successfully."
}
