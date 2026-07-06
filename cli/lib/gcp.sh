#!/usr/bin/env bash
# gcp.sh — GCP wizard, deploy, and management helpers

gcp_profile_value() {
  local file="$1"
  local key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}=" "$file" 2>/dev/null \
    | tail -1 \
    | cut -d'=' -f2- \
    | sed 's/^"\(.*\)"$/\1/'
}

gcp_choose_preset() {
  local options=()
  local preset

  for preset in "${GCP_PRESETS[@]}"; do
    options+=("$(printf '%-10s — %s' "$preset" "${GCP_PRESET_LABELS[$preset]}")")
  done

  choose_one "Choose a GCP preset" "${options[@]}" | awk '{print $1}'
}

gcp_choose_extra_packs() {
  local options=()
  local pack
  local selection=""
  local resolved=""

  for pack in "${GCP_CAPABILITY_PACKS[@]}"; do
    options+=("$(printf '%-16s — %s [%s]' "$pack" "${GCP_PACK_LABELS[$pack]}" "${GCP_PACK_SUPPORT_LEVEL[$pack]}")")
  done

  selection=$(printf '%s\n' "${options[@]}" | gum choose \
    --no-limit \
    --header "Select extra GCP capability packs (optional)" \
    --header.foreground 245 \
    --cursor.foreground 212 \
    --selected.foreground 212 || true)

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ -n "$resolved" ]]; then
      resolved+=","
    fi
    resolved+="$(echo "$line" | awk '{print $1}')"
  done <<< "$selection"

  echo "$resolved"
}

gcp_detect_allowed_cidr() {
  local configured_cidr="${1:-}"
  local my_ip=""

  if [[ -n "$configured_cidr" ]]; then
    echo "$configured_cidr"
    return 0
  fi

  my_ip=$(curl -sf --max-time 5 "https://api.ipify.org" \
    || curl -sf --max-time 5 "https://ifconfig.me" \
    || echo "0.0.0.0")
  echo "${my_ip}/32"
}

gcp_machine_vcpu() {
  local machine_type="$1"
  echo "${GCP_MACHINE_VCPU[$machine_type]:-2}"
}

gcp_csv_to_tf_list() {
  local items=("$@")
  local output="["
  local item

  for item in "${items[@]}"; do
    [[ -z "$item" ]] && continue
    if [[ "$output" != "[" ]]; then
      output+=", "
    fi
    output+="\"${item}\""
  done

  output+="]"
  echo "$output"
}

gcp_has_pack() {
  local packs_csv="$1"
  local target="$2"
  local pack

  IFS=',' read -r -a _gcp_check_packs <<< "$packs_csv"
  for pack in "${_gcp_check_packs[@]}"; do
    pack="${pack// /}"
    [[ "$pack" == "$target" ]] && return 0
  done

  return 1
}

