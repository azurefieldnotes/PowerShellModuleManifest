
Function Use-PSManifest
{
	$PSMM = Get-Module PowerShellModuleManifest
    $Module = get-item $PSMM.Path
    $ManifestBase = (get-item $Module.PSParentPath).PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::','')
	$ManifestPath = Join-Path $ManifestBase Manifests
	$PowerShellModuleManifest = join-path $ManifestPath  ($PSMM.Name + '-' + $PSMM.Version.ToString() + '.html')
	
	
    if (!(Test-Path $PowerShellModuleManifest ))
	{
		Publish-PowerShellModuleManifest -ManifestPath $ManifestPath
	}
	Invoke-Item $PowerShellModuleManifest 
}

Function Publish-PowerShellModuleManifest
{
	Param 
	(
		$maxJobs = 10,
		[switch]$DisableGenerateContents,
		[switch]$Regenerate,
		$CompanyLogoURL,
		[switch]$RunAsJobs=$true
	)
	#$VerbosePreference='Continue'
	
	
	$PSMM = Get-Module PowerShellModuleManifest
    $Module = get-item $PSMM.Path
    $ManifestBase = (get-item $Module.PSParentPath).PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::','')
	$ManifestPath = Join-Path $ManifestBase Manifests
	
	if (!(test-path $ManifestPath)){New-Item -ItemType directory -Name Manifests -Path $ManifestBase}
	$PowerShellModuleManifest = join-path $ManifestPath "ReportHTML-1.3.2.2.html"# ($PSMM.Name + '-' + $PSMM.Version.ToString() + '.html')
	
	Publish-PowerShellModuleManifestContents  -Manifestpath $ManifestPath
	
	$InstalledModules = Get-Module -ListAvailable 
	$ExistingManifests = Get-ChildItem $ManifestPath  
    $PSMMPSD1 = (Get-Module PowerShellModuleManifest).path.Replace('.psm1','.psd1')
	$ReportPSD1 = (Get-Module ReportHTML).path.Replace('.psm1','.psd1')
	write-verbose "Path to PowerShellModuleManifest module $PSMMPSD1"
	foreach ($InstalledModule in $InstalledModules)
	{
		#$InstalledModule = $InstalledModules | ? {$_.name -eq 'PowerShellModuleManifest'}
		$ModuleName = $InstalledModule.Name
		$ModuleVersion = $InstalledModule.version.ToString()
		if ($Regenerate -ne $true) 
		{
			$ExistingManifest = $ExistingManifests | ? {$_.basename -eq  ($ModuleName + "-" + $ModuleVersion )}
		}
		if ($ExistingManifest  -eq $null) 
		{
			Write-Verbose "Manifest Search returned nothing, Generating Job for $ModuleName for version $ModuleVersion to $ManifestPath"
			if ($RunAsJobs -eq $true)
			{
				Start-Job -Name $ModuleName -ScriptBlock {import-module $args[4];Import-Module $args[3];Publish-PowerShellModuleReport -modulename $args[0] -ModuleVersion $args[1]  -ManifestPath  $args[2]  } -ArgumentList $ModuleName,$ModuleVersion ,$ManifestPath,$PSMMPSD1,$ReportPSD1 
				sleep 3
			}
			else
			{
				Publish-PowerShellModuleReport -modulename $ModuleName -ModuleVersion $ModuleVersion -ManifestPath  $ManifestPath
			}
			
		}
		else
		{
			Write-Verbose ("Manifest Search found Manifest " +  $ExistingManifest.FullName)
		}
		
		$jobs = @(Get-Job | ? {$_.state -eq 'Running'})
		while ($jobs.Count -ge $maxJobs) 
		{
			Write-Verbose ([string]$jobs.count + " Running jobs...waiting")
			$jobs = @(Get-Job | ? {$_.state -eq 'Running'})
            Get-Job | ? {$_.state -eq 'Running'}
			sleep 10
			
		} 
		
	}
	Write-Verbose "Failed Jobs"
	Get-Job | ? {$_.state -eq 'Failed'}
	Invoke-Item $PowerShellModuleManifest
}

