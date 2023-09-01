# ReadConfig.ps1

$configDir = [Environment]::GetEnvironmentVariable("CONFIG_DIR", [System.EnvironmentVariableTarget]::Machine)

# Read and apply config settings
Write-Host "Reading config from $configDir"