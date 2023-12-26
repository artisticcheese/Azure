variable "vnet_id" {
  type = string
}

variable "subnet1_name" {
  type = string
}

variable "subnet2_name" {
  type = string
}


##################################################
### Resource group
variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tags" {
  type        = map(any)
  description = "Tags assosiatied with provision location"
}

variable "clustername" {
  type = string
}
variable "diskinfo" {
  type = object({
    osdisk = object({
      DiskType = optional(string, "Premium_LRS")
      caching  = optional(string, "ReadWrite")
    })

    sqldata = object({
      path                = optional(string, "F:\\data\\")
      DiskType            = string
      DiskSize            = number
      Logical_Sector_Size = number
      iops                = number
      bandwidth           = number
      caching             = optional(string, "None")
    })
    sqllog = object({
      path                = optional(string, "g:\\log\\")
      DiskType            = string
      DiskSize            = number
      Logical_Sector_Size = number
      iops                = number
      bandwidth           = number
      caching             = optional(string, "None")
    })
  })
  description = "Disk configuration information"

}
############################
## VM Variables

variable "bootstrap_script" {
  type        = string
  description = "relative location of script containing bootstrap settings for VM"
}

variable "vm_size" {
  type    = string
  default = "Standard_E8ds_v5"

}

variable "automation_account_resource_id" {
  type        = string
  description = "Azure Resource ID for Automation account to hold DSC scripts as well as credentials"

}
variable "Itemslist" {
  type    = list(any)
  default = ["1", "2"]
}
variable "vm_admin_user" {
  type        = string
  default     = "adminuser"
  description = "This username must not be renamed unless got apprvoved."
}

variable "sql_login_admin_user" {
  type        = string
  default     = "sqladmin"
  description = "This username must not be renamed unless got apprvoved."
}
variable "datadisk_storage_logical_sector_size" {
  type    = number
  default = 4096
}

#############################################################

variable "DNS_Private_Zone" {
  type = string
}

variable "DNS_Private_Zone_Resource_Group" {
  type = string
}

################################################################
## Storage Account

################################################################
## Shell 

variable "listener_name" {
  type = string
}
variable "DSCconfigurationName" {
  type        = string
  description = "Configuration name of DSC script which will be uploaded to Azure Automation"
}
variable "cluster_subnet_mask" {
  type        = string
  default     = "255.255.254.0"
  description = "subnet mask for SQL HAG"
}
variable "backup_path" {
  type        = string
  description = "File to setup default backup path for SQL"
  default     = "c:\\backup"
}

variable "temp_db_path" {
  type        = string
  description = "Local for temp db files"
  default     = "d:\\tempdb"

}
