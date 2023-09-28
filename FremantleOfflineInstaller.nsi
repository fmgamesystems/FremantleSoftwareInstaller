RequestExecutionLevel admin ; Require admin rights

; Define Macros first
!macro MUI_PAGE_CUSTOM FunctionName
    Page custom ${FunctionName}
!macroend

; Include necessary headers
!include "MUI2.nsh"
!include "ZipDLL.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!insertmacro GetFileName
!insertmacro GetParent

; Variables
Var NupkgFile
Var SelectedBuild
Var InstallDir


Function .onInit
  ; Initialize InstallDir with default path
  StrCpy $InstallDir "$PROGRAMFILES\Fremantle\Software"
  StrCpy $INSTDIR $InstallDir
FunctionEnd




; Page Customizations
!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Installer. Click Next to continue."
!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY


Function .onSelChange
  ; Update InstallDir when the user selects a new directory
  StrCpy $InstallDir $INSTDIR
  MessageBox MB_OK "onSelChange called. New InstallDir is: $InstallDir"
FunctionEnd

; onSelChange is called when the directory changes.
!define MUI_DIRECTORYPAGE_CUSTOMFUNCTION_PRE onSelChange


Function NupkgPicker
  nsDialogs::Create 1018
  Pop $0
  
  ; File picker for .nupkg
  ${NSD_CreateLabel} 0 0 100% 12u "Select a .nupkg file:"
  Pop $0

  ${NSD_CreateText} 0 13u 80% 12u ""
  Pop $NupkgFile

  ${NSD_CreateButton} 82% 13u 18% 12u "Browse"
  Pop $0
  
  ${NSD_OnClick} $0 PickNupkgFile
  nsDialogs::Show
FunctionEnd

Function PickNupkgFile
  nsDialogs::SelectFileDialog open "Nupkg Files (*.nupkg)|*.nupkg"
  Pop $R0

  ; If a file was chosen, populate textbox
  ${If} $R0 != error
    ${NSD_SetText} $NupkgFile $R0
    StrCpy $SelectedBuild $R0 
    ;MessageBox MB_OK "File picked: $R0"
    ;MessageBox MB_OK "SelectedBuild set to: $SelectedBuild"
  ${EndIf}
FunctionEnd






!insertmacro MUI_PAGE_CUSTOM NupkgPicker
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Output and other settings
Outfile "FremantleOfflineInstaller.exe"
# Default Install directory
InstallDir "$PROGRAMFILES\Fremantle\Software"
Caption "Fremantle Software Installer"
Icon "fremantle.ico"
BrandingText "Fremantle Software"

Section "MainSection" SEC01
  
  ; SectionIn RW

  ; Sync InstallDir to the user's final selection in case it was changed on the Directory page
  StrCpy $InstallDir $INSTDIR

  ;MessageBox MB_OK "Entering MainSection. SelectedBuild: $SelectedBuild"
  
  ; Isolate the variable
  StrCpy $1 $SelectedBuild
  ;MessageBox MB_OK "Isolated copy of SelectedBuild: $1"

  ; Re-validate the file exists
  IfFileExists $1 0 +2
    ;MessageBox MB_OK|MB_ICONEXCLAMATION "File $1 does exist!"
  
  ; Initialize InstallDir
  ;StrCpy $InstallDir "$PROGRAMFILES\Fremantle\Installer"
  MessageBox MB_OK "InstallDir set to: $InstallDir"

  ; Create the directory if it doesn't exist
  IfFileExists $InstallDir 0 +2
    CreateDirectory $InstallDir
  ;MessageBox MB_OK "Checking InstallDir: $InstallDir"

  ; Debug message box to display selected file
  MessageBox MB_OK "Selected file: $SelectedBuild"

  ; Prepare extraction directory, using $InstallDir this time
  SetOutPath $InstallDir
  ;MessageBox MB_OK "SetOutPath called with: $InstallDir"

  ; Check if output directory exists
  IfFileExists $InstallDir 0 +2
    CreateDirectory $InstallDir
  ;MessageBox MB_OK "Rechecking InstallDir: $InstallDir"

 
  ; Check extraction success
  ;${If} $R0 != "success"
  ;  MessageBox MB_ICONSTOP|MB_OK "Zip extraction failed with error $R0 for $SelectedBuild to $InstallDir"
 ;   Abort
 ; ${EndIf}

; Execute script using CMD to call PowerShell



ExecWait 'cmd.exe /K powershell.exe -NoExit -inputformat none -ExecutionPolicy Bypass -File "$EXEDIR\InstallFromNupkg.ps1" -NupkgPath "$SelectedBuild" -Destination "$InstallDir"'
  

  MessageBox MB_OK "Fremantle Software Successfully installed to $InstallDir"
  
SectionEnd
