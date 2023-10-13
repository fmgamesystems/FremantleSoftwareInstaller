
$commonRepoPath = Join-Path $PSScriptRoot 'Common'
$localChocolateyPackageFilePath = Join-Path $commonRepoPath 'chocolatey.2.2.2.nupkg'
$ChocoInstallPath = "$($env:ProgramData)\Fremantle\PackageManager\bin"
$env:ChocolateyInstall = "$($env:ProgramData)\Fremantle\PackageManager"
#$env:ChocolateyEnvironmentDebug = 'true'



# === ENVIRONMENT VARIABLES YOU CAN SET ===
# Prior to running this script, in a PowerShell session, you can set the
# following environment variables and it will affect the output

# - $env:ChocolateyEnvironmentDebug = 'true' # see output
# - $env:chocolateyIgnoreProxy = 'true' # ignore proxy
# - $env:chocolateyProxyLocation = '' # explicit proxy
# - $env:chocolateyProxyUser = '' # explicit proxy user name (optional)
# - $env:chocolateyProxyPassword = '' # explicit proxy password (optional)

# === NO NEED TO EDIT ANYTHING BELOW THIS LINE ===
# Ensure we can run everything
Set-ExecutionPolicy Bypass -Scope Process -Force;

# Reroute TEMP to a local location
#New-Item $env:ALLUSERSPROFILE\choco-cache -ItemType Directory -Force
#$env:TEMP = "$env:ALLUSERSPROFILE\choco-cache"


$ErrorActionPreference = 'Continue'



$env:Path += ";$ChocoInstallPath"
$DebugPreference = 'Continue'; 

# PowerShell v2/3 caches the output stream. Then it throws errors due
# to the FileStream not being what is expected. Fixes "The OS handle's
# position is not what FileStream expected. Do not use a handle
# simultaneously in one FileStream and in Win32 code or another
# FileStream."
function Update-PowerShellOutputRedirectionBug {
  $poshMajorVerion = $PSVersionTable.PSVersion.Major

  if ($poshMajorVerion -lt 4) {
    try{
      # http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/ plus comments
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
      $objectRef = $host.GetType().GetField("externalHostRef", $bindingFlags).GetValue($host)
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
      $consoleHost = $objectRef.GetType().GetProperty("Value", $bindingFlags).GetValue($objectRef, @())
      [void] $consoleHost.GetType().GetProperty("IsStandardOutputRedirected", $bindingFlags).GetValue($consoleHost, @())
      $bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
      $field = $consoleHost.GetType().GetField("standardOutputWriter", $bindingFlags)
      $field.SetValue($consoleHost, [Console]::Out)
      [void] $consoleHost.GetType().GetProperty("IsStandardErrorRedirected", $bindingFlags).GetValue($consoleHost, @())
      $field2 = $consoleHost.GetType().GetField("standardErrorWriter", $bindingFlags)
      $field2.SetValue($consoleHost, [Console]::Error)
    } catch {
      Write-Output 'Unable to apply redirection fix.'
    }
  }

  Write-Host "Finished powershell redirection fix"
}

Update-PowerShellOutputRedirectionBug

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

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        try {
        $shellApplication = new-object -com shell.application
        $zipPackage = $shellApplication.NameSpace($file)
        $destinationFolder = $shellApplication.NameSpace($tempDir)
        $destinationFolder.CopyHere($zipPackage.Items(),0x10)
        } catch {
        throw "Unable to unzip package using built-in compression. Set `$env:chocolateyUseWindowsCompression = 'false' and call install again to use 7zip to unzip. Error: `n $_"
        }
    } else {
        Expand-Archive -Path "$file" -DestinationPath "$tempDir" -Force
    }

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


Write-Host "Checking if Chocolatey is installed at $ChocoInstallPath..."

if (Test-Path $ChocoInstallPath) {
  Write-Host "Chocolatey install is found at $ChocoInstallPath."
  # Optionally, you can uninstall Chocolatey here before proceeding to the reinstall
  Write-Host "Continuing with other packages without reinstalling Chocolatey..."
} else {
  Write-Host "Chocolatey not detected, beginning installation..."
  # Install Chocolatey
  Install-ChocolateyFromPackage $localChocolateyPackageFilePath
}

# Continue with other packages after finding Chocolatey's installation status
choco source add -n=common $commonRepoPath
choco source disable --name chocolatey
choco install chocolatey-license --pre --source="'common'" -y
choco install chocolatey.extension --source="'common'" -y
choco source disable --name chocolatey.licensed
choco install chocolateygui.extension --source="'common'" -y
choco install vscode --source="'common'" -y
choco install powershell-core --source="'common'" -y

Write-Host "Installation completed."