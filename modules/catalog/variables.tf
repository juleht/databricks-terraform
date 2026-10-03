variable "name" {
  type        = string
  description = "Catalogin nimi"
}

variable "comment" {
  type        = string
  description = "Catalogin kommentti"
  default     = null
}

variable "warehouse_id" {
  type        = string
  description = "SQL warehouse, jossa luonti- ja poistolauseet ajetaan"
}

variable "force_destroy" {
  type        = bool
  description = "true: poisto sisältöineen (CASCADE). false: catalog ei poistu, koska siinä on aina default-schema"
  default     = false
}