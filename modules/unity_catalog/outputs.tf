output "catalog_names" {
  description = "Kaikki luodut catalogit"
  value       = concat([module.bronze.name], [for c in module.env : c.name])
  # value     = concat([databricks_catalog.bronze.name], keys(databricks_catalog.env))
}

output "schema_names" {
  description = "Kaikki luodut schemat muodossa catalog.schema"
  value       = concat([for s in databricks_schema.bronze : s.id], keys(databricks_schema.env))
}