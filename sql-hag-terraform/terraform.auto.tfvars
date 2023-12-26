location = "eastus"
/* vmCredential = {
  AutomationAccountCredentialName = "sql1Credentials"
  vmUsername                      = "Administrator"
  vmPassword                      = "A123456!"
} */
resource_group_name = "sql-rg"
tags = {
  Product           = "DevOps"
  ProductComponents = "SQL"
  Environment       = "MyEnvironment"
  Contact           = "artisticchese@gmail.com"
}
project                 = "tf"
environment             = "development"
prefix                  = "greg"
automation_account_name = "sql-automation-account"
/* modulesToImport = {
  "SQLServer"             = "https://psg-prod-eastus.azureedge.net/packages/sqlserver.22.1.1.nupkg"
  "FailoverClusterDsc"    = "https://psg-prod-eastus.azureedge.net/packages/failoverclusterdsc.2.1.0.nupkg"
  "SQLServerDsc"          = "https://psg-prod-eastus.azureedge.net/packages/sqlserverdsc.16.5.0.nupkg"
  "WindowsDefender"       = "https://psg-prod-eastus.azureedge.net/packages/windowsdefender.1.0.0.4.nupkg"
  "AccessControlDSC"      = "https://psg-prod-eastus.azureedge.net/packages/accesscontroldsc.1.4.3.nupkg"
  "ComputerManagementDSC" = "https://psg-prod-eastus.azureedge.net/packages/computermanagementdsc.9.0.0.nupkg"
} */


subnet1_name                    = "sql-subnet1"
subnet2_name                    = "sql-subnet2"
DNS_Private_Zone                = "azure.sql"
DNS_Private_Zone_Resource_Group = "sql-rg"

diskinfo = {
  osdisk = {
    DiskType = "Premium_LRS"
  }
  sqldata = {
    DiskType            = "PremiumV2_LRS"
    DiskSize            = 200
    Logical_Sector_Size = 4096
    iops                = 3000
    bandwidth           = 125
    caching             = "None"
  }
  sqllog = {
    DiskType            = "PremiumV2_LRS"
    DiskSize            = 200
    Logical_Sector_Size = 4096
    iops                = 3000
    bandwidth           = 125
    caching             = "None"
  }
}
DSCconfigurationName = "sqlconfig_1_1"
vm_size              = "Standard_E2ds_v5"
clustername          = "sql-cluster-ag"
listener_name        = "sql-listener-ag"
bootstrap_script     = "/scripts/prep.ps1"

