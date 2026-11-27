# Empty Logic App container.
# It has to name the resource group, so that file comes first.
# The HTTP trigger and the Office 365 email step are clicks in the portal.
# They are not in this file. A callback address is not written here.
#
# Microsoft.Logic is not registered yet. Register it before apply.
# This file does not register it.
#
# local.tags includes created, which changes on every plan, so created
# is ignored after the first apply.

resource "azurerm_logic_app_workflow" "cost_alert" {
  name                = var.logic_app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  lifecycle {
    ignore_changes = [tags["created"]]
  }
}