gcp_label_map_to_tfvars() {
  local preset="$1"
  local labels_csv="${2:-}"
  local key value

  cat <<EOF
resource_labels = {
  managed_by = "hermes-agent-cloud"
  service    = "hermes-agent"
  preset     = "${preset//-/_}"
EOF

  IFS=',' read -r -a _gcp_labels <<< "$labels_csv"
  for key in "${_gcp_labels[@]}"; do
    value="${key#*=}"
    key="${key%%=*}"
    key="$(echo "$key" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
    value="$(echo "$value" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
    [[ -z "$key" || -z "$value" ]] && continue
    printf '  %s = "%s"\n' "$key" "$value"
  done

  echo "}"
}

gcp_required_services_array() {
  local packs_csv="$1"
  mapfile -t GCP_REQUIRED_SERVICES < <(gcp_catalog_collect_apis "$packs_csv")
}

gcp_required_roles_array() {
  local packs_csv="$1"
  mapfile -t GCP_REQUIRED_ROLES < <(gcp_catalog_collect_roles "$packs_csv")
}

GCP_BILLING_ACCOUNT=""

gcp_core_preflight() {
  local project_id="$1"
  local region="$2"
  local zone="$3"
  local machine_type="$4"
  local required_cpu="$5"
  local required_services_csv="$6"
  local budget_amount="$7"
  local billing_account=""
  local enabled_services=""
  local api
  local missing_services=()

  step_header 1 1 "GCP Project Readiness Checks"

  if ! gcloud projects describe "$project_id" --format="value(projectId)" &>/dev/null; then
    error "Project ${project_id} was not found or is not accessible."
    return 1
  fi
  success "Project access confirmed: ${project_id}"

  billing_account=$(gcloud billing projects describe "$project_id" \
    --format="value(billingAccountName)" 2>/dev/null | sed 's|billingAccounts/||')
  if [[ -z "$billing_account" ]]; then
    error "No billing account linked to project ${project_id}."
    return 1
  fi
  success "Billing linked: ${billing_account}"

  if ! gcloud compute regions describe "$region" --project "$project_id" &>/dev/null; then
    error "Region ${region} is not available in project ${project_id}."
    return 1
  fi
  success "Region available: ${region}"

  if ! gcloud compute zones describe "$zone" --project "$project_id" &>/dev/null; then
    error "Zone ${zone} is not available in project ${project_id}."
    return 1
  fi
  success "Zone available: ${zone}"

  local quota_json
  quota_json=$(gcloud compute regions describe "$region" \
    --project "$project_id" \
    --format=json 2>/dev/null || echo "")
  if [[ -n "$quota_json" ]]; then
    if ! REQUIRED_CPU="$required_cpu" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
required_cpu = float(os.environ.get("REQUIRED_CPU", "2"))
quotas = {q["metric"]: (float(q.get("limit", 0)), float(q.get("usage", 0))) for q in data.get("quotas", [])}
checks = {"CPUS": required_cpu, "INSTANCES": 1, "IN_USE_ADDRESSES": 1}
for metric, needed in checks.items():
    limit, usage = quotas.get(metric, (0, 0))
    if limit and limit - usage < needed:
        print(f"Quota check failed for {metric}: need {needed}, have {limit - usage}", file=sys.stderr)
        sys.exit(1)
' <<< "$quota_json"; then
      error "Quota check failed for region ${region}."
      return 1
    fi
    success "Quota looks sufficient for ${machine_type}"
  else
    warn "Could not read regional quota information; continuing."
  fi

  enabled_services=$(gcloud services list \
    --enabled \
    --project "$project_id" \
    --format="value(config.name)" 2>/dev/null || echo "")
  IFS=',' read -r -a _gcp_service_list <<< "$required_services_csv"
  for api in "${_gcp_service_list[@]}"; do
    [[ -z "$api" ]] && continue
    if ! grep -qx "$api" <<< "$enabled_services"; then
      missing_services+=("$api")
    fi
  done

  if [[ ${#missing_services[@]} -gt 0 ]]; then
    warn "The following APIs are not enabled yet and will be enabled during deploy:"
    printf '  - %s\n' "${missing_services[@]}"
  else
    success "Required APIs are already enabled."
  fi

  if [[ "$budget_amount" != "0" ]]; then
    if ! gcloud services list --available --project "$project_id" \
      --filter="config.name=billingbudgets.googleapis.com" --format="value(config.name)" \
      | grep -q "billingbudgets.googleapis.com"; then
      warn "Budget API visibility could not be confirmed; Terraform will still attempt to enable it."
    else
      success "Budget API is available for the project."
    fi
  fi
  GCP_BILLING_ACCOUNT="$billing_account"
}

gcp_explain_plan() {
  local project_id="$1"
  local region="$2"
  local zone="$3"
  local machine_type="$4"
  local preset="$5"
  local packs_csv="$6"
  local allowed_cidr="$7"
  local budget_amount="$8"

  summary_table \
    "Cloud"       "GCP" \
    "Project"     "$project_id" \
    "Region/Zone" "${region} / ${zone}" \
    "Machine"     "$machine_type" \
    "Preset"      "${GCP_PRESET_LABELS[$preset]}" \
    "Packs"       "$(gcp_catalog_csv_to_labels "$packs_csv")" \
    "Ingress"     "$allowed_cidr" \
    "Cost Class"  "${GCP_PRESET_COST_CLASS[$preset]}" \
    "Blast Radius" "${GCP_PRESET_BLAST_RADIUS[$preset]}" \
    "Budget"      "$([[ "$budget_amount" == "0" ]] && echo "disabled" || echo "\$${budget_amount}/month")"

  divider "SUPPORTED SERVICES AND RESOURCES"
  gcp_catalog_collect_resources "$packs_csv" | sed 's/^/  • /'
  echo ""

  divider "IAM SCOPE"
  gcp_catalog_collect_roles "$packs_csv" | sed 's/^/  • /'
  echo ""

  divider "PROJECT APIS"
  gcp_catalog_collect_apis "$packs_csv" | sed 's/^/  • /'
  echo ""
}

gcp_write_tfvars() {
  local tf_dir="$1"
  local project_id="$2"
  local region="$3"
  local zone="$4"
  local machine_type="$5"
  local allowed_cidr="$6"
  local preset="$7"
  local packs_csv="$8"
  local billing_account="$9"
  local budget_amount="${10}"
  local bucket_name="${11}"
  local dataset_id="${12}"
  local topic_name="${13}"
  local repo_name="${14}"
  local secret_id="${15}"
  local kms_keyring="${16}"
  local kms_key="${17}"
  local labels_csv="${18:-}"
  local pack_args=()

  gcp_required_services_array "$packs_csv"
  gcp_required_roles_array "$packs_csv"
  if (( budget_amount > 0 )); then
    GCP_REQUIRED_SERVICES+=("billingbudgets.googleapis.com")
  fi
  IFS=',' read -r -a pack_args <<< "$packs_csv"

  cat > "${tf_dir}/terraform.tfvars" <<EOF
project_id         = "${project_id}"
region             = "${region}"
zone               = "${zone}"
machine_type       = "${machine_type}"
allowed_ssh_cidr   = "${allowed_cidr}"
gcp_preset         = "${preset}"
capability_packs   = $(gcp_csv_to_tf_list "${pack_args[@]}")
required_services  = $(gcp_csv_to_tf_list "${GCP_REQUIRED_SERVICES[@]}")
service_account_roles = $(gcp_csv_to_tf_list "${GCP_REQUIRED_ROLES[@]}")
billing_account    = "${billing_account}"
budget_amount      = ${budget_amount}

manage_secret_manager   = $(gcp_has_pack "$packs_csv" "secretmanager" && echo true || echo false)
manage_kms              = $(gcp_has_pack "$packs_csv" "kms" && echo true || echo false)
manage_storage_bucket   = $(gcp_has_pack "$packs_csv" "storage" && echo true || echo false)
manage_bigquery_dataset = $(gcp_has_pack "$packs_csv" "bigquery" && echo true || echo false)
manage_pubsub_topic     = $(gcp_has_pack "$packs_csv" "pubsub" && echo true || echo false)
manage_artifact_registry = $(gcp_has_pack "$packs_csv" "artifactregistry" && echo true || echo false)

storage_bucket_name     = "${bucket_name}"
bigquery_dataset_id     = "${dataset_id}"
pubsub_topic_name       = "${topic_name}"
artifact_registry_id    = "${repo_name}"
secret_manager_secret_id = "${secret_id}"
kms_keyring_name        = "${kms_keyring}"
kms_crypto_key_name     = "${kms_key}"
EOF

  gcp_label_map_to_tfvars "$preset" "$labels_csv" >> "${tf_dir}/terraform.tfvars"
}

gcp_resolved_value() {
  local explicit="$1"
  local profile_file="$2"
  local key="$3"
  local fallback="${4:-}"
  local value="$explicit"

  if [[ -z "$value" && -n "$profile_file" ]]; then
    value="$(gcp_profile_value "$profile_file" "$key")"
  fi

  if [[ -z "$value" ]]; then
    value="$fallback"
  fi

  echo "$value"
}

gcp_doctor_check() {
  local ok_message="$1"
  local fail_message="$2"
  local command="$3"

  if bash -c "$command" &>/dev/null; then
    success "$ok_message"
  else
    warn "$fail_message"
  fi
}

gcp_wizard() {
  local steps=8
  preflight_check_cloud "gcp"

  local active_account
  active_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
  if [[ -z "$active_account" ]]; then
    warn "No active GCP session. Launching gcloud auth login..."
    gcloud auth login
    gcloud auth application-default login
  fi

  local project_id zone machine_type allowed_cidr my_ip preset extra_packs packs_csv
  local budget_amount labels_csv billing_account
  local bucket_name dataset_id topic_name repo_name secret_id kms_keyring kms_key
  local cpu_count required_services_csv

  step_header 1 $steps "GCP Project & Region"
  project_id="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_PROJECT_ID")"
  project_id="${project_id:-$(gcloud config get-value project 2>/dev/null || echo "")}"
  if [[ -z "$project_id" ]]; then
    project_id=$(plain_input "GCP Project ID")
  else
    warn "Using GCP project: ${project_id}"
  fi
  [[ -z "$project_id" ]] && { error "GCP Project ID is required."; exit 1; }

  if [[ -n "$REGION" ]]; then
    validate_gcp_region "$REGION"
  else
    REGION="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_REGION")"
    if [[ -z "$REGION" ]]; then
      local region_choice
      region_choice=$(choose_one "Select deployment region" "${GCP_REGION_LABELS[@]}")
      REGION="$(echo "$region_choice" | awk '{print $1}')"
    fi
    validate_gcp_region "$REGION"
  fi

  step_header 2 $steps "GCP Zone"
  zone="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_ZONE")"
  if [[ -z "$zone" ]]; then
    local zone_list
    zone_list=$(gcloud compute zones list --filter="region:(${REGION})" --format="value(name)" 2>/dev/null || echo "")
    if [[ -n "$zone_list" ]]; then
      mapfile -t _gcp_zones <<< "$zone_list"
      zone=$(choose_one "Select deployment zone" "${_gcp_zones[@]}")
    else
      zone="${REGION}-a"
      warn "Could not fetch zones from GCP. Falling back to ${zone}."
    fi
  fi

  step_header 3 $steps "Machine Type"
  machine_type="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_MACHINE_TYPE")"
  if [[ -z "$machine_type" ]]; then
    local machine_choice
    machine_choice=$(choose_one "Select machine type" "${GCP_MACHINE_TYPE_LABELS[@]}")
    machine_type="$(echo "$machine_choice" | awk '{print $1}')"
  fi
  validate_gcp_machine_type "$machine_type"
  show_cost_hint "gcp" "$machine_type"

  step_header 4 $steps "Preset & Capability Packs"
  preset="${GCP_PRESET:-$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_PRESET" "minimal")}"
  if [[ -z "${GCP_PRESET:-}" && -z "$CONFIG_INPUT_FILE" ]]; then
    preset="$(gcp_choose_preset)"
  fi
  gcp_catalog_validate_preset "$preset" || exit 1

  extra_packs="$GCP_PACKS"
  if [[ -z "$extra_packs" ]]; then
    extra_packs="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_PACKS")"
  fi
  if [[ -z "$extra_packs" && -z "$CONFIG_INPUT_FILE" ]]; then
    extra_packs="$(gcp_choose_extra_packs)"
  fi
  packs_csv="$(gcp_catalog_merge_pack_csv "$preset" "$extra_packs")" || exit 1
  success "Resolved packs: $(gcp_catalog_csv_to_labels "$packs_csv")"

  step_header 5 $steps "Network & Governance"
  allowed_cidr="$(gcp_detect_allowed_cidr "$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_ALLOWED_CIDR")")"
  my_ip="${allowed_cidr%/*}"
  warn "SSH / gateway access will be locked to: ${allowed_cidr}"
  warn "If your local IP changes, run: hermes-agent-cloud update-ip"

  budget_amount="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_BUDGET_AMOUNT" "0")"
  if [[ -z "$CONFIG_INPUT_FILE" ]]; then
    budget_amount="$(plain_input "Optional monthly budget in USD (0 disables)" "$budget_amount")"
    budget_amount="${budget_amount:-0}"
  fi
  [[ ! "$budget_amount" =~ ^[0-9]+$ ]] && budget_amount=0

  labels_csv="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_LABELS")"

  bucket_name="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_BUCKET_NAME" "${project_id}-hermes-agent-storage")"
  dataset_id="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_BIGQUERY_DATASET" "hermes_agent")"
  topic_name="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_PUBSUB_TOPIC" "hermes-agent-events")"
  repo_name="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_ARTIFACT_REPOSITORY" "hermes-agent")"
  secret_id="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_SECRET_ID" "hermes-agent-config")"
  kms_keyring="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_KMS_KEYRING" "hermes-agent")"
  kms_key="$(gcp_resolved_value "" "$CONFIG_INPUT_FILE" "HERMES_GCP_KMS_KEY" "hermes-agent-key")"

  gcp_required_services_array "$packs_csv"
  required_services_csv="$(IFS=','; echo "${GCP_REQUIRED_SERVICES[*]}")"
  cpu_count="$(gcp_machine_vcpu "$machine_type")"
  gcp_core_preflight "$project_id" "$REGION" "$zone" "$machine_type" "$cpu_count" "$required_services_csv" "$budget_amount" || exit 1
  billing_account="$GCP_BILLING_ACCOUNT"

  step_header 6 $steps "Explain Plan"
  gcp_explain_plan "$project_id" "$REGION" "$zone" "$machine_type" "$preset" "$packs_csv" "$allowed_cidr" "$budget_amount"

  if [[ "$EXPLAIN_ONLY" == "true" ]]; then
    success "Explain-only mode complete."
    return 0
  fi

  step_header 7 $steps "Deployment Summary"
  summary_table \
    "Project"     "$project_id" \
    "Preset"      "${GCP_PRESET_LABELS[$preset]}" \
    "Packs"       "$(gcp_catalog_csv_to_labels "$packs_csv")" \
    "Allowed IP"  "$allowed_cidr" \
    "Budget"      "$([[ "$budget_amount" == "0" ]] && echo "disabled" || echo "\$${budget_amount}/month")"

  step_header 8 $steps "Deploy"
  gum confirm "Deploy Hermes Agent to GCP (${REGION})?" || { warn "Aborted."; exit 0; }

  local tf_dir="${HERMES_DEPLOY_HOME}/gcp"
  mkdir -p "$tf_dir"
  cp -r "${HERMES_DEPLOY_DIR}/terraform/gcp/." "$tf_dir/"

  gcp_write_tfvars \
    "$tf_dir" "$project_id" "$REGION" "$zone" "$machine_type" "$allowed_cidr" \
    "$preset" "$packs_csv" "$billing_account" "$budget_amount" \
    "$bucket_name" "$dataset_id" "$topic_name" "$repo_name" "$secret_id" \
    "$kms_keyring" "$kms_key" "$labels_csv"

  config_set "cloud"               "gcp"
  config_set "region"              "$REGION"
  config_set "zone"                "$zone"
  config_set "project_id"          "$project_id"
  config_set "tf_dir"              "$tf_dir"
  config_set "ssh_user"            "ubuntu"
  config_set "allowed_ip"          "$my_ip"
  config_set "allowed_cidr"        "$allowed_cidr"
  config_set "gcp_preset"          "$preset"
  config_set "gcp_packs"           "$packs_csv"
  config_set "gcp_budget_amount"   "$budget_amount"
  config_set "gcp_labels"          "$labels_csv"
  config_set "billing_account"     "$billing_account"
  config_set "gcp_bigquery_dataset" "$dataset_id"

  if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run — showing plan only, no resources will be created."
    spinner "Initializing Terraform..." terraform -chdir="$tf_dir" init -upgrade -no-color
    terraform -chdir="$tf_dir" plan -no-color
    return 0
  fi

  spinner "Initializing Terraform..." terraform -chdir="$tf_dir" init -no-color
  spinner "Applying (this takes ~4 min)..." terraform -chdir="$tf_dir" apply -auto-approve -no-color

  local ip sa_email
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null || echo "")
  sa_email=$(terraform -chdir="$tf_dir" output -raw service_account_email 2>/dev/null || echo "")
  [[ -z "$ip" ]] && ip="unknown"

  config_set "public_ip"           "$ip"
  config_set "instance_id"         "hermes-instance"
  config_set "service_account_email" "$sa_email"

  local gcp_ssh_key="$HOME/.ssh/google_compute_engine"
  local active_profile
  active_profile="$(_ssh_active_profile)"
  ssh_wait "$ip" "ubuntu" "$gcp_ssh_key"
  ssh_upload_profile_keys "$ip" "ubuntu" "$gcp_ssh_key"
  ssh_install "$ip" "ubuntu" "$gcp_ssh_key" "$active_profile" "${HERMES_DEPLOY_DIR}/scripts/bootstrap.sh"

  post_deploy_guide "gcp" "$ip" "hermes-instance" "$zone" "$gcp_ssh_key"
}

