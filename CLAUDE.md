# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A learning repository for Azure serverless (Azure Functions, IaC with Terraform). Currently it contains only the Terraform configuration in `infra/`; function app code will come later. Because it is course material, `infra/provider.tf` carries long explanatory comments — keep that teaching-oriented commenting style when adding new configuration.

## Commands

All Terraform commands run against `infra/`:

```bash
az login                          # required: the azurerm provider authenticates via Azure CLI
terraform -chdir=infra init
terraform -chdir=infra fmt -check
terraform -chdir=infra validate
terraform -chdir=infra plan
terraform -chdir=infra apply
terraform -chdir=infra destroy    # tear down after an exercise to avoid charges
```

There is no test suite, build step, or linter beyond `terraform fmt` / `validate`.

## Architecture

Single flat Terraform root module in `infra/` (no submodules). Files are split by purpose rather than by resource type:

- `provider.tf` — azurerm `~> 3.0`, `features {}`.
- `backend.tf` — remote state in an Azure Storage blob (`serverless-rg` / `tfstateserverless0508` / container `tfstate`). This storage account was created **manually, outside Terraform**, and is not managed by this configuration. The blob lease acts as the state lock, preventing concurrent applies.
- `variables.tf` — `project_name` (`order-system`), `environment` (`dev`), `location` (`westus3`). Everything has a default, so no `.tfvars` file is needed.
- `main.tf` — shared foundation: resource group, Linux consumption service plan (`Y1`), and the storage account backing the function apps.
- `function-app-order-api.tf` — one file per function app. Holds the Linux function app plus its Application Insights instance and the shared Log Analytics workspace.
- `outputs.tf` — resource group name and function app hostname.

### Naming convention

Resource names are composed from the variables with a type suffix: `${var.project_name}-${var.environment}-<suffix>` where suffix is `rg`, `asp`, `law`, `ai`, `func`. Storage account names strip hyphens and lowercase (`${replace(var.project_name, "-", "")}${var.environment}sa`) because Azure only allows lowercase alphanumerics there. Follow this pattern for new resources.

Azure storage account and function app names are globally unique across all of Azure, so a name collision on `apply` is normally resolved by bumping a numeric suffix on the name.

### Adding a new function app

Create a new `function-app-<name>.tf` that reuses `azurerm_resource_group.main`, `azurerm_service_plan.my_plan`, `azurerm_storage_account.main`, and `azurerm_log_analytics_workspace.main`, and adds its own `azurerm_application_insights` instance.

## Conventions

- Every resource carries a `tags = { "course" = "serverless" }` tag.
- Never commit `local.settings.json`, `*.tfvars`, state files, or plan files — all are gitignored.
