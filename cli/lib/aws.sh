#!/usr/bin/env bash
# aws.sh — AWS wizard, deploy, and management helpers
# Enum values (VALID_AWS_REGIONS, AWS_REGION_LABELS, VALID_AWS_INSTANCE_TYPES,
# AWS_INSTANCE_TYPE_LABELS, API_PROVIDER_*) are defined in lib/enums.sh

# ─── Wizard ─────────────────────────────────────────────────────────────────
aws_wizard() {
  local steps=7
  preflight_check_cloud "aws"

  # ── Step 1: Region ────────────────────────────────────────────────────────
  step_header 1 $steps "AWS Region"
  local region_choice
  region_choice=$(choose_one "Select deployment region" "${AWS_REGION_LABELS[@]}")
  REGION="$(echo "$region_choice" | awk '{print $1}')"
  validate_aws_region "$REGION"

  # ── Step 2: Instance size ─────────────────────────────────────────────────
  step_header 2 $steps "Instance Size"
  local instance_choice
  instance_choice=$(choose_one "Select EC2 instance type" "${AWS_INSTANCE_TYPE_LABELS[@]}")
  local instance_type
  instance_type="$(echo "$instance_choice" | awk '{print $1}')"
  validate_aws_instance_type "$instance_type"

  # ── Step 3: SSH access ────────────────────────────────────────────────────
  step_header 3 $steps "SSH Access"
  local key_name
  key_name=$(plain_input "EC2 Key Pair name  (must already exist in region ${REGION})" "my-key-pair")
  if [[ -z "$key_name" ]]; then
    error "EC2 Key Pair name is required."
    exit 1
  fi

  local ssh_key_path
  ssh_key_path=$(plain_input "Path to local private key file" "~/.ssh/id_rsa")
  [[ -z "$ssh_key_path" ]] && ssh_key_path="~/.ssh/id_rsa"

  # Auto-detect deployer IP for security group lockdown
  local my_ip
  my_ip=$(curl -sf --max-time 5 "https://api.ipify.org" \
            || curl -sf --max-time 5 "https://ifconfig.me" \
            || echo "0.0.0.0")
  local allowed_cidr="${my_ip}/32"
  warn "SSH / gateway access will be locked to your current IP: ${my_ip}"

  # ── Step 4: Permission Profile ────────────────────────────────────────────
  step_header 4 $steps "Permission Profile  (IAM policies for this instance)"

  gum style --foreground 245 \
    "Select the cloud services Hermes Agent should be able to operate." \
    "Each selection attaches the corresponding managed AWS policy to the EC2 IAM role."
  echo ""

  local perm_choice
  perm_choice=$(choose_one "Permission profile" \
    "minimal    — SSM only  (default, no extra access)" \
    "s3         — SSM + S3 read/write" \
    "billing    — SSM + Billing/Cost Explorer read-only" \
    "rds        — SSM + RDS full access" \
    "s3+billing — SSM + S3 + Billing" \
    "s3+rds     — SSM + S3 + RDS" \
    "full       — SSM + S3 + Billing + RDS")

  local enable_s3=false enable_billing=false enable_rds=false
  case "$perm_choice" in
    s3\ *)      enable_s3=true ;;
    billing*)   enable_billing=true ;;
    rds\ *)     enable_rds=true ;;
    s3+billing*) enable_s3=true; enable_billing=true ;;
    s3+rds*)    enable_s3=true; enable_rds=true ;;
    full*)      enable_s3=true; enable_billing=true; enable_rds=true ;;
  esac

  local perm_summary=""
  [[ "$enable_s3"      == "true" ]] && perm_summary+=" S3"
  [[ "$enable_billing" == "true" ]] && perm_summary+=" Billing"
  [[ "$enable_rds"     == "true" ]] && perm_summary+=" RDS"
  [[ -z "$perm_summary" ]] && perm_summary=" SSM only"
  success "Selected:${perm_summary}"

  # ── Step 5: Persistent Data Volume (EBS) ─────────────────────────────────
  step_header 5 $steps "Persistent Data Volume  (EBS)"

  gum style --foreground 245 \
    "An independent EBS volume keeps your Hermes data (config, model cache, chat history)" \
    "separate from the EC2 instance.  When you upgrade the instance, just detach ↔ reattach." \
    ""

  local ebs_enabled=true
  local ebs_size=50

  local ebs_choice
  ebs_choice=$(choose_one "Persistent data volume" \
    "enabled  — 50 GB  gp3 (recommended)" \
    "custom   — choose size" \
    "disabled — data lives on root disk only  (lost on terminate)")

  case "$ebs_choice" in
    enabled*)  ebs_enabled=true;  ebs_size=50 ;;
    custom*)
      ebs_enabled=true
      local size_input
      size_input=$(plain_input "Volume size in GB  (min 20, max 16384)" "50")
      ebs_size="${size_input:-50}"
      if ! [[ "$ebs_size" =~ ^[0-9]+$ ]] || (( ebs_size < 20 )); then
        warn "Invalid size '${ebs_size}', defaulting to 50 GB."
        ebs_size=50
      fi
      ;;
    disabled*) ebs_enabled=false; ebs_size=0 ;;
  esac

  if [[ "$ebs_enabled" == "true" ]]; then
    success "EBS data volume: ${ebs_size} GB gp3  (encrypted, persists independently)"
  else
    warn "EBS disabled — data will be lost when instance is terminated."
  fi

  # ── Step 6: Summary ───────────────────────────────────────────────────────
  step_header 6 $steps "Deployment Summary"
  summary_table \
    "Cloud"       "AWS" \
    "Region"      "$REGION" \
    "Instance"    "$instance_type" \
    "Disk"        "50 GB gp3 (encrypted)" \
    "Data Volume" "$([ "$ebs_enabled" = "true" ] && echo "${ebs_size} GB gp3 EBS (persistent)" || echo "disabled")" \
    "Key Pair"    "$key_name" \
    "Allowed IP"  "$my_ip" \
    "Permissions" "${perm_summary# }"

  gum style --foreground 245 \
    "  ℹ  LLM API keys are configured after install via: hermes setup"
  echo ""

  # ── Step 7: Confirm ───────────────────────────────────────────────────────
  step_header 7 $steps "Deploy"
  gum confirm "Deploy Hermes Agent to AWS (${REGION})?" || { warn "Aborted."; exit 0; }

  # ── Prepare workspace ─────────────────────────────────────────────────────
  local tf_dir="${HERMES_DEPLOY_HOME}/aws"
  mkdir -p "$tf_dir"
  cp -r "${HERMES_DEPLOY_DIR}/terraform/aws/." "$tf_dir/"

  cat > "${tf_dir}/terraform.tfvars" <<EOF
