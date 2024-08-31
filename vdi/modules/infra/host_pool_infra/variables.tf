

variable "resource_group_id" {
  type        = string
  description = "Resource Group ID to place resource in"
}

variable "hostpool_name" {
  type        = string
  description = "Name of the Azure Virtual Desktop host pool"
}
variable "workspace_id" {
  type        = string
  description = "Azure Resource ID of workspace to tie application group to"
}

variable "location" {
  type        = string
  description = "Location for hostpool"

}
variable "time_zone_for_scaling" {
  type        = string
  default     = "Eastern Standard Time"
  description = "Time for scaling up activation, allowed values listed here https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/"
}

variable "automation_account_resource_id" {
  type        = string
  description = "Azure Resource ID for Automation account to hold DSC scripts as well as credentials"
}

