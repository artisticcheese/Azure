resource "azurerm_automation_dsc_configuration" "main" {
  name                    = local.azure_automation_configuration_name
  resource_group_name     = local.automation_account_rg_name
  automation_account_name = local.automation_account_name
  #Location of DSC configuration corresponds to location of automation account
  location         = var.location
  content_embedded = local.content_embedded
}
locals {
  content_embedded = file("./modules/infra/host_pool_infra/dsc/devopshosts.ps1")
  source_code_hash = filebase64sha256("./modules/infra/host_pool_infra/dsc/devopshosts.ps1")
}
resource "random_uuid" "main" {
  keepers = {
  file_hash = local.source_code_hash }
}

resource "azapi_resource_action" "create_compilation_job" {
  type        = "Microsoft.Automation/automationAccounts/compilationjobs@2023-05-15-preview"
  resource_id = "${var.automation_account_resource_id}/compilationjobs/compilation_job_${random_uuid.main.result}"
  method      = "PUT"
  body = {
    properties = {
      configuration = {
        name = azurerm_automation_dsc_configuration.main.name
      }
      incrementNodeConfigurationBuild = false
    }
  }
  timeouts {
    create = "10m"
  }
}
