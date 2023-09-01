; FremantleInstaller.nsi

RequestExecutionLevel admin

!include MUI.nsh


!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Installer.\r\nClick Next to continue."
!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."


!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH


!insertmacro MUI_LANGUAGE "English"

!define CONFIG_DIR "default_config"

Outfile "FremantleSoftwareInstaller.exe"
InstallDir "$PROGRAMFILES\Fremantle\Installer"
Caption "Fremantle Software Installer"
Icon "fremantle.ico"
BrandingText "Fremantle Software"

; Pre-installation section
Section "PreInstall" SEC00
  SetOutPath $INSTDIR
  File /r source\*.*
SectionEnd

; Main installation section
Section "MainSection" SEC01
  SectionIn RO
  ExecWait 'powershell.exe -inputformat none  -ExecutionPolicy Bypass -File "$INSTDIR\InstallChocolatey.ps1" -InstDir "$INSTDIR"'
  MessageBox MB_OK "Fremantle Software Successfully installed to Chocolatey folder"
SectionEnd
