$password = 'A123456!' | ConvertTo-SecureString -AsPlainText -Force
$username = 'Administrator'
$credential = [PSCredential]::New($username, $password) 
$sqlData =
@{
   AllNodes    =
   @(
      @{
         NodeName                    = "*"
         PSDscAllowPlainTextPassword = $true
      }
      @{
         NodeName = "sql1"
         Role     = 'Primary'
      }  
      @{
         NodeName = "sql2"
         Role     = 'Secondary'
      } 

   );

   NonNodeData =
   @{
      vmDnsZone                 = 'local'
      vm1Name                   = 'SQL1'
      vm2Name                   = 'SQL2'
      clusterName               = 'sqlCluster'
      clusterIP1                = '10.1.0.50'
      clusterSubNetMask1        = '255.255.255.0'
      clusterIP2                = '10.2.0.50'
      clusterSubNetMask2        = '255.255.255.0'
      listenerName              = 'SQL1-listener'
      listenerIP1               = '10.1.0.100'
      listenerIP2               = '10.2.0.100'
      witnessStorageAccountName = 'ppsqlwitnesssa'
      dbMasterKeyPassword       = 'UtdfckFroC4YdZ'
      dbLoginPassword           = '9ZceETmqhLPNQV'
      DataPath                  = 'c:\data\'
      LogPath                   = 'c:\log'
      BackupPath                = 'c:\backup'
      TempDBPath                = 'c:\tempdb'
      TempLOGPath               = 'c:\tempdb'
      witnessStorageKey         = 'WaGBkT7AlKbksuEBTPhH75QDRzbYDDwF5VmvqU2bo0cqhaTyJkUKKNtYFGbEsB/LzsJvQzD+ASt6KREZg=='
      vmCredentials             = $credential
   }
}

. $PSScriptRoot/sqlconfig.ps1
$VerbosePreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
sqlconfig -ConfigurationData $sqlData -OutputPath $PSScriptRoot\. -InformationAction Continue

Start-DscConfiguration -ComputerName sql1, sql2 -Credential $credential -path $PSScriptRoot -force -InformationAction Continue
