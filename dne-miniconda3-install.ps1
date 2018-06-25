<#
.SYNOPSIS
    Install Miniconda 3 on your system.

.DESCRIPTION
    Install Miniconda3 on your system in the deploy area by downloading the
    installer to installerName and executing it with some options.

.PARAMETER deployArea
    Specify where the target directory to install Miniconda is.

.PARAMETER installerName
    Fullpath where the installer should be or where it will be be downloaded.

.PARAMETER createDnePy27
    (Deactivated) Does the installer should create another conda env with python2.7.

.PARAMETER createDnePy36
    (Deactivated) Does the installer should create another conda env with python 3.6.

.PARAMETER installPyside2
    Does Pyside have to be installed (conda base and potentially dnepy36 if created).

.PARAMETER installNimp
    Does Nimp will be installed in base environment and addtional conda envs.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea,
    [Alias("in")]
    [string]$installerName="$deployArea\mc3-install.exe",
    [Alias("27")]
    [bool]$createDnepy27=$false,
    [Alias("36")]
    [bool]$createDnepy36=$false,
    [Alias("ps2")]
    [bool]$installPySide2=$false,
    [Alias("nimp")]
    [bool]$installNimp=$true
)

$condaDir = "$deployArea\miniconda3"
# $ProgressPreference='SilentlyContinue'

function Install-Miniconda3 {
    if (Test-Path $deployArea\dne_install_miniconda3.lock) {
        Write-Warning "Lock file already present. A previous installation has been started but have not finished successfully."
        $confirm = Read-Host -Prompt "Do you want to continue ? [Y/n] "
        if ($confirm -notIn "", "Y", "y") {
            Exit
        }
    }
    New-Item -itemType File -Force $deployArea\dne_install_miniconda3.lock >> $null
    # step 1
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -PercentComplete (100.0/6.0 * 1)
    check-requirements
    # step 2
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Update conda base env"  -PercentComplete (100.0/6.0 * 2)
    update-conda-base
    # step 3
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Install packages in conda base env"  -PercentComplete (100.0/6.0 * 3)
    install-packages-base
    # step 4
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Upgrade pip in conda base env"  -PercentComplete (100.0/6.0 * 4)
    upgrade-pip-base
    if ($installPySide2) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Install PySide2 conda base env"  -PercentComplete (100.0/6.0 * 5)
        # step 5
        install-pyside2
    }
    # step 6
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Install Nimp conda base env"  -PercentComplete (100.0/6.0 * 6)
    if ($installNimp) {
        install-nimp-base
    }
    Remove-Item -Force $deployArea\dne_install_miniconda3.lock
    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Completed
}

# internal functions
function check-requirements {

    if (-not(Test-Path $installerName)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe' in '$installerName'."
        Start-BitsTransfer `
            -Source https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe `
            -Destination $installerName
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip' in '$installerName'."
    } else {
        Write-Warning "Installer already downloaded in '$installerName'."
    }

    # Adding clink to have a pseudo readline behaviour ... IMOO, a must have.
    if (-not(Test-Path $deployArea/clink_0.4.9.zip)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip' in '$deployArea'."
        # Start-BitsTransfer `
        #     -Source https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip `
        #     -Destination $deployArea
        # Start-BitsTransfer has difficulties with redirections
        # see https://powershell.org/forums/topic/bits-transfer-with-github/ for details.
        BITSADMIN /TRANSFER "Downloading Clink ..." /DYNAMIC /DOWNLOAD /priority FOREGROUND `
            https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip `
            $deployArea\clink_0.4.9.zip
    } else {
        Write-Warning "Clink archive already downloaded in '$deployArea'."
    }

    if (-not(Test-Path $condaDir)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Starting installer in silent mode ..."
        Start-Process -Wait `
            -FilePath $installerName `
            -Args "/S",
            "/InstallationType=0",
            "/RegisterPython=0",
            "/AddToPath=0",
            "/NoRegistry=1",
            "/D=$condaDir"
    } else {
        Write-Warning "'$condaDir' path exists, skipping installer."
    }

    if (-not(Test-Path $deployArea\clink_0.4.9)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Unzipping clink archive ..."
        Expand-Archive -Path $deployArea\clink_0.4.9.zip -DestinationPath $deployArea
    } else {
        Write-Warning "'$deployArea\clink_0.4.9' path exists, skipping uncompress."
    }
}

function update-conda-base {

    Write-Host -NoNewline "Updating conda in base env ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda update conda -y"
    Write-Host "Done."
}

function install-packages-base {

    Write-Host -NoNewline "Installing git, pip, ipython in base env ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda install git pip ipython -y"
    Write-Host "Done."
}

function upgrade-pip-base {

    Write-Host -NoNewline "Upgrading pip in base env ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "python -m pip install --upgrade pip"
    Write-Host "Done."
}

function install-pyside2 {

    Write-Host -NoNewline "Installing PySide 2 in base env ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda install -y",
            "-c conda-forge",
            "PySide2"
    Write-Host "Done."
}

function install-nimp-base {

    Write-Host -NoNewline "Installing nimp in the base interpreter ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "pip install --upgrade",
            "git+https://github.com/dontnod/nimp.git",
            "git+https://github.com/dontnod/bittornado.git",
            "requests"
    Write-Host "Done."
}

# if ($createDnepy27) {
#     Write-Host -NoNewline "Creating dnepy27 env ... "
#     Start-Process -Wait -FilePath CMD `
#         -ArgumentList "/C",
#         "$condaDir\Scripts\activate.bat & ",
#         "conda create -n dnepy27 -y",
#             "-c conda-forge",
#             "python=2.7",
#             "ipython", "git"
#     if ($installPySide2) {
#         Start-Process -Wait -FilePath CMD `
#             -ArgumentList "/C",
#             "$condaDir\Scripts\activate.bat & ",
#             "conda install -n dnepy27 -y",
#                 "-c conda-forge",
#                 "PySide2"
#     }
#     Write-Host "Done."
# } else {
#     Write-Host "Skipping dnepy27 creation."
# }

# if ($createDnepy36) {
#     Write-Host -NoNewline "Creating dnepy36 env ... "
#         Start-Process -Wait -FilePath CMD `
#             -ArgumentList "/C",
#             "$condaDir\Scripts\activate.bat & ",
#             "conda create -n dnepy36 -y",
#                 "-c conda-forge",
#                 "python=3.6",
#                 "ipython", "git"
#     if ($installPySide2) {
#         Start-Process -Wait -FilePath CMD `
#             -ArgumentList "/C",
#             "$condaDir\Scripts\activate.bat & ",
#             "conda install -n dnepy36 -y",
#                 "-c conda-forge",
#                 "PySide2"
#     }
#     Write-Host "Done."

#     if ($installNimp) {
#         Write-Host -NoNewline "Updating nimp in dnepy36 env ... "
#         Start-Process -Wait -FilePath CMD `
#         -ArgumentList "/C",
#         "$condaDir\Scripts\activate.bat dnepy36 &",
#         "python -m pip install --upgrade",
#         "git+https://github.com/dontnod/nimp.git", 
#         "git+https://github.com/dontnod/bittornado.git",
#         "requests"
#         Write-Host "Done."
#     }
# } else {
#     Write-Host "Skipping dnepy36 creation."
# }

# Entry Point
Install-Miniconda3
