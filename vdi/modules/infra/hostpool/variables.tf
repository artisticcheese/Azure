variable "location" {
  description = "Location of resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource group in which to deploy service objects"
}
variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
}

variable "prefix" {
  type        = string
  description = "Prefix of the name of the AVD machine(s)"
}
variable "vm_size" {
  description = "Size of the machine to deploy"
  default     = "Standard_D4s_v5"
}
variable "local_admin_username" {
  type        = string
  default     = "localadm"
  description = "local admin username"
}

variable "workspace_id" {
  type        = string
  description = "Azure Resource ID of workspace to tie application group to"
}

variable "hostpool_id" {
  type        = string
  description = "Azure Resource ID of hostpool to add to"
}


variable "registration_token" {
  type        = string
  sensitive   = true
  description = "Registration token for hostpool"
}

variable "hostpool_subnet_id" {
  type        = string
  description = "Subnet ID where to deploy hosts to"
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-smalldisk"
    version   = "latest"
  }
}
variable "entra_vdiuser_group_guid" {
  type        = string
  description = "GUID for group which would be assigned user of application group"
}
variable "entra_vdiadmin_group_guid" {
  type        = string
  description = "GUID for group which would be assigned user of application group"
}
variable "dsc_configuration_name" {
  type        = string
  description = "Name of DSC configuration to apply"
}

variable "automation_account_resource_id" {
  type        = string
  description = "resource ID of automation account"
}
