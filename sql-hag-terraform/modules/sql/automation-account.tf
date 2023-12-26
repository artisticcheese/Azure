locals {
  test = abspath(path.module)
}
output "test" { value = local.test }

resource "azurerm_automation_dsc_configuration" "main" {
  name                    = local.azure_automation_configuration_name
  resource_group_name     = local.automation_account_rg_name
  automation_account_name = local.automation_account_name
  location                = var.location
  content_embedded        = replace(file("./modules/sql/scripts/${var.DSCconfigurationName}.ps1"), "sqlconfig", local.azure_automation_configuration_name)
  tags                    = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
}


resource "null_resource" "compile_dsc_config_locally" {
  provisioner "local-exec" {
    command     = textencodebase64(nonsensitive(local.DSCconfig), "UTF-16LE")
    interpreter = ["powershell", "-encodedCommand"]
  }
  triggers = {
    #variable_name = var.DSCconfigurationName
    always = timestamp()
  }

}

resource "azurerm_automation_dsc_nodeconfiguration" "sqlconfigPrimary" {
  depends_on              = [null_resource.compile_dsc_config_locally]
  name                    = "${azurerm_automation_dsc_configuration.main.name}.${azurerm_windows_virtual_machine.SQLVM[0].name}"
  resource_group_name     = local.automation_account_rg_name
  automation_account_name = local.automation_account_name
  content_embedded        = data.local_file.dsc_mof_primaryVM.content
}
resource "azurerm_automation_dsc_nodeconfiguration" "sqlconfigSecondary" {
  depends_on              = [null_resource.compile_dsc_config_locally]
  name                    = "${azurerm_automation_dsc_configuration.main.name}.${azurerm_windows_virtual_machine.SQLVM[1].name}"
  resource_group_name     = local.automation_account_rg_name
  automation_account_name = local.automation_account_name
  content_embedded        = data.local_file.dsc_mof_secondaryVM.content
}


