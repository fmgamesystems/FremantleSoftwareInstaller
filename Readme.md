# Fremantle Software Installer

This repository contains the Fremantle Software Installer, a Windows installer using **NSIS**. It allows for both online and offline installations of Fremantle Software packages.

## Overview

### Offline Installer
Designed for situations where installation packages (.nupkg files) need to be locally available. This could be particularly beneficial in scenarios without internet access. This method allows users to select and install specific software versions from a .nupkg file.

### Online Installer
Provides an automated experience, fetching and installing the most up-to-date Fremantle Software packages directly. The installer uses **Chocolatey** to fetch and deploy the latest software from online repositories. It connects with Fremantle's Dropbox and Box folders, ensuring users receive the latest updates.

## Features

- **Custom Directory Selection**: Offers the choice to specify the desired installation directory.
- **.Nupkg File Picker**: For offline installations, allowing users to select a specific .nupkg file.
- **Seamless Online Installation**: Connects to Fremantle's Dropbox and Box repositories for the latest software packages.
- **Automated Sync**: This process is enabled by the nupkg_list.txt file, which effectively maintains a real-time listing of all the latest available packages.



## Setup

1. **Download the Installer**: Obtain the `FremantleSoftwareInstaller.exe` tailored for online/offline use.
2. **Installation**: Launch the required installer as admin. 
3. **Directory Selection**: After the welcome page, choose your desired installation directory.
4. **Package Selection**:
   - **Offline**: Utilize the "Browse" function to select the .nupkg file.
   - **Online**: Let the installer fetch the latest Fremantle Software packages and select them.
5. **Finalize Installation**: Follow on-screen installer to complete the process.

### Offline Installations

- **Preparation**: Acquire the desired .nupkg file(s). You can also use the sample .nupkg files found in the `packages` folder of this repo.

### Online Installations

- **Chocolatey Requirement**: Ensure Chocolatey is pre-installed and configured on your system with access