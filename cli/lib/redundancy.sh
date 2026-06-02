#!/usr/bin/env bash
# redundancy.sh — Multi-cloud redundancy and failover helpers

# ── Validate a cloud provider name ───────────────────────────────────────────
_redundancy_validate_cloud() {
  local cloud="$1"
  case "$cloud" in
    aws|gcp|azure) return 0 ;;
    *) error "Unsupported cloud provider: '${cloud}'. Must be aws, gcp, or azure."; return 1 ;;
  esac
}

# ── Call the appropriate cloud deploy function ────────────────────────────────
_redundancy_call_deploy() {
  local cloud="$1"
  case "$cloud" in
    aws)   aws_deploy   ;;
    gcp)   gcp_deploy   ;;
    azure) azure_deploy ;;
  esac
}

# ── Deploy to two clouds and configure failover ───────────────────────────────
# redundancy_deploy <primary_cloud> <secondary_cloud>
redundancy_deploy() {
  local primary_cloud="$1"
  local secondary_cloud="$2"

  # Validate both clouds
  _redundancy_validate_cloud "$primary_cloud"  || return 1
  _redundancy_validate_cloud "$secondary_cloud" || return 1

  if [[ "$primary_cloud" == "$secondary_cloud" ]]; then
    error "Primary and secondary clouds must be different (both are '${primary_cloud}')."
    return 1
  fi

  local hermes_version
  hermes_version="${HERMES_VERSION:-latest}"

  # ── Deploy primary ────────────────────────────────────────────────────────
  info "Deploying primary instance on ${primary_cloud}..."
  CLOUD="$primary_cloud"
  _redundancy_call_deploy "$primary_cloud"

  local primary_ip
  primary_ip=$(_get_live_ip "$primary_cloud")
  if [[ -z "$primary_ip" ]]; then
    error "Could not determine primary IP after deploy on ${primary_cloud}."
    return 1
  fi
  config_set "redundant_primary_ip" "$primary_ip"
  success "Primary deployed: ${primary_ip} (${primary_cloud})"

  # ── Deploy secondary ──────────────────────────────────────────────────────
  info "Deploying secondary instance on ${secondary_cloud}..."
  # CLOUD is read by the deploy functions via global scope
  # shellcheck disable=SC2034
  CLOUD="$secondary_cloud"
  _redundancy_call_deploy "$secondary_cloud"

  local secondary_ip
  secondary_ip=$(_get_live_ip "$secondary_cloud")
  if [[ -z "$secondary_ip" ]]; then
    error "Could not determine secondary IP after deploy on ${secondary_cloud}."
    return 1
  fi
  config_set "redundant_secondary_ip"    "$secondary_ip"
  config_set "redundant_secondary_cloud" "$secondary_cloud"
  config_set "active_ip"                 "$primary_ip"
  success "Secondary deployed: ${secondary_ip} (${secondary_cloud})"

  # ── Bootstrap both VMs ────────────────────────────────────────────────────
  local ssh_key
  ssh_key=$(config_get "ssh_key_path" 2>/dev/null || echo "")
  ssh_key="${ssh_key/#\~/$HOME}"

  if [[ -n "$ssh_key" ]]; then
    local bootstrap_script="${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh"
    if [[ -f "$bootstrap_script" ]]; then
      info "Running bootstrap.sh on primary VM (${primary_ip}) with HERMES_VERSION=${hermes_version}..."
      HERMES_VERSION="$hermes_version" ssh_install "$primary_ip" "ubuntu" "$ssh_key" "$bootstrap_script"

      info "Running bootstrap.sh on secondary VM (${secondary_ip}) with HERMES_VERSION=${hermes_version}..."
      HERMES_VERSION="$hermes_version" ssh_install "$secondary_ip" "ubuntu" "$ssh_key" "$bootstrap_script"
    else
      warn "bootstrap.sh not found at ${bootstrap_script} — skipping remote bootstrap."
    fi
  else
    warn "No SSH key configured — skipping remote bootstrap."
  fi

  # ── Summary ───────────────────────────────────────────────────────────────
  echo ""
  gum style --foreground 212 --bold "  ─── Multi-Cloud Redundancy Summary ──────────────────────────"
  printf "  %-22s %s\n" "Primary cloud:"   "${primary_cloud}"
  printf "  %-22s %s\n" "Primary IP:"      "${primary_ip}"
  printf "  %-22s %s\n" "Secondary cloud:" "${secondary_cloud}"
  printf "  %-22s %s\n" "Secondary IP:"    "${secondary_ip}"
  printf "  %-22s %s\n" "Active endpoint:" "http://${primary_ip}:8080"
  printf "  %-22s %s\n" "Failover command:" "hermes-deploy redundancy failover"
  echo ""
  success "Multi-cloud redundancy configured. Primary is active."
}

