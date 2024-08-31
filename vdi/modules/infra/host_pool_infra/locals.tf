locals {
  workspace_resource_group_name       = element(split("/", var.workspace_id), 4)
  workspace_name                      = element(split("/", var.workspace_id), 8)
  automation_account_rg_name          = element(split("/", var.automation_account_resource_id), 4)
  automation_account_name             = element(split("/", var.automation_account_resource_id), 8)
  azure_automation_configuration_name = "devops_vdi_config"

}

