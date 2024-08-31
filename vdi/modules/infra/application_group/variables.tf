variable "location" {
  type        = string
  description = "Location where to deploy application group"
}

variable "resource_group_id" {
  type        = string
  description = "Resource Group ID to place resource in"
}

variable "workspace_id" {
  type        = string
  description = "Azure Resource ID of workspace to tie application group to"
}
variable "hostpool_id" {
  type        = string
  description = "Azure Resource ID of hostpool to tie application group to"
}
variable "application_group_name" {
  type        = string
  description = "Name of application group to create"
}

variable "entra_vdiuser_group_guid" {
  type        = string
  description = "GUID for group which would be assigned user of application group"
}
variable "display_name_for_desktop_group" {
  type    = string
  default = "DevOps EastUS desktop"
}
