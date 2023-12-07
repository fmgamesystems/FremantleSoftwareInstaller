# SetNSISPath.ps1
# Sets the MAKENSIS_PATH environment variable to the path of the makensis.exe 


# Default path for makensis.exe. Update this path to your NSIS install location.
param(
    [string]$NsisExecutablePath = "C:\Program Files (x86)\NSIS\makensis.exe"
)

# Verify if the path to makensis.exe is correct
function Test-NsisPath {
    param(
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        throw "The path provided for makensis.exe does not exist: $Path"
    }

    if (-not $Path.ToLower().EndsWith("makensis.exe")) {
        throw "The path provided does not contain the required makensis.exe"
    }
}

# Set the system environment variable
try {
    Test-NsisPath -Path $NsisExecutablePath
    [Environment]::SetEnvironmentVariable('MAKENSIS_PATH', $NsisExecutablePath, [EnvironmentVariableTarget]::Machine)
    Write-Host "The MAKENSIS_PATH environment variable has been set to: $NsisExecutablePath"
} catch {
    Write-Error $_.Exception.Message
    Write-Host "Please provide the correct path to the makensis.exe if the default path is not correct."
    exit 1
}

Write-Host "Environment variable updated successfully:"
Write-Host "- Please close any windows and reopen them to use the new MAKENSIS_PATH setting."
Write-Host "- A system restart is recommended for the changes to take full effect"


