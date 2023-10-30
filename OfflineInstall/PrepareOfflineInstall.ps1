#Requires -Version 5.0
# Ensure we can run everything
Set-ExecutionPolicy Bypass -Scope Process -Force
$commonSource = "Common"
$packages = 
    @{ 
		Name = "chocolatey-license"
        Source = $commonSource
		Enable = 1
	},
    @{ 
		Name = "ventuz-7"
        Source = $commonSource
		Enable = 1
	},
    @{ 
		Name = "dotnet-7.0-desktopruntime"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "dotnet-7.0-aspnetruntime"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "vscode"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "vnc-connect"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "7zip"
        Source = "chocolatey"
		Enable = 1
        Force = 0
	},
    @{ 
		Name = "vlc"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "chocolatey"
        Source = "chocolatey"
		Enable = 1
	},
    @{ 
		Name = "chocolatey.extension"
        Source = "chocolatey.licensed"
		Enable = 1
	},
    @{ 
		Name = "chocolateygui.extension"
        Source = "chocolatey.licensed,chocolatey"
		Enable = 1
	},
    @{ 
		Name = "powershell-core"
        Source = "chocolatey"
		Enable = 1
	}

if ($env:BOXROOT) {
    $boxRoot = $env:BOXROOT
} else {
    # Use the default username path for Box
    $boxRoot = "C:\Users\$env:USERNAME\Box"
    #Output the path provided
    Write-Output ("Box Root: {0}" -f $boxRoot)
}
    

$repoDir = Join-Path $boxRoot 'FM Game Systems\ChocoOfflineInstall\Common'
$outDir = Join-Path $PSScriptRoot Internalize
$tempDir = Join-Path $PSScriptRoot Temp

#End of config

function Get-LatestVersionNumber {
    param (
        $repository,
        $packageName 
    )

    $searchResult = choco search $packageName --source=$repository --exact --limitoutput

    if ($searchResult) {
        $match = $searchResult | Select-String -Pattern "^(?:.*?)\|((?:\.?[0-9]+){3,}(?:[-a-z]+)?)"

        if ($match) {
            return $match.Matches.Groups[1].Value
        }
    }

    # Return default value if no match is found
    return "0.0.0.0"
}


function Get-SourceDirectory {
    param (
        $repository
    )
    (
        choco sources list | 
        Select-String -Pattern "$repository - (.*?) \|"
    ).Matches.Groups[1].Value
}

function Get-LatestPackage {
    param (
        $packageDirectory,
        $packageName 
    )
    #Hand crafted by HB, 2023-10-11
    $reg = [Regex]::new('^(.*?)\.((?:\.?[0-9]+){3,}(?:[-a-z]+)?)\.nupkg$')
  
    (Get-ChildItem -Path $packageDirectory -Filter "$packageName.*.nupkg") | 
        ForEach-Object {
            $match = $reg.Match($_.Name)
            if ($match.Success -and $match.Groups[1].Value -eq $packageName) {
                New-Object PSObject -Property @{
                    PackageName = $match.Groups[1].Value
                    Version = [Version]$match.Groups[2].Value
                    Path = $_.FullName
                }
            }
        } |
        Sort-Object Version -Descending |
        Select-Object -First 1
}

#Remove previous offline common packages and previously internalized packages
#Get-ChildItem -Path $repoDir -Exclude *.ps1 | Remove-Item –recurse -Force
# Clear temp directory
if (Test-Path $tempDir) {
    Get-ChildItem -Path $tempDir | Remove-Item –recurse -Force
} else {
    New-Item -ItemType Directory -Force -Path $tempDir
}

