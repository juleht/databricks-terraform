provider "databricks" {}

locals {
  sql_warehouse  = "Serverless Starter Warehouse"
  bronze_catalog = "bronze"
  domains        = ["data_engineer", "machine_learning"]
  environments   = ["dev", "test", "prod"]

  # Bronze-catalogin schemat
  bronze_schemas = ["bakehouse"]

  # Domain => kerros => schemat. Domain, jota ei ole listattu, ei saa schemoja.
  domain_schemas = {
    data_engineer = {
      silver = ["bakehouse", "sales"]
      gold   = ["sales"]
    }
  }
}

module "unity_catalog" {
  source         = "./modules/unity_catalog"
  sql_warehouse  = local.sql_warehouse
  bronze_catalog = local.bronze_catalog
  domains        = local.domains
  environments   = local.environments
  bronze_schemas = local.bronze_schemas
  domain_schemas = local.domain_schemas
}
