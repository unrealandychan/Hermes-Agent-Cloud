# Terraform Module: hermes-agent/gcp

Deploy [Hermes Agent](https://github.com/unrealandychan/Hermes-Agent-Cloud) on Google Cloud Platform (Compute Engine + VPC + IAM + optional services).

## Registry Usage

```hcl
module "hermes_agent" {
  source  = "unrealandychan/hermes-agent/gcp"
  version = "1.4.0"

  project_id       = "my-gcp-project"
  region           = "asia-east2"
  zone             = "asia-east2-a"
  machine_type     = "e2-standard-2"
  allowed_ssh_cidr = "203.0.113.0/32"

  # Optional capability packs
  manage_storage_bucket = false
  manage_secret_manager = false
}
```

> **Monorepo note:** Until published to the Terraform Registry, reference locally:
> ```hcl
> source = "github.com/unrealandychan/Hermes-Agent-Cloud//modules/gcp"
> ```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | GCP project ID | `string` | — | **yes** |
| `region` | GCP region | `string` | — | **yes** |
| `zone` | GCP zone | `string` | — | **yes** |
| `machine_type` | GCP machine type | `string` | — | **yes** |
| `allowed_ssh_cidr` | CIDR for SSH/gateway/dashboard | `string` | — | **yes** |
| `gcp_preset` | Deployment preset | `string` | `"minimal"` | no |
| `capability_packs` | GCP capability packs to enable | `list(string)` | `[]` | no |
| `required_services` | Project APIs to enable | `list(string)` | `[]` | no |
| `service_account_roles` | IAM roles for the Hermes SA | `list(string)` | `[]` | no |
| `resource_labels` | Labels applied to resources | `map(string)` | `{}` | no |
| `billing_account` | Billing account ID (for budget alerts) | `string` | `""` | no |
| `budget_amount` | Monthly budget in USD (0 = disabled) | `number` | `0` | no |
| `manage_secret_manager` | Create Secret Manager secret | `bool` | `false` | no |
| `manage_kms` | Create KMS key ring & crypto key | `bool` | `false` | no |
| `manage_storage_bucket` | Create Cloud Storage bucket | `bool` | `false` | no |
| `manage_bigquery_dataset` | Create BigQuery dataset | `bool` | `false` | no |
| `manage_pubsub_topic` | Create Pub/Sub topic | `bool` | `false` | no |
| `manage_artifact_registry` | Create Artifact Registry repository | `bool` | `false` | no |
| `storage_bucket_name` | Bucket name | `string` | `""` | no |
| `bigquery_dataset_id` | BigQuery dataset ID | `string` | `"hermes_agent"` | no |
| `pubsub_topic_name` | Pub/Sub topic name | `string` | `"hermes-agent-events"` | no |
| `artifact_registry_id` | Artifact Registry repo ID | `string` | `"hermes-agent"` | no |
| `secret_manager_secret_id` | Secret Manager secret ID | `string` | `"hermes-agent-config"` | no |
| `kms_keyring_name` | KMS key ring name | `string` | `"hermes-agent"` | no |
| `kms_crypto_key_name` | KMS crypto key name | `string` | `"hermes-agent-key"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `public_ip` | Reserved public IP of the Hermes instance |
| `instance_id` | Compute Engine instance name |
| `service_account_email` | Service account attached to the VM |
| `network_name` | Custom VPC name |
| `subnetwork_name` | Dedicated subnet name |
| `gateway_url` | Hermes gateway URL (http://\<ip\>:8080) |
