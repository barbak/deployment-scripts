$createDnepy27= if ($env:PTN_DNEPY27) { $true } else { $false }
$createDnepy36= if ($env:PTN_DNEPY37) { $true } else { $false }
$installNimp= if ($env:PTN_GET_NIMP) { $true } else { $false }
$installPySide2= if ($env:PTN_GET_PYSIDE2) { $true } else { $false }

$deployAera= if ($env:PTN_DEPLOY_AERA) { $env:PTN_DEPLOY_AERA } else { "D:\dne_seeds\DeployAera" }
$installerName="$deployAera\mc3-install.exe"
$condaDir="$deployAera\miniconda3"

function main {
    New-Item -itemType File -Force $deployAera\dne_install_miniconda3.lock >> $null
    check-requirements
    update-conda-base
    install-packages-base
    upgrade-pip-base
    if ($installPySide2) {
        install-pyside2
    }
    install-nimp-base
    Remove-Item -Force $deployAera\dne_install_miniconda3.lock
}

function check-requirements {

    if (-not(Test-Path $installerName)) {
        Write-Output "Downloading archive 'https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe' in '$installerName'."
        Start-BitsTransfer `
            -Source https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe `
            -Destination $installerName
        Write-Output "Done."
        # https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip
    } else {
        Write-Output "Installer already downloaded in '$installerName'"
    }

    if (-not(Test-Path $condaDir)) {
        Write-Output "Starting installer in silent mode ..."
        Start-Process -Wait `
            -FilePath $installerName `
            -Args "/S",
            "/InstallationType=0",
            "/RegisterPython=0",
            "/AddToPath=0",
            "/NoRegistry=1",
            "/D=$condaDir"
        Write-Output "Done."
    } else {
        Write-Output "'$condaDir' path exists, skipping installer."
    }
}

function update-conda-base {

    Write-Output "Updating conda in base env ..."
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda update conda -y"
    Write-Output "Done."
}

function install-packages-base {

    Write-Output "Installing git, pip, ipython in base env ..."
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda install git pip ipython -y"
    Write-Output "Done."
}

function upgrade-pip-base {

    Write-Output "Upgrading pip in base env ..."
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "python -m pip install --upgrade pip"
    Write-Output "Done."
}

function install-pyside2 {

    Write-Output "Installingf PySIde 2 in base env ..."
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda install -y",
            "-c conda-forge",
            "PySide2"
    Write-Output "Done."
}

function install-nimp-base {

    Write-Output "Installing nimp in the base interpreter ..."
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "pip install --upgrade",
            "git+https://github.com/dontnod/nimp.git",
            "git+https://github.com/dontnod/bittornado.git",
            "requests"
    Write-Output "Done."
}

# if ($createDnepy27) {
#     Write-Output "Creating dnepy27 env ..."
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
#     Write-Output "Done."
# } else {
#     Write-Output "Skipping dnepy27 creation."
# }

# if ($createDnepy36) {
#     Write-Output "Creating dnepy36 env ..."
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
#     Write-Output "Done."

#     if ($installNimp) {
#         Write-Output "Updating nimp in dnepy36 env ..."
#         Start-Process -Wait -FilePath CMD `
#         -ArgumentList "/C",
#         "$condaDir\Scripts\activate.bat dnepy36 &",
#         "python -m pip install --upgrade",
#         "git+https://github.com/dontnod/nimp.git", 
#         "git+https://github.com/dontnod/bittornado.git",
#         "requests"
#         Write-Output "Done."
#     }
# } else {
#     Write-Output "Skipping dnepy36 creation."
# }

main # <- Entry point

Start-Sleep 3
Pause
