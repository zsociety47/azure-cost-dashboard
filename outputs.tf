# Names printed after apply.
# Each value is a name already set in variables.tf.
# The workspace id contains the subscription id, so it is not printed.
# The Logic App access endpoint is not the HTTP trigger address, so it
# is not printed either. The trigger address comes from the portal click.

output "resource_group_name" {
  description = "Resource group that holds the workspace, the action group, and the Logic App."
  value       = azurerm_resource_group.main.name
}

output "log_analytics_workspace_name" {
  description = "Workspace that receives the activity log."
  value       = azurerm_log_analytics_workspace.main.name
}

output "action_group_name" {
  description = "Action group that receives the budget email."
  value       = azurerm_monitor_action_group.email_alerts.name
}

output "budget_name" {
  description = "Subscription budget. It is not inside the resource group."
  value       = azurerm_consumption_budget_subscription.main.name
}

output "logic_app_name" {
  description = "Empty Logic App. The trigger and the email step are portal clicks."
  value       = azurerm_logic_app_workflow.cost_alert.name
}

output "diagnostic_setting_name" {
  description = "Subscription diagnostic setting. It is not inside the resource group."
  value       = azurerm_monitor_diagnostic_setting.subscription_logs.name
}
