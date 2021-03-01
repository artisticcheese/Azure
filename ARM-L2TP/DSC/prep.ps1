param(
   [Parameter(Mandatory = $true)]
   [ValidateNotNullorEmpty()]
   [string]$vpnAccount,
   [Parameter(Mandatory = $true)]
   [ValidateNotNullorEmpty()]
   [securestring]$vpnPassword,
   [Parameter(Mandatory = $true)]
   [ValidateNotNullorEmpty()]
   [string]$sharedSecret,
   [string[]]$ipAddressRange 
)
if (-not (find-packageprovider Nuget -force)) { Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force }
if (-not (Get-InstalledModule PSDscResources)) { find-module PSDscResources | install-module -force }
Start-Transcript .\process.log -Append
& .\run.ps1
Stop-Transcript