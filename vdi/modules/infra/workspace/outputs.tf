output "azure_virtual_desktop_compute_resource_group_id" {
  description = "Name of the Resource group in which to deploy session host"
  value       = azurerm_resource_group.main.id
}


output "azurerm_virtual_desktop_workspace_id" {
  description = "Name of the Azure Virtual Desktop workspace"
  value       = azurerm_virtual_desktop_workspace.workspace.id
}

output "automation_account_id" {
  value = azurerm_automation_account.main.id
}

