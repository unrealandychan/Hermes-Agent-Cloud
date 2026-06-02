# Terraform Module: hermes-agent/azure

Deploy [Hermes Agent](https://github.com/unrealandychan/Hermes-Agent-Cloud) on Microsoft Azure (Linux VM + VNet + NSG).

## Registry Usage

```hcl
module "hermes_agent" {
  source  = "unrealandychan/hermes-agent/azure"
  version = "1.4.0"

  subscription_id  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  location         = "eastasia"
  vm_size          = "Standard_D2s_v3"
  ssh_public_key   = file("~/.ssh/id_rsa.pub")
  allowed_ssh_cidr = "203.0.113.0/32"
}
```

> **Monorepo note:** Until published to the Terraform Registry, reference locally:
> ```hcl
> source = "github.com/unrealandychan/Hermes-Agent-Cloud//modules/azure"
> ```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| azurerm | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `subscription_id` | Azure Subscription ID | `string` | — | **yes** |
| `location` | Azure region | `string` | `"eastasia"` | no |
| `vm_size` | Azure VM size (minimum Standard_D2s_v3) | `string` | `"Standard_D2s_v3"` | no |
| `ssh_public_key` | SSH public key content | `string` | — | **yes** |
| `allowed_ssh_cidr` | CIDR allowed for SSH (22) and gateway (8080) | `string` | — | **yes** |

## Outputs

| Name | Description |
|------|-------------|
| `public_ip` | Public IP address of the Hermes VM |
| `instance_id` | VM name |
| `ssh_command` | Direct SSH command |
| `az_ssh_command` | Azure CLI SSH command (no open port needed) |
| `gateway_url` | Hermes gateway URL (http://\<ip\>:8080) |
