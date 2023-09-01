# InstallChocolatey.ps1


param (
    [string]$InstDir
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
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    else {
        Write-Log "Chocolatey is already installed."
    }

    # Check if the package is already installed and uninstall it
    if (choco list --local-only -e Fremantle.Familyfeud.control) {
        Write-Log "Uninstalling existing Fremantle FamilyFeud Control..."
        choco uninstall Fremantle.Familyfeud.control -y
        Write-Log "Successfully uninstalled existing package."
    }

    Write-Log "Installing Fremantle FamilyFeud Control..."

    # Install the package
    choco install Fremantle.Familyfeud.control -y
    Write-Log "Successfully installed Fremantle FamilyFeud Control."



    # Set environment variables

    Exit 0
} catch {
    Write-Log "An error occurred: $_"

    Exit 1
}
