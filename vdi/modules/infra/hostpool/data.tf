data "azurerm_virtual_desktop_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = local.workspace_resource_group_name
}


data "azurerm_virtual_desktop_host_pool" "main" {
  name                = local.hostpool_name
  resource_group_name = local.hostpool_resource_group_name
}
data "local_file" "bootstrap" {
  filename = "./modules/infra/hostpool/tools/bootstrap.ps1"
}


data "azurerm_automation_account" "main" {
  name                = local.automation_account_name
  resource_group_name = local.automation_account_rg_name
}
