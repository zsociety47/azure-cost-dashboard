#!/bin/bash
# Reads the live cost dashboard and prints a pass/fail table.
# Inputs: an Azure command-line interface (CLI) login, plus .env in this
# folder for the Terraform plan. The alert address is TF_VAR_alert_email.
# The subscription id and the address are not printed.
# Output: ten lines, each PASS or FAIL. Exit 0 when all pass, exit 1 otherwise.
# Side effects: none. terraform plan does not apply.
#
# The workbook and the Office 365 email step are portal clicks. They are
# not lines in this script. A quiet budget is a pass while spend has not
# crossed 25 percent. This script does not fake a crossing.

set -u
set -o pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

resource_group="rg-cost-poc-zeon01"
location="eastus"
workspace_name="log-cost"
action_group_name="ag-cost"
action_short_name="costalerts"
budget_name="budget-cost-zeon01"
logic_app_name="logic-cost"
diagnostic_name="diag-cost-zeon01"
budget_amount="200"
budget_start="2026-11-01"

if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv 2>/dev/null || true)"
  export ARM_SUBSCRIPTION_ID
fi

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

failed=0
pass() { printf '%s  %s: PASS\n' "$1" "$2"; }
fail() { printf '%s  %s: FAIL\n' "$1" "$2"; failed=1; }

group_json="$(az group show --name "$resource_group" \
  --query "{location:location, id:id, tags:tags}" -o json 2>/dev/null || echo '{}')"

group_location="$(printf '%s' "$group_json" | python3 -c '
import json, sys
print((json.load(sys.stdin).get("location") or "").lower())
')"
if [[ "$group_location" == "$location" ]]; then
  pass 1 "Resource group ${resource_group} is in East US"
else
  fail 1 "Resource group ${resource_group} is in East US"
fi

tags_ok="$(printf '%s' "$group_json" | python3 -c '
import json, sys
tags = json.load(sys.stdin).get("tags") or {}
ok = (
    tags.get("lifetime") == "1d"
    and tags.get("owner") == "zeon"
    and tags.get("project") == "08-azure-cost-dashboard"
    and bool(tags.get("created"))
)
print("yes" if ok else "no")
')"
if [[ "$tags_ok" == "yes" ]]; then
  pass 2 "Resource group has lifetime, owner, project, and created"
else
  fail 2 "Resource group has lifetime, owner, project, and created"
fi

scope="$(printf '%s' "$group_json" | python3 -c '
import json, sys
print(json.load(sys.stdin).get("id") or "")
')"

workspace_json="{}"
if [[ -n "$scope" ]]; then
  workspace_json="$(az monitor log-analytics workspace show \
    --resource-group "$resource_group" --workspace-name "$workspace_name" \
    --query "{sku:sku, retention:retentionInDays}" \
    -o json 2>/dev/null || echo '{}')"
fi
workspace_ok="$(printf '%s' "$workspace_json" | python3 -c '
import json, sys
raw = json.load(sys.stdin)
sku = raw.get("sku") or {}
if isinstance(sku, str):
    name, reservation = sku, None
else:
    name = sku.get("name")
    reservation = sku.get("capacityReservationLevel")
unset = reservation in (None, 0, "0", "")
ok = name == "PerGB2018" and int(raw.get("retention") or 0) == 30 and unset
print("yes" if ok else "no")
')"
if [[ "$workspace_ok" == "yes" ]]; then
  pass 3 "Workspace ${workspace_name} is PerGB2018 for 30 days with no reservation"
else
  fail 3 "Workspace ${workspace_name} is PerGB2018 for 30 days with no reservation"
fi

action_json="{}"
if [[ -n "$scope" ]]; then
  action_json="$(az monitor action-group show \
    --resource-group "$resource_group" --name "$action_group_name" \
    --query "{short:groupShortName, receivers:emailReceivers}" \
    -o json 2>/dev/null || echo '{}')"
fi
action_ok="$(printf '%s' "$action_json" | python3 -c '
import json, sys
raw = json.load(sys.stdin)
receivers = raw.get("receivers") or []
def kept(row):
    address = row.get("emailAddress") or ""
    return (
        row.get("name") == "owner-email"
        and row.get("useCommonAlertSchema") is True
        and "@" in address
    )
ok = raw.get("short") == "costalerts" and len(receivers) == 1 and kept(receivers[0])
print("yes" if ok else "no")
')"
if [[ "$action_ok" == "yes" ]]; then
  pass 4 "Action group ${action_group_name} has one email receiver"
else
  fail 4 "Action group ${action_group_name} has one email receiver"
fi

budget_json="{}"
if [[ -n "${ARM_SUBSCRIPTION_ID}" ]]; then
  budget_json="$(az rest --method get \
    --url "https://management.azure.com/subscriptions/${ARM_SUBSCRIPTION_ID}/providers/Microsoft.Consumption/budgets/${budget_name}?api-version=2023-11-01" \
    --query "{amount:properties.amount, grain:properties.timeGrain, start:properties.timePeriod.startDate, notes:properties.notifications}" \
    -o json 2>/dev/null || echo '{}')"
fi
budget_ok="$(printf '%s' "$budget_json" | python3 -c '
import json, sys
raw = json.load(sys.stdin)
notes = list((raw.get("notes") or {}).values())
def quiet(note):
    groups = note.get("contactGroups") or []
    emails = note.get("contactEmails") or []
    return (
        note.get("enabled") is True
        and note.get("operator") == "GreaterThan"
        and note.get("thresholdType") == "Actual"
        and emails == []
        and len(groups) == 1
        and str(groups[0]).lower().endswith("/actiongroups/ag-cost")
    )
