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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.hermes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ssh_cidr"></a> [allowed\_ssh\_cidr](#input\_allowed\_ssh\_cidr) | CIDR allowed for SSH (port 22) and gateway (port 8080) | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region to deploy into | `string` | `"eastasia"` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key content (the full key string, not a file path) | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure Subscription ID to deploy into | `string` | n/a | yes |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Azure VM size (minimum Standard\_D2s\_v3 for Hermes 5 GB RAM requirement) | `string` | `"Standard_D2s_v3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_az_ssh_command"></a> [az\_ssh\_command](#output\_az\_ssh\_command) | Azure CLI SSH command (no open port needed) |
| <a name="output_gateway_url"></a> [gateway\_url](#output\_gateway\_url) | Hermes gateway URL |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | VM name |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | Public IP address of the Hermes instance |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | Direct SSH command |
<!-- END_TF_DOCS -->