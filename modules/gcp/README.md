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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_artifact_registry_repository.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_bigquery_dataset.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset) | resource |
| [google_billing_budget.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_compute_address.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_firewall.hermes_dashboard](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.hermes_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.hermes_ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_kms_crypto_key.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_key_ring.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_project_iam_member.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.required](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_topic.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_secret_manager_secret.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_service_account.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.hermes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_project.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR allowed for SSH (22), gateway (8080), and dashboard (9119) | `string` | n/a | yes |
| <a name="input_artifact_registry_id"></a> [artifact\_registry\_id](#input\_artifact\_registry\_id) | Repository ID for the Artifact Registry capability pack | `string` | `"hermes-agent"` | no |
| <a name="input_bigquery_dataset_id"></a> [bigquery\_dataset\_id](#input\_bigquery\_dataset\_id) | Dataset ID for the BigQuery capability pack | `string` | `"hermes_agent"` | no |
| <a name="input_billing_account"></a> [billing\_account](#input\_billing\_account) | Billing account ID without the billingAccounts/ prefix | `string` | `""` | no |
| <a name="input_budget_amount"></a> [budget\_amount](#input\_budget\_amount) | Optional monthly budget in USD (0 disables) | `number` | `0` | no |
| <a name="input_capability_packs"></a> [capability\_packs](#input\_capability\_packs) | Selected GCP capability packs | `list(string)` | `[]` | no |
| <a name="input_gcp_preset"></a> [gcp\_preset](#input\_gcp\_preset) | Selected GCP deployment preset | `string` | `"minimal"` | no |
| <a name="input_kms_crypto_key_name"></a> [kms\_crypto\_key\_name](#input\_kms\_crypto\_key\_name) | Crypto key name for the KMS capability pack | `string` | `"hermes-agent-key"` | no |
| <a name="input_kms_keyring_name"></a> [kms\_keyring\_name](#input\_kms\_keyring\_name) | Key ring name for the KMS capability pack | `string` | `"hermes-agent"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | GCP machine type | `string` | n/a | yes |
| <a name="input_manage_artifact_registry"></a> [manage\_artifact\_registry](#input\_manage\_artifact\_registry) | Create an Artifact Registry repository | `bool` | `false` | no |
| <a name="input_manage_bigquery_dataset"></a> [manage\_bigquery\_dataset](#input\_manage\_bigquery\_dataset) | Create a BigQuery dataset | `bool` | `false` | no |
| <a name="input_manage_kms"></a> [manage\_kms](#input\_manage\_kms) | Create a KMS key ring and crypto key | `bool` | `false` | no |
| <a name="input_manage_pubsub_topic"></a> [manage\_pubsub\_topic](#input\_manage\_pubsub\_topic) | Create a Pub/Sub topic | `bool` | `false` | no |
| <a name="input_manage_secret_manager"></a> [manage\_secret\_manager](#input\_manage\_secret\_manager) | Create a Secret Manager secret container | `bool` | `false` | no |
| <a name="input_manage_storage_bucket"></a> [manage\_storage\_bucket](#input\_manage\_storage\_bucket) | Create a Cloud Storage bucket | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID to deploy into | `string` | n/a | yes |
| <a name="input_pubsub_topic_name"></a> [pubsub\_topic\_name](#input\_pubsub\_topic\_name) | Topic name for the Pub/Sub capability pack | `string` | `"hermes-agent-events"` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | n/a | yes |
| <a name="input_required_services"></a> [required\_services](#input\_required\_services) | Project APIs to enable declaratively | `list(string)` | `[]` | no |
| <a name="input_resource_labels"></a> [resource\_labels](#input\_resource\_labels) | Labels applied to supported resources | `map(string)` | `{}` | no |
| <a name="input_secret_manager_secret_id"></a> [secret\_manager\_secret\_id](#input\_secret\_manager\_secret\_id) | Secret ID for the Secret Manager capability pack | `string` | `"hermes-agent-config"` | no |
| <a name="input_service_account_roles"></a> [service\_account\_roles](#input\_service\_account\_roles) | Project-level IAM roles for the Hermes VM service account | `list(string)` | `[]` | no |
| <a name="input_storage_bucket_name"></a> [storage\_bucket\_name](#input\_storage\_bucket\_name) | Bucket name for the storage capability pack | `string` | `""` | no |
| <a name="input_storage_lifecycle_age"></a> [storage\_lifecycle\_age](#input\_storage\_lifecycle\_age) | Days before noncurrent objects are deleted | `number` | `30` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone within the region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_url"></a> [gateway\_url](#output\_gateway\_url) | Hermes gateway URL |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | Instance name |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | Custom VPC for the Hermes deployment |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Reserved public IP address of the Hermes instance |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Service account attached to the Hermes VM |
| <a name="output_subnetwork_name"></a> [subnetwork\_name](#output\_subnetwork\_name) | Dedicated subnet for the Hermes deployment |
<!-- END_TF_DOCS -->