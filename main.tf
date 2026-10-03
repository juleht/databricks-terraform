provider "databricks" {}

# Kirjautunut käyttäjä (paikallisesti sinä, GitHubissa PAT:n omistaja), SP:n manageriksi
data "databricks_current_user" "me" {}

locals {
  sql_warehouse  = "Serverless Starter Warehouse"
  bronze_catalog = "bronze"
  domains        = ["data_engineer", "machine_learning"]
  environments   = ["dev", "test", "prod"]

  # Bronze-catalogin schemat
  bronze_schemas = ["bakehouse", "taxi"]

  # Bronzen schema => volumet raakatiedostoille, esim. /Volumes/bronze/taxi/raw/
  bronze_volumes = {
    taxi = ["raw"]
  }

  # Domain => kerros => schemat. Domain, jota ei ole listattu, ei saa schemoja.
  domain_schemas = {
    data_engineer = {
      silver = ["bakehouse", "sales", "taxi"]
      gold   = ["sales", "taxi"]
    }
  }

  # Projektin omat oikeuspaketit (Unity Catalogissa ei ole valmiita rooleja)
  privileges = {
    contribute = [
      "USE_CATALOG", "USE_SCHEMA",
      "APPLY_TAG",
      "EXECUTE", "READ_VOLUME", "SELECT",
      "MODIFY", "WRITE_VOLUME",
      "CREATE_FUNCTION", "CREATE_MATERIALIZED_VIEW", "CREATE_MODEL",
      // CREATE SCHEMA
      "CREATE_TABLE",
      "CREATE_VOLUME",
    ]
    read = [
      "USE_CATALOG", "USE_SCHEMA",
      "SELECT", "READ_VOLUME",
      "EXECUTE",
    ]
  }
}

module "unity_catalog" {
  source         = "./modules/unity_catalog"
  sql_warehouse  = local.sql_warehouse
  bronze_catalog = local.bronze_catalog
  domains        = local.domains
  environments   = local.environments
  bronze_schemas = local.bronze_schemas
  bronze_volumes = local.bronze_volumes
  domain_schemas = local.domain_schemas
}

# Data engineer -putkien SP: CONTRIBUTE omiin catalogeihin, READ bronzeen
module "data_engineer_sp" {
  source       = "./modules/service_principals"
  display_name = "data-engineer-sp"

  workspace_access      = true
  databricks_sql_access = true

  # Sinä hallitset SP:tä, data-engineers-ryhmä saa käyttää sitä (esim. jobien run_as)
  account_id = var.account_id
  managers   = [data.databricks_current_user.me.acl_principal_id]
  users      = [module.data_engineers_group.acl_principal_id]

  catalog_grants = merge(
    { for c in module.unity_catalog.domain_catalogs["data_engineer"] : c => local.privileges.contribute },
    { (local.bronze_catalog) = local.privileges.read },
  )

  # Catalogit pitää olla olemassa ennen grantteja
  depends_on = [module.unity_catalog]
}

# Data engineer -käyttäjät: CONTRIBUTE dev- ja test-catalogeihin, READ prodiin ja bronzeen
module "data_engineers_group" {
  source       = "./modules/account_group"
  display_name = "data-engineers"

  workspace_access      = true
  databricks_sql_access = true

  catalog_grants = merge(
    {
      for name, c in module.unity_catalog.env_catalogs :
      name => c.env == "prod" ? local.privileges.read : local.privileges.contribute
      if c.domain == "data_engineer"
    },
    { (local.bronze_catalog) = local.privileges.read },
  )

  # Catalogit pitää olla olemassa ennen grantteja
  depends_on = [module.unity_catalog]
}

# Ingestion-jobien SP: CONTRIBUTE bronzeen (sisältää raw-volumet), ei pääsyä silveriin ja goldiin
module "integration_engineers_sp" {
  source       = "./modules/service_principals"
  display_name = "integration-engineers-sp"

  workspace_access      = true
  databricks_sql_access = true

  # Sinä hallitset SP:tä, integration-engineers-ryhmä saa käyttää sitä (esim. jobien run_as)
  account_id = var.account_id
  managers   = [data.databricks_current_user.me.acl_principal_id]
  users      = [module.integration_engineers_group.acl_principal_id]

  catalog_grants = {
    (local.bronze_catalog) = local.privileges.contribute
  }

  # Catalogit pitää olla olemassa ennen grantteja
  depends_on = [module.unity_catalog]
}

# Integration engineer -käyttäjät: CONTRIBUTE bronzeen (sisältää raw-volumet)
module "integration_engineers_group" {
  source       = "./modules/account_group"
  display_name = "integration-engineers"

  workspace_access      = true
  databricks_sql_access = true

  catalog_grants = {
    (local.bronze_catalog) = local.privileges.contribute
  }

  # Catalogit pitää olla olemassa ennen grantteja
  depends_on = [module.unity_catalog]
}
