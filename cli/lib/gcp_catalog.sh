#!/usr/bin/env bash
# gcp_catalog.sh — Central catalog for GCP presets, capability packs, APIs, IAM,
# and managed resource summaries.

readonly GCP_CORE_DEPLOY_RESOURCES=(
  "Compute Engine VM"
  "Static public IP"
  "Custom VPC"
  "Dedicated subnet"
  "Ingress firewall rules"
  "Service account"
  "Declarative IAM bindings"
)

readonly GCP_CORE_REQUIRED_APIS=(
  "compute.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "iam.googleapis.com"
  "serviceusage.googleapis.com"
)

readonly GCP_CAPABILITY_PACKS=(
  "secretmanager"
  "kms"
  "storage"
  "bigquery"
  "pubsub"
  "scheduler"
  "cloudrun"
  "artifactregistry"
  "logging"
  "monitoring"
  "alerts"
  "vertexai"
  "cloudsql"
)

declare -A GCP_PACK_LABELS=(
  [secretmanager]="Secret Manager"
  [kms]="Cloud KMS"
  [storage]="Cloud Storage"
  [bigquery]="BigQuery"
  [pubsub]="Pub/Sub"
  [scheduler]="Cloud Scheduler"
  [cloudrun]="Cloud Run"
  [artifactregistry]="Artifact Registry"
  [logging]="Cloud Logging"
  [monitoring]="Cloud Monitoring"
  [alerts]="Alerting"
  [vertexai]="Vertex AI"
  [cloudsql]="Cloud SQL"
)

declare -A GCP_PACK_SUPPORT_LEVEL=(
  [secretmanager]="supported"
  [kms]="supported"
  [storage]="supported"
  [bigquery]="supported"
  [pubsub]="supported"
  [scheduler]="preview"
  [cloudrun]="preview"
  [artifactregistry]="supported"
  [logging]="preview"
  [monitoring]="preview"
  [alerts]="preview"
  [vertexai]="preview"
  [cloudsql]="preview"
)

declare -A GCP_PACK_DESCRIPTIONS=(
  [secretmanager]="Managed secret containers only; secret values stay out of Terraform state."
  [kms]="Dedicated key ring and crypto key for future app-level encryption workflows."
  [storage]="Managed bucket with versioning and lifecycle retention."
  [bigquery]="Managed analytics dataset for structured logs and billing exports."
  [pubsub]="Managed topic for events and automation."
  [scheduler]="API and IAM baseline for scheduled workflows."
  [cloudrun]="API and IAM baseline for serverless app deployments."
  [artifactregistry]="Managed Docker repository for build/runtime artifacts."
  [logging]="API and IAM baseline for log-heavy automation."
  [monitoring]="API and IAM baseline for metrics and dashboards."
  [alerts]="API and IAM baseline for alert policies and governance."
  [vertexai]="API and IAM baseline for Gemini / Vertex AI workloads."
  [cloudsql]="API and IAM baseline for managed relational data access."
)

declare -A GCP_PACK_APIS=(
  [secretmanager]="secretmanager.googleapis.com"
  [kms]="cloudkms.googleapis.com"
  [storage]="storage.googleapis.com"
  [bigquery]="bigquery.googleapis.com"
  [pubsub]="pubsub.googleapis.com"
  [scheduler]="cloudscheduler.googleapis.com"
  [cloudrun]="run.googleapis.com"
  [artifactregistry]="artifactregistry.googleapis.com"
  [logging]="logging.googleapis.com"
  [monitoring]="monitoring.googleapis.com"
  [alerts]="monitoring.googleapis.com"
  [vertexai]="aiplatform.googleapis.com"
  [cloudsql]="sqladmin.googleapis.com"
)

declare -A GCP_PACK_ROLES=(
  [secretmanager]="roles/secretmanager.admin"
  [kms]="roles/cloudkms.admin"
  [storage]="roles/storage.objectAdmin"
  [bigquery]="roles/bigquery.dataEditor,roles/bigquery.jobUser"
  [pubsub]="roles/pubsub.editor"
  [scheduler]="roles/cloudscheduler.admin"
  [cloudrun]="roles/run.developer"
  [artifactregistry]="roles/artifactregistry.writer"
  [logging]="roles/logging.admin"
  [monitoring]="roles/monitoring.editor"
  [alerts]="roles/monitoring.alertPolicyEditor"
  [vertexai]="roles/aiplatform.user"
  [cloudsql]="roles/cloudsql.admin"
)

declare -A GCP_PACK_MANAGED_RESOURCES=(
  [secretmanager]="Secret Manager secret"
  [kms]="KMS key ring + crypto key"
  [storage]="Cloud Storage bucket"
  [bigquery]="BigQuery dataset"
  [pubsub]="Pub/Sub topic"
  [scheduler]="No managed resource yet (API + IAM only)"
  [cloudrun]="No managed resource yet (API + IAM only)"
  [artifactregistry]="Artifact Registry repository"
  [logging]="No managed resource yet (API + IAM only)"
  [monitoring]="No managed resource yet (API + IAM only)"
  [alerts]="No managed resource yet (API + IAM only)"
  [vertexai]="No managed resource yet (API + IAM only)"
  [cloudsql]="No managed resource yet (API + IAM only)"
)

readonly GCP_PRESETS=(
  "minimal"
  "dev-agent"
  "data-agent"
  "ai-agent"
  "full-ops"
)

declare -A GCP_PRESET_LABELS=(
  [minimal]="Minimal"
  [dev-agent]="Dev Agent"
  [data-agent]="Data Agent"
  [ai-agent]="AI Agent"
  [full-ops]="Full Ops"
)

