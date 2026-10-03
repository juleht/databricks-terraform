output "application_id" {
  description = "SP:n Application ID, jota käytetään granteissa ja tunnistautumisessa"
  value       = databricks_service_principal.this.application_id
}

output "display_name" {
  description = "SP:n nimi"
  value       = databricks_service_principal.this.display_name
}