# InternalizePackages.ps1

$configDir = [Environment]::GetEnvironmentVariable("CONFIG_DIR", [System.EnvironmentVariableTarget]::Machine)

# Internalize packages
Write-Host "Internalizing packages as per config in $configDir"
