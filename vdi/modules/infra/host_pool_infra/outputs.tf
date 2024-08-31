
output "azurerm_virtual_desktop_hostpool_id" {
  value = azurerm_virtual_desktop_host_pool.hostpool.id
}

output "azurerm_virtual_desktop_host_pool_registration_token" {
  sensitive = true
  value     = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
}

