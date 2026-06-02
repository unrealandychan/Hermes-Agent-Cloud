variable "project_id" {
  description = "GCP project ID to deploy into"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone within the region"
  type        = string
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH (22), gateway (8080), and dashboard (9119)"
  type        = string
}

variable "gcp_preset" {
  description = "Selected GCP deployment preset"
  type        = string
  default     = "minimal"
}

variable "capability_packs" {
  description = "Selected GCP capability packs"
  type        = list(string)
  default     = []
}

variable "required_services" {
  description = "Project APIs to enable declaratively"
  type        = list(string)
  default     = []
}

variable "service_account_roles" {
  description = "Project-level IAM roles for the Hermes VM service account"
  type        = list(string)
  default     = []
}

variable "resource_labels" {
  description = "Labels applied to supported resources"
  type        = map(string)
  default     = {}
}

variable "billing_account" {
  description = "Billing account ID without the billingAccounts/ prefix"
  type        = string
  default     = ""
}

variable "budget_amount" {
  description = "Optional monthly budget in USD (0 disables)"
  type        = number
  default     = 0
}

variable "manage_secret_manager" {
  description = "Create a Secret Manager secret container"
  type        = bool
  default     = false
}

variable "manage_kms" {
  description = "Create a KMS key ring and crypto key"
  type        = bool
  default     = false
}

variable "manage_storage_bucket" {
  description = "Create a Cloud Storage bucket"
  type        = bool
  default     = false
}

variable "manage_bigquery_dataset" {
  description = "Create a BigQuery dataset"
  type        = bool
  default     = false
}

variable "manage_pubsub_topic" {
  description = "Create a Pub/Sub topic"
  type        = bool
  default     = false
}

variable "manage_artifact_registry" {
  description = "Create an Artifact Registry repository"
  type        = bool
  default     = false
}

variable "storage_bucket_name" {
  description = "Bucket name for the storage capability pack"
  type        = string
  default     = ""
}

variable "storage_lifecycle_age" {
  description = "Days before noncurrent objects are deleted"
  type        = number
  default     = 30
}

variable "bigquery_dataset_id" {
  description = "Dataset ID for the BigQuery capability pack"
  type        = string
  default     = "hermes_agent"
}

variable "pubsub_topic_name" {
  description = "Topic name for the Pub/Sub capability pack"
  type        = string
  default     = "hermes-agent-events"
}

variable "artifact_registry_id" {
  description = "Repository ID for the Artifact Registry capability pack"
  type        = string
  default     = "hermes-agent"
}

variable "secret_manager_secret_id" {
  description = "Secret ID for the Secret Manager capability pack"
  type        = string
  default     = "hermes-agent-config"
}

variable "kms_keyring_name" {
  description = "Key ring name for the KMS capability pack"
  type        = string
  default     = "hermes-agent"
}

variable "kms_crypto_key_name" {
  description = "Crypto key name for the KMS capability pack"
  type        = string
  default     = "hermes-agent-key"
}
