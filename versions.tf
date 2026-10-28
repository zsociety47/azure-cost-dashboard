# Pins the tool versions before any Azure resource is declared.
# terraform init reads this block and downloads the providers it names.
# Later resource files depend on those providers staying the same version.
#
# azurerm manages the resource group, the workspace, the action group,
# the budget, the Logic App, and the diagnostic setting.
# The Microsoft Entra app that GitHub Actions uses is created by the
# shared pipeline-foundation module, not by this repository, so azuread
# is not pinned here.
#
# Remote state is a separate backend.tf. It is not in this file.
# That file is added after the shared state account exists, because
# terraform init would fail if it pointed at an account that is not there yet.

terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 5.10.0"
    }
  }
}
