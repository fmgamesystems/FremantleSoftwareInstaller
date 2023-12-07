# Fremantle Software Installer

This repository contains the Fremantle Software Installer, a Windows installer using **NSIS**. 

## Overview

The Fremantle Software Installer is optimized for situations where installation packages need to be locally available, such as in environments without internet access.


## Setup and Build Process

### Setting Up the Environment


NSIS: Download the latest beta release of NSIS from [here](https://sourceforge.net/projects/nsis/).

Powershell: Download the latest release of Powershell from [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4).

Before building the installer, set up the environment by specifying the path to the `makensis.exe` file required by NSIS.

#### SetNSISPath.ps1 Script

- **Purpose**: Sets the `MAKENSIS_PATH` environment variable to the path of the `makensis.exe` file.
- **Setup**: Run `SetNSISPath.ps1` in PowerShell with administrative privileges. It defaults to a preset NSIS directory. This script only needs to be run once unless the location of `makensis.exe` changes.

### Building the Installer

After setting up the environment, use the `BuildInstaller.ps1` to compile the NSIS script into the installer.

#### BuildInstaller.ps1 Script

- **Purpose**: Completes the building of NSIS installers from the provided `.nsi` script.
- **Prerequisites**: The `MAKENSIS_PATH` environment variable should be set correctly. You can check and confirm the path by opening up a command line window and providing the command `echo %MAKENSIS_PATH` which will provide the current path for NSIS.  
- **Usage**: Run `BuildInstaller.ps1` from the same directory where the `.nsi` script is located to build the installer for different configurations.



## Installation Process

1. **Download the Installer**: After building, locate the `FremantleSoftwareInstaller.exe`.

2. **Launch**: Run the installer as admin.

3. **Finalize Installation**: Follow the on-screen instructions to complete the installation.


