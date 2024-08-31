
data "azurerm_resource_group" "main" {
  name = local.workspace_resource_group_name
}

data "azurerm_virtual_desktop_workspace" "main" {
  name                = local.workspace_name
  resource_group_name = local.workspace_resource_group_name
}
data "azuread_service_principal" "avd-sp" {
  display_name = "Azure Virtual Desktop"
}

