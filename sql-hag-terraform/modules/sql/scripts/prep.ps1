$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force 
$modulestoInstall = @('FailoverClusterDsc', 'SqlServerDsc', 'ComputerManagementDSC', 'WindowsDefender', 'AccessControlDSC')
$modulestoInstall | Foreach-Object {
   Write-Verbose "Checking $_ module installed"
   if ((Get-InstalledModule $_ -ErrorAction SilentlyContinue) -eq $null) {
      Write-Verbose "Installing $_ module"
      install-module $_ -Force
   }
}
Enable-PSRemoting -force
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False