
output "node_config_id" {
  value = azurerm_automation_dsc_nodeconfiguration.sqlconfigSecondary.id
}
output "automation_configuration_name" {
  value = local.azure_automation_configuration_name
}

