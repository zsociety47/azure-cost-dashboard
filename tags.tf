# Tags the nightly delete script reads.
# variables.tf holds project, environment, managed-by, and owner.
# This file adds the two tags that file cannot hold.
#
# lifetime = 1d is the consent for envctl.sh to delete this resource group.
# created is the UTC time of the first apply. timestamp() changes on every
# plan, so the resource that uses these tags must ignore changes to created.
# The budget and the diagnostic setting do not accept tags.

locals {
  created = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())

  tags = merge(var.tags, {
    lifetime = "1d"
    created  = local.created
  })
}
