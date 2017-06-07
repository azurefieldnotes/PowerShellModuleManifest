Remove-Module PowerShellModuleManifest
Remove-Module reporthtml
import-module C:\Users\matt.quickenden\Documents\GitHub\ReportHTML\ReportHTML

import-module C:\Users\matt.quickenden\Documents\GitHub\PowerShellModuleManifest




$r = Get-Module reporthtml
$r.path
$r.Version

$p = Get-Module PowerShellModuleManifest
$p.path
$p.Version


#Publish-PowerShellModuleManifestContents -Manifestpath C:\Users\matt.quickenden\Documents\GitHub\Manifests
#$Result = Publish-PowerShellModuleReport -ModuleName Avanade.ArmTools -ModuleVersion '1.6.2' -ManifestPath C:\Users\matt.quickenden\Documents\GitHub\Manifests
#$Result 
#Invoke-Item $Result 

Publish-PowerShellModuleManifest -disableGenerateContents
