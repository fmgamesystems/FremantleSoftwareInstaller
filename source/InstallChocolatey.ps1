# InstallChocolatey.ps1

param (
    [string]$InstDir,
    [string]$ConfigDir,
    [string]$SelectedBuild
)

# Log file location
$logFile = "$InstDir\InstallChocolateyLog.txt"

function Write-Log {
    param (
        [string]$message
    )
    Add-Content $logFile -value $message
}

try {
    # Check if Chocolatey is installed
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Chocolatey is not installed. Installing now..."
        
        # Installing from a local package for offline installation
        Start-Process -FilePath "choco.exe" -ArgumentList "install chocolatey -s $ConfigDir\chocolatey.nupkg"
    } else {
        Write-Log "Chocolatey is already installed."
    }

    # Further actions based on Selected Build
    if ($SelectedBuild -eq "Fremantle.FamilyFeud") {
        # Perform installation specific to the selected build
    }

    # Rest of the code remains unchanged

    Exit 0
} catch {
    Write-Log "An error occurred: $_"
    Exit 1
}
