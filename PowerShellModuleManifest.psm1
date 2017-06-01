
Function Use-PSManifest
{
	param
	(
	    $CompanyLogoURL
	)
	$VerbosePreference='Continue'
	write-host "this process will scan your module directory and generate a series of reports.  Depending on how many modules you have installed."
	$Answer = Read-Host "Do you want to proceed Y/N"
	$Answer 
	switch ($Answer )
	{
		'y' {}
		'n' {exit}
	}
	

    $PSMM = Get-Module PowerShellModuleManifest
    $Module = get-item $PSMM.Path
    $ManifestBase = (get-item $Module.PSParentPath).PSParentPath.Replace('Microsoft.PowerShell.Core\FileSystem::','')
	$ManifestPath = Join-Path $ManifestBase Manifests
	
	if (!(test-path $ManifestPath)){New-Item -ItemType directory -Name Manifests -Path $ManifestBase}
	

	$Manifest = join-path $ManifestPath  ($PSMM.Name + '-' + $PSMM.Version.ToString() + '.html')
	if (Test-Path $Manifest )
	{
		Invoke-Item $Manifest 
	}
	else
	{
		Publish-PowerShellModuleManifestContents  -Manifestpath $ManifestPath
		Publish-PowerShellModuleManifest -ManifestPath $ManifestPath
	}
	Invoke-Item $Manifest 
	
}

Function Publish-PowerShellModuleManifest
{
	Param 
	(
		$maxJobs = 10,
		$ManifestPath ,
		[switch]$GenerateContents 
	)
	
	if ($GenerateContents) {Publish-PowerShellModuleManifestContents}
	
	$InstalledModules = Get-Module -ListAvailable 
	$ExistingManifests = Get-ChildItem $ManifestPath  
    $PSMMPSD1 = (Get-Module PowerShellModuleManifest).path.Replace('.psm1','.psd1')
	foreach ($InstalledModule in $InstalledModules)
	{
		$ModuleName = $InstalledModule.Name
		$ModuleVersion = $InstalledModule.version.ToString()
		$ExistingManifest = $ExistingManifests | ? {$_.basename -eq  ($ModuleName + "-" + $ModuleVersion )}
		if ($ExistingManifest  -eq $null) 
		{
			Write-Verbose "Manifest Search returned nothing, Generating Job for $ModuleName for version $ModuleVersion to $ManifestPath"
			Start-Job -Name $ModuleName -ScriptBlock {Import-Module $args[3];Publish-PowerShellModuleReport -modulename $args[0] -ModuleVersion $args[1]  -ManifestPath  $args[2]  } -ArgumentList $ModuleName,$ModuleVersion ,$ManifestPath,$PSMMPSD1 
			sleep 3
		}
		else
		{
			Write-Verbose ("Manifest Search found Manifest " +  $ExistingManifest.FullName)
		}
		
		$jobs = @(Get-Job | ? {$_.state -eq 'Running'})
		while ($jobs.Count -ge $maxJobs) 
		{
			Write-Verbose ([string]$jobs.count + " Running jobs...waiting")
			sleep 30
		} 
		
	}
	
}

Function Publish-PowerShellModuleManifestContents
{
	param
	(
		$Manifestpath
	)

	$InstalledModules = Get-Module -ListAvailable
	$Modules = @()
	foreach ($InstalledModule in $InstalledModules)
	{
			Write-Verbose ("Trying " + $InstalledModule.name)
			Try 
			{
				$PSGallery = Find-Module $InstalledModule 
				$InstalledModule | Add-Member -Name PSgalleryResult -Value $PSGallery -MemberType NoteProperty
			}
			Catch 
			{
				$InstalledModule | Add-Member -Name PSgalleryResult -Value "Missing" -MemberType NoteProperty
			}
			Finally 
			{
				$Modules += $InstalledModule 
			}
	}
	
	$ModuleReportList = $Modules | select `
		@{n='Module Report';e={"URL01$Manifestpath\" + $_.Name+ "-" + $_.version + ".htmlURL02" + $_.Name + "URL03"}}, `
		@{n='Installed Version';e={$_.version}}, `
		@{n='PSGallery Latest';e={$_.PSgalleryResult.version}},`
		#@{n='Repository Source';e={$_.RepositorySourceLocation}},`
		ModuleType ,
		@{n='Web Search';e={"URL01Newhttps://www.google.ca/search?q=powershell module" + $_.Name + "URL02SearchURL03"}} `
		| sort 'Module Report' 

	$rptManifest= @()
	$rptManifest += get-htmltabcontentopen -TabName 'PowerShell Module Manifest' -tabheading ' '
		$rptManifest  += Get-HTMLContentOpen -HeaderText 'PowerShell Module Manifest'
			$rptManifest  += Get-HTMLContentTable $ModuleReportList 
		$rptManifest  += Get-HTMLContentClose
	$rptManifest += get-htmltabcontentclose
	
	$rptManifest += get-htmltabcontentopen -TabName 'About' -tabheading ' '
		$rptManifest  += Get-HTMLContentOpen -HeaderText 'About PowerShell Module Manifest'
			$rptManifest  += Get-HTMLContentText -Heading "This code" -Detail "was written to help use powershell help easier"
		$rptManifest  += Get-HTMLContentClose
	$rptManifest += get-htmltabcontentclose
	

	#$rpt = @()
	#$rpt += Get-HTMLOpenPage -TitleText ("Powershell Module Manifest") -leftLogoName Corporate -RightLogoName PowerShell
	#$rpt += Get-HTMLTabHeader -TabNames 'PowerShell Module Manifest','About'
	#$rpt += $rptManifest
	#$rpt += Get-HTMLClosePage 
	#$Helpfile = Save-HTMLReport -ReportContent $rpt -ReportPath $Manifestpath -ReportName 'PowerShellModuleManifestContents'


	$rptManifest | Set-Content "$Manifestpath\Contents.Part"

	#Invoke-Item (join-path $OutputPath PowerShellModuleManifest.html)
}

Function Publish-PowerShellModuleReport
{
	param 
	(
		$ModuleName ,#= 'ReportHTML',
		$ModuleVersion,# = '1.3.2.1',
		$ManifestPath#  = 'C:\Users\matt.quickenden\Documents\GitHub\PowerShellModuleManifest\Manifest'
	)

	Import-Module $ModuleName
	$Module = Get-Module $ModuleName | ? {$_.version -eq $ModuleVersion}
	$Mpath = Get-Item $Module.Path
	$FunctionList = @(get-command -module $ModuleName)
	$AllFunctions = Get-Functions -path $Mpath.PSParentPath


	$rpt = @()
	$rpt += Get-HTMLOpenPage -TitleText ("Powershell Module Manifest - " + $ModuleName + " (" + $Module.Version + ")") -leftLogoName Corporate -RightLogoName PowerShell
	$rpt += Get-HTMLTabHeader -TabNames 'Summary','Function Descriptions','Functions with Parameters','PowerShell Module Manifest','About'

	
	$rpt += Get-Content (join-path $ManifestPath 'Contents.Part')

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


		$rpt += Get-HTMLContentClose
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
	Write-Output $ManifestPath
	$Helpfile = Save-HTMLReport -ReportContent $rpt -ReportPath $ManifestPath -ReportName ($ModuleName + "-" + $Module.Version)

}

