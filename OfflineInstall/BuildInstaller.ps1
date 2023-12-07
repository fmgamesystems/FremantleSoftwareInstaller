# BuildInstaller.ps1
# Script to build the NSIS installer using an environment variable for the makensis path

try {
    # Get the path of makensis.exe from the environment variable
    $nsisPath = [System.Environment]::GetEnvironmentVariable('MAKENSIS_PATH', 'Machine')
    Write-Host "makensis path: $nsisPath"

    if (-not $nsisPath) {
        throw "The environment variable MAKENSIS_PATH is not set. Please set it to the path of makensis.exe."
    }

    if (-not (Test-Path $nsisPath)) {
        throw "The path provided in the MAKENSIS_PATH environment variable does not exist: $nsisPath"
    }

    # Finds the NSIS script within the directory 
    $scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    $nsiScriptPath = Join-Path $scriptDirectory "ChocoCompleteSetup.nsi"
    Write-Host "NSIS script path: $nsiScriptPath"

    if (-not (Test-Path $nsiScriptPath)) {
        throw "The NSIS script file was not found: $nsiScriptPath"
    }

    # Execute the NSIS build process
    & $nsisPath $nsiScriptPath

    if ($LASTEXITCODE -eq 0) {
        Write-Host "NSIS build completed successfully."
    } else {
        throw "NSIS build failed with exit error $LASTEXITCODE."
    }
} catch {
    Write-Error $_.Exception.Message
} finally {
    Write-Host "Press any key to continue ..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