# ── Show status of both VMs ───────────────────────────────────────────────────
redundancy_status() {
  config_load
  local primary_ip secondary_ip secondary_cloud active_ip
  primary_ip=$(config_get "redundant_primary_ip"    2>/dev/null || echo "")
  secondary_ip=$(config_get "redundant_secondary_ip" 2>/dev/null || echo "")
  secondary_cloud=$(config_get "redundant_secondary_cloud" 2>/dev/null || echo "")
  active_ip=$(config_get "active_ip" 2>/dev/null || echo "$primary_ip")

  if [[ -z "$primary_ip" || -z "$secondary_ip" ]]; then
    error "No redundant deployment found. Run: hermes-deploy deploy --cloud <primary> --redundant <secondary>"
    return 1
  fi

  echo ""
  gum style --foreground 212 --bold "  ─── Multi-Cloud Redundancy Status ───────────────────────────"
  echo ""

  # Check primary
  local primary_health secondary_health
  printf "  Checking primary  (%s)... " "$primary_ip"
  if curl -sf --max-time 5 "http://${primary_ip}:8080/health" &>/dev/null; then
    primary_health="healthy"
    printf "\033[32m✓ healthy\033[0m\n"
  else
    primary_health="unreachable"
    printf "\033[31m✗ unreachable\033[0m\n"
  fi

  # Check secondary
  printf "  Checking secondary (%s / %s)... " "$secondary_ip" "$secondary_cloud"
  if curl -sf --max-time 5 "http://${secondary_ip}:8080/health" &>/dev/null; then
    secondary_health="healthy"
    printf "\033[32m✓ healthy\033[0m\n"
  else
    secondary_health="unreachable"
    printf "\033[31m✗ unreachable\033[0m\n"
  fi

  echo ""
  printf "  %-22s %s\n" "Primary IP:"      "${primary_ip} (${primary_health})"
  printf "  %-22s %s\n" "Secondary IP:"    "${secondary_ip} (${secondary_cloud} / ${secondary_health})"
  printf "  %-22s %s\n" "Active endpoint:" "http://${active_ip}:8080"

  if [[ "$active_ip" == "$primary_ip" ]]; then
    printf "  %-22s %s\n" "Active node:" "primary"
  else
    printf "  %-22s %s\n" "Active node:" "secondary (failover)"
  fi
  echo ""
}

# ── Fail over to secondary ────────────────────────────────────────────────────
redundancy_failover() {
  config_load
  local secondary_ip secondary_cloud ssh_key
  secondary_ip=$(config_get "redundant_secondary_ip"    2>/dev/null || echo "")
  secondary_cloud=$(config_get "redundant_secondary_cloud" 2>/dev/null || echo "")

  if [[ -z "$secondary_ip" ]]; then
    error "No secondary deployment found. Run: hermes-deploy deploy --cloud <primary> --redundant <secondary>"
    return 1
  fi

  info "Verifying secondary VM health at ${secondary_ip}..."

  # Verify health via HTTP
  if ! curl -sf --max-time 10 "http://${secondary_ip}:8080/health" &>/dev/null; then
    # Also try via SSH
    ssh_key=$(config_get "ssh_key_path" 2>/dev/null || echo "")
    ssh_key="${ssh_key/#\~/$HOME}"
    if [[ -n "$ssh_key" ]]; then
      warn "/health HTTP check failed; trying SSH verification..."
      if ! ssh_run_cmd "$secondary_ip" "ubuntu" "$ssh_key" \
            'systemctl is-active --quiet hermes-gateway || exit 1'; then
        error "Secondary VM at ${secondary_ip} is not healthy. Failover aborted."
        return 1
      fi
      warn "hermes-gateway is running on secondary but HTTP /health did not respond."
    else
      error "Secondary VM at ${secondary_ip} failed health check and no SSH key configured. Failover aborted."
      return 1
    fi
  fi

  config_set "active_ip" "$secondary_ip"

  echo ""
  success "Failover complete!"
  printf "  %-22s %s\n" "New active endpoint:" "http://${secondary_ip}:8080"
  printf "  %-22s %s\n" "Cloud:"               "${secondary_cloud}"
  echo ""
  info "Update any DNS / load balancer records to point to ${secondary_ip}."
  info "To fail back to primary, update active_ip with: hermes-deploy redundancy failover (after restoring primary)"
}

# ── Entry point ───────────────────────────────────────────────────────────────
cmd_redundancy() {
  local subcmd="${1:-status}"
  shift || true

  case "$subcmd" in
    status)   redundancy_status   ;;
    failover) redundancy_failover ;;
    *)
      error "Unknown redundancy subcommand: '${subcmd}'. Use: status | failover"
      exit 1
      ;;
  esac
}