declare -A GCP_PRESET_PACKS=(
  [minimal]=""
  [dev-agent]="secretmanager,storage,artifactregistry,logging,monitoring"
  [data-agent]="storage,bigquery,pubsub,scheduler"
  [ai-agent]="secretmanager,storage,artifactregistry,vertexai,logging,monitoring"
  [full-ops]="secretmanager,kms,storage,bigquery,pubsub,scheduler,cloudrun,artifactregistry,logging,monitoring,alerts,vertexai,cloudsql"
)

declare -A GCP_PRESET_COST_CLASS=(
  [minimal]="Low"
  [dev-agent]="Medium"
  [data-agent]="Medium-High"
  [ai-agent]="Medium-High"
  [full-ops]="High"
)

declare -A GCP_PRESET_BLAST_RADIUS=(
  [minimal]="Single VM, network, and IAM baseline only."
  [dev-agent]="VM plus build/runtime services with moderate project-level IAM scope."
  [data-agent]="VM plus storage, analytics, and messaging services."
  [ai-agent]="VM plus AI, storage, and registry services."
  [full-ops]="Broadest API surface and managed resources across security, data, and runtime packs."
)

declare -A GCP_MACHINE_VCPU=(
  [e2-medium]=2
  [e2-standard-2]=2
  [e2-standard-4]=4
  [e2-standard-8]=8
)

gcp_catalog_pack_exists() {
  local pack="$1"
  enum_contains "$pack" "${GCP_CAPABILITY_PACKS[@]}"
}

gcp_catalog_validate_pack_csv() {
  local csv="$1"
  local pack

  [[ -z "$csv" ]] && return 0

  IFS=',' read -r -a _gcp_validate_packs <<< "$csv"
  for pack in "${_gcp_validate_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    if ! gcp_catalog_pack_exists "$pack"; then
      error "Unknown GCP capability pack: ${pack}"
      return 1
    fi
  done
}

gcp_catalog_validate_preset() {
  local preset="$1"
  if ! enum_contains "$preset" "${GCP_PRESETS[@]}"; then
    error "Unknown GCP preset: ${preset}"
    return 1
  fi
}

gcp_catalog_merge_pack_csv() {
  local preset="$1"
  local extras_csv="${2:-}"
  local merged_csv=""
  local pack
  declare -A seen=()

  gcp_catalog_validate_preset "$preset" || return 1
  gcp_catalog_validate_pack_csv "$extras_csv" || return 1

  IFS=',' read -r -a _gcp_preset_packs <<< "${GCP_PRESET_PACKS[$preset]}"
  for pack in "${_gcp_preset_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    seen["$pack"]=1
  done

  IFS=',' read -r -a _gcp_extra_packs <<< "$extras_csv"
  for pack in "${_gcp_extra_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    seen["$pack"]=1
  done

  for pack in "${GCP_CAPABILITY_PACKS[@]}"; do
    [[ -n "${seen[$pack]:-}" ]] || continue
    if [[ -n "$merged_csv" ]]; then
      merged_csv+=","
    fi
    merged_csv+="$pack"
  done

  echo "$merged_csv"
}

gcp_catalog_csv_to_labels() {
  local csv="$1"
  local labels=()
  local pack

  [[ -z "$csv" ]] && {
    echo "Core Deploy only"
    return 0
  }

  IFS=',' read -r -a _gcp_csv_packs <<< "$csv"
  for pack in "${_gcp_csv_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    labels+=("${GCP_PACK_LABELS[$pack]} (${GCP_PACK_SUPPORT_LEVEL[$pack]})")
  done

  (IFS=', '; echo "${labels[*]}")
}

gcp_catalog_collect_apis() {
  local csv="$1"
  local pack api
  declare -A seen=()

  for api in "${GCP_CORE_REQUIRED_APIS[@]}"; do
    seen["$api"]=1
  done

  IFS=',' read -r -a _gcp_api_packs <<< "$csv"
  for pack in "${_gcp_api_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    IFS=',' read -r -a _gcp_pack_apis <<< "${GCP_PACK_APIS[$pack]}"
    for api in "${_gcp_pack_apis[@]}"; do
      api="${api// /}"
      [[ -z "$api" ]] && continue
      seen["$api"]=1
    done
  done

  for api in "${!seen[@]}"; do
    echo "$api"
  done | sort
}

gcp_catalog_collect_roles() {
  local csv="$1"
  local pack role
  declare -A seen=()

  IFS=',' read -r -a _gcp_role_packs <<< "$csv"
  for pack in "${_gcp_role_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    IFS=',' read -r -a _gcp_pack_roles <<< "${GCP_PACK_ROLES[$pack]}"
    for role in "${_gcp_pack_roles[@]}"; do
      role="${role// /}"
      [[ -z "$role" ]] && continue
      seen["$role"]=1
    done
  done

  for role in "${!seen[@]}"; do
    echo "$role"
  done | sort
}

gcp_catalog_collect_resources() {
  local csv="$1"
  local pack

  for pack in "${GCP_CORE_DEPLOY_RESOURCES[@]}"; do
    echo "$pack"
  done

  IFS=',' read -r -a _gcp_resource_packs <<< "$csv"
  for pack in "${_gcp_resource_packs[@]}"; do
    pack="${pack// /}"
    [[ -z "$pack" ]] && continue
    echo "${GCP_PACK_MANAGED_RESOURCES[$pack]}"
  done
}
