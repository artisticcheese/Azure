Configuration devops_vdi_config {
    param(
        $requiredServices = @('telnet-client', 'Web-Mgmt-Console', 'Web-Metabase', 'Web-Lgcy-Mgmt-Console', 'RSAT'),
        $requiredChocolateyPackages = @(
            @{ Name = 'terraform'; Version = '1.5.0' },
            @{ Name = 'notepadplusplus' },
            @{ Name = '7zip' },
            @{ Name = 'sql-server-management-studio' },
            @{ Name = 'pgadmin4' },
            @{ Name = 'dbeaver' },
            @{ Name = 'vscode' },
            @{ Name = 'pycharm' },
            @{ Name = 'microsoftazurestorageexplorer' },
            @{ Name = 'kubernetes-cli' },
            @{ Name = 'kubelogin' },
            @{ Name = 'helmsman' },
            @{ Name = 'saml2aws' },
            @{ Name = 'terragrunt' },
            @{ Name = 'vault' },
            @{ Name = 'psql' },
            @{ Name = 'vim' },
            @{ Name = 'rdcman' },
            @{ Name = 'powershell-core' },
            @{ Name = 'royalts-v7-x64' },
            @{ Name = 'pritunl-client' }
        )
    )
     
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'cChoco'
    Node 'localhost' {
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
        File TempFolder {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\Temp"
        }
        cChocoInstaller installChoco
        {
            InstallDir = 'C:\choco'
        }
        cChocoFeature showDownloadProgress
        {
            FeatureName = "showDownloadProgress"
            Ensure      = 'Absent'
            DependsOn   =  '[cChocoInstaller]installChoco'
        }
        foreach ($package in $requiredChocolateyPackages) {
            if ($package.version) {
                cChocoPackageInstaller "Install_$($package.Name)" {
                    Name      = $package.Name
                    Version   = $package.Version
                    Ensure    = 'Present'
                    DependsOn = '[cChocoInstaller]InstallChoco'
                }
            }
            else {
                cChocoPackageInstaller "Install_$($package.Name)" {
                    Name      = $package.Name
                    Ensure    = 'Present'
                    DependsOn = '[cChocoInstaller]InstallChoco'
                }
            }
        }

    }
}
#$config = devops_vdi_config
#Start-DscConfiguration -path $config.psparentpath -Wait -Verbose -force