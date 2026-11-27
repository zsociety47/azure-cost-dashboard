# Forwards the subscription activity log into the workspace.
# The workspace must exist first, and the subscription id comes from the
# data source in budget.tf. The id is not written in this file.
#
# This setting sits on the subscription, not in the resource group, so the
# nightly delete will not remove it. terraform destroy removes it.
# Copying these logs can incur ingestion charges. The workspace bills
# per gigabyte. There is no daily reservation.
#
# Administrative, Security, and Policy are the three categories in the export.
# A diagnostic setting does not accept tags.
# Microsoft.Insights is not registered yet. Register it before apply.
# This file does not register it.

resource "azurerm_monitor_diagnostic_setting" "subscription_logs" {
  name                       = var.diagnostic_setting_name
  target_resource_id         = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = toset(var.diagnostic_log_categories)
    content {
      category = enabled_log.value
    }
  }
}
