$VerbosePreference = 'Continue'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$password = 'A123456!' | ConvertTo-SecureString -AsPlainText -Force
$username = 'Administrator'
$credential = [PSCredential]::New($username, $password)
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
   Node @("SQL1", "SQL2")
   {
      Settings {
         RefreshMode        = 'Push'
         ActionAfterReboot  = 'ContinueConfiguration'
         ConfigurationMode  = 'ApplyAndAutoCorrect'
         RebootNodeIfNeeded = $true

      }
   }
}
LCMConfig -OutputPath "$env:temp\prep"
Invoke-Command -VMName  SQL1, sql2 -Credential $credential -FilePath $PSScriptRoot\prep.ps1
Set-DscLocalConfigurationManager -ComputerName SQL1, SQL2 -path "$env:temp\prep" -Credential $credential -Force


