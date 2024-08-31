locals {
  key_vault_name = "vdi-${random_string.kvrandom.result}-kv"
}
resource "random_string" "kvrandom" {
  length  = 4 # Adjust the length as needed
  special = false
}
resource "azurerm_key_vault" "main" {
  name                          = local.key_vault_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption   = true
  sku_name                      = "standard"
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = true
}


resource "azurerm_role_assignment" "keyvault-admin-assignment" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.main.id
  principal_id         = var.entra_vdiadmin_group_guid
  timeouts {
    create = "10m"
  }
}

resource "azurerm_role_assignment" "keyvault-secret-user-assignment" {
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.main.id
  principal_id         = var.entra_vdiadmin_group_guid
}

data "azurerm_client_config" "current" {}

resource "random_string" "AVD_local_password" {
  length           = 12
  special          = true
  min_special      = 1
  override_special = "*!@#?"
}

resource "azurerm_key_vault_secret" "VMAdminPassword" {
  name         = "vm-password"
  value        = random_string.AVD_local_password.result
  key_vault_id = azurerm_key_vault.main.id
}
