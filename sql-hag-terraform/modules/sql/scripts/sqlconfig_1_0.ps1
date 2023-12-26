Configuration sqlconfig {
   #region prep
   param(
      $vmDnsZone = $ConfigurationData.NonNodeData.vmDnsZone,
      # Parameter help description
      [Parameter()]
      [ValidateNotNullorEmpty()]
      [string] $clusterName = $ConfigurationData.NonNodeData.clusterName,
      [PSCredential] $vmCredentials = $ConfigurationData.NonNodeData.vmCredentials,
      [Parameter()]
      [ValidateNotNullorEmpty()]
      $clusterIP1 = $ConfigurationData.NonNodeData.clusterIP1,
      [Parameter()]
      [ValidateNotNullorEmpty()]
      $vm1Name = $ConfigurationData.NonNodeData.vm1Name,
      [Parameter()]
      [ValidateNotNullorEmpty()]
      $vm2Name = $ConfigurationData.NonNodeData.vm2Name,
      [Parameter()]
      [ValidateNotNullorEmpty()]
      $clusterSubNetMask1 = $ConfigurationData.NonNodeData.clusterSubNetMask1,
      $clusterIP2 = $ConfigurationData.NonNodeData.clusterIP2,
      $clusterSubNetMask2 = $ConfigurationData.NonNodeData.clusterSubNetMask2,
      $listenerName = $ConfigurationData.NonNodeData.listenerName,
      $listenerIP1 = $ConfigurationData.NonNodeData.listenerIP1,
      $listenerIP2 = $ConfigurationData.NonNodeData.listenerIP2,
      $witnessStorageAccountName = $ConfigurationData.NonNodeData.witnessStorageAccountName,
      $dbMasterKeyPassword = $ConfigurationData.NonNodeData.dbMasterKeyPassword,
      $dbLoginPassword = $ConfigurationData.NonNodeData.dbLoginPassword,
      $DataPath = $ConfigurationData.NonNodeData.DataPath,
      $LogPath = $ConfigurationData.NonNodeData.LogPath,
      $BackupPath = $ConfigurationData.NonNodeData.BackupPath,
      $TempDBPath = $ConfigurationData.NonNodeData.TempDBPath,
      $TempLOGPath = $ConfigurationData.NonNodeData.TempLOGPath,
      $witnessStorageKey = $ConfigurationData.NonNodeData.witnessStorageKey,
      $automationCredential = $ConfigurationData.NonNodeData.automationCredential,
      $requiredServices = @('Failover-clustering', 'RSAT-Clustering-Mgmt', 'RSAT-Clustering-PowerShell')
   )
   
   Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
   Import-DscResource -ModuleName 'SqlServerDsc'
   Import-DscResource -ModuleName 'FailoverClusterDsc'
   Import-DscResource -ModuleName 'ComputerManagementDsc'
   Import-DscResource -ModuleName 'WindowsDefender'
   Import-DSCResource -moduleName 'AccessControlDSC'
   if ($automationCredential) { $vmCredentials = Get-AutomationPSCredential $automationCredential }
   #endregion
   #region AllNodes
   node $AllNodes.NodeName {
      Registry DomainValue {
         Key       = "HKLM:\system\CurrentControlSet\Services\tcpip\parameters"
         ValueName = "Domain"
         ValueData = $vmDNSZone
      }
      Registry NVDomainValue {
         Key       = "HKLM:\system\CurrentControlSet\Services\tcpip\parameters"
         ValueName = "NV Domain"
         ValueData = $vmDNSZone
      }
      PendingReboot CheckForReboot {
         Name      = 'CheckForeboot'
         DependsOn = $requiredServices | Foreach-object { "[WindowsFeature]$_" }
      }
      foreach ($requiredService in $requiredServices) {
         WindowsFeature $requiredService {
            Name                 = $requiredService
            Ensure               = 'Present'
            IncludeAllSubFeature = $false
         }
      }
      Script RemoveSQLASISFeatures {
         TestScript = {
            $null -eq (get-wmiobject win32_product | Where-Object { ($_.Name -match "SQL Server 2019 Analysis Services" -OR $_.Name -match "SQL Server 2019 Integration Services") -AND $_.vendor -eq "Microsoft Corporation" })
         }
         SetScript  = {
            $setup = Get-ChildItem -Recurse -Include setup.exe -Path "$env:ProgramFiles\Microsoft SQL Server" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match 'Setup Bootstrap\\SQL' -or $_.FullName -match 'Bootstrap\\Release\\Setup.exe' -or $_.FullName -match 'Bootstrap\\Setup.exe' } | Sort-Object FullName -Descending | Select-Object -First 1
            $installerPath = $setup.Fullname
            $installerArgs = "/Action=Uninstall /FEATURES=AS,IS /INSTANCENAME=MSSQLSERVER /Quiet"
            Start-Process -FilePath $installerPath -ArgumentList $installerArgs -Verb RunAs -Wait
         }
         GetScript  = {
            @{}
         }
      }
      File TempFolder {
         Ensure          = "Present"
         Type            = "Directory"
         DestinationPath = "C:\Temp"        
      }
      File SQLLogsFolder {
         Ensure          = 'Present'
         Type            = 'Directory'
         DestinationPath = $LogPath
         
      }

      File SQLBackupFolder {
         Ensure          = 'Present'
         Type            = 'Directory'
         DestinationPath = $BackupPath
         
      }
      WindowsDefender Set-DefenderExclusions {
         IsSingleInstance = 'yes'
         ExclusionPath    = @($DataPath, $LogPath, $TempDBPath, $TempLOGPath ) | Select-Object -unique
      } 

      Script DisableNicRegisterDNS {
         TestScript = {
            $interfaceIndex = (Get-NetAdapter | Where-Object { ( $_.Status -eq "up" ) -and ($_.ifDesc -like "Microsoft Hyper-V Network Adapter*") }).ifIndex
            if (!$interfaceIndex) {
               Write-Host "No active Microsoft Hyper-V Network Adapters were found on a VM"
               $result = $true
            }
            else {
               if (!((Get-DnsClient -InterfaceIndex $interfaceIndex).RegisterThisConnectionsAddress)) {
                  $result = $true
               }
               else {
                  $result = $false
               }
            }
            return $result
         }
         SetScript  = {
            $interfaceIndex = (Get-NetAdapter | Where-Object { ( $_.Status -eq "up" ) -and ($_.ifDesc -like "Microsoft Hyper-V Network Adapter*") }).ifIndex
            Set-DNSClient -InterfaceIndex $interfaceIndex -RegisterThisConnectionsAddress $False
         }
         GetScript  = {
            @{}
         }
         DependsOn  = @('[Registry]DomainValue', '[Registry]NVDomainValue')
      }
      ('HKLM:\\SOFTWARE\\Wow6432Node\\Microsoft\\.NetFramework\\v4.0.30319', 'HKLM:\\SOFTWARE\\Microsoft\\.NetFramework\\v4.0.30319') | foreach-object {
         Registry $_ {
            Key       = $_
            ValueName = 'SchUseStrongCrypto'
            ValueData = 1
         }
      }   
      Script DisableFirewall {
         TestScript = {
            $Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
            $Status -eq $True
         }
         SetScript  = {
            Set-NetFirewallProfile -All -Enabled False -Verbose
         }
         GetScript  = {
            @{
               GetScript  = $GetScript
               SetScript  = $SetScript
               TestScript = $TestScript
               Result     = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
            }
         }
      }
      NTFSAccessEntry GrantAdminPermissionsForRsaFolder {
         Path              = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
         AccessControlList = @(
            foreach ($principal in @('System', 'Administrators', 'MSSQLServer')) {
               NTFSAccessControlList {
                  Principal          = $principal
                  ForcePrincipal     = $true
                  AccessControlEntry = @(
                     NTFSAccessControlEntry {
                        AccessControlType = 'Allow'
                        FileSystemRights  = 'FullControl'
                        Inheritance       = 'This folder subfolders and files'
                        Ensure            = 'Present'
                     }
                     
                  )
               }
            }
         )
      }
   
   }
   #endegion

   #region Primary node
   node $AllNodes.Where{ $_.Role -eq "Primary" }.NodeName {  
      $SQLAgentMaximumHistoryRows = 100000
      $SQLAgentMaximumJobHistoryRows = 1000
      $InstanceName = "MSSQLSERVER"

      Script ChangeSQLServerSettings {
         TestScript = {
            Test-Path "C:\Temp\SQLSettingsUpdated.txt"
         }
         SetScript  = {
            Import-Module SQLPS -DisableNameChecking
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server('localhost')
            $server.DefaultFile = $using:DataPath
            $server.DefaultLog = $using:LogPath
            $server.BackupDirectory = $using:BackupPath
            $server.Settings.LoginMode = "Mixed"
            $server.Alter()
            # Enable FILESTREAM
            $instance = $($server.Properties["ServiceName"].Value)
            $wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement$($server.Properties["VersionMajor"].Value)" -Class FilestreamSettings | Where-Object { $_.InstanceName -eq $instance }
            $wmi.EnableFilestream(1, $instance)
            # Set up max memory settings
            $PhisMem = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1mb
            $value = [Math]::Round([Math]::Min($PhisMem * 0.9, $PhisMem - 4096))
            # SQL settings
            Invoke-Sqlcmd "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'max server memory', $value; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure Backup_Compression_default, 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure 'max degree of parallelism', 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure 'cost threshold for parallelism', 50; RECONFIGURE;"
            Restart-Service -Name MSSQLSERVER -Force
            New-Item -Path "C:\Temp" -Name "SQLSettingsUpdated.txt" -Type "file" -value "SQL settings successfully updated" -Force
         }
         GetScript  = {
            @{}
         }
      }

      Script CreateMasterKey {
         TestScript           = {
                (Invoke-Sqlcmd "SELECT COUNT(*) FROM sys.symmetric_keys WHERE name LIKE '%DatabaseMasterKey%'").Column1 -eq 1
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$using:dbMasterKeyPassword';"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = '[Script]ChangeSQLServerSettings'
      }
      Script CreateCluster {
         TestScript           = {
            Write-Host "Checking if need to create cluster $using:clusterName"
            (Get-Cluster -ErrorAction:SilentlyContinue).Name -eq $clusterName
         }
         SetScript            = {
            Write-Host "Trying to create cluster $clusterName"
            New-Cluster -Name "$using:clusterName" -Node "$using:vm1Name.$using:vmDnsZone", "$using:vm2Name.$using:vmDnsZone" -ManagementPointNetworkType Singleton -StaticAddress "$using:clusterIP1", "$using:clusterIP2" -AdministrativeAccessPoint Dns -NoStorage
         }
         GetScript            = {
            return @{Result = Get-Cluster -Name "$using:clusterName" }
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateMasterKey"
      } 

      ClusterQuorum SetQuorum {
         IsSingleInstance        = 'yes'
         Type                    = 'NodeAndCloudMajority'
         Resource                = $witnessStorageAccountName
         StorageAccountAccessKey = $witnessStorageKey
         DependsOn               = '[Script]CreateCluster'

      }
      File ClusterForumFile {
         Ensure          = 'Present'
         DestinationPath = "c:\SetClusterQuorum.txt"
         DependsOn       = "[ClusterQuorum]SetQuorum"
         Type            = 'File'
         Contents        = ""
      } 

      Service SQLServerAgent1 {
         Name        = "SQLSERVERAGENT"
         Ensure      = "Present"
         StartupType = "Manual"
         State       = 'Running'
         DependsOn   = "[ClusterQuorum]SetQuorum"
      }

      Script ChangeSQLAgentHistorySettings1 {
         TestScript           = {
            Start-Sleep -Seconds 5
            Import-Module SQLPS -DisableNameChecking
            $TargetMaximumHistoryRows = $using:SQLAgentMaximumHistoryRows
            $TargetMaximumJobHistoryRows = $using:SQLAgentMaximumJobHistoryRows
            try {
               # Using Windows authenticated connection
               $db = get-sqldatabase -serverinstance . -name msdb
               # Select SQLAgent
               $SQLAgent = $db.parent.JobServer
               # Show settings
               $CurrentSettings = $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               $CurrentSettings | Format-Table -AutoSize
               if ( $CurrentSettings.MaximumHistoryRows -ne $TargetMaximumHistoryRows -or $CurrentSettings.MaximumJobHistoryRows -ne $TargetMaximumJobHistoryRows ) {
                  return $false
               }
               else {
                  return $true
               }
            }
            catch {
               # Handle the error
               $err = $_.Exception
               write-error $err.Message
               while ( $err.InnerException ) {
                  $err = $err.InnerException
                  write-error $err.Message
               }
               break
            }
         }
         SetScript            = {
            Start-Sleep -Seconds 5
            Import-Module SQLPS -DisableNameChecking
            $TargetMaximumHistoryRows = $using:SQLAgentMaximumHistoryRows
            $TargetMaximumJobHistoryRows = $using:SQLAgentMaximumJobHistoryRows
            try {
               # Using Windows authenticated connection
               $db = get-sqldatabase -serverinstance . -name msdb
               # Select SQLAgent
               $SQLAgent = $db.parent.JobServer
               # Show settings
               $CurrentSettings = $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               $CurrentSettings | Format-Table -AutoSize
               if ( $CurrentSettings.MaximumHistoryRows -ne $TargetMaximumHistoryRows -or $CurrentSettings.MaximumJobHistoryRows -ne $TargetMaximumJobHistoryRows ) {
                  Write-Host 'Altering SQLAgent settings';
                  $SQLAgent.MaximumHistoryRows = $TargetMaximumHistoryRows
                  $SQLAgent.MaximumJobHistoryRows = $TargetMaximumJobHistoryRows
                  $SQLAgent.Alter()
                  # ensuring we have the latest information
                  $SQLAgent.Refresh()
                  $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               }
               #Close connection
               $db.Parent.ConnectionContext.Disconnect()
            }
            catch {
               # Handle the error
               $err = $_.Exception
               write-error $err.Message
               while ( $err.InnerException ) {
                  $err = $err.InnerException
                  write-error $err.Message
               }
               break
            }
            write-host 'Successfully updated SQLAgent settings'
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Service]SQLServerAgent1"
      }

      SqlAlwaysOnService EnableAlwaysOn1 {
         Ensure               = 'Present'
         ServerName           = 'localhost'
         InstanceName         = $InstanceName
         RestartTimeout       = 120
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[ClusterQuorum]SetQuorum"
      }

      SqlLogin AddNTServiceClusSvc1 {
         Ensure               = 'Present'
         Name                 = 'NT SERVICE\ClusSvc'
         LoginType            = 'WindowsUser'
         ServerName           = 'localhost'
         InstanceName         = $InstanceName
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn1"
      }
        
      SqlPermission AddNTServiceClusSvcPermissions1 {
         ServerName   = 'localhost'
         InstanceName = $InstanceName
         Name         = 'NT SERVICE\ClusSvc'
         Credential   = $vmCredentials
         Permission   = @(
            ServerPermission {
               State      = 'Grant'
               Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
            }
            ServerPermission {
               State      = 'GrantWithGrant'
               Permission = @()
            }
            ServerPermission {
               State      = 'Deny'
               Permission = @()
            }
         )
         DependsOn    = '[SqlLogin]AddNTServiceClusSvc1'
      }
        
      Script CreateAndBackupCertificate1 {
         TestScript           = {
                    (Invoke-Sqlcmd "SELECT * FROM sys.certificates where name = '$using:vm1Name'").name -eq "$using:vm1Name"
         }
         SetScript            = {
            $expireDate = (Get-Date).AddYears(+10).ToString('yyyyMMdd')
            Invoke-Sqlcmd "CREATE CERTIFICATE [$using:vm1Name] WITH SUBJECT = '$vm1Name Certificate', EXPIRY_DATE = '$expireDate';"
            Invoke-Sqlcmd "BACKUP CERTIFICATE [$using:vm1Name] TO FILE = 'C:\Temp\$using:vm1Name.cer';"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = @("[Script]CreateMasterKey", "[Script]CreateCluster")
      }
      File CopySecondCertificate {
         Ensure          = 'Present'
         DestinationPath = "C:\Temp\$vm2Name.cer" 
         SourcePath      = "\\$vm2Name\c$\Temp\$vm2Name.cer"
         DependsOn       = "[Script]CreateAndBackupCertificate1"
         Credential      = $vmCredentials
      }
      <#       Script WaitAndCopySecondCertificate1 {
         TestScript           = {
            test-path "c:\Temp\$using:vm2Name.cer"
         }
         SetScript            = {
          
            $tryIndex = 1
            $maxTryCount = 180 / 5
            do {
               $hostPresent = Test-Connection -ComputerName $using:vm2Name -Count 2 -Quiet
               if (!$hostPresent) {
                  Write-Host "Awaiting when $using:vm2Name host is up. Attempt #$tryIndex of #$maxTryCount"
                  Start-Sleep -Seconds 10
               }
               $tryIndex = $tryIndex + 1
            }
            while ($tryIndex -le $maxTryCount -and !$hostPresent)
            if (!$hostPresent) {
               throw "Cannot connect to $using:vm2Name host"
            }
            $tryIndex = 1
            $maxTryCount = 180 / 5
            $certPath = "\\$vm2Name\c$\Temp\$vm2Name.cer"
            do {
               
               $certPresent = test-path $certPath
               if (!$certPresent) {
                  Write-Host "Awaiting when certificate is present on $certPath on $vm2Name. Attempt #$tryIndex of #$maxTryCount"
                  Start-Sleep -Seconds 10
               }
               $tryIndex = $tryIndex + 1
            }
            while ($tryIndex -le $maxTryCount -and !$certPresent)
            if (!$certPresent) {
               throw "Cannot find $certPath"
            }
            else {
               Copy-Item -Path $certPath -Destination "C:\Temp\$using:vm2Name.cer" 
            }
            Stop-Transcript
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateAndBackupCertificate1"
      } #>

      Script CreateLoginAndUserWithCertificate1 {
         TestScript           = {
                    (Invoke-Sqlcmd "SELECT * FROM sys.server_principals  where name = '$using:vm2Name'").name -eq "$using:vm2Name"
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE LOGIN [$using:vm2Name] WITH PASSWORD = '$using:dbLoginPassword';"
            Invoke-Sqlcmd "CREATE USER [$using:vm2Name] FOR LOGIN [$using:vm2Name];"
            Invoke-Sqlcmd "CREATE CERTIFICATE [$using:vm2Name] AUTHORIZATION [$using:vm2Name] FROM FILE = 'C:\Temp\$using:vm2Name.cer'"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[File]CopySecondCertificate"
      }

      Script CreateEnpointWithPermissions1 {
         TestScript           = {
                    (Invoke-Sqlcmd "SELECT * FROM sys.endpoints where name = 'HADR_Endpoint'").name -eq "HADR_Endpoint"
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE ENDPOINT HADR_Endpoint STATE = STARTED AS TCP ( LISTENER_PORT = 5022, LISTENER_IP = ALL) FOR DATABASE_MIRRORING ( AUTHENTICATION = CERTIFICATE [$using:vm1Name], ROLE = ALL );"
            Invoke-Sqlcmd "GRANT CONNECT ON ENDPOINT::HADR_Endpoint TO [$using:vm2Name];"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateLoginAndUserWithCertificate1"
      }
      Script CreateAgWithListener {
         TestScript           = {
                    (Invoke-Sqlcmd "SELECT * FROM sys.availability_groups where name = '$using:clusterName'").name -eq "$using:clusterName"
         }
         SetScript            = {
            $node1Url = "TCP://" + "$using:vm1Name" + "." + "$using:vmDnsZone" + ":5022"
            $node2Url = "TCP://" + "$using:vm2Name" + "." + "$using:vmDnsZone" + ":5022"
            Invoke-Sqlcmd "CREATE AVAILABILITY GROUP [$using:clusterName] WITH ( AUTOMATED_BACKUP_PREFERENCE = PRIMARY, DB_FAILOVER = OFF, DTC_SUPPORT = NONE ) FOR REPLICA ON '$using:vm1Name' WITH ( ENDPOINT_URL = '$node1Url', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE ( ALLOW_CONNECTIONS = NO ) ), '$using:vm2Name' WITH ( ENDPOINT_URL = '$node2Url', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, SEEDING_MODE = AUTOMATIC, SECONDARY_ROLE ( ALLOW_CONNECTIONS = NO ) );"
            Invoke-Sqlcmd "ALTER AVAILABILITY GROUP [$using:clusterName] ADD LISTENER N'$using:listenerName' ( WITH IP ((N'$using:listenerIP1', N'$using:clusterSubNetMask1'), (N'$using:listenerIP2', N'$using:clusterSubNetMask2')), PORT=1433);"
            New-Item -Path "C:\Temp" -Name "AgCreated.txt" -Type "file" -value "Availability Group on SQL was successfully created" -Force
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateEnpointWithPermissions1"
      }

      Script ConfigureProbePort {
         TestScript           = {
            Test-Path "C:\Temp\AgProbesConfigured.txt"
         }
         SetScript            = {
            <#
                    # Probe port configuration for Cluster IP
                    $ClusterNetworkName = "Cluster Network 1" # the cluster network name (Use Get-ClusterNetwork on Windows Server 2012 of higher to find the name)
                    # fixed a bug to remove the null result  where-object Name -like "Cluster IP Address ==> Where-Object Name -match "$clusterName*"
                    $IPResourceName = (Get-ClusterResource | where-object Name -like "Cluster IP Address" | where-object Cluster -match "$using:clusterName*").name # the IP Address resource name
                    [int]$ClusterProbePort = 58888
                    Import-Module FailoverClusters
                    Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address" = "$using:clusterIP"; "ProbePort" = $ClusterProbePort; "SubnetMask" = "$using:clusterSubNetMask"; "Network" = "$ClusterNetworkName"; "EnableDhcp" = 0 } -ErrorAction SilentlyContinue
                    # Probe port configuration for Listener IP
                    $IPResourceName = (Get-ClusterResource | where-object ResourceType -eq "IP Address" | where-object Cluster -match "$using:clusterName*").name
                    [int]$ListenerProbePort = 59999
                    Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address" = "$using:listenerIP"; "ProbePort" = $ListenerProbePort; "SubnetMask" = "$using:clusterSubNetMask"; "Network" = "$ClusterNetworkName"; "EnableDhcp" = 0 } -ErrorAction SilentlyContinue
                    #>
            # Restarting cluster to apply changes
            Stop-Cluster -Force
            Start-Sleep -Seconds 15
            Start-Cluster
            Start-Sleep -Seconds 15
            New-Item -Path "C:\Temp" -Name "AgProbesConfigured.txt" -Type "file" -value "Availability Group Probes successfully configured" -Force
            # If Reboot required but disabled for now
            #$global:DSCMachineStatus = 1 
         }
         GetScript            = {
            return @{ 'Result' = $true }
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateAgWithListener"
      }
   }

   #endregion

   #region Secondary node
   node $AllNodes.Where{ $_.Role -eq "Secondary" }.NodeName {
      $SQLAgentMaximumHistoryRows = 100000
      $SQLAgentMaximumJobHistoryRows = 1000
      $InstanceName = "MSSQLSERVER"        
      Script ChangeSQLServerSettings {
         TestScript = {
            Test-Path "C:\Temp\SQLSettingsUpdated.txt"
         }
         SetScript  = {
            Import-Module SQLPS -DisableNameChecking
            [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server('localhost')
            $server.DefaultFile = $using:DataPath
            $server.DefaultLog = $using:LogPath
            $server.BackupDirectory = $using:BackupPath
            $server.Settings.LoginMode = "Mixed"
            $server.Alter()
            # Enable FILESTREAM
            $instance = $($server.Properties["ServiceName"].Value)
            $wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement$($server.Properties["VersionMajor"].Value)" -Class FilestreamSettings | where { $_.InstanceName -eq $instance }
            $wmi.EnableFilestream(1, $instance)
            # Set up max memory settings
            $PhisMem = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1mb
            $value = [Math]::Round([Math]::Min($PhisMem * 0.9, $PhisMem - 4096))
            # SQL settings
            Invoke-Sqlcmd "EXEC sp_configure 'show advanced options', 1; RECONFIGURE; EXEC sp_configure 'max server memory', $value; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure Backup_Compression_default, 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure 'max degree of parallelism', 1; RECONFIGURE;"
            Invoke-Sqlcmd "EXEC sp_configure 'cost threshold for parallelism', 50; RECONFIGURE;"
            Restart-Service -Name MSSQLSERVER -Force
            Start-Sleep -Seconds 10
            New-Item -Path "C:\Temp" -Name "SQLSettingsUpdated.txt" -Type "file" -value "SQL settings successfully updated" -Force 
         }
         GetScript  = {
            @{}
         }
         
      } 

      Script CreateMasterKey {
         TestScript           = {
                (Invoke-Sqlcmd "SELECT COUNT(*) FROM sys.symmetric_keys WHERE name LIKE '%DatabaseMasterKey%'").Column1 -eq 1
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$using:dbMasterKeyPassword';"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = '[Script]ChangeSQLServerSettings'
      }
      Service SQLServerAgent2 {
         Name        = "SQLSERVERAGENT"
         Ensure      = "Present"
         StartupType = "Manual"
         State       = 'Running'
      }

      Script ChangeSQLAgentHistorySettings2 {
         TestScript           = {
            Start-Sleep -Seconds 5
            Import-Module SQLPS -DisableNameChecking
            $TargetMaximumHistoryRows = $using:SQLAgentMaximumHistoryRows
            $TargetMaximumJobHistoryRows = $using:SQLAgentMaximumJobHistoryRows
            try {
               # Using Windows authenticated connection
               $db = get-sqldatabase -serverinstance . -name msdb
               # Select SQLAgent
               $SQLAgent = $db.parent.JobServer
               # Show settings
               $CurrentSettings = $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               $CurrentSettings | Format-Table -AutoSize
               if ( $CurrentSettings.MaximumHistoryRows -ne $TargetMaximumHistoryRows -or $CurrentSettings.MaximumJobHistoryRows -ne $TargetMaximumJobHistoryRows ) {
                  return $false
               }
               else {
                  return $true
               }
            }
            catch {
               # Handle the error
               $err = $_.Exception
               write-error $err.Message
               while ( $err.InnerException ) {
                  $err = $err.InnerException
                  write-error $err.Message
               }
               break
            }
         }
         SetScript            = {
            Start-Sleep -Seconds 5
            Import-Module SQLPS -DisableNameChecking
            $TargetMaximumHistoryRows = $using:SQLAgentMaximumHistoryRows
            $TargetMaximumJobHistoryRows = $using:SQLAgentMaximumJobHistoryRows
            try {
               # Using Windows authenticated connection
               $db = get-sqldatabase -serverinstance . -name msdb
               # Select SQLAgent
               $SQLAgent = $db.parent.JobServer
               # Show settings
               $CurrentSettings = $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               $CurrentSettings | Format-Table -AutoSize
               if ( $CurrentSettings.MaximumHistoryRows -ne $TargetMaximumHistoryRows -or $CurrentSettings.MaximumJobHistoryRows -ne $TargetMaximumJobHistoryRows ) {
                  Write-Host 'Altering SQLAgent settings';
                  $SQLAgent.MaximumHistoryRows = $TargetMaximumHistoryRows
                  $SQLAgent.MaximumJobHistoryRows = $TargetMaximumJobHistoryRows
                  $SQLAgent.Alter()
                  # ensuring we have the latest information
                  $SQLAgent.Refresh()
                  $SQLAgent | Select-Object @{n = "SQLInstance"; e = { $db.parent.Name } }, MaximumHistoryRows, MaximumJobHistoryRows
               }
               #Close connection
               $db.Parent.ConnectionContext.Disconnect()
            }
            catch {
               # Handle the error
               $err = $_.Exception
               write-error $err.Message
               while ( $err.InnerException ) {
                  $err = $err.InnerException
                  write-error $err.Message
               }
               break
            }
            write-host 'Successfully updated SQLAgent settings'
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Service]SQLServerAgent2"
      }
      File WaitForFailoverCluster {
         SourcePath      = "\\$vm1Name\c$\SetClusterQuorum.txt"
         DestinationPath = "c:\temp\quotum.txt"
         Credential      = $vmCredentials
         DependsOn       = "[Script]CreateMasterKey"
      }

      <#       Script WaitForFailoverCluster {
      
         TestScript           = {
            test-path -path "\\$using:vm1Name\c$\SetClusterQuorum.txt" -ErrorAction SilentlyContinue
         }
         SetScript            = {
            $tryIndex = 1
            $maxTryCount = 360 / 5
            do {
               $clusterPresent = test-path -path "\\$using:vm1Name\c$\SetClusterQuorum.txt" -errorAction SilentlyContinue
               if (!$clusterPresent) {
                  Write-Host "Awaiting when Failover Cluster is created on primary node. Attempt #$tryIndex of #$maxTryCount"
                  Start-Sleep -Seconds 10
               }
               $tryIndex = $tryIndex + 1
            }
            while ($tryIndex -le $maxTryCount -and !$clusterPresent)
            if (!$clusterPresent) {
               throw "Cannot find \\$using:vm1Name\c$\SetClusterQuorum.txt"
            }
            else {
               Start-Sleep -Seconds 20
            }
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateMasterKey"
      } #>

      SqlAlwaysOnService EnableAlwaysOn2 {
         Ensure               = 'Present'
         ServerName           = 'localhost'
         InstanceName         = $InstanceName
         RestartTimeout       = 120
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[File]WaitForFailoverCluster"
      }

      SqlLogin AddNTServiceClusSvc2 {
         Ensure               = 'Present'
         Name                 = 'NT SERVICE\ClusSvc'
         LoginType            = 'WindowsUser'
         ServerName           = 'localhost'
         InstanceName         = $InstanceName
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[SqlAlwaysOnService]EnableAlwaysOn2"
      }
     
      SqlPermission 'AddNTServiceClusSvcPermissions2' {
         ServerName   = 'localhost'
         InstanceName = $InstanceName
         Name         = 'NT SERVICE\ClusSvc'
         Credential   = $vmCredentials
         Permission   = @(
            ServerPermission {
               State      = 'Grant'
               Permission = @('AlterAnyAvailabilityGroup', 'ViewServerState')
            }
            ServerPermission {
               State      = 'GrantWithGrant'
               Permission = @()
            }
            ServerPermission {
               State      = 'Deny'
               Permission = @()
            }
         )
         DependsOn    = '[SqlLogin]AddNTServiceClusSvc2'
      }
     
   
      Script CreateAndBackupCertificate2 {
         TestScript           = {
                 (Invoke-Sqlcmd "SELECT * FROM sys.certificates where name = '$using:vm2Name'").name -eq "$using:vm2Name"
         }
         SetScript            = {
            $expireDate = (Get-Date).AddYears(+10).ToString('yyyyMMdd')
            Invoke-Sqlcmd "CREATE CERTIFICATE [$using:vm2Name] WITH SUBJECT = '$vm2Name Certificate', EXPIRY_DATE = '$expireDate';"
            Invoke-Sqlcmd "BACKUP CERTIFICATE [$using:vm2Name] TO FILE = 'C:\Temp\$using:vm2Name.cer';"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[File]WaitForFailoverCluster"
      }

      File CopySecondCertificate {
         SourcePath           = "\\$vm1Name\c$\Temp\$vm1Name.cer"
         DestinationPath      = "c:\temp\$vm1Name.cer"
         DependsOn            = "[File]WaitForFailoverCluster"
         PsDscRunAsCredential = $vmCredentials

      }
  

      Script CreateLoginAndUserWithCertificate2 {
         TestScript           = {
                 (Invoke-Sqlcmd "SELECT * FROM sys.server_principals  where name = '$using:vm1Name'").name -eq "$using:vm1Name"
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE LOGIN [$using:vm1Name] WITH PASSWORD = '$using:dbLoginPassword';"
            Invoke-Sqlcmd "CREATE USER [$using:vm1Name] FOR LOGIN [$using:vm1Name];"
            Invoke-Sqlcmd "CREATE CERTIFICATE [$using:vm1Name] AUTHORIZATION [$using:vm1Name] FROM FILE = 'C:\Temp\$using:vm1Name.cer'"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[File]CopySecondCertificate"
      }

      Script CreateEnpointWithPermissions2 {
         TestScript           = {
                 (Invoke-Sqlcmd "SELECT * FROM sys.endpoints where name = 'HADR_Endpoint'").name -eq "HADR_Endpoint"
         }
         SetScript            = {
            Invoke-Sqlcmd "CREATE ENDPOINT HADR_Endpoint STATE = STARTED AS TCP ( LISTENER_PORT = 5022, LISTENER_IP = ALL) FOR DATABASE_MIRRORING ( AUTHENTICATION = CERTIFICATE [$using:vm2Name], ROLE = ALL );"
            Invoke-Sqlcmd "GRANT CONNECT ON ENDPOINT::HADR_Endpoint TO [$using:vm1Name];"
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = "[Script]CreateLoginAndUserWithCertificate2"
      }

      
      Script WaitForAgAndJoin {
         TestScript           = {
            Test-Path "C:\Temp\JoinedToAG.txt"
         }
         SetScript            = {
            $tryIndex = 1
            $maxTryCount = 180 / 5
            $agFilePath = "\\$using:vm1Name\c$\Temp\AgProbesConfigured.txt"
            do {
               $agPresent = Test-Path $agFilePath
               if (!$agPresent) {
                  Write-Host "Awaiting when availbility group is created on primary node. Attempt #$tryIndex of #$maxTryCount"
                  Start-Sleep -Seconds 10
               }
               $tryIndex = $tryIndex + 1
            }
            while ($tryIndex -le $maxTryCount -and !$agPresent)
            if (!$agPresent) {
               throw "Cannot find $agFilePath"
            }
            else {
               Start-Sleep -Seconds 30
               Invoke-Sqlcmd "ALTER AVAILABILITY GROUP [$using:clusterName] JOIN;"
               Invoke-Sqlcmd "ALTER AVAILABILITY GROUP [$using:clusterName] GRANT CREATE ANY DATABASE;"
               New-Item -Path "C:\Temp" -Name "JoinedToAG.txt" -Type "file" -value "Successfully joined to AG" -Force
            }
            $global:DSCMachineStatus = 1
         }
         GetScript            = {
            @{}
         }
         PsDscRunAsCredential = $vmCredentials
         DependsOn            = @("[Script]CreateEnpointWithPermissions2", "[SqlPermission]AddNTServiceClusSvcPermissions2")
         
      }
   }
   #endregion
}