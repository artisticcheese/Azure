locals {
  workspace_resource_group_name = element(split("/", var.workspace_id), 4)
  workspace_name                = element(split("/", var.workspace_id), 8)
  resource_group_name           = element(split("/", var.resource_group_id), 4)
}

