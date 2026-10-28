# Names, region, amounts, and tags for this build.
# The provider is already configured. Resource files read these values
# so a name is written once and reused.
#
# The alert address has no default. It is supplied from the environment
# as TF_VAR_alert_email. It is not written in this file.

variable "location" {
  description = "Azure region for every resource in this build."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group that holds the workspace, the action group, and the Logic App."
  type        = string
  default     = "rg-cost-poc-zeon01"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace inside the resource group. Log is Microsoft's abbreviation."
  type        = string
  default     = "log-cost"
}

variable "log_analytics_sku" {
  description = "Workspace pricing. PerGB2018 bills for ingested data. It is not a daily reservation."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "Days before log data is deleted. 30 is the shortest retention the workspace allows."
  type        = number
  default     = 30
}

variable "action_group_name" {
  description = "Action group that receives the budget alerts. Ag is Microsoft's abbreviation."
  type        = string
  default     = "ag-cost"
}

variable "action_group_short_name" {
  description = "Name used in a text message. Azure allows at most 12 characters."
  type        = string
  default     = "costalerts"
}

variable "alert_email" {
  description = "Address that receives the action group email. Supplied at apply time. Not stored in this file."
  type        = string
  sensitive   = true
}

variable "budget_name" {
  description = "Subscription budget name. A budget has no Microsoft abbreviation, so the word budget stays."
  type        = string
  default     = "budget-cost-zeon01"
}

variable "budget_amount" {
  description = "Monthly budget amount in the subscription currency. Alerts fire at percentages of this amount. A budget does not stop spending."
  type        = number
  default     = 200
}

variable "budget_start_date" {
  description = "First day of the budget, in RFC3339. Azure rejects a monthly start date outside the current month. The export used 2026-03-01, which is outside October 2026."
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "budget_threshold_percents" {
  description = "Actual-spend percentages that alert. 25, 50, and 100 percent of 200 are 50, 100, and 200."
  type        = list(number)
  default     = [25, 50, 100]
}

variable "budget_threshold_operator" {
  description = "Comparison for each threshold. GreaterThan does not fire when spend lands exactly on the line."
  type        = string
  default     = "GreaterThan"
}

variable "budget_threshold_type" {
  description = "Actual compares spend so far. Forecasted compares Azure's prediction."
  type        = string
  default     = "Actual"
}

variable "logic_app_name" {
  description = "Logic App container. The workflow steps are added in the portal. Logic is Microsoft's abbreviation."
  type        = string
  default     = "logic-cost"
}

variable "diagnostic_setting_name" {
  description = "Subscription diagnostic setting that forwards the activity log to the workspace."
  type        = string
  default     = "diag-cost-zeon01"
}

variable "diagnostic_log_categories" {
  description = "Activity log categories copied into the workspace. Each category can incur ingestion charges."
  type        = list(string)
  default     = ["Administrative", "Security", "Policy"]
}

variable "tags" {
  description = "Tags shared by resources that accept them. The resource group also gets lifetime and created in a later file. The budget does not accept tags."
  type        = map(string)
  default = {
    project     = "08-azure-cost-dashboard"
    environment = "poc"
    managed-by  = "terraform"
    owner       = "zeon"
  }
}
