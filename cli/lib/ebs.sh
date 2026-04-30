#!/usr/bin/env bash
# ebs.sh — Persistent EBS data volume management for Hermes Agent Cloud
#
# Subcommands:
#   hermes-agent-cloud ebs status   — show volume info and mount state
#   hermes-agent-cloud ebs detach   — safely unmount + detach from current instance
#   hermes-agent-cloud ebs attach   — attach (and mount) to the current/new instance
#   hermes-agent-cloud ebs migrate  — guided workflow: detach → new instance → reattach

# ── Helpers ──────────────────────────────────────────────────────────────────

_ebs_require_aws() {
  if ! command -v aws &>/dev/null; then
    error "AWS CLI is not installed. Install it from https://aws.amazon.com/cli/"
    exit 1
  fi
}

_ebs_load_config() {
  _ebs_require_aws
  REGION="$(config_get "region")"
  EBS_VOLUME_ID="$(config_get "ebs_volume_id" 2>/dev/null || echo "")"
  INSTANCE_ID="$(config_get "instance_id" 2>/dev/null || echo "")"
  SSH_KEY="$(config_get "ssh_key_path" 2>/dev/null || echo "~/.ssh/id_rsa")"
  PUBLIC_IP="$(config_get "public_ip" 2>/dev/null || echo "")"

  if [[ -z "$EBS_VOLUME_ID" ]]; then
    # Try reading from terraform output
    local tf_dir
    tf_dir="$(config_get "tf_dir" 2>/dev/null || echo "")"
    if [[ -n "$tf_dir" && -d "$tf_dir" ]]; then
      EBS_VOLUME_ID=$(terraform -chdir="$tf_dir" output -raw ebs_volume_id 2>/dev/null || echo "")
      [[ -n "$EBS_VOLUME_ID" && "$EBS_VOLUME_ID" != "EBS not enabled" ]] && \
        config_set "ebs_volume_id" "$EBS_VOLUME_ID"
    fi
  fi

  if [[ -z "$EBS_VOLUME_ID" || "$EBS_VOLUME_ID" == "EBS not enabled" ]]; then
    error "No EBS volume found in config. Was EBS enabled at deploy time?"
    echo ""
    gum style --foreground 245 "  To check, run:  hermes-agent-cloud status"
    exit 1
  fi
}

