output "catalogs" {
  value = module.unity_catalog.catalog_names
}

output "schemas" {
  value = module.unity_catalog.schema_names
}
