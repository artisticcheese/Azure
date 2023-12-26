variable "automation-account-name" {
  type        = string
  description = "Name of automation account to create for State Management"

}
variable "location" {
  description = "The azure region where RG will be created"
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the storage account."
}

variable "tags" {
  type        = map(any)
  description = "Tags assosiatied with the storage account"
}
