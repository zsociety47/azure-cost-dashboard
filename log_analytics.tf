# Workspace that will store the activity logs.
# It has to name the resource group, so that file comes first.
# The diagnostic setting, written later, sends logs here.
#
# PerGB2018 bills for the data ingested. There is no daily reservation.
# retention_in_days = 30 is the shortest the workspace allows.
# Microsoft.OperationalInsights is not registered yet. Register it
# before apply. This file does not register it.
#
# local.tags includes created, which changes on every plan, so created
# is ignored after the first apply.

resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = local.tags

  lifecycle {
    ignore_changes = [tags["created"]]
  }
}