gcp_status() {
  local tf_dir zone project_id ip state preset packs
  tf_dir=$(config_get "tf_dir")
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  preset=$(config_get "gcp_preset")
  packs=$(config_get "gcp_packs")
  ip=$(terraform -chdir="$tf_dir" output -raw public_ip 2>/dev/null || config_get "public_ip" || echo "unknown")
  state=$(gcloud compute instances describe hermes-instance \
    --zone "$zone" --project "$project_id" \
    --format="value(status)" 2>/dev/null || echo "unknown")

  summary_table \
    "Cloud"      "GCP" \
    "Zone"       "$zone" \
    "Instance"   "hermes-instance" \
    "Public IP"  "$ip" \
    "Preset"     "${preset:-minimal}" \
    "Packs"      "$(gcp_catalog_csv_to_labels "$packs")" \
    "State"      "$state"
}

gcp_ssh() {
  local zone project_id ip
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  ip=$(config_get "public_ip")

  local method
  method=$(choose_one "Connection method" \
    "gcloud compute ssh  (recommended)" \
    "Direct SSH          (manual key)")

  case "$method" in
    gcloud*)
      warn "Connecting via gcloud to hermes-instance / ${zone} ..."
      gcloud compute ssh hermes-instance --zone "$zone" --project "$project_id"
      ;;
    Direct*)
      local key="$HOME/.ssh/google_compute_engine"
      warn "Connecting to ${ip} as ubuntu ..."
      ssh -i "$key" -o StrictHostKeyChecking=accept-new "ubuntu@${ip}"
      ;;
  esac
}

