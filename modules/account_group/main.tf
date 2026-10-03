# Account-tason ryhmä, joka luodaan Databricks CLI:llä.
# Free Edition: databricks_group luo workspace-paikallisen ryhmän, jota Unity Catalog ei hyväksy
# granteissa, ja api = "account" vaatii account-hostin, jota Free Editionissa ei ole.
# Workspace välittää account-tason SCIM-kutsut osoitteessa /api/2.0/account/scim/v2.
resource "terraform_data" "this" {
  # Destroy-vaihe näkee vain self-arvot, joten nimi tallennetaan inputiin
  input = {
    display_name = var.display_name
  }

  # jq -e kaataa ajon, jos vastauksessa ei ole ryhmän id:tä
  provisioner "local-exec" {
    command     = "databricks api post /api/2.0/account/scim/v2/Groups --json \"$BODY\" | jq -e '.id'"
    environment = { BODY = jsonencode({ displayName = self.input.display_name }) }
  }

  # Poistossa ryhmän id haetaan nimellä
  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOT
      id=$(databricks api get /api/2.0/account/scim/v2/Groups | jq -r --arg n "$NAME" '.Resources[] | select(.displayName == $n) | .id')
      [ -z "$id" ] || databricks api delete /api/2.0/account/scim/v2/Groups/$id
    EOT
    environment = { NAME = self.input.display_name }
  }
}

# Ryhmä liitetään workspaceen, jotta sille voi antaa entitlementit
resource "databricks_permission_assignment" "this" {
  group_name  = terraform_data.this.output.display_name
  permissions = ["USER"]
}

# Entitlementit: mitä workspacen osia ryhmä saa käyttää (data-oikeudet tulevat granteista)
resource "databricks_entitlements" "this" {
  group_id              = databricks_permission_assignment.this.id
  workspace_access      = var.workspace_access
  databricks_sql_access = var.databricks_sql_access
}

# databricks_grant (yksikkö) hallitsee vain tämän ryhmän oikeuksia catalogissa.
# Catalog-tason oikeudet periytyvät kaikkiin catalogin schemoihin ja tauluihin.
resource "databricks_grant" "catalog" {
  for_each = var.catalog_grants

  catalog    = each.key
  principal  = terraform_data.this.output.display_name
  privileges = each.value
}