variable "account_id" {
  type        = string
  description = "Databricks account ID. Annetaan ympäristömuuttujana TF_VAR_account_id (.env / GitHub secret), ei koodissa."
  sensitive   = true # piilottaa arvon ja siitä johdetut arvot planista, lokeista ja PR-kommenteista
}