Function Publish-PowerShellModuleManifestContents
{
	param
	(
		$Manifestpath
	)

	$InstalledModules = Get-Module -ListAvailable
	
	$ModuleReportList = $InstalledModules | select `
		@{n='Module Report';e={"URL01" + $_.Name+ "-" + $_.version + ".htmlURL02" + $_.Name + "URL03"}}, `
		@{n='Installed Version';e={$_.version}}, `
		#@{n='PSGallery Latest';e={$_.PSgalleryResult.version}},`
		#@{n='Repository Source';e={$_.RepositorySourceLocation}},`
		ModuleType ,
		@{n='Web Search';e={"URL01Newhttps://www.google.ca/search?q=powershell module" + $_.Name + "URL02SearchURL03"}} `
		| sort 'Module Report' 

	$rptManifest= @()
	$rptManifest += get-htmltabcontentopen -TabName 'Module Manifest' -tabheading ' '
		$rptManifest  += Get-HTMLContentOpen -HeaderText 'PowerShell Module Manifest'
			$rptManifest  += Get-HTMLContentTable $ModuleReportList 
		$rptManifest  += Get-HTMLContentClose
	$rptManifest += get-htmltabcontentclose
#	
	$rptManifest += get-htmltabcontentopen -TabName "Cmdlet Listing" -tabheading ' '
	$rptManifest += Get-HTMLContentOpen -HeaderText "Complete PowerShell Cmdlet Listing" 
	$Cmdlets = Get-Command | select  Name	,CommandType	,Source	,Version	,Visibility	,ModuleName	,Module 
	$rptManifest += Get-HTMLContentDataTable $Cmdlets
	$rptManifest += Get-HTMLContentClose
	$rptManifest += get-htmltabcontentclose
#	
	$r = Get-Module reporthtml
	$p = Get-Module PowerShellModuleManifest

	$rptManifest += get-htmltabcontentopen -TabName 'About' -tabheading ' '
		$rptManifest  += Get-HTMLContentOpen -HeaderText 'About PowerShell Module Manifest'
			$rptManifest  += Get-HTMLContentText -Heading "This code" -Detail "was written to help use powershell help easier"
			$rptManifest  += Get-HTMLContentText -Heading "Reporthtml Version"  -Detail ($r.Version)
			$rptManifest  += Get-HTMLContentText -Heading "Reporthtml Path"  -Detail ($r.path)
			$rptManifest  += Get-HTMLContentText -Heading "PowerShellModuleManifest Version" -Detail ($p.Version)
			$rptManifest  += Get-HTMLContentText -Heading "PowerShellModuleManifest Path" -Detail ($p.path)
		$rptManifest  += Get-HTMLContentClose
	$rptManifest += get-htmltabcontentclose
	
	$rptManifest | Set-Content "$Manifestpath\Contents.Part" -Force
    $InstalledModules | select name, version | Export-Csv -Path "$Manifestpath\PSModuleContents.csv" -Force

}

Function Publish-PowerShellModuleReport
{
	param 
	(
		$ModuleName = 'Avanade.AzureReports',
		$ModuleVersion = '1.0.5',
		$ManifestPath  = 'C:\Users\matt.quickenden\Documents\GitHub\Manifests'
	)

	Write-Verbose "update help for $ModuleName"
	update-help $ModuleName
	Write-Verbose "Importing $ModuleName Module $ModuleVersion version"
	Import-Module $ModuleName
	$Module = Get-Module $ModuleName | ? {$_.version -eq $ModuleVersion}
	$Mpath = Get-Item $Module.Path
	$FunctionList = @(get-command -module $ModuleName)
	$AllFunctions = Get-Functions -path $Mpath.PSParentPath
	$PSGallery = Find-Module $ModuleName 

	$rpt = @()
	$rpt += Get-HTMLOpenPage -TitleText ("Powershell Module Manifest - " + $ModuleName + " (" + $Module.Version + ")") -leftLogoName Corporate -RightLogoName PowerShell
	$rpt += Get-HTMLTabHeader -TabNames 'Summary','Cmdlet Descriptions','Cmdlets with Parameters','Module Manifest','Cmdlet Listing','About'

	$rpt += Get-Content "$ManifestPath\contents.part"

	#	
#	$rpt += get-htmltabcontentopen -TabName "Cmdlet Listing" -tabheading ' '
#	$rpt += Get-HTMLContentOpen -HeaderText "Complete PowerShell Cmdlet Listing" 
#	$Cmdlets = Get-Command | select  Name	,CommandType	,Source	,Version	,Visibility	,ModuleName	,Module 
#	$rpt += Get-HTMLContentDataTable $Cmdlets
#	$rpt += Get-HTMLContentClose
#	$rpt += get-htmltabcontentclose
	


	#region Details 
	$rpt += get-htmltabcontentopen -TabName "Summary" -tabheading ' '
		$rpt += Get-HTMLContentOpen -HeaderText "$ModuleName Details" -BackgroundShade 2
			
            $rpt += Get-HTMLContentOpen -HeaderText "Module Details" 
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
				$rpt += Get-HTMLContentText  -Heading "Avaliable Version" -detail $PSGallery.Version.ToString()
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
			
		$rpt += Get-HTMLContentClose
	$rpt += get-htmltabcontentclose
	#Endregion

	#region FunctionList
		$rpt += get-htmltabcontentopen -TabName 'Cmdlet Descriptions' -tabheading ' '
	        $rpt += Get-HtmlContentOpen -HeaderText "Functions with Parameters" -BackgroundShade 2
	        foreach ($function in ( $FunctionList  | sort Name))
			{
	                $rpt += Get-HtmlContentOpen  -HeaderText ($function.Name)
	                $FunctionHelp = Get-Help $function.Name
	                    $rpt += Get-HTMLContentText -Heading "Name" -Detail ($FunctionHelp.Name)
	                    $rpt += Get-HTMLContentText -Heading "Synopsis" -Detail ($FunctionHelp.synopsis)
	                    #$rpt += Get-HTMLContentText -Heading "syntax" -Detail ($FunctionHelp.syntax)
						$rpt += Get-HTMLContentText -Heading "Remarks" -Detail ($FunctionHelp.Remarks)
	                    foreach ($Example in @($FunctionHelp.Examples)) {
							$exText = ($Example.example)
							$rpt += Get-HTMLContentText -Heading "introduction" -Detail $exText.title
							$rpt += Get-HTMLContentText -Heading "introduction" -Detail $exText.introduction
							$rpt += Get-HTMLContentText -Heading "introduction" -Detail $exText.commandLines
							$rpt += Get-HTMLContentText -Heading "introduction" -Detail $exText.remarks
							
							$rpt += Get-HTMLContentText -Heading "Examples" -Detail (Get-HTMLCodeBlock -Code $exText.code -Style PowerShell) 
						}
	                $rpt += Get-HtmlContentclose
	        }
	    	$rpt += Get-Htmlcontentclose
	    $rpt += get-htmltabcontentclose
	#endregion

	#region Params
	$rpt += get-htmltabcontentopen -TabName 'Cmdlets with Parameters' -tabheading ' '
	$rpt += Get-HTMLAnchor -AnchorName "Top"

	          $rpt += Get-HtmlContentOpen -HeaderText "Functions with Parameters" -BackgroundShade 2
			  $rpt += Get-HtmlContentOpen -HeaderText "Available Functions "  
	          	$rpt += ($FunctionList | % { (Get-HTMLAnchorLink -AnchorName $_.Name -AnchorText $_.Name ) + '<BR>'} )
	   		  $rpt += Get-HtmlContentclose
	          foreach ($function in ( $FunctionList | sort Name)){
	                $rpt += Get-HTMLAnchorlink -AnchorName Top -AnchorText 'Back To  List'
	                $Params = @(Get-Parameters -Cmdlet $function.Name)
	                
	                if ($Params.count -gt 0) {
	                      $rpt += Get-HtmlContentOpen  -HeaderText ($function.Name) -Anchor $function.Name
	                      $FunctionHelp = Get-Help $function.Name
	                      $rpt += Get-HtmlContentOpen  -HeaderText Overview 
						  	$rpt += Get-HTMLContentText -Heading "Name" -Detail ($FunctionHelp.Name)
	                      	$rpt += Get-HTMLContentText -Heading "Synopsis" -Detail ($FunctionHelp.synopsis)
	                      	$rpt += Get-HTMLContentText -Heading "Remarks" -Detail ($FunctionHelp.Remarks)
	                      	$rpt += Get-HTMLContentText -Heading "Examples" -Detail ($FunctionHelp.Examples)
						  $rpt += Get-HtmlContentclose
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
	Write-Output $ManifestPath
	$Helpfile = Save-HTMLReport -ReportContent $rpt -ReportPath $ManifestPath -ReportName ($ModuleName + "-" + $Module.Version)
	Write-Output $Helpfile 
}



