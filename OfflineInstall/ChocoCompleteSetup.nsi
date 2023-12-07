; ChocoCompleteSetup
RequestExecutionLevel admin ; Require admin rights

; Include headers
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!insertmacro GetFileName
!insertmacro GetParent
!define VERSION "0.1.4"


; Pages
!define MUI_WELCOMEPAGE_TITLE "Fremantle Game Systems Software Installer"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Installer. Click Install to continue."

!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."
!define MUI_FINISHPAGE_TITLE "Installation Complete"
!define MUI_FINISHPAGE_TEXT "Fremantle Software has been successfully installed."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_PAGE_FINISH
Page instfiles "" InstFilesShow

; Progress Bar function
Function InstFilesShow
nsDialogs::Create 1018
Pop $0
${If} $0 == error
    Abort
${EndIf}
nsDialogs::CreateItem 65535
Pop $1
nsDialogs::CreateControl PROGRESS "ws_visible | ws_tabstop" 0 125u 100% -20u ""
Pop $2
nsDialogs::Show
StrCpy $3 $0
FunctionEnd

Function DestroyInstFilesDialog
    ${If} $3 != 0
        SendMessage $3 ${WM_CLOSE} 0 0
    ${EndIf}
FunctionEnd

Function IncludePackages
  ; include all the nupkg packages
  File /nonfatal /r "Common\*.nupkg"

FunctionEnd



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
  SendMessage $2 ${PBM_SETPOS} 10 0; 

  
  SetOutPath "$TEMP\FremantleInstaller"

  ; File paths
  File "install.ps1"
  File "PrepareOfflineInstall.ps1"

  SendMessage $2 ${PBM_SETPOS} 20 0;

  ; Switch to the Common directory inside the installer's temp directory
  SetOutPath "$TEMP\FremantleInstaller\Common"
  File "Common\chocolatey.2.2.2.nupkg"
  File "Common\chocolatey.extension.6.1.0.nupkg"
  File "Common\chocolatey-license.2024.05.11.nupkg"
  SendMessage $2 ${PBM_SETPOS} 30 0;

  ; Include all .nupkg files


  Call IncludePackages

  ; PowerShell script for Chocolatey installation
  ExecWait 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "$TEMP\FremantleInstaller\install.ps1"'
  ${If} ${Errors}
    MessageBox MB_ICONSTOP|MB_OK "An error occurred during Chocolatey installation."
    RMDir /r "$TEMP\FremantleInstaller"
    Abort
  ${EndIf}
  
  SendMessage $2 ${PBM_SETPOS} 70 0;

  MessageBox MB_OK "Chocolatey install complete: now preparing bundled packages..."
  
  ; Fix for handling files larger than 2gb, 
  ; Combine split files using 7-Zip
  ;nsExec::ExecToLog '"$TEMP\FremantleInstaller\7za.exe" x "$TEMP\FremantleInstaller\output_file_name.7z.001" -o"$TEMP\FremantleInstaller"'

  
  ;ExecWait 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "$TEMP\FremantleInstaller\PrepareOfflineInstall.ps1"'
  ${If} ${Errors}
    MessageBox MB_ICONSTOP|MB_OK "An error occurred during the package installation."
    RMDir /r "$TEMP\FremantleInstaller"
    Abort
  ${EndIf}

  SendMessage $2 ${PBM_SETPOS} 80 0;

  MessageBox MB_OK "Installation complete"

  SendMessage $2 ${PBM_SETPOS} 100 0;

  ; Cleanup after installation
  RMDir /r "$TEMP\FremantleInstaller"

  Call DestroyInstFilesDialog

SectionEnd
