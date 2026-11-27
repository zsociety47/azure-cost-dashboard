# The folder for the workspace, the action group, and the Logic App.
# Those three files name this block, so Terraform creates the group first.
# The budget and the diagnostic setting sit on the subscription, not in this group.
#
# local.tags adds lifetime = 1d and created. The nightly script deletes a group
# only when lifetime is 1d. timestamp() changes on every plan, so created is
# ignored after the first apply.

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags

  lifecycle {
    ignore_changes = [tags["created"]]
  }
}
