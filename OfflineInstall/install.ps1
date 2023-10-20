#Requires -Version 5.0
#This file requires a BOM otherwise it won't work in "Windows Powershell"
$host.UI.RawUI.ForegroundColor = 'Black'
$host.UI.RawUI.BackgroundColor = 'White'
Write-Output ' 
▒░
▒▓██████████▓                                                 ▒▓░ ▓
  ░▓                                                   ▓     ▒▓  ▓▒
  █░                                               ▓███▓▓▓▓▓▓▓▒▒▓▒
 ░▓  ░▒░        ░░               ░                   ░▓     ▓ ▒▓     ░
▒██▓▒░ ▒▒ ░▓█▓▒▓▒ ▒▒   ▓▓ ░▓█▒  ▓▓░▓░  ▒▓▓▒▓▓ ░ ▒▓▒▓  ▒▒    ░▓      ▓░ ▓░     ░
▒▓    ▓▓▓░   ▓░░░  ▒▓▒▒▓▓░ ░▓░▓░  ▒▒ ▓▒  ▓░ ▓▓▓░  ▓░ ▓    ▒█▓░    ▓▒▓▓    ▒▓▓
▓     ▓▒     ▒███▓▒   ▓▒    ▒▓     ▓ ▒█▓░░░ ▓▓    ░░ ▓▒▒▓▓  ░████▓▒▓████▓▒
'
$host.UI.RawUI.ForegroundColor = 'White'
$host.UI.RawUI.BackgroundColor = 'Black'
Write-Output '
~~~~~~Chocolatey offline install script~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~Hamish Barjonas 2023-10-12~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~ Expected directory layout:                                                  ~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~   install.ps1                | This file                                    ~~
~~    -Common                   | The mandatory repository                     ~~
~~     - chocolatey.n.n.n.nupkg | The latest version of the chocolatey package ~~
~~    -Repository1              | First optional repository                    ~~
~~    ...                       |                                              ~~
~~    -Repositoryn              | Last optional repository                     ~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
'

$commonSource = 'Common'
$commonRepoPath = Join-Path $PSScriptRoot $commonSource
$ChocoInstallPath = "$($env:ProgramData)\Fremantle\PackageManager\bin"
$env:ChocolateyInstall = "$($env:ProgramData)\Fremantle\PackageManager"

Set-ExecutionPolicy Bypass -Scope Process -Force;

if (!(Test-Path $commonRepoPath))
{
  Write-Output "Expected to find a directory at $commonRepoPath"
  return;
}

# Reroute TEMP to a local location
New-Item $env:ALLUSERSPROFILE\choco-cache -ItemType Directory -Force
$env:TEMP = "$env:ALLUSERSPROFILE\choco-cache"

$env:Path += ";$ChocoInstallPath"
$DebugPreference = 'Continue';

function Get-LatestPackage {
  param (
      $PackageDirectory,
      $PackageName 
  )
  #Hand crafted by HB, 2023-10-11
  $reg = [Regex]::new('^(.*?)\.((?:\.?[0-9]+){3,}(?:[-a-z]+)?)\.nupkg$')

  (Get-ChildItem -Path $PackageDirectory -Filter "$PackageName.*.nupkg") | 
      ForEach-Object {
          $match = $reg.Match($_.Name)
          if ($match.Success -and $match.Groups[1].Value -eq $PackageName) {
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

function Get-UninstalledNugetPackages {
  param (
      $PackageDirectory
  )
  #Hand crafted by HB, 2023-10-11
  $installed = & choco list --idonly | ForEach-Object {
      $_
  }
  $installed = $installed[1..($installed.Length - 2)]

  $reg = [Regex]::new('^(.*?)\.((?:\.?[0-9]+){3,}(?:[-a-z]+)?)\.nupkg$')
  (Get-ChildItem -Path $PackageDirectory -Filter "*.nupkg") | 
      ForEach-Object {
          $match = $reg.Match($_.Name)
          if ($match.Success) {
              New-Object String $match.Groups[1].Value
          }
      } |
      Get-Unique -AsString |
      Where-Object { $_ -notin $installed }
}

function Install-ChocolateyFromPackage {
param (
  [string]$chocolateyPackageFilePath = ''
)

  if ($chocolateyPackageFilePath -eq $null -or $chocolateyPackageFilePath -eq '') {
    throw "You must specify a local package to run the local install."
  }

  if (!(Test-Path($chocolateyPackageFilePath))) {
    throw "No file exists at $chocolateyPackageFilePath"
  }

  $chocTempDir = Join-Path $env:TEMP "chocolatey"
  $tempDir = Join-Path $chocTempDir "chocInstall"
  if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
  $file = Join-Path $tempDir "chocolatey.zip"
  Copy-Item $chocolateyPackageFilePath $file -Force

  # unzip the package
  Write-Output "Extracting $file to $tempDir..."
  Expand-Archive -Path "$file" -DestinationPath "$tempDir" -Force

  # Call Chocolatey install
  Write-Output 'Installing chocolatey on this machine'
  $toolsFolder = Join-Path $tempDir "tools"
  $chocInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"

  & $chocInstallPS1

  Write-Output 'Ensuring chocolatey commands are on the path'
  $chocInstallVariableName = 'ChocolateyInstall'
  $chocoPath = [Environment]::GetEnvironmentVariable($chocInstallVariableName)
  if ($chocoPath -eq $null -or $chocoPath -eq '') {
    $chocoPath = "$($env:ProgramData)\Fremantle\PackageManager"
  }

  $chocoExePath = Join-Path $chocoPath 'bin'

  if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
  }

  Write-Output 'Ensuring chocolatey.nupkg is in the lib folder'
  $chocoPkgDir = Join-Path $chocoPath 'lib\chocolatey'
  $nupkg = Join-Path $chocoPkgDir 'chocolatey.nupkg'
  if (!(Test-Path $nupkg)) {
    Write-Output 'Copying chocolatey.nupkg is in the lib folder'
    if (![System.IO.Directory]::Exists($chocoPkgDir)) { [System.IO.Directory]::CreateDirectory($chocoPkgDir); }
    Copy-Item "$file" "$nupkg" -Force -ErrorAction SilentlyContinue
  }
}


# Idempotence - do not install Chocolatey if it is already installed
if ((Test-Path $ChocoInstallPath))
{
  Write-Output 'Detected that Chocolatey was already installed so skipping installation part'
}
else
{
  # Install Chocolatey 
  $localChocolateyPackageFilePath = (Get-LatestPackage -PackageDirectory $commonRepoPath -PackageName 'chocolatey').Path
  Install-ChocolateyFromPackage $localChocolateyPackageFilePath 
}
choco source disable --name chocolatey

# Add all sibling directories as sources
Get-ChildItem -Path $PSScriptRoot -Force -Directory | 
    Foreach-Object { choco source add -n="$($_.Name)" -s="""$($_.FullName)""" }

# Install licensing essentials
choco install chocolatey-license --pre --source="$commonSource" -y
choco install chocolatey.extension  --source="$commonSource" -y
choco source disable --name chocolatey.licensed

# Install all packages in Common
$allCommonPackages = Get-UninstalledNugetPackages -PackageDirectory $commonRepoPath
choco install $allCommonPackages --source="$commonSource" -y
