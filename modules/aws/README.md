# Terraform Module: hermes-agent/aws

Deploy [Hermes Agent](https://github.com/unrealandychan/Hermes-Agent-Cloud) on AWS (EC2 + IAM + EBS + SSM).

## Registry Usage

```hcl
module "hermes_agent" {
  source  = "unrealandychan/hermes-agent/aws"
  version = "1.4.0"

  aws_region      = "us-east-1"
  instance_type   = "t3.large"
  key_name        = "my-keypair"
  allowed_ssh_cidr = "203.0.113.0/32"

  # Optional capability toggles
  enable_s3      = false
  enable_billing = false
  enable_rds     = false

  # Persistent data volume
  ebs_enabled = true
  ebs_size    = 50
}
```

> **Monorepo note:** Until this module is published to the Terraform Registry, reference it locally:
> ```hcl
> source = "github.com/unrealandychan/Hermes-Agent-Cloud//modules/aws"
> ```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `aws_region` | AWS region to deploy into | `string` | `"ap-east-1"` | no |
| `instance_type` | EC2 instance type (minimum t3.large) | `string` | `"t3.large"` | no |
| `key_name` | Existing EC2 Key Pair name | `string` | — | **yes** |
| `allowed_ssh_cidr` | CIDR allowed for SSH (22) and gateway (8080) | `string` | — | **yes** |
| `enable_s3` | Attach AmazonS3FullAccess to the IAM role | `bool` | `false` | no |
| `enable_billing` | Attach billing read-only policy | `bool` | `false` | no |
| `enable_rds` | Attach AmazonRDSFullAccess to the IAM role | `bool` | `false` | no |
| `ebs_enabled` | Provision a persistent EBS data volume | `bool` | `true` | no |
| `ebs_size` | Size in GB of the EBS data volume | `number` | `50` | no |

## Outputs

| Name | Description |
|------|-------------|
| `public_ip` | Public IP address of the Hermes EC2 instance |
| `instance_id` | EC2 instance ID |
| `ssh_command` | Direct SSH command |
| `ssm_command` | AWS SSM Session Manager command |
| `gateway_url` | Hermes gateway URL (http://\<ip\>:8080) |
| `ebs_volume_id` | ID of the persistent EBS volume |
| `ebs_device` | Device path the EBS volume is attached to |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.hermes_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_iam_instance_profile.hermes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.billing_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.hermes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.billing_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.rds_full](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_full](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.hermes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.hermes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.hermes_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.billing_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.hermes_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR block allowed to reach port 22 (SSH) and port 8080 (gateway) | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy into | `string` | `"ap-east-1"` | no |
| <a name="input_ebs_enabled"></a> [ebs\_enabled](#input\_ebs\_enabled) | Provision a persistent data EBS volume separate from the root disk | `bool` | `true` | no |
| <a name="input_ebs_size"></a> [ebs\_size](#input\_ebs\_size) | Size in GB of the persistent data EBS volume | `number` | `50` | no |
| <a name="input_enable_billing"></a> [enable\_billing](#input\_enable\_billing) | Attach a billing read-only policy (Cost Explorer, Budgets) to the Hermes IAM role | `bool` | `false` | no |
| <a name="input_enable_rds"></a> [enable\_rds](#input\_enable\_rds) | Attach AmazonRDSFullAccess to the Hermes IAM role | `bool` | `false` | no |
| <a name="input_enable_s3"></a> [enable\_s3](#input\_enable\_s3) | Attach AmazonS3FullAccess to the Hermes IAM role | `bool` | `false` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type (minimum: t3.large for Hermes 5 GB RAM requirement) | `string` | `"t3.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of an existing EC2 Key Pair in the selected region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ebs_device"></a> [ebs\_device](#output\_ebs\_device) | Device path the EBS volume is attached to on the instance |
| <a name="output_ebs_volume_id"></a> [ebs\_volume\_id](#output\_ebs\_volume\_id) | ID of the persistent data EBS volume (survives instance replacement) |
| <a name="output_gateway_url"></a> [gateway\_url](#output\_gateway\_url) | Hermes gateway URL |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | EC2 instance ID |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Public IP address of the Hermes instance |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | Direct SSH command |
| <a name="output_ssm_command"></a> [ssm\_command](#output\_ssm\_command) | AWS SSM Session Manager command (no open SSH port needed) |
<!-- END_TF_DOCS -->