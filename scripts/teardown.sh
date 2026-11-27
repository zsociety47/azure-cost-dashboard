#!/bin/bash
# Deletes this proof of concept after the resource group name is typed.
# Inputs: an Azure command-line interface (CLI) login, and .env so
# Terraform can read TF_VAR_alert_email. The address is not printed.
# The subscription id is not printed.
# Output: Terraform's destroy plan, then its own yes prompt.
# Side effects: after the typed name matches and you type yes, this
# deletes the resource group and the two resources that sit outside it.
# The nightly delete removes only the group. It does not remove the
# budget or the diagnostic setting. This command does.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

resource_group="rg-cost-poc-zeon01"

echo "This deletes:"
echo "  resource group ${resource_group}"
echo "    workspace log-cost"
echo "    action group ag-cost"
echo "    Logic App logic-cost"
echo "  subscription budget budget-cost-zeon01"
echo "  subscription diagnostic setting diag-cost-zeon01"
echo
echo "The budget and the diagnostic setting are outside the group."
echo "Nothing is deleted until the name matches and you type yes for the destroy plan."
printf 'Type %s to continue: ' "$resource_group"
read -r typed
if [[ "$typed" != "$resource_group" ]]; then
  echo "The name did not match. Nothing was deleted."
  exit 1
fi

if [[ ! -f .env ]]; then
  echo ".env is missing. Nothing was deleted."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${TF_VAR_alert_email:-}" ]]; then
  echo "TF_VAR_alert_email is missing. Nothing was deleted."
  exit 1
fi

if [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
  ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
  export ARM_SUBSCRIPTION_ID
fi

terraform destroy -input=false