gcp_logs() {
  local zone project_id
  zone=$(config_get "zone")
  project_id=$(config_get "project_id")
  warn "Streaming hermes-gateway logs (Ctrl+C to exit)..."
  gcloud compute ssh hermes-instance \
    --zone "$zone" \
    --project "$project_id" \
    -- "journalctl -u hermes-gateway -f --no-pager"
}

gcp_secrets() {
  local ip
  ip=$(config_get "public_ip")
  local gcp_ssh_key="$HOME/.ssh/google_compute_engine"

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
    return 0
  fi

  ssh_update_key "$ip" "ubuntu" "$gcp_ssh_key" "$var_name" "$new_value"
}

gcp_doctor() {
  local project_id zone tf_dir allowed_cidr preset packs billing_account sa_email dataset_id
  project_id=$(config_get "project_id")
  zone=$(config_get "zone")
  tf_dir=$(config_get "tf_dir")
  allowed_cidr=$(config_get "allowed_cidr")
  preset=$(config_get "gcp_preset")
  packs=$(config_get "gcp_packs")
  billing_account=$(config_get "billing_account")
  sa_email=$(config_get "service_account_email")
  dataset_id=$(config_get "gcp_bigquery_dataset")
  [[ -z "$dataset_id" ]] && dataset_id="hermes_agent"

  [[ -z "$project_id" || -z "$zone" ]] && {
    error "No saved GCP deployment config found."
    return 1
  }

  divider "GCP DEPLOYMENT DOCTOR"
  echo ""
  gcp_doctor_check "Project is reachable." "Project could not be queried." \
    "gcloud projects describe '$project_id' --format='value(projectId)'"
  gcp_doctor_check "Billing linkage still exists." "Billing linkage is missing or inaccessible." \
    "gcloud billing projects describe '$project_id' --format='value(billingAccountName)' | grep -q ."
  gcp_doctor_check "Instance still exists." "Instance lookup failed." \
    "gcloud compute instances describe hermes-instance --zone '$zone' --project '$project_id'"

  if [[ -n "$packs" ]]; then
    local api
    while IFS= read -r api; do
      gcp_doctor_check "API enabled: ${api}" "API missing: ${api}" \
        "gcloud services list --enabled --project '$project_id' --format='value(config.name)' | grep -qx '$api'"
    done < <(gcp_catalog_collect_apis "$packs")
  fi

  if [[ -n "$sa_email" ]]; then
    gcp_doctor_check "Service account still exists." "Service account lookup failed." \
      "gcloud iam service-accounts describe '$sa_email' --project '$project_id'"
  fi

  gcp_doctor_check "SSH firewall remains restricted." "SSH firewall rule appears broad or missing." \
    "gcloud compute firewall-rules describe hermes-allow-ssh --project '$project_id' --format='value(sourceRanges[0])' | grep -qx '$allowed_cidr'"
  gcp_doctor_check "Gateway firewall remains restricted." "Gateway firewall rule appears broad or missing." \
    "gcloud compute firewall-rules describe hermes-allow-gateway --project '$project_id' --format='value(sourceRanges[0])' | grep -qx '$allowed_cidr'"
  if gcp_has_pack "$packs" "bigquery"; then
    gcp_doctor_check "Managed BigQuery dataset exists." "Managed BigQuery dataset not detected." \
      "bq --project_id '$project_id' show --dataset '${project_id}:${dataset_id}'"
  else
    warn "BigQuery pack not enabled; billing export readiness remains advisory only."
  fi

  if [[ -n "$tf_dir" ]]; then
    gcp_doctor_check "Terraform state directory still exists." "Terraform directory is missing." \
      "test -d '$tf_dir'"
  fi

  echo ""
  summary_table \
    "Project" "$project_id" \
    "Zone" "$zone" \
    "Preset" "${preset:-minimal}" \
    "Packs" "$(gcp_catalog_csv_to_labels "$packs")" \
    "Billing" "${billing_account:-unknown}"
}

gcp_destroy() {
  local tf_dir packs preset
  tf_dir=$(config_get "tf_dir")
  packs=$(config_get "gcp_packs")
  preset=$(config_get "gcp_preset")

  summary_table \
    "Cloud" "GCP" \
    "Preset" "${preset:-minimal}" \
    "Packs" "$(gcp_catalog_csv_to_labels "$packs")"
  divider "RESOURCES THAT WILL BE DESTROYED"
  gcp_catalog_collect_resources "$packs" | sed 's/^/  • /'
  echo ""

  confirm_destructive "This will permanently destroy your GCP core deployment and all managed capability pack resources."
  spinner "Destroying GCP infrastructure..." terraform -chdir="$tf_dir" destroy -auto-approve -no-color
  success "All GCP resources destroyed."
}