aws_region        = "${REGION}"
instance_type     = "${instance_type}"
key_name          = "${key_name}"
allowed_ssh_cidr  = "${allowed_cidr}"
enable_s3         = ${enable_s3}
enable_billing    = ${enable_billing}
enable_rds        = ${enable_rds}
ebs_enabled       = ${ebs_enabled}
ebs_size          = ${ebs_size}
EOF

  # Persist config
  config_set "cloud"        "aws"
  config_set "region"       "$REGION"
  config_set "tf_dir"       "$tf_dir"
  config_set "ssh_key_path" "$ssh_key_path"
  config_set "ssh_user"     "ubuntu"
  config_set "permissions"  "${perm_summary# }"
  config_set "ebs_enabled"  "$ebs_enabled"
  config_set "ebs_size"     "$ebs_size"

  # ── Terraform ─────────────────────────────────────────────────────────────
  echo ""
  if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run — showing plan only, no resources will be created."
    spinner "Initializing Terraform..." \
      terraform -chdir="$tf_dir" init -upgrade -no-color
    terraform -chdir="$tf_dir" plan -no-color
    return
  fi

  spinner "Initializing Terraform..."       \
    terraform -chdir="$tf_dir" init -no-color
  spinner "Applying (this takes ~3 min)..." \
    terraform -chdir="$tf_dir" apply -auto-approve -no-color

  # Capture outputs
  local ip instance_id ebs_volume_id
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null)
  ip="${ip//$'\n'/}"
  [[ -z "$ip" ]] && ip="unknown"
  instance_id=$(terraform -chdir="$tf_dir" output -raw instance_id 2>/dev/null)
  instance_id="${instance_id//$'\n'/}"
  [[ -z "$instance_id" ]] && instance_id="unknown"
  ebs_volume_id=$(terraform -chdir="$tf_dir" output -raw ebs_volume_id 2>/dev/null || echo "")
  [[ "$ebs_volume_id" == "EBS not enabled" ]] && ebs_volume_id=""

  config_set "public_ip"   "$ip"
  config_set "instance_id" "$instance_id"
  [[ -n "$ebs_volume_id" ]] && config_set "ebs_volume_id" "$ebs_volume_id"

  # ── SSH-based installation ─────────────────────────────────────────────────
  ssh_wait    "$ip" "ubuntu" "$ssh_key_path"
  ssh_install "$ip" "ubuntu" "$ssh_key_path" \
    "${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh"

  # ── Mount EBS data volume ─────────────────────────────────────────────────
  if [[ "$ebs_enabled" == "true" && -n "$ebs_volume_id" ]]; then
    warn "Mounting persistent data volume on instance..."
    PUBLIC_IP="$ip" SSH_KEY="$ssh_key_path" ebs_attach "$instance_id"
  fi

  post_deploy_guide "aws" "$ip" "$instance_id" "$REGION" "$ssh_key_path"
}

