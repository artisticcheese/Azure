
#################################################################
### Resource Group
data "azurerm_resource_group" "SQLVMAG" {
  name = var.resource_group_name
}

#################################################################
## Keyvault 

data "azurerm_client_config" "current" {}


resource "random_integer" "kvrandom" {
  min = 100
  max = 999

}

resource "random_string" "kvrandom" {
  length  = 5 # Adjust the length as needed
  special = false
}


resource "azurerm_key_vault" "sqlagkv" {
  name                        = "${var.project}-${var.environment}-${random_string.kvrandom.result}"
  location                    = data.azurerm_resource_group.SQLVMAG.location
  resource_group_name         = data.azurerm_resource_group.SQLVMAG.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  sku_name                    = "standard"
  purge_protection_enabled    = true
  tags                        = var.tags
  enable_rbac_authorization   = true
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
}


resource "random_password" "vmAdminPass" {
  length           = 18
  special          = true
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  min_special      = 2
  override_special = "!@#_"
}

resource "random_password" "sqlLoginAdminPass" {
  length           = 16
  special          = true
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  min_special      = 2
  override_special = "!@#_"
}

resource "random_password" "sqlMasterKey" {
  length           = 16
  special          = true
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  min_special      = 2
  override_special = "!@#_"
}

resource "azurerm_key_vault_secret" "VMAdminUser" {
  name         = "vm-admin-username"
  value        = var.vm_admin_user
  key_vault_id = azurerm_key_vault.sqlagkv.id
  depends_on   = [azurerm_key_vault.sqlagkv]
}

resource "azurerm_key_vault_secret" "VMAdminPassword" {
  name         = "vm-password"
  value        = random_password.vmAdminPass.result
  key_vault_id = azurerm_key_vault.sqlagkv.id
  depends_on   = [azurerm_key_vault.sqlagkv]
}

resource "azurerm_key_vault_secret" "sqlLoginAdminUser" {
  name         = "sql-login-admin-user"
  value        = var.sql_login_admin_user
  key_vault_id = azurerm_key_vault.sqlagkv.id
  depends_on   = [azurerm_key_vault.sqlagkv]
}

resource "azurerm_key_vault_secret" "sqlLoginAdminPass" {
  name         = "sql-login-admin-pass"
  value        = random_password.sqlLoginAdminPass.result
  key_vault_id = azurerm_key_vault.sqlagkv.id
  depends_on   = [azurerm_key_vault.sqlagkv]
}

resource "azurerm_key_vault_secret" "sqlMasterKey" {
  name         = "sql-Master-Key"
  value        = random_password.sqlMasterKey.result
  key_vault_id = azurerm_key_vault.sqlagkv.id
  depends_on   = [azurerm_key_vault.sqlagkv]
}

