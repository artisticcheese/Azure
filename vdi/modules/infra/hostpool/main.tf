resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_role_assignment" "userRBACAssignment" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = var.entra_vdiuser_group_guid
}
resource "azurerm_role_assignment" "adminRBACAssignment" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.entra_vdiadmin_group_guid
}
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = var.hostpool_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                             = var.rdsh_count
  name                              = "${var.prefix}-${count.index + 1}"
  resource_group_name               = azurerm_resource_group.main.name
  location                          = var.location
  size                              = var.vm_size
  network_interface_ids             = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent                = true
  admin_username                    = var.local_admin_username
  admin_password                    = random_string.AVD_local_password.result
  patch_assessment_mode             = "AutomaticByPlatform"
  patch_mode                        = "AutomaticByPlatform"
  vm_agent_platform_updates_enabled = true
  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }
  identity {
    type = "SystemAssigned"
  }
  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_network_interface.avd_vm_nic
  ]
  lifecycle {
    ignore_changes = [additional_capabilities]
  }

}
resource "azapi_resource_action" "stop-vm" {
  count                  = var.rdsh_count
  type                   = "Microsoft.Compute/virtualMachines@2024-03-01"
  resource_id            = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  action                 = "deallocate"
  response_export_values = ["*"]
  depends_on = [
    azurerm_virtual_machine_extension.boot_strap
  ]
}


resource "azapi_update_resource" "enable-hibernation" {
  count       = var.rdsh_count
  type        = "Microsoft.Compute/virtualMachines@2024-03-01"
  resource_id = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]

  body = jsonencode({
    properties = {
      additionalCapabilities = {
        hibernationEnabled = true
      }
    }
    }
  )
  depends_on = [
    azapi_resource_action.stop-vm
  ]
}

resource "azapi_resource_action" "start-vm" {
  count                  = var.rdsh_count
  type                   = "Microsoft.Compute/virtualMachines@2024-03-01"
  resource_id            = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  action                 = "start"
  response_export_values = ["*"]
  depends_on = [
    azapi_update_resource.enable-hibernation
  ]
}
locals {
  encodedCommand = data.local_file.bootstrap.content_base64
}
resource "azurerm_virtual_machine_extension" "boot_strap" {
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-avd_bootstrap"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = <<SETTINGS
{
         "commandToExecute": "powershell -encodedCommand ${textencodebase64(data.local_file.bootstrap.content, "UTF-16LE")}" 

}
SETTINGS

}


resource "azurerm_virtual_machine_extension" "vdi_onboard" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.83"
  auto_upgrade_minor_version = true
  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02748.388.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${data.azurerm_virtual_desktop_host_pool.main.name}",
         "aadJoin": true,
         "UseAgentDownloadEndpoint": true
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.registration_token}"
    }
  }
PROTECTED_SETTINGS
  depends_on         = [azurerm_virtual_machine_extension.entraid_join]
}

resource "azurerm_virtual_machine_extension" "entraid_join" {
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-entra-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "2.0"

  depends_on = [azapi_resource_action.start-vm]
}
resource "azapi_resource_action" "delete-dsc-extension" {
  count                  = var.rdsh_count
  type                   = "Microsoft.Compute/virtualMachines/extensions@2024-07-01"
  resource_id            = azurerm_virtual_machine_extension.vdi_onboard.*.id[count.index]
  method                 = "DELETE"
  response_export_values = ["*"]
  depends_on = [
    azapi_update_resource.enable-hibernation, azurerm_virtual_machine_extension.vdi_onboard
  ]
}

resource "azurerm_virtual_machine_extension" "dsc_onboarding" {
  depends_on           = [azapi_resource_action.delete-dsc-extension]
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83"
  //auto_upgrade_minor_version = true
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
            "RegistrationUrl": "${data.azurerm_automation_account.main.endpoint}",
            "NodeConfigurationName": "${var.dsc_configuration_name}",
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
            "Password": "${data.azurerm_automation_account.main.primary_key}"
         }
      }
   }
PROTECTED_SETTINGS
}

