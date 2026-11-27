# Remote state for this proof.
# The shared account already exists. Shared keys are off, so Terraform
# signs in with Microsoft Entra. use_azuread_auth is that sign-in.
# The blob key is this project only. Other projects use other keys.
# terraform init has not been run for this file.

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-zeon01"
    storage_account_name = "sttfstatezeon01"
    container_name       = "tfstate"
    key                  = "cost-dashboard.tfstate"
    use_azuread_auth     = true
  }
}
