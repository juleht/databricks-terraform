variable "display_name" {
  type        = string
  description = "Service principalin nimi"
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

variable "account_id" {
  type        = string
  description = "Databricks account ID, tarvitaan SP:n käyttöoikeussääntöihin"
}

variable "managers" {
  type        = list(string)
  description = "Saavat hallita SP:tä (roles/servicePrincipal.manager), esim. users/etunimi@example.com"
  default     = []
}

variable "users" {
  type        = list(string)
  description = "Saavat käyttää SP:tä, esim. ajaa jobeja sen nimissä (roles/servicePrincipal.user), esim. groups/data-engineers"
  default     = []
}

variable "catalog_grants" {
  type        = map(list(string))
  description = "Catalog => oikeudet, esim. { bronze = [\"USE_CATALOG\", \"SELECT\"] }"
  default     = {}
}