got = sorted(float(n.get("threshold") or 0) for n in notes if quiet(n))
start = str(raw.get("start") or "")
ok = (
    float(raw.get("amount") or 0) == 200.0
    and raw.get("grain") == "Monthly"
    and start.startswith("2026-11-01")
    and got == [25.0, 50.0, 100.0]
)
print("yes" if ok else "no")
')"
if [[ "$budget_ok" == "yes" ]]; then
  pass 5 "Budget ${budget_name} is ${budget_amount} monthly from ${budget_start} with three alerts"
else
  fail 5 "Budget ${budget_name} is ${budget_amount} monthly from ${budget_start} with three alerts"
fi

# 25 percent of 200 is 50. GreaterThan stays quiet at 50 and below.
# A missing cost read is a failure. This line does not invent a crossing.
cost_raw=""
if [[ -n "${ARM_SUBSCRIPTION_ID}" ]]; then
  cost_body='{"type":"ActualCost","timeframe":"MonthToDate","dataset":{"granularity":"None","aggregation":{"totalCost":{"name":"Cost","function":"Sum"}}}}'
  cost_raw="$(az rest --method post \
    --url "https://management.azure.com/subscriptions/${ARM_SUBSCRIPTION_ID}/providers/Microsoft.CostManagement/query?api-version=2023-03-01" \
    --body "$cost_body" \
    --query "properties.rows[0][0]" -o tsv 2>/dev/null || true)"
fi
cost_ok="$(COST="$cost_raw" python3 -c '
import os
raw = os.environ.get("COST", "").strip()
try:
    cost = float(raw)
except ValueError:
    print("no")
else:
    print("yes" if cost <= 50 else "no")
')"
if [[ "$cost_ok" == "yes" ]]; then
  pass 6 "Month-to-date spend has not crossed 25 percent of the budget"
else
  fail 6 "Month-to-date spend has not crossed 25 percent of the budget"
fi

policy_json="[]"
if [[ -n "$scope" ]]; then
  policy_json="$(az policy assignment list --scope "$scope" -o json 2>/dev/null || echo '[]')"
fi
policy_ok="$(SCOPE="$scope" python3 -c '
import json, os, sys
scope = os.environ.get("SCOPE", "").lower()
rows = json.load(sys.stdin)
if scope == "":
    print("no")
else:
    own = [row for row in rows if str(row.get("scope") or "").lower() == scope]
    print("yes" if own == [] else "no")
' <<<"$policy_json")"
if [[ "$policy_ok" == "yes" ]]; then
  pass 7 "Resource group has no policy assignment"
else
  fail 7 "Resource group has no policy assignment"
fi

logic_name=""
if [[ -n "$scope" ]]; then
  logic_name="$(az logic workflow show \
    --resource-group "$resource_group" --name "$logic_app_name" \
    --query name -o tsv 2>/dev/null || true)"
fi
if [[ "$logic_name" == "$logic_app_name" ]]; then
  pass 8 "Logic App ${logic_app_name} exists"
else
  fail 8 "Logic App ${logic_app_name} exists"
fi

diagnostic_json="{}"
if [[ -n "${ARM_SUBSCRIPTION_ID}" ]]; then
  diagnostic_json="$(az rest --method get \
    --url "https://management.azure.com/subscriptions/${ARM_SUBSCRIPTION_ID}/providers/microsoft.insights/diagnosticSettings/${diagnostic_name}?api-version=2021-05-01-preview" \
    --query "properties" \
    -o json 2>/dev/null || echo '{}')"
fi
diagnostic_ok="$(printf '%s' "$diagnostic_json" | python3 -c '
import json, sys
raw = json.load(sys.stdin)
logs = raw.get("logs") or raw.get("log") or []
enabled = sorted(
    row.get("category") for row in logs
    if row.get("enabled") is True and row.get("category")
)
workspace = str(raw.get("workspaceId") or "")
ok = enabled == ["Administrative", "Policy", "Security"] and workspace.endswith("/workspaces/log-cost")
print("yes" if ok else "no")
')"
if [[ "$diagnostic_ok" == "yes" ]]; then
  pass 9 "Diagnostic setting ${diagnostic_name} sends three categories to ${workspace_name}"
else
  fail 9 "Diagnostic setting ${diagnostic_name} sends three categories to ${workspace_name}"
fi

plan_log="$(mktemp)"
masked="$(mktemp)"
trap 'rm -f "$plan_log" "$masked"' EXIT
set +e
terraform plan -input=false -detailed-exitcode -no-color >"$plan_log" 2>&1
plan_status=$?
set -e
if [[ "$plan_status" -eq 0 ]]; then
  pass 10 "terraform plan reports no changes"
else
  fail 10 "terraform plan reports no changes"
  sed -E \
    -e 's#/subscriptions/[0-9a-fA-F-]+#/subscriptions/<id>#g' \
    -e 's#[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}#<address>#g' \
    "$plan_log" >"$masked"
  if [[ -n "${ARM_SUBSCRIPTION_ID}" ]]; then
    sed -e "s#${ARM_SUBSCRIPTION_ID}#<id>#g" "$masked" | tail -n 20
  else
    tail -n 20 "$masked"
  fi
fi

exit "$failed"
