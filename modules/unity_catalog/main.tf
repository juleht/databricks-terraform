locals {
  layers = ["silver", "gold"]

  # Kaikki yhdistelmät domain × kerros × ympäristö, esim. machine_learning_gold_dev => { domain = "machine_learning", layer = "gold", env = "dev" }
  env_catalogs = {
    for combo in setproduct(var.domains, local.layers, var.environments) :
    join("_", combo) => { domain = combo[0], layer = combo[1], env = combo[2] }
  }

  # Jokainen catalog × sen domainin ja kerroksen schemat, esim. "data_engineer_silver_dev.sales" => { catalog, schema, env }
  # Domain, jolle ei ole määritelty schemoja, ei saa yhtään schemaa.
  env_schemas = {
    for s in flatten([
      for catalog, c in local.env_catalogs : [
        for schema in lookup(lookup(var.domain_schemas, c.domain, {}), c.layer, []) :
        { catalog = catalog, schema = schema, env = c.env }
      ]
    ]) : "${s.catalog}.${s.schema}" => s
  }

  # Bronzen volumet, esim. "taxi.raw" => { schema = "taxi", volume = "raw" }
  bronze_volumes = {
    for v in flatten([
      for schema, volumes in var.bronze_volumes : [
        for volume in volumes : { schema = schema, volume = volume }
      ]
    ]) : "${v.schema}.${v.volume}" => v
  }
}

data "databricks_sql_warehouse" "this" {
  name = var.sql_warehouse
}

# Yksi bronze, yhteinen kaikille domaineille ja ympäristöille
module "bronze" {
  source = "../catalog"

  name         = var.bronze_catalog
  comment      = "Hallinnoi Terraform (shared)"
  warehouse_id = data.databricks_sql_warehouse.this.id
}

# Silver ja gold jokaiselle domainille ja ympäristölle
module "env" {
  source   = "../catalog"
  for_each = local.env_catalogs

  name          = each.key
  comment       = "Hallinnoi Terraform (${each.value.env})"
  force_destroy = contains(["dev", "test"], each.value.env) // dev ja test poistetaan sisältöineen, prod ei poistu
  warehouse_id  = data.databricks_sql_warehouse.this.id
}

# Schemat toimivat Free Editionissa API:n kautta, joten käytetään providerin omaa resurssia.
# catalog_name viittaa catalog-moduulin outputiin, joten catalog luodaan aina ennen schemaa.

# Bronzen schemat
resource "databricks_schema" "bronze" {
  for_each = toset(var.bronze_schemas)

  catalog_name = module.bronze.name
  name         = each.key
  comment      = "Hallinnoi Terraform (shared)"
}

# Bronzen volumet raakatiedostoille (managed: tiedostot metastoren oletustallennustilassa)
resource "databricks_volume" "bronze" {
  for_each = local.bronze_volumes

  catalog_name = module.bronze.name
  schema_name  = databricks_schema.bronze[each.value.schema].name # virhe, jos schemaa ei ole bronze_schemas-listassa
  name         = each.value.volume
  volume_type  = "MANAGED"
  comment      = "Raakatiedostot sellaisenaan. Hallinnoi Terraform (shared)"
}

# Silverin ja goldin schemat domaineittain
resource "databricks_schema" "env" {
  for_each = local.env_schemas

  catalog_name  = module.env[each.value.catalog].name
  name          = each.value.schema
  comment       = "Hallinnoi Terraform (${each.value.env})"
  force_destroy = contains(["dev", "test"], each.value.env) // dev ja test poistetaan sisältöineen, prod vain tyhjänä
}

# --- Alkuperäinen toteutus databricks_catalog-resurssilla ---
# Ei toimi Free Editionissa: "Metastore storage root URL does not exist. Default Storage is enabled".
# Voidaan ottaa takaisin käyttöön workspacessa, jossa metastorella on storage root.
#
# resource "databricks_catalog" "bronze" {
#   name    = var.bronze_catalog
#   comment = "Hallinnoi Terraform (shared)"
# }
#
# resource "databricks_catalog" "env" {
#   for_each = local.env_catalogs
#
#   name          = each.key
#   comment       = "Hallinnoi Terraform (${each.value.env})"
#   force_destroy = contains(["dev", "test"], each.value.env) // dev ja test poistetaan sisältöineen, prod vain tyhjänä
# }