$commonDirectory = Get-SourceDirectory $commonSource
foreach ($package in $packages) 
{
	if ($($package.Enable))
	{
        $package.Status = "Not started"
        if ($($package.Source) -ne $commonSource)
        {
            #Internalizing licence project leads to recursive logic issue. All internal packages should be copied, not internalized.
            $communityVersion = Get-LatestVersionNumber -repository $($package.Source) -packageName $($package.Name)
            $commonVersion = Get-LatestVersionNumber -repository $commonSource -packageName $($package.Name)
            if (([version]$communityVersion -gt [version]$commonVersion) -or $($package.Force)) {
                Write-Output "Common version of $($package.Name) is out-of-date ($commonVersion). Updating to $communityVersion"
                choco download $($package.Name) --source=$($package.Source) --outdir=$outDir --internalize --no-progress
                $ChocoSuccess = $?
                if($ChocoSuccess)
                {
                    $package.Status = "Internalized"
                    Get-ChildItem -Path $outDir -Filter *.nupkg | ForEach-Object { 
                        Write-Output ("Pushing " + $_.FullName + " to source " + $commonDirectory)
                        choco push $_.FullName --source $commonDirectory
                        $ChocoSuccess = $?
                        if($ChocoSuccess)
                        {
                            $package.Status = "Pushed to $commonDirectory"
                        }
                        else {
                            Write-Output "Push to $commonDirectory failed"
                            $package.Status = "Push to $commonDirectory failed"
                            $package.Failed = 1
                            return
                        }
                        Remove-Item $($_.FullName)
                        $package.Status = "Pushed to $commonDirectory and removed from $outDir"
                    }
                }
                else {
                    $package.Status = "internalize failed"
                    $package.Failed = 1
                }
            }
            else {
                Write-Output "Common version of $($package.Name) is already up-to-date."
                $package.Status = "No internalize required"
            }
        }
        
	}
    else {
        $package.Status = "Not enabled"
    }
}
#reset the out dir, ready for the Common->Offline step
Get-ChildItem $outDir | Remove-Item –recurse -Force
foreach ($package in $packages) 
{
	if (($($package.Enable) -eq 1) -and ($($package.Failed) -ne 1))
    {
        #package now exists in common repo either due to internalization, explicit specification, or the fact it was already up-to-date
        #download from common repository to the staging dir WITHOUT internalizing. It was either done before, or doesn't need to be done.
        #Using choco download is important, because it follows dependency tree
        choco download $($package.Name) --source=$commonSource --outdir=$outDir --no-progress
        $ChocoSuccess = $?
        if($ChocoSuccess)
        {
            $package.Status = "Downloaded from $commonSource"
        }
        else {
            $package.Status = "Download from $commonSource failed"
            $package.Failed = 1
        }
    }
}

#Before deleting .nupkg files from $repoDir, check if $outDir has .nupkg files
$outDirNupkgCount = (Get-ChildItem -Path $outDir -Filter *.nupkg).Count
$repoDirNupkgCount = (Get-ChildItem -Path $repoDir -Filter *.nupkg).Count

if ($outDirNupkgCount -gt 0 -and $repoDirNupkgCount -gt 0) {
    #Move the nupkgs to temp
    Get-ChildItem -Path $repoDir -Filter *.nupkg | ForEach-Object {
        Move-Item $_.FullName -Destination $tempDir -Force
    }
    Write-Output "Old .nupkg files moved to $tempDir for backup."
} else {
    Write-Output "Not moving .nupkg files from $repoDir."
}


Get-ChildItem -Path $repoDir -Filter *.nupkg | Remove-Item –recurse -Force #Clear out old nupkgs
#Now push every downloaded nupkg to offline common directory. This method makes sense, because there are many duplicated dependencies
Get-ChildItem -Path $outDir -Filter *.nupkg | ForEach-Object { 
    Write-Output "Pushing $_.FullName to source $commonDirectory"
    #choco push $_.FullName --source $repoDir
    Move-Item $_.FullName -Destination $tempDir
    $ChocoSuccess = $?
    if($ChocoSuccess)
    {
        Write-Output "Pushed $($_.Name) to source $commonDirectory"
    }
    else {
        Write-Output ("Failed to push to source")
    }
}

# After moving all packages to temp directory, now move them to the repo directory.
Get-ChildItem -Path $tempDir -Filter *.nupkg | ForEach-Object {
    Move-Item $_.FullName -Destination $repoDir
}

#Remove-Item $tempDir -Recurse -Force
# check if the packages are processed 
$allProcessedSuccessfully = $packages | Where-Object { $_.Failed -eq 1 } | Measure-Object
if (-not $allProcessedSuccessfully.Count) {
    Remove-Item $tempDir -Recurse -Force
    Write-Output "All packages processed successfully. Cleared the temp directory."
} else {
    Write-Output "Some packages failed to process. Check the $tempDir ."
}


$(foreach ($package in $packages) {
	Write-Output "$($package.Name) $($package.Status)"
})
