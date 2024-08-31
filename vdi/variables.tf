
variable "subscription_id" {
  type        = string
  description = "Default subscription ID where resources will be deloyed to"

}

##################################################
### Resource group
variable "location" {
  type = string
}

variable "automation_account_name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "workspace_name" {
  type = string

}
variable "hostpool_name" {
  type = string
}
variable "application_group_name" {
  type = string
}
variable "entra_vdiuser_group_guid" {
  type = string
}
variable "entra_vdiadmin_group_guid" {
  type = string
}
variable "vdi_resource_group_name" {
  type = string
}

variable "rdsh_count" {
  type = number
}
variable "prefix" {
  type = string
}
variable "hostpool_subnet_id" {
  type = string
}
variable "dsc_configuration_name" {
  type    = string
  default = "devops_vdi_config.localhost"
}

