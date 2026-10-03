output "display_name" {
  description = "Ryhmän nimi"
  value       = terraform_data.this.output.display_name
}

output "acl_principal_id" {
  description = "Tunniste access control -sääntöihin, esim. groups/data-engineers"
  value       = "groups/${terraform_data.this.output.display_name}"
}