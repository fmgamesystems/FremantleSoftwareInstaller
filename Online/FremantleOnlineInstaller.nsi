RequestExecutionLevel admin ; Require admin rights

; Include necessary NSIS headers
!include "MUI2.nsh"
!include "nsDialogs.nsh"
!include "StrFunc.nsh"
!include "FileFunc.nsh"


!ifndef NSD_LB_GetSelectionIndex
!define NSD_LB_GetSelectionIndex `!insertmacro __NSD_LB_GetSelectionIndex `
!macro __NSD_LB_GetSelectionIndex CONTROL VAR
    SendMessage ${CONTROL} ${LB_GETCURSEL} 0 0 ${VAR}
!macroend
!endif

; Variables
Var InstallDir
Var SelectedPackage
Var hListBox

Function .onInit
  ; Initialize InstallDir with default path
  StrCpy $InstallDir "$PROGRAMFILES\Fremantle\Software"
  StrCpy $SelectedPackage ""
FunctionEnd

; File name path extraction for packages 
Function GetFileNameFromPath
    Exch $R0
    Push $R1
    Push $R2
    ClearErrors
    StrCpy $R2 -1
    loop:
        IntOp $R2 $R2 + 1
        StrCpy $R1 $R0 1 $R2
        StrCmp $R1 "\" loop
    StrCpy $R0 $R0 "" $R2
    Pop $R2
    Pop $R1
FunctionEnd

; Page Customizations
!define MUI_INSTFILESPAGE_ENABLE_DETAILSBUTTON
!define MUI_WELCOMEPAGE_TEXT "Welcome to the Fremantle Software Online Installer. Click Next to continue."
!define MUI_INNERTEXT_INSTFILES "Please wait while Fremantle software is installed..."

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY

Function ChoosePackage
    nsDialogs::Create 1018
    Pop $0

    ; Create a list box to display the packages
    ${NSD_CreateListBox} 0 0 100% 100% ""
    Pop $hListBox

    ; Run findnupkg.bat to get the list of .nupkg files
    ExecWait 'cmd.exe /C "$EXEDIR\findnupkg.bat"'
    MessageBox MB_OK "Finished finding nupkg packages"

    ; Directly try to read the nupkg_list.txt and add its lines to the listbox
    ClearErrors
    FileOpen $2 "$EXEDIR\nupkg_list.txt" r
    
    loop_read:
        FileRead $2 $3
        IfErrors exit_loop_read
        ; Add the read line to the list box using $hListBox
        ${NSD_LB_AddString} $hListBox $3
        Goto loop_read

    exit_loop_read:
    FileClose $2

    
    nsDialogs::Show
FunctionEnd



Function ExtractPackageName
    Pop $R0 ; The full path from nupkg_list.txt
    
    ; Create a temporary batch file to execute the command with $R0
    FileOpen $1 "$TEMP\temp_batch.bat" w
    FileWrite $1 '@echo off$\r$\nfor %%A in ("$R0") do echo %%~nA > "$TEMP\temp.txt"'
    FileClose $1

    ; Execute the temporary batch file
    ExecWait 'cmd.exe /C "$TEMP\temp_batch.bat"'
    Delete "$TEMP\temp_batch.bat" ; Cleanup the temporary batch file
    
    ; Read the extracted package name
    FileOpen $4 "$TEMP\temp.txt" r
    FileRead $4 $R0
    FileClose $4
    Delete "$TEMP\temp.txt" ; Cleanup temp file

    Push $R0
FunctionEnd


Function StoreSelectedPackage
  ; Step 1: Get the index of the selected item
  SendMessage $hListBox ${LB_GETCURSEL} 0 0 $0
  
  ; Display the selected index for debugging
  ;MessageBox MB_OK "Selected Index: $0"
  
  ; Step 2: If an item is selected, retrieve its text
  ${If} $0 != LB_ERR

    ; Use cmd to retrieve the text from the file
    ExecWait 'cmd.exe /C more +$0 "$EXEDIR\nupkg_list.txt" | findstr /n "^" | find "1:" > "$TEMP\temp.txt"'
    
    ; Read the result into $SelectedPackage
    FileOpen $4 "$TEMP\temp.txt" r
    FileRead $4 $SelectedPackage
    FileClose $4
    Delete "$TEMP\temp.txt"
    ; Cleanup temp file

    ; Trim the line number from the result
    StrCpy $SelectedPackage $SelectedPackage -2

    ; Extract package name from the full path
    Push $SelectedPackage
    Call ExtractPackageName
    Pop $SelectedPackage

    ; Display the selected text for debugging
    MessageBox MB_OK "Selected Package: $SelectedPackage"
    
  ${Else}
    MessageBox MB_OK "No package was selected!"
  ${EndIf}
FunctionEnd



!define MUI_PAGE_HEADER_TEXT "Custom Installation Options"
!define MUI_PAGE_HEADER_SUBTEXT "Choose a package for installation."
Page custom ChoosePackage StoreSelectedPackage

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

; Output and other settings
Outfile "FremantleOnlineInstaller.exe"
InstallDir "$PROGRAMFILES\Fremantle\Software"
Caption "Fremantle Software Online Installer"
Icon "..\fremantle.ico"
BrandingText "Fremantle Software Online"


Section "MainSection" SEC01
  ; Debug message
  ;MessageBox MB_OK "Entering MainSection..."
  
  ; Check if a package was selected
  StrCmp $SelectedPackage "" NoPackageSelected

  

  ; Execute Chocolatey install for the selected package and redirect output to the log file
  ExecWait 'cmd.exe /C choco install $SelectedPackage -y'

  Sleep 3000


  MessageBox MB_OK "Fremantle Software package $SelectedPackage installed successfully to $InstallDir"
  Goto EndOfSection

  NoPackageSelected:
  MessageBox MB_OK "No package was selected!"
  
  EndOfSection:
SectionEnd

