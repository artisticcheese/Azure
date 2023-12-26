module "sql-automation-account" {
  source                  = "./modules/global"
  automation-account-name = var.automation_account_name
  tags                    = var.tags
  resource_group_name     = var.resource_group_name
  location                = var.location
}

module "main" {
  depends_on                      = [module.sql-automation-account]
  source                          = "./modules/sql"
  automation_account_resource_id  = module.sql-automation-account.azurerm_automation_account_id
  DSCconfigurationName            = var.DSCconfigurationName
  tags                            = var.tags
  environment                     = var.environment
  diskinfo                        = var.diskinfo
  vnet_id                         = var.vnet_id
  DNS_Private_Zone                = var.DNS_Private_Zone
  DNS_Private_Zone_Resource_Group = var.DNS_Private_Zone_Resource_Group
  prefix                          = var.prefix
  resource_group_name             = var.resource_group_name
  subnet1_name                    = var.subnet1_name
  subnet2_name                    = var.subnet2_name
  listener_name                   = var.listener_name
  bootstrap_script                = var.bootstrap_script
  location                        = var.location
  clustername                     = var.clustername
  project                         = var.project
}
