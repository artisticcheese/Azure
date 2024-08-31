# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "main" {
  resource_group_name          = data.azurerm_resource_group.main.name
  host_pool_id                 = var.hostpool_id
  location                     = var.location
  type                         = "Desktop"
  name                         = var.application_group_name
  friendly_name                = "Desktop AppGroup"
  description                  = "AVD application group"
  default_desktop_display_name = var.display_name_for_desktop_group
}



resource "azurerm_role_assignment" "Desktop_Virtualization_User" {
  scope                = azurerm_virtual_desktop_application_group.main.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = var.entra_vdiuser_group_guid
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.main.id
  workspace_id         = var.workspace_id
}
