# Azure Serverless Course

Hands-on examples and infrastructure for learning how to build serverless applications on Microsoft Azure.

> This project is a work in progress. The repository currently contains the Terraform provider setup that will support later course examples.

## Topics

- Azure Functions
- Infrastructure as code with Terraform
- Serverless application patterns
- Examples in multiple programming languages

## Repository structure

```text
.
├── infra/       # Terraform configuration
└── README.md
```

## Prerequisites

- An Azure subscription
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/install)

## Getting started

Authenticate with Azure, initialize Terraform, and validate the configuration:

```bash
az login
terraform -chdir=infra init
terraform -chdir=infra fmt -check
terraform -chdir=infra validate
```

## Security and costs

- Do not commit credentials, Terraform state, variable files, or saved plan files.
- Review every Terraform plan before applying it.
- Destroy course resources when you finish an exercise to avoid unexpected Azure charges.
