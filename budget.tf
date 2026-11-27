# Monthly budget on the whole subscription.
# It notifies the action group. It does not stop spending.
# It does not live in the resource group, so the nightly delete will not remove it.
# terraform destroy removes it. The GitHub identity cannot create it.
# The laptop login can.
#
# The data source reads the subscription from the current sign-in.
# The id is not written in this file. The diagnostic setting will use the same read.
#
# The export start date was 2026-03-01. A monthly budget must start on the
# first day of the current month, so this one starts on 2026-11-01.
# GreaterThan does not fire when spend lands exactly on the line.
# A budget does not accept tags.

data "azurerm_client_config" "current" {}

resource "azurerm_consumption_budget_subscription" "main" {
  name = var.budget_name
  # The data source returns the id alone. This resource requires the
  # full path, the same shape the diagnostic setting already uses.
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = toset(var.budget_threshold_percents)
    content {
      enabled        = true
      threshold      = notification.value
      operator       = var.budget_threshold_operator
      threshold_type = var.budget_threshold_type
      contact_groups = [azurerm_monitor_action_group.email_alerts.id]
    }
  }
}