# ─── Status ─────────────────────────────────────────────────────────────────
aws_status() {
  local tf_dir region ip instance_id
  tf_dir=$(config_get "tf_dir")
  region=$(config_get "region")
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null \
       || config_get "public_ip" || echo "unknown")
  instance_id=$(terraform -chdir="$tf_dir" output -raw instance_id 2>/dev/null \
                || config_get "instance_id" || echo "unknown")

  local state="unknown"
  if [[ -n "$instance_id" && "$instance_id" != "unknown" ]]; then
    state=$(aws ec2 describe-instance-status \
      --instance-ids "$instance_id" \
      --region "$region" \
      --query "InstanceStatuses[0].InstanceState.Name" \
      --output text 2>/dev/null || echo "unknown")
  fi

  local perms
  perms=$(config_get "permissions" 2>/dev/null || echo "SSM only")

  summary_table \
    "Cloud"       "AWS" \
    "Region"      "$region" \
    "Instance"    "$instance_id" \
    "Public IP"   "$ip" \
    "Permissions" "$perms" \
    "State"       "$state"
}

# ─── SSH ────────────────────────────────────────────────────────────────────
aws_ssh() {
  local ip instance_id region ssh_key
  ip=$(config_get "public_ip")
  instance_id=$(config_get "instance_id")
  region=$(config_get "region")
  ssh_key=$(config_get "ssh_key_path")

  ssh_key="${ssh_key/#\~/$HOME}"

  local method
  method=$(choose_one "Connection method" \
    "Direct SSH  (key pair)" \
    "AWS SSM Session Manager  (no open port needed)")

  case "$method" in
    Direct*)
      if [[ ! -f "$ssh_key" ]]; then
        error "Private key not found: ${ssh_key}"
        exit 1
      fi
      warn "Connecting to ${ip} as ubuntu ..."
      ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}"
      ;;
    AWS*)
      if ! command -v session-manager-plugin &>/dev/null; then
        warn "AWS Session Manager plugin not found."
        echo "  Install from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
        exit 1
      fi
      warn "Opening SSM session to ${instance_id} ..."
      aws ssm start-session --target "$instance_id" --region "$region"
      ;;
  esac
}

# ─── Logs ───────────────────────────────────────────────────────────────────
aws_logs() {
  local ip ssh_key
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"
  ssh_key="${ssh_key/#\~/$HOME}"
  warn "Streaming hermes-gateway logs from ${ip} (Ctrl+C to exit)..."
  ssh -i "$ssh_key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}" \
    "journalctl -u hermes-gateway -f --no-pager"
}

# ─── Secrets ────────────────────────────────────────────────────────────────
aws_secrets() {
  local ip ssh_key
  ip=$(config_get "public_ip")
  ssh_key="$(config_get "ssh_key_path")"

  gum style --bold --foreground 212 "Update API Keys on the Hermes instance"
  echo ""

  local provider
  provider=$(choose_one "Which provider's key?" \
    "OpenRouter  (OPENROUTER_API_KEY)" \
    "OpenAI      (OPENAI_API_KEY)" \
    "Anthropic   (ANTHROPIC_API_KEY)" \
    "Gemini      (GEMINI_API_KEY)")

  local var_name
  var_name=$(echo "$provider" | grep -oE '\([^)]+\)' | tr -d '()')
  local new_value
  new_value=$(masked_input "New value for ${var_name}")

  if [[ -z "$new_value" ]]; then
    warn "No value entered. Skipped."
    return
  fi

  ssh_update_key "$ip" "ubuntu" "$ssh_key" "$var_name" "$new_value"
}

# ─── Destroy ────────────────────────────────────────────────────────────────
aws_destroy() {
  local tf_dir
  tf_dir=$(config_get "tf_dir")
  spinner "Destroying AWS infrastructure..." \
    terraform -chdir="$tf_dir" destroy -auto-approve -no-color
  success "All AWS resources destroyed."
}