##################################################################
## SQL VM
resource "azurerm_network_interface" "SQLNIC1" {
  name                = "${var.project}-1-nic"
  location            = data.azurerm_resource_group.SQLVMAG.location
  resource_group_name = data.azurerm_resource_group.SQLVMAG.name
  tags                = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = data.azurerm_subnet.Subnet1.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = data.azurerm_subnet.Subnet1.id
    private_ip_address_allocation = "Dynamic"
  }

  ip_configuration {
    name                          = "internal3"
    subnet_id                     = data.azurerm_subnet.Subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "SQLNIC2" {
  name                = "${var.project}-2-nic"
  location            = data.azurerm_resource_group.SQLVMAG.location
  resource_group_name = data.azurerm_resource_group.SQLVMAG.name
  tags                = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = data.azurerm_subnet.Subnet2.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = data.azurerm_subnet.Subnet2.id
    private_ip_address_allocation = "Dynamic"
  }

  ip_configuration {
    name                          = "internal3"
    subnet_id                     = data.azurerm_subnet.Subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}



resource "azurerm_windows_virtual_machine" "SQLVM" {
  count                 = 2
  name                  = "${var.project}-VM${var.Itemslist[count.index]}"
  resource_group_name   = data.azurerm_resource_group.SQLVMAG.name
  location              = data.azurerm_resource_group.SQLVMAG.location
  computer_name         = "${var.project}-VM${var.Itemslist[count.index]}"
  size                  = var.vm_size
  admin_username        = azurerm_key_vault_secret.VMAdminUser.value
  admin_password        = azurerm_key_vault_secret.VMAdminPassword.value
  network_interface_ids = [tolist(local.NICs)[count.index]]
  zone                  = var.Itemslist[count.index]
  tags                  = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

  os_disk {
    caching              = var.diskinfo.osdisk.caching
    storage_account_type = var.diskinfo.osdisk.DiskType
  }

  identity {
    type = "SystemAssigned"

  }

  additional_capabilities {
    ultra_ssd_enabled = true
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2022"
    sku       = "enterprise-gen2"
    version   = "latest"
  }

}

resource "azurerm_managed_disk" "SQLDataDisk" {

  count                = 2
  name                 = "${azurerm_windows_virtual_machine.SQLVM.*.name[count.index]}-DataDisk"
  location             = data.azurerm_resource_group.SQLVMAG.location
  resource_group_name  = data.azurerm_resource_group.SQLVMAG.name
  storage_account_type = var.diskinfo.sqldata.DiskType
  create_option        = "Empty"
  disk_size_gb         = var.diskinfo.sqldata.DiskSize
  logical_sector_size  = var.diskinfo.sqldata.Logical_Sector_Size
  disk_iops_read_write = var.diskinfo.sqldata.iops
  disk_mbps_read_write = var.diskinfo.sqldata.bandwidth
  zone                 = azurerm_windows_virtual_machine.SQLVM.*.zone[count.index]
  tags                 = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "DataDiskAttach" {

  count              = 2
  managed_disk_id    = azurerm_managed_disk.SQLDataDisk.*.id[count.index]
  virtual_machine_id = azurerm_windows_virtual_machine.SQLVM.*.id[count.index]
  lun                = 0
  caching            = var.diskinfo.sqldata.caching
}

resource "azurerm_managed_disk" "LogDisk" {

  count                = 2
  name                 = "${azurerm_windows_virtual_machine.SQLVM.*.name[count.index]}-LogDisk"
  location             = data.azurerm_resource_group.SQLVMAG.location
  resource_group_name  = data.azurerm_resource_group.SQLVMAG.name
  storage_account_type = var.diskinfo.sqllog.DiskType
  create_option        = "Empty"
  disk_size_gb         = var.diskinfo.sqllog.DiskSize
  disk_iops_read_write = var.diskinfo.sqllog.iops
  disk_mbps_read_write = var.diskinfo.sqllog.bandwidth
  zone                 = azurerm_windows_virtual_machine.SQLVM.*.zone[count.index]
  tags                 = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "LogDiskAttach" {

  count              = 2
  managed_disk_id    = azurerm_managed_disk.LogDisk.*.id[count.index]
  virtual_machine_id = azurerm_windows_virtual_machine.SQLVM.*.id[count.index]
  lun                = 1
  caching            = var.diskinfo.sqllog.caching
}

resource "azurerm_mssql_virtual_machine" "SQLVMPrimary" {

  virtual_machine_id               = azurerm_windows_virtual_machine.SQLVM[0].id
  sql_license_type                 = "AHUB"
  r_services_enabled               = true
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_username = azurerm_key_vault_secret.sqlLoginAdminUser.value
  sql_connectivity_update_password = azurerm_key_vault_secret.sqlLoginAdminPass.value
  tags                             = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
  storage_configuration {
    disk_type             = "NEW"  # (Required) The type of disk configuration to apply to the SQL Server. Valid values include NEW, EXTEND, or ADD.
    storage_workload_type = "OLTP" # (Required) The type of storage workload. Valid values include GENERAL, OLTP, or DW.

    # The storage_settings block supports the following:
    data_settings {
      default_file_path = var.diskinfo.sqldata.path
      luns              = [azurerm_virtual_machine_data_disk_attachment.DataDiskAttach[0].lun]

    }

    log_settings {
      default_file_path = var.diskinfo.sqllog.path
      luns              = [azurerm_virtual_machine_data_disk_attachment.LogDiskAttach[0].lun] # (Required) A list of Logical Unit Numbers for the disks.
    }
    temp_db_settings {
      default_file_path = "d:\\tempdb\\"
      luns              = []
    }
  }
  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }
}

resource "azurerm_mssql_virtual_machine" "SQLVMSecondary" {

  virtual_machine_id               = azurerm_windows_virtual_machine.SQLVM[1].id
  sql_license_type                 = "DR"
  r_services_enabled               = true
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_username = azurerm_key_vault_secret.sqlLoginAdminUser.value
  sql_connectivity_update_password = azurerm_key_vault_secret.sqlLoginAdminPass.value
  tags                             = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
  storage_configuration {
    disk_type             = "NEW"  # (Required) The type of disk configuration to apply to the SQL Server. Valid values include NEW, EXTEND, or ADD.
    storage_workload_type = "OLTP" # (Required) The type of storage workload. Valid values include GENERAL, OLTP, or DW.

    # The storage_settings block supports the following:
    data_settings {
      default_file_path = var.diskinfo.sqldata.path
      luns              = [azurerm_virtual_machine_data_disk_attachment.DataDiskAttach[1].lun]

    }

    log_settings {
      default_file_path = var.diskinfo.sqllog.path
      luns              = [azurerm_virtual_machine_data_disk_attachment.LogDiskAttach[1].lun] # (Required) A list of Logical Unit Numbers for the disks.
    }
    temp_db_settings {
      default_file_path = "d:\\tempdb\\"
      luns              = []
    }
  }
  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }
}

###########################################################
resource "azurerm_private_dns_a_record" "clusterdnsrecord" {
  name                = "${var.project}-ag"
  zone_name           = var.DNS_Private_Zone
  resource_group_name = var.DNS_Private_Zone_Resource_Group
  ttl                 = 3600
  records             = [azurerm_network_interface.SQLNIC1.ip_configuration[1].private_ip_address, azurerm_network_interface.SQLNIC2.ip_configuration[1].private_ip_address]
}

resource "azurerm_private_dns_a_record" "listenerdnsrecord" {
  name                = var.listener_name
  zone_name           = var.DNS_Private_Zone
  resource_group_name = var.DNS_Private_Zone_Resource_Group
  ttl                 = 3600
  records             = [azurerm_network_interface.SQLNIC1.ip_configuration[2].private_ip_address, azurerm_network_interface.SQLNIC2.ip_configuration[2].private_ip_address]
}
resource "random_integer" "random" {
  min = 100
  max = 999

}
##### Storage Account

resource "azurerm_storage_account" "SQLCluster" {
  name                     = "${var.project}${var.environment}wtnss${random_integer.random.result}${local.region_code}"
  resource_group_name      = data.azurerm_resource_group.SQLVMAG.name
  location                 = data.azurerm_resource_group.SQLVMAG.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  tags                     = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
}




resource "azurerm_virtual_machine_extension" "bootsrap_node" {
  count                = 2
  name                 = "bootstrap_node"
  virtual_machine_id   = azurerm_windows_virtual_machine.SQLVM[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }

  settings = <<SETTINGS
{
        "commandToExecute": "powershell -encodedCommand ${textencodebase64(data.local_file.bootstrap.content, "UTF-16LE")}" 
}
SETTINGS


  depends_on = [
    azurerm_mssql_virtual_machine.SQLVMSecondary,
    azurerm_mssql_virtual_machine.SQLVMPrimary,
    azurerm_private_dns_a_record.clusterdnsrecord,
    azurerm_virtual_machine_data_disk_attachment.LogDiskAttach,
    azurerm_virtual_machine_data_disk_attachment.DataDiskAttach
  ]

}

resource "azurerm_virtual_machine_extension" "dsc_onboarding" {
  depends_on                 = [azurerm_automation_dsc_nodeconfiguration.sqlconfigSecondary, azurerm_automation_dsc_nodeconfiguration.sqlconfigPrimary, azurerm_virtual_machine_extension.bootsrap_node]
  count                      = 2
  name                       = "DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.SQLVM[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.83"
  auto_upgrade_minor_version = true
  tags                       = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
  settings = <<SETTINGS
      {
         "wmfVersion": "latest",
         "privacy": {
            "dataCollection": "enable"
         },
         "advancedOptions": {
            "forcePullandApply": false
         },
         "configurationArguments": {
            "RegistrationUrl": "${data.azurerm_automation_account.automation_account.endpoint}",
            "NodeConfigurationName": "${local.azure_automation_configuration_name}.${azurerm_windows_virtual_machine.SQLVM[count.index].name}",
            "ConfigurationMode": "ApplyAndAutoCorrect",
            "ConfigurationModeFrequencyMins": 15,
            "RefreshFrequencyMins": 30,
            "RebootNodeIfNeeded": true,
            "ActionAfterReboot": "ContinueConfiguration",
            "AllowModuleOverwrite": true
         }
      }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
   {
      "configurationArguments": {
         "RegistrationKey": {
            "userName": "NOT_USED",
            "Password": "${data.azurerm_automation_account.automation_account.primary_key}"
         }
      }
   }
PROTECTED_SETTINGS
}
