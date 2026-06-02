HERMES_GCP_PROJECT_ID="my-gcp-project"
HERMES_GCP_REGION="us-central1"
HERMES_GCP_ZONE="us-central1-a"
HERMES_GCP_MACHINE_TYPE="e2-standard-2"

# Presets: minimal | dev-agent | data-agent | ai-agent | full-ops
HERMES_GCP_PRESET="ai-agent"

# Optional comma-separated extra packs:
# secretmanager,kms,storage,bigquery,pubsub,scheduler,cloudrun,artifactregistry,logging,monitoring,alerts,vertexai,cloudsql
HERMES_GCP_PACKS="pubsub"

# Optional: override CIDR lock-down, monthly budget, and custom labels
HERMES_GCP_ALLOWED_CIDR=""
HERMES_GCP_BUDGET_AMOUNT="200"
HERMES_GCP_LABELS="environment=dev,team=platform"

# Optional managed resource names
HERMES_GCP_BUCKET_NAME="my-gcp-project-hermes-agent-storage"
HERMES_GCP_BIGQUERY_DATASET="hermes_agent"
HERMES_GCP_PUBSUB_TOPIC="hermes-agent-events"
HERMES_GCP_ARTIFACT_REPOSITORY="hermes-agent"
HERMES_GCP_SECRET_ID="hermes-agent-config"
HERMES_GCP_KMS_KEYRING="hermes-agent"
HERMES_GCP_KMS_KEY="hermes-agent-key"
