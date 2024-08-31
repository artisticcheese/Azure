variable "location" {
  type        = string
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource group in which to deploy service objects"
}

variable "workspace_name" {
  type        = string
  description = "Name of the Azure Virtual Desktop workspace"
}

variable "friendly_workspace_name" {
  type = string
}
variable "workspace_description" {
  type    = string
  default = "Workspace is managed by DevOps to provider secure and manageable resource access for Intapp Production infrastructure and beyound"
}
variable "automation_account_name" {
  type        = string
  description = "Name of automation account"
}

variable "dsc_modules" {
  default = {
    "xNetworking" : "https://www.powershellgallery.com/api/v2/package/xNetworking/5.7.0.0"
    "ComputerManagementDSC" : "https://www.powershellgallery.com/api/v2/package/ComputerManagementDsc/9.1.0"
    "cChoco" : "https://www.powershellgallery.com/api/v2/package/cChoco/2.6.0.0"
  }
}
