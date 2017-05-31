param
(
	#$ModuleName = 'Avanade.AzureAD'
	#$ModuleName = 'ReportHTML',
	#$ModuleName = 'Avanade.AzureReports'
	#$ModuleName = 'AzureRM.Insights'
	$OutputPath = 'C:\temp'
)

remove-Module reporthtml
Import-Module C:\Users\matt.quickenden\Documents\GitHub\ReportHTML\ReportHTML\reporthtml.psd1

#Get-HTMLReportHelp -GenerateReport
#Get-HTMLReportHelp 

$InstalledModules = Get-Module -ListAvailable

$rptManifest= @()
$rptManifest += get-htmltabcontentopen -TabName 'PowerShell Module Manifest' -tabheading ' '
	$rptManifest  += Get-HTMLContentOpen -HeaderText 'PowerShell Module Manifest'
		$rptManifest  += Get-HTMLContentTable ($InstalledModules | select name,@{n='Web Search';e={"URL01Newhttps://www.google.ca/search?q=powershell module" + $_.Name + "URL02SearchURL03"}},@{n='Module Report';e={"URL01$OutputPath\" + $_.Name+ ".htmlURL02" + $_.Name + "URL03"}}, Version, ModuleType | sort 'Name' )
	$rptManifest  += Get-HTMLContentClose
$rptManifest += get-htmltabcontentclose


$rpt = @()
$rpt += Get-HTMLOpenPage -TitleText ("Powershell Module Manifest") -leftLogoName Corporate -RightLogoName PowerShell
$rpt += Get-HTMLTabHeader -TabNames 'PowerShell Module Manifest','About'

$rpt += $rptManifest

$rpt += get-htmltabcontentopen -TabName 'About' -tabheading ' '
	$rpt  += Get-HTMLContentOpen -HeaderText 'About These Report'
		$rpt += Get-HTMLContentText  -Heading "What is this?" -Detail "A bunch of HTML reports"
	$rpt  += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

$rpt += Get-HTMLClosePage 
$Helpfile = Save-HTMLReport -ReportContent $rpt -ReportPath $OutputPath -ReportName 'PowerShellModuleManifest'


$rpt = @()
foreach ($InstalledModule in $InstalledModules)
{
$ModuleName = $InstalledModule.Name



#import-module $ModuleName
Import-Module $ModuleName
$Module = Get-Module $ModuleName
$Mpath = Get-Item $Module.Path
$FunctionList = @(get-command -module $ModuleName)
$AllFunctions = Get-Functions -path $Mpath.PSParentPath


$rpt = @()
$rpt += Get-HTMLOpenPage -TitleText ("Powershell Module - " + $ModuleName + " (" + $Module.Version + ")") -leftLogoName Blank -RightLogoName PowerShell
$rpt += Get-HTMLTabHeader -TabNames 'Module Summary','Function Descriptions','Functions with Parameters','PowerShell Module Manifest'

$rpt += $rptManifest

#region Details 
$rpt += get-htmltabcontentopen -TabName 'Module Summary' -tabheading ' '
	$rpt += Get-HTMLContentOpen -HeaderText 'Module Details Summary'
		$rpt += Get-HTMLContentText  -Heading "Author" -Detail $Module.Author
		$rpt += Get-HTMLContentText  -Heading "CompanyName" -detail $Module.CompanyName
		$rpt += Get-HTMLContentText  -Heading "Description" -detail $Module.Description	
		$rpt += Get-HTMLContentText  -Heading "Path" -Detail $Module.Path
		
	$rpt += Get-HTMLContentClose
	
	
	$InstalledPSG = Get-InstalledModule $ModuleName
	$PSG = Find-Module $ModuleName
	$rpt += Get-HTMLContentOpen -HeaderText 'PS Gallery'
		$rpt += Get-HTMLContentText  -Heading "Description" -Detail $InstalledPSG.Description
		$rpt += Get-HTMLContentText  -Heading "PublishedDate" -detail $InstalledPSG.PublishedDate
		$rpt += Get-HTMLContentText  -Heading "Install Date" -detail $InstalledPSG.InstalledDate
		$rpt += Get-HTMLContentText  -Heading "Install Location" -detail $InstalledPSG.InstalledLocation
		$rpt += Get-HTMLContentText  -Heading "Installed Version" -detail $InstalledPSG.Version
		$rpt += Get-HTMLContentText  -Heading "Avaliable Version" -detail $PSG.Version
		$rpt += Get-HTMLContentText  -Heading "ProjectUri" -detail ("URL01$InstalledPSG.ProjectUriURL02Project LinkURL03")
		$Dependancies = ''
		($PSG.Dependencies | %{ $Dependancies += $_.Name + ", "} )
		$rpt += Get-HTMLContentText  -Heading "Dependencies" -detail $Dependancies
		
	$rpt += Get-HTMLContentClose
	
	$rpt += Get-HtmlContentOpen -HeaderText "Cmdlets List" 
		$rpt += Get-HTMLContentTable  ($AllFunctions | select FunctionName)
	$rpt += Get-HtmlContentclose

	
	$rpt += Get-HtmlContentOpen -HeaderText "Functions in Code"  -IsHidden
		$rpt += Get-HTMLContentTable  (($AllFunctions | sort FileName,Line) | select FileName, FunctionName, Line	) -GroupBy FileName	
	$rpt += Get-HtmlContentclose



$rpt += get-htmltabcontentclose



#Endregion

#region FunctionList
	$rpt += get-htmltabcontentopen -TabName 'Function Descriptions' -tabheading ' '
        $rpt += Get-HtmlContentOpen -HeaderText "Functions with Parameters" -BackgroundShade 2
        foreach ($function in ( $FunctionList  | sort Name)){
  
                $rpt += Get-HtmlContentOpen  -HeaderText ($function.Name)
                $FunctionHelp = Get-Help $function.Name
                    $rpt += Get-HTMLContentText -Heading "Name" -Detail ($FunctionHelp.Name)
                    $rpt += Get-HTMLContentText -Heading "Synopsis" -Detail ($FunctionHelp.synopsis)
                    #$rpt += Get-HTMLContentText -Heading "syntax" -Detail ($FunctionHelp.syntax)
					$rpt += Get-HTMLContentText -Heading "Remarks" -Detail ($FunctionHelp.Remarks)
                    $rpt += Get-HTMLContentText -Heading "Examples" -Detail ($FunctionHelp.Examples)
                $rpt += Get-HtmlContentclose

        }
    	$rpt += Get-Htmlcontentclose
    $rpt += get-htmltabcontentclose
#endregion

#region PArams
$rpt += get-htmltabcontentopen -TabName 'Functions with Parameters' -tabheading ' '
$rpt += Get-HTMLAnchor -AnchorName "Top"
    $rpt += Get-HtmlContentOpen -HeaderText "Available Functions "  
          $rpt += ($FunctionList | % { (Get-HTMLAnchorLink -AnchorName $_.Name -AnchorText $_.Name ) + '<BR>'} )
    $rpt += Get-HtmlContentclose
          $rpt += Get-HtmlContentOpen -HeaderText "Functions with Parameters" -BackgroundShade 2
          foreach ($function in ( $FunctionList | sort Name)){
                $rpt += Get-HTMLAnchorlink -AnchorName Top -AnchorText 'Back To  List'
                $Params = @(Get-Parameters -Cmdlet $function.Name)
                
                if ($Params.count -gt 0) {
                      $rpt += Get-HtmlContentOpen  -HeaderText ($function.Name) -Anchor $function.Name
                      $FunctionHelp = Get-Help $function.Name
                      $rpt += Get-HTMLContentText -Heading "Name" -Detail ($FunctionHelp.Name)
                      $rpt += Get-HTMLContentText -Heading "Synopsis" -Detail ($FunctionHelp.synopsis)
                      $rpt += Get-HTMLContentText -Heading "Remarks" -Detail ($FunctionHelp.Remarks)
                      $rpt += Get-HTMLContentText -Heading "Examples" -Detail ($FunctionHelp.Examples)
                            $rpt += Get-HtmlContentOpen -HeaderText 'Functions Parameters' 
                                  $rpt += Get-HtmlContentTable (Set-TableRowColor ($Params | select ParameterSet, Name ,Type ,IsMandatory  ,Pipeline ) -Alternating ) -GroupBy ParameterSet -Fixed 
                            $rpt += Get-HtmlContentclose
                      $rpt += Get-HtmlContentclose
                }
          }
        $rpt += Get-Htmlcontentclose
    $rpt += get-htmltabcontentclose
#endregion

$rpt += Get-HTMLClosePage 
$Helpfile = Save-HTMLReport -ReportContent $rpt -ReportPath $OutputPath -ReportName $ModuleName

}

Invoke-Item (join-path $OutputPath PowerShellModuleManifest.html)