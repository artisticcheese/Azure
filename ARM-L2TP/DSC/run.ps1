$cd = @{
   AllNodes = @(    
      @{  
         NodeName                    = 'localhost'
         PsDscAllowPlainTextPassword = $true
         PSDscAllowDomainUser        = $true
      }
   ) 
}
[DSCLocalConfigurationManager()]
Configuration localhost
{
   Node localhost
   {
      Settings {
         RebootNodeIfNeeded = $true
      }
   }
}
Configuration Prep
{
   param(
      [ValidateNotNullorEmpty()]   
      [string]$vpnAccount,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullorEmpty()]
      [securestring]$vpnPassword,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullorEmpty()]
      [string] $sharedSecret,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullorEmpty()]
      [string[]]$ipAddressRange 
   )
   Import-module psdscresources
   Import-DscResource -ModuleName 'PSDscResources'


   Node localhost {
      WindowsFeatureSet WindowsFeatureSetExample {
         Name                 = @('DirectAccess-VPN', 'Routing', 'RSAT-RemoteAccess-PowerShell')
         Ensure               = 'Present'
         IncludeAllSubFeature = $true
      }
      User VPNAccount {
         Ensure   = "Present"  
         UserName = $vpnAccount
         Password = New-Object System.Management.Automation.PSCredential ($vpnAccount, $vpnPassword)
      }
      Script InstallVPN {
         DependsOn  = @('[WindowsFeatureSet]WindowsFeatureSetExample')
         TestScript = { (Get-RemoteAccess).VPNStatus -eq "Installed" }
         SetScript  = {
            Install-RemoteAccess -IPAddressRange $using:ipAddressRange -VpnType Vpn
            Start-Sleep 10
            Set-VpnAuthProtocol -TunnelAuthProtocolsAdvertised PreSharedKey -SharedSecret $using:sharedSecret
            netsh ras set user $using:vpnAccount permit
         }
         GetScript  = { @{ Result = Get-RemoteAccess | out-string } }
      }
      Script ConfigureNAT {
         DependsOn  = @('[WindowsFeatureSet]WindowsFeatureSetExample', '[script]InstallVPN')
         TestScript = { (Invoke-Expression "netsh routing ip nat show interface")[1].Contains("NAT") }
         SetScript  = {
            netsh routing ip nat install
            netsh routing ip nat set global tcptimeoutmins=1440 udptimeoutmins=1 loglevel=ERROR
            netsh routing ip nat add interface name="Ethernet" mode=FULL
            Restart-Service RemoteAccess
         }
         GetScript  = { @{ Result = Invoke-Expression "netsh routing ip nat show interface" | out-string } }
      }
   }
}
localhost -OutputPath "$env:temp\localhost"
prep -OutputPath "$env:temp\prep" -vpnAccount $vpnAccount -vpnPassword $vpnPassword -ConfigurationData $cd -SharedSecret $sharedSecret -ipAddressRange $ipAddressRange
Set-DSCLocalConfigurationManager -path "$env:temp\localhost" -Verbose -force
Start-DscConfiguration -path "$env:temp\prep" -wait -Verbose -force

