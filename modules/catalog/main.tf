# Yksi Unity Catalog -catalog, joka luodaan SQL:llä.
# Free Edition: catalogia ei voi luoda API:n kautta (Default Storage), joten
# CREATE/DROP CATALOG ajetaan SQL warehousessa Databricks CLI:llä.
# jq -e kaataa ajon, jos SQL epäonnistuu (API vastaa onnistuneesti myös silloin).

locals {
  comment_sql = var.comment == null ? "" : " COMMENT '${var.comment}'"
}

resource "terraform_data" "this" {
  # Destroy-vaihe näkee vain self-arvot, joten kaikki poistoon tarvittava tallennetaan inputiin
  input = {
    name         = var.name
    warehouse_id = var.warehouse_id
    drop_sql     = "DROP CATALOG IF EXISTS ${var.name}${var.force_destroy ? " CASCADE" : ""}"
  }

  provisioner "local-exec" {
    command = "databricks api post /api/2.0/sql/statements --json \"$BODY\" | jq -e '.status.state == \"SUCCEEDED\"'"
    environment = {
      BODY = jsonencode({
        warehouse_id = self.input.warehouse_id
        statement    = "CREATE CATALOG IF NOT EXISTS ${self.input.name}${local.comment_sql}"
        wait_timeout = "50s"
      })
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "databricks api post /api/2.0/sql/statements --json \"$BODY\" | jq -e '.status.state == \"SUCCEEDED\"'"
    environment = {
      BODY = jsonencode({
        warehouse_id = self.input.warehouse_id
        statement    = self.input.drop_sql
        wait_timeout = "50s"
      })
    }
  }
}