# Signs in to Azure before any resource file runs.
# versions.tf already pinned the provider. Later resource files use this
# sign-in. They do not sign in themselves.
#
# Authentication uses the Azure command-line interface (CLI) login already
# on this machine. The subscription id is read from the ARM_SUBSCRIPTION_ID
# environment variable, so it is not stored in this file. ARM is the prefix
# the Azure Resource Manager provider uses for its environment variables.
#
# The Microsoft Entra app for GitHub is created by the shared pipeline
# module, not here, so there is no second provider.

provider "azurerm" {
  # Do not register Azure resource providers during apply.
  # Microsoft.Insights, Microsoft.Logic, and Microsoft.OperationalInsights
  # are not registered yet. Register those three by name before apply,
  # so the change is visible. An apply must not register them as a side effect.
  resource_provider_registrations = "none"

  # The shared state account has shared keys off. When backend.tf is added,
  # reading the state blob signs in with Microsoft Entra, not a storage key.
  storage_use_azuread = true

  # Required by the provider even when no feature flags are set.
  features {}
}
