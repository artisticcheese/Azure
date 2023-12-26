data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}


resource "azurerm_automation_account" "main" {
  name                = var.automation-account-name
  location            = data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  sku_name            = "Basic"
  tags                = var.tags
  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags["DateCreated"]
    ]
  }
}
