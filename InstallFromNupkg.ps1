#Set-ExecutionPolicy Unrestricted

param(
  [string]$NupkgPath,
  [string]$Destination
)

# Debugging information
Write-Host "Debug: NupkgPath is $NupkgPath"
Write-Host "Debug: Destination raw value is $Destination"

$Destination = $Destination.Replace('"', '')

# Destination debug value
Write-Host "Debug: Destination sanitized value is $Destination"

if (-Not (Test-Path $NupkgPath)) {
    Write-Host "Debug: $NupkgPath does not exist."
    exit 1
}

# Check for null or empty parameters
if ([string]::IsNullOrEmpty($NupkgPath) -or [string]::IsNullOrEmpty($Destination)) {
    Write-Host "Either NupkgPath or Destination is not provided. Exiting..."
    exit 1
}

# Make sure the destination directory exists
if (-Not (Test-Path $Destination)) {
    New-Item -Path $Destination -ItemType Directory
}

# Unpack the .nupkg to a temporary folder
$TempDir = "$env:TEMP\NupkgTemp"
if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Recurse
}
New-Item -Path $TempDir -ItemType Directory
Copy-Item -Path $NupkgPath -Destination $TempDir

Rename-Item -Path "$TempDir\$(Split-Path -Leaf $NupkgPath)" -NewName "package.zip"

# Expand the archive
Expand-Archive -Path "$TempDir\package.zip" -DestinationPath "$TempDir\extracted"

# execute chocolateyInstall.ps1 script

# Start the file move operation
# Iterates over each file and folder in the extracted directory.
$sourceItems = Get-ChildItem -Path "$TempDir\extracted"
foreach ($item in $sourceItems) {
    $destPath = Join-Path -Path $Destination -ChildPath $item.Name
    if (-Not (Test-Path $destPath)) {
        Move-Item -Path $item.FullName -Destination $destPath
    } else {
        # Checks if the item already exists in the destination directory.
        Write-Host "Skipping existing item: $destPath"
    }
}


# Clean up temporary directory
Remove-Item -Path $TempDir -Force -Recurse

Write-Host "Installation complete. Files have been extracted to $Destination."

# Pause and show output to the user
Read-Host -Prompt "Press Enter to exit"
