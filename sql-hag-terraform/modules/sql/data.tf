# Data resource to retrieve the existing virtual network information
data "azurerm_virtual_network" "Vnet" {
  name                = local.vnet_name
  resource_group_name = local.vnet_resource_group_name
}

data "azurerm_subnet" "Subnet1" {
  name                 = var.subnet1_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_resource_group_name
}

data "azurerm_subnet" "Subnet2" {
  name                 = var.subnet2_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_resource_group_name
}

data "azurerm_automation_account" "automation_account" {
  name                = local.automation_account_name
  resource_group_name = local.automation_account_rg_name
}
data "local_file" "bootstrap" {
  filename = "./modules/sql/${var.bootstrap_script}"
}
data "local_file" "dsc_mof_primaryVM" {
  filename   = "${azurerm_automation_dsc_configuration.main.name}/${azurerm_windows_virtual_machine.SQLVM[0].name}.mof"
  depends_on = [null_resource.compile_dsc_config_locally]
}
data "local_file" "dsc_mof_secondaryVM" {
  filename   = "${azurerm_automation_dsc_configuration.main.name}/${azurerm_windows_virtual_machine.SQLVM[1].name}.mof"
  depends_on = [null_resource.compile_dsc_config_locally]
}

