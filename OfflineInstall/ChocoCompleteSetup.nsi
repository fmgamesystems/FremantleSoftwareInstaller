; ChocoCompleteSetup
RequestExecutionLevel admin ; Require admin rights

; Include headers
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!insertmacro GetFileName
!insertmacro GetParent
!define VERSION "0.1.1"

; Pages
!define MUI_WELCOMEPAGE_TITLE "Fremantle Game Systems Software Installer"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Installer. Click Install to continue."

!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."
!define MUI_FINISHPAGE_TITLE "Installation Complete"
!define MUI_FINISHPAGE_TEXT "Fremantle Software has been successfully installed."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Output and other settings
Outfile "FremantleInstaller.exe"
Caption "Fremantle Software Installer v${VERSION}"
VIProductVersion "${VERSION}"
Icon "../fremantle.ico"
Name "Fremantle Software Installer"
BrandingText "Fremantle Game Systems Software"

Section "MainSection" SEC01
  ; Cleanup previous installations
  RMDir /r "$TEMP\FremantleInstaller"

  
  SetOutPath "$TEMP\FremantleInstaller"

  ; File paths
  File "install.ps1"
  File "PrepareOfflineInstall.ps1"

  ; Switch to the Common directory inside the installer's temp directory
  SetOutPath "$TEMP\FremantleInstaller\Common"
  File "Common\chocolatey.2.2.2.nupkg"
  File "Common\chocolatey.extension.6.1.0.nupkg"
  File "Common\chocolatey-license.2024.05.11.nupkg"

  ; PowerShell script for Chocolatey installation
  ExecWait 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "$TEMP\FremantleInstaller\install.ps1"'
  ${If} ${Errors}
    MessageBox MB_ICONSTOP|MB_OK "An error occurred during Chocolatey installation."
    RMDir /r "$TEMP\FremantleInstaller"
    Abort
  ${EndIf}

  MessageBox MB_OK "Chocolatey install complete: now installing packages..."

  
  ExecWait 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "$TEMP\FremantleInstaller\PrepareOfflineInstall.ps1"'
  ${If} ${Errors}
    MessageBox MB_ICONSTOP|MB_OK "An error occurred during the package installation."
    RMDir /r "$TEMP\FremantleInstaller"
    Abort
  ${EndIf}

  MessageBox MB_OK "Installation complete"

  ; Cleanup after installation
  RMDir /r "$TEMP\FremantleInstaller"
SectionEnd
