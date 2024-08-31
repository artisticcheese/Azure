$ErrorActionPreference = 'SilentlyContinue'
$VerbosePreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
Start-Transcript -OutputDirectory c:\prep
$partitionsize = (Get-PartitionSupportedSize -DriveLetter "C")
$size = Get-Partition -DriveLetter "C"
if ($partitionsize.SizeMax -ne $size.size) { Resize-Partition -DriveLetter "C" -Size $partitionsize.SizeMax }

Install-PackageProvider -Name NuGet -Force 
$modulestoInstall = @('cChoco')
$modulestoInstall | Foreach-Object {
    Write-Verbose "Checking $_ module installed"
    if ((Get-InstalledModule $_ -ErrorAction SilentlyContinue) -eq $null) {
        Write-Verbose "Installing $_ module"
        install-module $_ -Force
    }
}
Enable-PSRemoting -force
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
 
# Download VDOT
$URL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
$ZIP = 'VDOT.zip'
Invoke-WebRequest -Uri $URL -OutFile $ZIP -ErrorAction 'Stop'
# Extract VDOT from ZIP archive
Expand-Archive -LiteralPath $ZIP -Force -ErrorAction 'Stop'
    
# Run VDOT
& .\VDOT\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1  -Optimizations All -AcceptEULA -ErrorAction "SilentlyContinue"
$error.Clear() #Have to clear automatical error variable since script below fails frequently on Server 2022


Stop-Transcript