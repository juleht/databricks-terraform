variable "display_name" {
  type        = string
  description = "Ryhmän nimi"
}

variable "workspace_access" {
  type        = bool
  description = "Workspace access: notebookit, jobit ja pipelinet"
  default     = false
}

variable "databricks_sql_access" {
  type        = bool
  description = "Databricks SQL access: SQL warehouset ja SQL-editori"
  default     = false
}

variable "catalog_grants" {
  type        = map(list(string))
  description = "Catalog => oikeudet, esim. { bronze = [\"USE_CATALOG\", \"SELECT\"] }"
  default     = {}
}