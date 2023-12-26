locals {
  vnet_resource_group_name   = element(split("/", var.vnet_id), 4)
  vnet_name                  = element(split("/", var.vnet_id), 8)
  NICs                       = toset([azurerm_network_interface.SQLNIC1.id, azurerm_network_interface.SQLNIC2.id])
  SubnetMask1                = cidrnetmask(data.azurerm_subnet.Subnet1.address_prefixes[0])
  SubnetMask2                = cidrnetmask(data.azurerm_subnet.Subnet2.address_prefixes[0])
  automation_account_rg_name = element(split("/", var.automation_account_resource_id), 4)
  automation_account_name    = element(split("/", var.automation_account_resource_id), 8)
  region_codes = {
    "australiaeast" = "au"
    "eastus"        = "es"
    "westeurope"    = "we"
    # Add more mappings as needed
  }
  azure_automation_configuration_name = "${var.prefix}_${var.project}_${var.DSCconfigurationName}"
  region_code                         = try(local.region_codes[var.location], null)
  DSCconfig = templatefile("./modules/sql/dsc-compile.tftpl",
    {
      vmPassword                = random_password.vmAdminPass.result,
      vmUsername                = var.vm_admin_user,
      PrimaryNodeName           = azurerm_windows_virtual_machine.SQLVM[0].name,
      SecondaryNodeName         = azurerm_windows_virtual_machine.SQLVM[1].name,
      vmDnsZone                 = var.DNS_Private_Zone,
      clusterName               = var.clustername,
      clusterIP1                = azurerm_network_interface.SQLNIC1.private_ip_addresses[1],
      clusterSubNetMask1        = var.cluster_subnet_mask,
      clusterIP2                = azurerm_network_interface.SQLNIC2.private_ip_addresses[1],
      clusterSubNetMask2        = var.cluster_subnet_mask,
      listenerName              = var.listener_name,
      listenerIP1               = azurerm_network_interface.SQLNIC1.private_ip_addresses[2],
      listenerIP2               = azurerm_network_interface.SQLNIC2.private_ip_addresses[2],
      witnessStorageAccountName = azurerm_storage_account.SQLCluster.name,
      dbMasterKeyPassword       = random_password.sqlMasterKey.result,
      dbLoginPassword           = random_password.sqlLoginAdminPass.result,
      DataPath                  = var.diskinfo.sqldata.path,
      LogPath                   = var.diskinfo.sqllog.path,
      BackupPath                = var.backup_path
      TempDBPath                = var.temp_db_path
      TempLOGPath               = var.temp_db_path
      witnessStorageKey         = azurerm_storage_account.SQLCluster.primary_access_key
      configurationName         = local.azure_automation_configuration_name
      scriptVersion             = var.DSCconfigurationName
  })
}