# ── Status ────────────────────────────────────────────────────────────────────
ebs_status() {
  hermes_banner
  _ebs_load_config

  warn "Fetching EBS volume details..."
  local vol_json
  vol_json=$(aws ec2 describe-volumes \
    --volume-ids "$EBS_VOLUME_ID" \
    --region     "$REGION" \
    --output json 2>/dev/null)

  if [[ -z "$vol_json" ]]; then
    error "Could not fetch volume info. Check your AWS credentials and region."
    exit 1
  fi

  local state size az vol_type encrypted
  state=$(echo "$vol_json" | python3 -c "import sys,json; v=json.load(sys.stdin)['Volumes'][0]; print(v['State'])")
  size=$(echo  "$vol_json" | python3 -c "import sys,json; v=json.load(sys.stdin)['Volumes'][0]; print(v['Size'])")
  az=$(echo    "$vol_json" | python3 -c "import sys,json; v=json.load(sys.stdin)['Volumes'][0]; print(v['AvailabilityZone'])")
  vol_type=$(echo "$vol_json" | python3 -c "import sys,json; v=json.load(sys.stdin)['Volumes'][0]; print(v['VolumeType'])")
  encrypted=$(echo "$vol_json" | python3 -c "import sys,json; v=json.load(sys.stdin)['Volumes'][0]; print('yes' if v['Encrypted'] else 'no')")

  local attached_to="—  (detached)"
  local attach_device="—"
  local attach_state
  attach_state=$(echo "$vol_json" | python3 -c "
import sys,json
v=json.load(sys.stdin)['Volumes'][0]
atts = v.get('Attachments',[])
if atts:
  a=atts[0]
  print(a['InstanceId']+'  '+a['Device']+'  '+a['State'])
else:
  print('')
" 2>/dev/null)

  if [[ -n "$attach_state" ]]; then
    attached_to=$(echo "$attach_state" | awk '{print $1}')
    attach_device=$(echo "$attach_state" | awk '{print $2}')
    local att_st
    att_st=$(echo "$attach_state" | awk '{print $3}')
    state="${state} / attachment: ${att_st}"
  fi

  summary_table \
    "Volume ID"   "$EBS_VOLUME_ID" \
    "State"       "$state" \
    "Size"        "${size} GB" \
    "Type"        "$vol_type  (gp3 — 3000 IOPS / 125 MiB/s)" \
    "AZ"          "$az" \
    "Encrypted"   "$encrypted" \
    "Attached to" "$attached_to" \
    "Device"      "$attach_device" \
    "Mount path"  "/mnt/hermes-data  (on instance)"

  echo ""
  gum style --foreground 245 \
    "  ℹ  This volume persists independently of the EC2 instance." \
    "     hermes-agent-cloud ebs detach   — unmount and detach safely" \
    "     hermes-agent-cloud ebs attach   — re-attach to current or new instance" \
    "     hermes-agent-cloud ebs migrate  — guided instance-upgrade workflow"
  echo ""
}

# ── Detach ────────────────────────────────────────────────────────────────────
ebs_detach() {
  hermes_banner
  _ebs_load_config

  if [[ -z "$PUBLIC_IP" ]]; then
    error "No public IP in config. Is the instance running?"
    exit 1
  fi

  local ssh_key_expanded="${SSH_KEY/#\~/$HOME}"

  gum style --bold --foreground 212 "  EBS Detach — Volume: ${EBS_VOLUME_ID}"
  echo ""
  gum style --foreground 245 \
    "  This will:" \
    "    1. Flush writes and unmount /mnt/hermes-data on the instance" \
    "    2. Detach the EBS volume (volume stays in AWS, data is safe)" \
    ""
  gum confirm "Proceed with detach?" || { warn "Aborted."; exit 0; }

  # Step 1 — Unmount on the instance via SSH
  warn "Unmounting /mnt/hermes-data on ${PUBLIC_IP} ..."
  ssh -i "$ssh_key_expanded" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "ubuntu@${PUBLIC_IP}" \
      "sudo sync && sudo umount /mnt/hermes-data && echo 'unmounted'" \
  || { error "Unmount failed. The instance may be unreachable or the volume is not mounted."; exit 1; }
  success "Volume unmounted cleanly."

  # Step 2 — AWS detach
  warn "Detaching ${EBS_VOLUME_ID} from ${INSTANCE_ID} ..."
  aws ec2 detach-volume \
    --volume-id  "$EBS_VOLUME_ID" \
    --instance-id "$INSTANCE_ID" \
    --region     "$REGION" \
    --output text > /dev/null

  # Poll until detached
  local elapsed=0
  while (( elapsed < 60 )); do
    local vol_state
    vol_state=$(aws ec2 describe-volumes \
      --volume-ids "$EBS_VOLUME_ID" \
      --region     "$REGION" \
      --query      "Volumes[0].State" \
      --output text 2>/dev/null)
    if [[ "$vol_state" == "available" ]]; then
      success "Volume ${EBS_VOLUME_ID} is now detached (state: available)."
      config_set "ebs_attached" "false"
      return 0
    fi
    sleep 5
    (( elapsed += 5 ))
  done

  error "Timed out waiting for detach. Check AWS Console."
  exit 1
}

# ── Attach ────────────────────────────────────────────────────────────────────
ebs_attach() {
  hermes_banner
  _ebs_load_config

  local target_instance_id="${1:-$INSTANCE_ID}"

  if [[ -z "$target_instance_id" ]]; then
    target_instance_id=$(plain_input \
      "Target EC2 instance ID  (leave blank to use current: ${INSTANCE_ID})" \
      "$INSTANCE_ID")
    [[ -z "$target_instance_id" ]] && target_instance_id="$INSTANCE_ID"
  fi

  local target_ip="${PUBLIC_IP}"
  if [[ "$target_instance_id" != "$INSTANCE_ID" ]]; then
    # Look up the public IP of the new instance
    target_ip=$(aws ec2 describe-instances \
      --instance-ids "$target_instance_id" \
      --region       "$REGION" \
      --query        "Reservations[0].Instances[0].PublicIpAddress" \
      --output text 2>/dev/null || echo "")
    if [[ -z "$target_ip" || "$target_ip" == "None" ]]; then
      error "Could not determine public IP for instance ${target_instance_id}"
      exit 1
    fi
    # Save new instance
    config_set "instance_id" "$target_instance_id"
    config_set "public_ip"   "$target_ip"
    INSTANCE_ID="$target_instance_id"
    PUBLIC_IP="$target_ip"
  fi

  local ssh_key_expanded="${SSH_KEY/#\~/$HOME}"

  gum style --bold --foreground 212 "  EBS Attach"
  summary_table \
    "Volume"   "$EBS_VOLUME_ID" \
    "Target"   "$target_instance_id" \
    "IP"       "$target_ip" \
    "Device"   "/dev/xvdf" \
    "Mount"    "/mnt/hermes-data"
  gum confirm "Attach volume to this instance?" || { warn "Aborted."; exit 0; }

  # Step 1 — AWS attach
  warn "Attaching ${EBS_VOLUME_ID} to ${target_instance_id} ..."
  aws ec2 attach-volume \
    --volume-id   "$EBS_VOLUME_ID" \
    --instance-id "$target_instance_id" \
    --device      "/dev/xvdf" \
    --region      "$REGION" \
    --output text > /dev/null

  # Poll until attached
  local elapsed=0
  while (( elapsed < 90 )); do
    local att_state
    att_state=$(aws ec2 describe-volumes \
      --volume-ids "$EBS_VOLUME_ID" \
      --region     "$REGION" \
      --query      "Volumes[0].Attachments[0].State" \
      --output text 2>/dev/null)
    if [[ "$att_state" == "attached" ]]; then
      success "Volume attached."
      break
    fi
    sleep 5
    (( elapsed += 5 ))
  done
  if [[ "$att_state" != "attached" ]]; then
    error "Timed out waiting for attachment. Check AWS Console."
    exit 1
  fi

  # Step 2 — Mount on instance via SSH (format only if first use)
  warn "Mounting on instance ${target_ip} ..."
  ssh -i "$ssh_key_expanded" \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=15 \
      "ubuntu@${target_ip}" <<'REMOTE'
set -euo pipefail

DEVICE=""
# Nitro instances expose xvdf as nvme1n1; classic as xvdf
for candidate in /dev/nvme1n1 /dev/xvdf; do
  if [[ -b "$candidate" ]]; then DEVICE="$candidate"; break; fi
done

if [[ -z "$DEVICE" ]]; then
  echo "ERROR: data device not found. Tried /dev/nvme1n1 and /dev/xvdf" >&2
  exit 1
fi

# Format only if this is a brand-new unformatted volume
if ! blkid "$DEVICE" | grep -q ext4; then
  echo "First-use detected — formatting ${DEVICE} as ext4 ..."
  sudo mkfs.ext4 -L hermes-data "$DEVICE"
fi

sudo mkdir -p /mnt/hermes-data
sudo mount "$DEVICE" /mnt/hermes-data

# Make ubuntu the owner
sudo chown ubuntu:ubuntu /mnt/hermes-data

# Persist mount across reboots via /etc/fstab (idempotent)
if ! grep -q "hermes-data" /etc/fstab; then
  echo "LABEL=hermes-data  /mnt/hermes-data  ext4  defaults,nofail  0  2" \
    | sudo tee -a /etc/fstab > /dev/null
fi

echo "OK: /mnt/hermes-data mounted from ${DEVICE}"
df -h /mnt/hermes-data
REMOTE

  success "Data volume mounted at /mnt/hermes-data on ${target_ip}"
  config_set "ebs_attached" "true"

  echo ""
  gum style --foreground 245 \
    "  Your Hermes data is available at /mnt/hermes-data on the instance." \
    "  Hermes stores config + model cache here automatically." \
    "  To verify:  hermes-agent-cloud ssh  →  ls /mnt/hermes-data"
  echo ""
}

# ── Migrate ───────────────────────────────────────────────────────────────────
# Guided workflow for upgrading the EC2 instance type while keeping data.
ebs_migrate() {
  hermes_banner
  _ebs_load_config

  gum style --bold --foreground 212 "  Instance Migration with Data Persistence"
  echo ""
  gum style --foreground 245 \
    "  This wizard lets you upgrade (or replace) the EC2 instance" \
    "  while keeping all your Hermes data on the EBS volume." \
    "" \
    "  Steps:" \
    "    1.  Detach the data volume from the current instance" \
    "    2.  You deploy a new instance (hermes-agent-cloud deploy)" \
    "    3.  Re-attach the volume to the new instance" \
    ""

  gum confirm "Start migration workflow?" || { warn "Aborted."; exit 0; }

  # ── Step 1: Detach ─────────────────────────────────────────────────────────
  gum style --bold --foreground 212 "  Step 1 / 3 — Detach volume from current instance"
  echo ""
  ebs_detach
  echo ""

  # ── Step 2: Deploy new instance ────────────────────────────────────────────
  gum style --bold --foreground 212 "  Step 2 / 3 — Deploy new instance"
  echo ""
  gum style --foreground 245 \
    "  Now deploy your upgraded instance. The wizard will ask for the new" \
    "  instance type. Choose EBS disabled (or enabled to get a new blank one)." \
    ""
  gum style --foreground 245 "  Press ENTER to launch the deploy wizard now, or Ctrl+C to do it manually later."
  read -r

  # Run the deploy wizard — EBS will be re-enabled by default but
  # we tell the user to set ebs_enabled=false so they reuse this volume.
  gum style --foreground 212 "  Launching deploy wizard..."
  echo ""
  cmd_deploy

  echo ""
  gum style --bold --foreground 212 "  Step 3 / 3 — Attach data volume to new instance"
  echo ""
  gum style --foreground 245 "  The new instance has been deployed. Attaching data volume now..."
  echo ""

  # Reload config to pick up new instance_id / public_ip set by cmd_deploy
  config_load
  INSTANCE_ID="$(config_get "instance_id")"
  PUBLIC_IP="$(config_get "public_ip")"

  ebs_attach "$INSTANCE_ID"

  echo ""
  gum style \
    --border double \
    --border-foreground 46 \
    --padding "1 4" \
    "$(gum style --foreground 46 --bold '✓  Migration complete!')" \
    "$(gum style --foreground 245 "Volume ${EBS_VOLUME_ID} is now mounted at /mnt/hermes-data on the new instance.")"
  echo ""
}

# ── Dispatcher ────────────────────────────────────────────────────────────────
ebs_cmd() {
  local subcmd="${1:-status}"
  shift || true

  case "$subcmd" in
    status)  ebs_status   ;;
    detach)  ebs_detach   ;;
    attach)  ebs_attach "$@" ;;
    migrate) ebs_migrate  ;;
    *)
      error "Unknown ebs subcommand: ${subcmd}"
      echo ""
      gum style --foreground 245 "  Available: status  detach  attach  migrate"
      exit 1
      ;;
  esac
}
