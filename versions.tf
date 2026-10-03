terraform {
  required_version = ">= 1.5" # Terraform-CLI:n vähimmäisversio

  cloud {
    organization = "orgjtlehto"

    workspaces {
      name = "databricks_infrastructure"
    }
  }

  required_providers {
    databricks = {
      source  = "databricks/databricks" # mistä provider ladataan (Terraform Registry)
      version = "~> 1.13"               # mikä versio hyväksytään
    }
  }
}