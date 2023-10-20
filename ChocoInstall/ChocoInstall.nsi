RequestExecutionLevel admin ; Require admin rights


; Include headers
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!insertmacro GetFileName
!insertmacro GetParent
!define VERSION "0.1.0"




; Pages
!define MUI_WELCOMEPAGE_TITLE "Fremantle Game Systems Software Installer"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Installer. Click Install to continue."

!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."
!define MUI_FINISHPAGE_TITLE "Installation Complete"
!define MUI_FINISHPAGE_TEXT "Fremantle Software has been successfully installed."

; Pages
!insertmacro MUI_PAGE_WELCOME
;!insertmacro MUI_PAGE_DIRECTORY






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
  
  ; SectionIn RW
  ; Cleanup previous installations
  RMDir /r "$TEMP\FremantleInstaller"

  ; Set the installation directory
  SetOutPath "$TEMP\FremantleInstaller"

  ; File paths
  File "install.ps1"
  ; Switch to the Common directory inside the installer's temp directory
  SetOutPath "$TEMP\FremantleInstaller\Common" 
  File "Common\chocolatey.2.2.2.nupkg"

  ; Go back to main directory and run the PowerShell script
  SetOutPath "$TEMP\FremantleInstaller"
  ExecWait 'powershell.exe -NoExit -ExecutionPolicy Bypass -NoProfile -File "$TEMP\FremantleInstaller\install.ps1"'

  MessageBox MB_OK "Installation complete"
  
SectionEnd
