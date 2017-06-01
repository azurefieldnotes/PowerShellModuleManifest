Remove-Module PowerShellModuleManifest
remove-Module ReportHTML
Import-Module C:\Users\matt.quickenden\Documents\GitHub\PowerShellModuleManifest\PowerShellModuleManifest.psd1
Import-Module C:\Users\matt.quickenden\Documents\GitHub\ReportHTML\ReportHTML\reporthtml.psd1
get-module ReportHTML
#$PMM = Get-Module PowerShellModuleManifest

#$ModulePath = get-childitem $PMM.Path
#$ModuleParentPath = $ModulePath.PSParentPath

$ManifestPath =
if (!(Test-Path $ManifestPath))
{
	New-Item -ItemType directory -Name Manifest -Path C:\Users\matt.quickenden\Documents\GitHub\PowerShellModuleManifest
}
$VerbosePreference="Continue"

$ModuleName = 'Reporthtml'
$ModuleVersion = '1.3.2.1' 



$j = get-job -Id 5
$j.Command