resource "databricks_service_principal" "this" {
  display_name = var.display_name

  # Entitlementit: mitä workspacen osia SP saa käyttää (data-oikeudet tulevat granteista)
  workspace_access      = var.workspace_access
  databricks_sql_access = var.databricks_sql_access
}

# Kuka saa hallita ja käyttää SP:tä. Sääntö on autoritatiivinen: se korvaa kaikki SP:n roolit,
# joten managers-listalta puuttuva menettää manager-roolinsa.
# sensitive() piilottaa
# principalit (käyttäjien sähköpostit) planista, lokeista ja PR-kommenteista.
resource "databricks_access_control_rule_set" "this" {
  name = "accounts/${var.account_id}/servicePrincipals/${databricks_service_principal.this.application_id}/ruleSets/default"

  dynamic "grant_rules" {
    for_each = length(var.managers) > 0 ? [1] : []
    content {
      principals = [for p in var.managers : sensitive(p)]
      role       = "roles/servicePrincipal.manager"
    }
  }

  dynamic "grant_rules" {
    for_each = length(var.users) > 0 ? [1] : []
    content {
      principals = [for p in var.users : sensitive(p)]
      role       = "roles/servicePrincipal.user"
    }
  }
}

# databricks_grant (yksikkö) hallitsee vain tämän SP:n oikeuksia catalogissa.
# databricks_grants (monikko) korvaisi kaikki catalogin oikeudet, myös muiden.
# Catalog-tason oikeudet periytyvät kaikkiin catalogin schemoihin ja tauluihin.
resource "databricks_grant" "catalog" {
  for_each = var.catalog_grants

  catalog    = each.key
  principal  = databricks_service_principal.this.application_id
  privileges = each.value
}