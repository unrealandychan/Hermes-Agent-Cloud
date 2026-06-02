#!/usr/bin/env bash
# lib/backup.sh — Snapshot Hermes Agent data to local + optional cloud storage
# Implements: hermes-deploy backup

backup_cmd() {
  config_load
  [[ -z "$CLOUD" ]] && CLOUD="$(config_get "cloud")"
  [[ -z "$CLOUD" ]] && { error "No deployment found. Run: hermes-deploy deploy"; exit 1; }

  hermes_banner

  local ip ssh_key
  info "Fetching current IP for ${CLOUD}..."
  ip=$(_get_live_ip "$CLOUD")
  [[ -z "$ip" ]] && { error "Cannot determine VM IP. Check: hermes-deploy status"; exit 1; }

  ssh_key=$(config_get "ssh_key_path")
  ssh_key="${ssh_key/#\~/$HOME}"

  # ── Create tarball on the remote VM ────────────────────────────────────────
  info "Creating backup archive on remote VM (${ip})..."
  ssh_run_cmd "$ip" "ubuntu" "$ssh_key" '
    set -e
    PATHS=""
    for p in \
      "$HOME/.hermes/skills" \
      "$HOME/.hermes/memory" \
      "$HOME/.hermes/.env" \
      "$HOME/.hermes/config"; do
      [[ -e "$p" ]] && PATHS="$PATHS $p"
    done
    if [[ -z "$PATHS" ]]; then
      echo "No hermes data found at ~/.hermes — nothing to back up." >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    tar -czf /tmp/hermes-backup.tar.gz $PATHS
    echo "Remote archive created: /tmp/hermes-backup.tar.gz"
    du -sh /tmp/hermes-backup.tar.gz
  '

  # ── Download tarball locally ────────────────────────────────────────────────
  local backup_dir timestamp local_path
  backup_dir="${HOME}/.hermes-agent-cloud/backups"
  mkdir -p "$backup_dir"
  timestamp="$(date +%Y-%m-%d-%H%M)"
  local_path="${backup_dir}/hermes-backup-${timestamp}.tar.gz"

  info "Downloading backup to ${local_path} ..."
  scp -i "$ssh_key" \
      -o StrictHostKeyChecking=accept-new \
      "ubuntu@${ip}:/tmp/hermes-backup.tar.gz" \
      "$local_path"

  # Clean up remote temp file
  ssh_run_cmd "$ip" "ubuntu" "$ssh_key" 'rm -f /tmp/hermes-backup.tar.gz' || true

  success "Backup downloaded: ${local_path}"

  # ── Optional cloud upload ───────────────────────────────────────────────────
  local bucket
  bucket="$(config_get "backup_bucket" 2>/dev/null || echo "")"

  if [[ -z "$bucket" ]]; then
    if command -v gum &>/dev/null; then
      warn "No backup_bucket configured."
      if gum confirm "Set a cloud storage bucket/container for remote backups?"; then
        bucket="$(gum input --placeholder "e.g. my-hermes-backups")"
        if [[ -n "$bucket" ]]; then
          config_set "backup_bucket" "$bucket"
          info "Saved backup_bucket = ${bucket}"
        fi
      fi
    fi
  fi

  if [[ -z "$bucket" ]]; then
    info "Skipping cloud upload (no backup_bucket set)."
    echo ""
    _backup_summary "$local_path" ""
    return 0
  fi

  local archive_name cloud_url
  archive_name="$(basename "$local_path")"

  case "$CLOUD" in
    aws)
      cloud_url="s3://${bucket}/hermes-backups/${archive_name}"
      info "Uploading to ${cloud_url} ..."
      aws s3 cp "$local_path" "$cloud_url"
      ;;
    gcp)
      cloud_url="gs://${bucket}/hermes-backups/${archive_name}"
      info "Uploading to ${cloud_url} ..."
      gcloud storage cp "$local_path" "$cloud_url"
      ;;
    azure)
      cloud_url="https://<storage-account>.blob.core.windows.net/hermes-backups/${archive_name}"
      info "Uploading to container hermes-backups in ${bucket} ..."
      az storage blob upload \
        --account-name "$bucket" \
        --container-name "hermes-backups" \
        --name "$archive_name" \
        --file "$local_path" \
        --auth-mode login
      cloud_url="az://${bucket}/hermes-backups/${archive_name}"
      ;;
    *)
      warn "Cloud upload not supported for provider: ${CLOUD}"
      cloud_url=""
      ;;
  esac

  echo ""
  _backup_summary "$local_path" "$cloud_url"
}

_backup_summary() {
  local local_path="$1"
  local cloud_url="$2"

  gum style --foreground 212 --bold "Backup Complete"
  printf "  %-14s %s\n" "Local path:"  "$local_path"
  if [[ -n "$cloud_url" ]]; then
    printf "  %-14s %s\n" "Cloud URL:"   "$cloud_url"
  fi
  local size
  size="$(du -sh "$local_path" 2>/dev/null | cut -f1 || echo "unknown")"
  printf "  %-14s %s\n" "Size:"        "$size"
  echo ""
}
