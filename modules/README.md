# Terraform Modules — Hermes Agent Cloud

This directory contains Terraform Registry-compatible modules for deploying Hermes Agent across AWS, GCP, and Azure.

## Structure

```
modules/
├── aws/          # AWS (EC2 + IAM + EBS + SSM)
├── gcp/          # GCP (Compute Engine + VPC + IAM + optional services)
└── azure/        # Azure (Linux VM + VNet + NSG)
```

Each module is a copy of the canonical source under `cli/terraform/<provider>/` and includes a `README.md` with full inputs/outputs documentation.

## Local Usage

Reference any module directly from GitHub:

```hcl
module "hermes_agent_aws" {
  source = "github.com/unrealandychan/Hermes-Agent-Cloud//modules/aws"
  # ...
}
```

## Publishing to the Terraform Registry

The Terraform Registry requires **one module per GitHub repository**, named `terraform-<provider>-<name>`. Since this is a monorepo, the recommended publication path is:

### Option A — Separate mirror repos (recommended for Registry)

1. Create three repos:
   - `terraform-aws-hermes-agent`
   - `terraform-google-hermes-agent`
   - `terraform-azurerm-hermes-agent`
2. Mirror / sync the contents of `modules/aws`, `modules/gcp`, `modules/azure` respectively.
3. Tag a release (e.g. `v1.4.0`) in each repo.
4. Connect each repo at [registry.terraform.io](https://registry.terraform.io/publish/module).

Users can then consume:
```hcl
module "hermes_agent" {
  source  = "unrealandychan/hermes-agent/aws"
  version = "1.4.0"
  # ...
}
```

### Option B — Monorepo submodule path (no Registry)

Reference the GitHub path directly with a `//` subpath:

```hcl
module "hermes_agent" {
  source = "github.com/unrealandychan/Hermes-Agent-Cloud//modules/aws?ref=v1.4.0"
}
```

## Auto-generated Docs

The `.github/workflows/tf-docs.yml` workflow automatically regenerates `README.md` files in each module directory whenever `.tf` files change on the `main` branch using [terraform-docs](https://terraform-docs.io).
