$createDnepy27= if ($env:PTN_DNEPY27) { $true } else { $false }
$createDnepy36= if ($env:PTN_DNEPY37) { $true } else { $false }
$installNimp= if ($env:PTN_GET_NIMP) { $true } else { $false }
$installPySide2= if ($env:PTN_GET_PYSIDE2) { $true } else { $false }

$deployAera= if ($env:PTN_DEPLOY_AERA) { $env:PTN_DEPLOY_AERA } else { "D:\dne_seeds\DeployAera" }
$installerName="$deployAera\mc3-install.exe"
$condaDir="$deployAera\miniconda3"

# $ProgressPreference='SilentlyContinue'

function main {
    if (Test-Path $deployAera\dne_install_miniconda3.lock) {
        Write-Warning "Lock file already present. A previous installation has been started but have not finished successfully."
        $confirm = Read-Host -Prompt "Do you want to continue ? [Y/n] "
        if ($confirm -notIn "", "Y", "y") {
            Exit
        }
    }
    New-Item -itemType File -Force $deployAera\dne_install_miniconda3.lock >> $null
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
    install-nimp-base
    Remove-Item -Force $deployAera\dne_install_miniconda3.lock
}

function check-requirements {

    if (-not(Test-Path $installerName)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe' in '$installerName'."
        Start-BitsTransfer `
            -Source https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe `
            -Destination $installerName
        # https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip
    } else {
        Write-Warning "Installer already downloaded in '$installerName'"
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

    Write-Host -NoNewline "Installingf PySIde 2 in base env ... "
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

main # <- Entry point

Start-Sleep 3
Pause
