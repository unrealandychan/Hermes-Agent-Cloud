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

# ─── Upload API keys to ~/.hermes/.env ──────────────────────────────────────
# ssh_upload_env <ip> <user> <key_path> <openrouter> <openai> <anthropic> <gemini>
# Keys are piped via stdin — they are never embedded in the command string.
ssh_upload_env() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local openrouter_key="$4"
  local openai_key="$5"
  local anthropic_key="$6"
  local gemini_key="$7"

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

  warn "Uploading API keys to ${user}@${ip}:~/.hermes/.env ..."
  # Pipe via stdin — value never appears in the remote command string.
  printf '%s' "$env_content" | ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${ip}" \
      'mkdir -p ~/.hermes && cat > ~/.hermes/.env && chmod 600 ~/.hermes/.env'

  success "API keys uploaded."
}

# ─── Run bootstrap.sh on the remote VM via SSH ──────────────────────────────
# ssh_install <ip> <user> <key_path> <bootstrap_script_path>
# Output is streamed directly to the terminal so the user sees every step.
ssh_install() {
  local ip="$1"
  local user="$2"
  local key="$3"
  local bootstrap="$4"

  key="${key/#\~/$HOME}"
  _fix_key_permissions "$key"

  echo ""
  gum style --foreground 212 --bold "  ─── Installing Hermes Agent via SSH ────────────────────────"
  warn "Streaming install output from ${ip} (this takes ~3-5 min)..."
  echo ""

  ssh -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=15 \
      "${user}@${ip}" \
      "sudo bash -s -- --user '${user}'" < "$bootstrap"

  echo ""
  success "Remote installation complete."
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
