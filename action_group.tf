# Who gets the budget email.
# The budget, written later, points at this block, so the group comes first.
# The address is TF_VAR_alert_email. It is not written in this file.
#
# short_name is what a text message would show. Azure allows 12 characters.
# use_common_alert_schema makes the email body the same shape for every alert.
# Microsoft.Insights is not registered yet. Register it before apply.
# This file does not register it.
#
# The Logic App is a separate resource. Its email step is a portal click,
# so this group does not call the Logic App.
#
# local.tags includes created, which changes on every plan, so created
# is ignored after the first apply.

resource "azurerm_monitor_action_group" "email_alerts" {
  name                = var.action_group_name
  resource_group_name = azurerm_resource_group.main.name
  short_name          = var.action_group_short_name

  email_receiver {
    name                    = "owner-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags["created"]]
  }
}
