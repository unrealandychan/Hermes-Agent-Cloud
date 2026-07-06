#!/usr/bin/env bash
# ssh.sh — SSH helpers for post-Terraform installation

# ── Fix SSH key permissions (cross-platform) ─────────────────────────────────
# On Linux/macOS, chmod 600 is sufficient.
# On WSL2, keys stored on the Windows filesystem (/mnt/c/...) have NTFS
# permissions that override Unix chmod. We detect this and use icacls via
# cmd.exe to lock down the key, then warn the user if that also fails.
_fix_key_permissions() {
  local key="$1"

  # If the key is on a Windows-mounted path (WSL2), use icacls
  if [[ "$key" == /mnt/* ]] && command -v cmd.exe &>/dev/null 2>&1; then
    # Convert /mnt/c/Users/... → C:\Users\...
    local win_path
    win_path="$(wslpath -w "$key" 2>/dev/null || true)"
    if [[ -n "$win_path" ]]; then
      local win_user
      win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || true)"
      if [[ -n "$win_user" ]]; then
        cmd.exe /c "icacls \"${win_path}\" /inheritance:r /grant:r \"${win_user}:R\" >NUL 2>&1" || true
        return
      fi
    fi
    warn "Could not fix key permissions via icacls. If SSH fails, move your key file out of /mnt/c/ (e.g. to ~/keys/) or run: chmod 600 \"$key\""
    return
  fi

  # Standard Unix path
  chmod 600 "$key" 2>/dev/null || warn "Could not chmod 600 $key — SSH may refuse the key"
}

# ─── Wait for SSH to become available ───────────────────────────────────────
# ssh_wait <ip> <user> <key_path> [timeout_seconds]
ssh_wait() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local timeout="${4:-300}"
  local elapsed=0
  local interval=10

  # Expand tilde
  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  warn "Waiting for SSH on ${ip} (up to ${timeout}s)..."
  while (( elapsed < timeout )); do
    if ssh -i "$key" \
         -o StrictHostKeyChecking=accept-new \
         -o ConnectTimeout=5 \
         -o BatchMode=yes \
         "${user}@${ip}" exit 0 &>/dev/null; then
      success "SSH is ready on ${ip}"
      return 0
    fi
    sleep "$interval"
    (( elapsed += interval ))
  done

  error "SSH did not become available on ${ip} after ${timeout}s"
  return 1
}

# ─── Upload API keys to the Hermes profile .env on the remote VM ─────────────
# ssh_upload_env <ip> <user> <key_path> <profile> <openrouter> <openai> <anthropic> <gemini>
# Keys are piped via stdin — they are never embedded in the command string.
# The profile argument controls the destination directory:
#   "default" -> ~/.hermes/.env
#   "<name>"  -> ~/.hermes-profiles/<name>/.env
ssh_upload_env() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local profile_name="${4:-default}"
  local openrouter_key="$5"
  local openai_key="$6"
  local anthropic_key="$7"
  local gemini_key="$8"

  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  # Build .env content — only include lines for non-empty keys.
  # printf is used instead of echo to avoid shell expansion of the values.
  local env_content
  env_content=$(
    [[ -n "$openrouter_key" ]] && printf 'OPENROUTER_API_KEY=%s\n' "$openrouter_key" || true
    [[ -n "$openai_key"     ]] && printf 'OPENAI_API_KEY=%s\n'     "$openai_key"     || true
    [[ -n "$anthropic_key"  ]] && printf 'ANTHROPIC_API_KEY=%s\n'  "$anthropic_key"  || true
    [[ -n "$gemini_key"     ]] && printf 'GEMINI_API_KEY=%s\n'     "$gemini_key"     || true
  )

  if [[ -z "$env_content" ]]; then
    warn "No API keys provided — skipping remote .env upload."
    return 0
  fi

  local env_dir
  if [[ "$profile_name" == "default" ]]; then
    env_dir="/home/${user}/.hermes"
  else
    env_dir="/home/${user}/.hermes-profiles/${profile_name}"
  fi

  warn "Uploading API keys to ${user}@${ip}:${env_dir}/.env (profile: ${profile_name}) ..."
  # Pipe via stdin — value never appears in the remote command string.
  printf '%s' "$env_content" | ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${ip}" \
      "mkdir -p ${env_dir} && cat > ${env_dir}/.env && chmod 600 ${env_dir}/.env"

  success "API keys uploaded for profile '${profile_name}'."
}

# ─── Run bootstrap.sh on the remote VM via SSH ──────────────────────
# ssh_install <ip> <user> <key_path> <profile> <bootstrap_script_path>
# Output is streamed directly to the terminal so the user sees every step.
ssh_install() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local profile_name="${4:-default}"
  local bootstrap="$5"

  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  echo ""
  gum style --foreground 212 --bold "  ─── Installing Hermes Agent via SSH ───────────────────"
  warn "Streaming install output from ${ip} (this takes ~3-5 min)..."
  warn "Profile: ${profile_name}"
  echo ""

  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=15 \
      "${user}@${ip}" \
      "sudo bash -s -- --user '${user}' --profile '${profile_name}'" < "$bootstrap"

  echo ""
  success "Remote installation complete for profile '${profile_name}'."
}

# Return the active Hermes profile name (defaults to "default").
_ssh_active_profile() {
  if command -v profile_get_active &>/dev/null; then
    profile_get_active
  else
    echo "default"
  fi
}

# Return the path to the named profile's .env file on the local machine.
_ssh_local_env_file() {
  local profile_name="${1:-$(_ssh_active_profile)}"
  if [[ "$profile_name" == "default" ]]; then
    echo "${HOME}/.hermes/.env"
  else
    echo "${HOME}/.hermes-profiles/${profile_name}/.env"
  fi
}

# Read keys from the local profile .env and upload them to the remote VM.
# ssh_upload_profile_keys <ip> <user> <key_path>
ssh_upload_profile_keys() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local profile_name="$(_ssh_active_profile)"
  local env_file
  env_file="$(_ssh_local_env_file "$profile_name")"

  if [[ ! -f "$env_file" ]]; then
    warn "Profile '${profile_name}' has no local .env file at ${env_file}."
    warn "You will need to set API keys on the VM before Hermes can start."
    warn "Run: hermes-agent-cloud secrets"
    return 0
  fi

  local openrouter_key="" openai_key="" anthropic_key="" gemini_key=""
  while IFS='=' read -r k v; do
    [[ -z "$k" || "$k" == \#* ]] && continue
    case "$k" in
      OPENROUTER_API_KEY) openrouter_key="$v" ;;
      OPENAI_API_KEY)     openai_key="$v"     ;;
      ANTHROPIC_API_KEY)  anthropic_key="$v"  ;;
      GEMINI_API_KEY)     gemini_key="$v"     ;;
    esac
  done < "$env_file"

  ssh_upload_env "$ip" "$user" "$key" "$profile_name" \
    "$openrouter_key" "$openai_key" "$anthropic_key" "$gemini_key"
}

# ─── Update a single key in ~/.hermes/.env and restart the gateway ──────────
# ssh_update_key <ip> <user> <key_path> <env_var_name> <new_value>
# The new value is passed via stdin to avoid command injection.
ssh_update_key() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local var_name="$4"
  local new_value="$5"

  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  warn "Updating ${var_name} on ${user}@${ip} ..."
  # Pass the new value via stdin; only the safe alphanumeric var_name is
  # embedded in the command string.
  printf '%s' "$new_value" | ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${ip}" \
      "read -r val
       sed -i '/^${var_name}=/d' ~/.hermes/.env
       printf '%s=%s\n' '${var_name}' \"\$val\" >> ~/.hermes/.env
       chmod 600 ~/.hermes/.env
       sudo systemctl restart hermes-gateway"

  success "${var_name} updated and hermes-gateway restarted."
}

# ─── Run a command on the remote VM and stream output ───────────────────────
# ssh_run_cmd <ip> <user> <key_path> <remote_command>
ssh_run_cmd() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local remote_cmd="$4"

  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=15 \
      -o ServerAliveInterval=30 \
      "${user}@${ip}" \
      "$remote_cmd"
}
