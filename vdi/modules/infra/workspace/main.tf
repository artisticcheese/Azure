# Resource group name is output when execution plan is applied.
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  friendly_name       = var.friendly_workspace_name
  description         = var.workspace_description
}
