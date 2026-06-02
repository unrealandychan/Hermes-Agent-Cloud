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
