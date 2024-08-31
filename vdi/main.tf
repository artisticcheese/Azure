module "automation-account" {
  source   = "./modules/global"
  location = var.location
}



module "hostpool" {
  source                         = "./modules/infra/hostpool"
  depends_on                     = [module.host_pool_infra, module.workspace]
  location                       = var.location
  entra_vdiuser_group_guid       = var.entra_vdiuser_group_guid
  entra_vdiadmin_group_guid      = var.entra_vdiadmin_group_guid
  rdsh_count                     = var.rdsh_count
  prefix                         = var.prefix
  resource_group_name            = var.vdi_resource_group_name
  hostpool_subnet_id             = var.hostpool_subnet_id
  automation_account_resource_id = module.workspace.automation_account_id
  registration_token             = module.host_pool_infra.azurerm_virtual_desktop_host_pool_registration_token
  hostpool_id                    = module.host_pool_infra.azurerm_virtual_desktop_hostpool_id
  workspace_id                   = module.workspace.azurerm_virtual_desktop_workspace_id
  dsc_configuration_name         = var.dsc_configuration_name
}

module "application_group" {
  source                   = "./modules/infra/application_group"
  location                 = var.location
  depends_on               = [module.hostpool, module.workspace]
  application_group_name   = var.application_group_name
  workspace_id             = module.workspace.azurerm_virtual_desktop_workspace_id
  resource_group_id        = module.workspace.azure_virtual_desktop_compute_resource_group_id
  hostpool_id              = module.host_pool_infra.azurerm_virtual_desktop_hostpool_id
  entra_vdiuser_group_guid = var.entra_vdiuser_group_guid

}

module "host_pool_infra" {
  source                         = "./modules/infra/host_pool_infra"
  depends_on                     = [module.workspace]
  automation_account_resource_id = module.workspace.automation_account_id
  location                       = var.location
  workspace_id                   = module.workspace.azurerm_virtual_desktop_workspace_id
  resource_group_id              = module.workspace.azure_virtual_desktop_compute_resource_group_id
  hostpool_name                  = var.hostpool_name
}

module "workspace" {
  source                  = "./modules/infra/workspace"
  automation_account_name = var.automation_account_name
  resource_group_name     = var.resource_group_name
  workspace_name          = var.workspace_name
  friendly_workspace_name = "VDI workspace"
  location                = var.location
}
