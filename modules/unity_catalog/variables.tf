variable "bronze_catalog" {
  type        = string
  description = "Kaikille domaineille yhteisen bronze-catalogin nimi"
}

variable "sql_warehouse" {
  type        = string
  description = "SQL warehouse, jossa catalogien luontilauseet ajetaan"
}

variable "domains" {
  type        = list(string)
  description = "Catalogien alkuosat, esim. pipelines, ml"
}

variable "environments" {
  type        = list(string)
  description = "Ympäristöt, joille silver ja gold luodaan"
}

variable "bronze_schemas" {
  type        = list(string)
  description = "Bronze-catalogin schemat"
  default     = []
}

variable "bronze_volumes" {
  type        = map(list(string))
  description = "Bronzen schema => volumet raakatiedostoille. Scheman pitää olla bronze_schemas-listassa."
  default     = {}
}

variable "domain_schemas" {
  type        = map(map(list(string)))
  description = "Domain => kerros => schemat, jotka luodaan domainin sen kerroksen catalogeihin kaikissa ympäristöissä"
  default     = {}
}
