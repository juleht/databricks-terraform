output "catalog_names" {
  description = "Kaikki luodut catalogit"
  value       = concat([module.bronze.name], [for c in module.env : c.name])
  # value     = concat([databricks_catalog.bronze.name], keys(databricks_catalog.env))
}

# Nimet tulevat localsista, jotta ne tiedetään jo planissa (for_each-avaimiksi)
output "domain_catalogs" {
  description = "Domain => sen silver- ja gold-catalogit kaikissa ympäristöissä"
  value = {
    for d in var.domains : d => [for name, c in local.env_catalogs : name if c.domain == d]
  }
}

output "env_catalogs" {
  description = "Silver- ja gold-catalogit tietoineen, esim. data_engineer_gold_dev => { domain, layer, env }"
  value       = local.env_catalogs
}

output "schema_names" {
  description = "Kaikki luodut schemat muodossa catalog.schema"
  value       = concat([for s in databricks_schema.bronze : s.id], keys(databricks_schema.env))
}