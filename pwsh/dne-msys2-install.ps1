<#
.SYNOPSIS
    Install MSYS2 on your system.

.DESCRIPTION
    Install MSYS2 on your system in the deploy area by downloading the archive
    and deploying it in the deploy aera.

.PARAMETER deployArea
    Specify where the target directory to install MSYS2 is.

.NOTES
    This script will close all of your mintty processes and gpg-agent before
    starting. It is not intended to be used within mintty process.
    Originally, the script was intended to be used by Patoune.
    Last SUCCESSFUL TEST DATE: 2021 08 10
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea
)

$msysXzArchive="$deployArea\msys2-base-x86_64-20210725.tar.xz"
$msysTarName="$deployArea\msys2-base-x86_64-20210725.tar"
$shCmd="$deployArea\msys64\msys2.exe"

function Install-MSYS2 {
    if (Test-Path $deployArea\dne_install_msys2.lock) {
        Write-Warning "Lock file already present. A previous installation has been started but have not finished successfully."
        $confirm = Read-Host -Prompt "Do you want to continue ? [Y/n] "
        if ($confirm -notIn "", "Y", "y") {
            Exit
        }
    }
    New-Item -itemType File -Force $deployArea\dne_install_msys2.lock >> $null
    # step1
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Materialize dependencies" -PercentComplete (100.0/7.0 * 1)
    materialize-dependencies
    # step 2
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Extract archive" -PercentComplete (100.0/7.0 * 2)
    extract-archive
    # step 3
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Setup install" -PercentComplete (100.0/7.0 * 3)
    setup-install
    # step 4
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Update install" -PercentComplete (100.0/7.0 * 4)
    update-install
    # step 5 # No more additional packages, only an updated vanilla install.
    # Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Install packages" -PercentComplete (100.0/7.0 * 5)
    # install-packages
    # step 7
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Cleaning" -PercentComplete (100.0/7.0 * 7)
    clean-deps
    Remove-Item -Force $deployArea\dne_install_msys2.lock
    Write-Progress -Id 1 -Activity "Install MSYS2" -Completed
}

function materialize-dependencies {
    if (-not(Test-Path $msysXzArchive)) {
        Write-Host -NoNewline "Downloading archive 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20210725.tar.xz' in '$msysXzArchive'."
        Start-BitsTransfer `
            -Source http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20210725.tar.xz `
            -Destination $msysXzArchive

        Write-Host " Done."
    } else {
      Write-Host "Archive already downloaded in '$msysXzArchive'"
    }

    if (-not(Test-Path $env:temp\PSModules\PS7Zip)) {
        Write-Host -NoNewline "Dependency not found, downloading it ..."
        if (-not(Test-Path $env:temp\PSModules)) {
            New-Item -Path $env:temp\PSModules -ItemType "directory" > $null
        }
        Save-Module -Name PS7Zip -Path $env:temp\PSModules
        Write-Host " Done."
    }

    $pathToModule = "$env:temp\PSModules\PS7Zip\2.2.0\PS7Zip.psd1"
    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Write-Host -NoNewline "Importing dependency ..."
        Import-Module $pathToModule
        Write-Host " Done."
    }
}

function extract-archive {
    Write-Host -NoNewline "Extracting archives '$msysXzArchive' to '$deployArea' ..."
    Expand-7Zip -FullName $msysXzArchive -DestinationPath $deployArea
    Expand-7Zip -FullName $msysTarName -DestinationPath $deployArea -Remove
    Write-Host " Done."
}

function stop-all-mintty-and-gpg-agent {
    Write-Host -NoNewline `
        "Stopping all current mintty and gpg-agent processes ..."
    if (Get-Process -Name mintty -ErrorAction SilentlyContinue) {
        Stop-Process (Get-Process -Name mintty)
    }
    if (Get-Process -Name gpg-agent -ErrorAction SilentlyContinue) {
        Stop-Process (Get-Process -Name gpg-agent)
    }
    Write-Host " Done."
}

function setup-install {
    # Closing all processes before beginning the installation
    stop-all-mintty-and-gpg-agent
    # Need a first launch to make default files in order.
    Write-Host -NoNewline "Running msys2.exe for the first time ..."
    Start-Process -Wait -FilePath $shCmd -ArgumentList 'dash -c "taskkill //F //IM gpg-agent.exe //IM dirmngr.exe; exit"'
    Write-Host " Done."

    # Patching path ... (Fixme: Find something better than this ugly command line)
    Write-Host -NoNewline "Patching bash path to have C:\\Python38 and C:\\Program Files\\Perforce in path ..."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList 'dash -c "echo ''PATH=/mingw64/bin:/c/Python38:/c/Python38/Scripts:$PATH:/c/Program\ Files/Perforce:/c/Program\ Files/Perforce/DVCS:/c/Program\ Files/Git/bin; export PATH'' >> ~/.bash_profile"'
    Write-Host " Done."

    Write-Host -NoNewline "Customize mintty cursor ..."
    # Making custom cursor to have a visual marker (blocky cool cyan cursor)
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList 'dash -c "echo \"CursorColour=0,128,255\nCursorType=block\nTerm=xterm-256color\" > ~/.minttyrc"'

    Write-Host " Done."
}

function wait-mintty-and-clean-gpg-agent {
    Start-Sleep 1
    $p = (get-process -Name mintty)
    Write-Host -NoNewline "  Waiting mintty Process Id" $p.Id "..."
    while (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) {
        Start-Sleep 1
    }
    Write-Host " Done."
    if (Get-Process -Name gpg-agent -ErrorAction SilentlyContinue) {
        Write-Host -NoNewline "  Residual gpg-agent process found ! Stopping it ..."
        Stop-Process (Get-Process -Name gpg-agent)
        Write-Host " Done."
    }
}

function update-install {
    Write-Host "Updating base install with potentially downgraded elements ..."
    # To update the system with some conflicts we have to do this ...
    Start-Process -FilePath $shCmd -ArgumentList "dash -c 'yes | pacman -Suy'"
    wait-mintty-and-clean-gpg-agent
    Write-Host "Done."
    Write-Host "Updating base install ..."
    Start-Process -FilePath $shCmd -ArgumentList 'pacman -Suy --noconfirm'
    wait-mintty-and-clean-gpg-agent
    Write-Host "Done."
}

function install-packages {
    Write-Host -NoNewline "Installing pacman packages ..."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList "pacman -S git mingw-w64-x86_64-tk --noconfirm"
    Write-Host " Done."
}

function clean-deps {
    Write-Host -NoNewline "Cleaning PS module ..."
    # Have to use get-item because powershell ...
    Remove-Item -Recurse -Force (Get-Item "$env:temp\PSModules\PS7Zip").FullName
    # Remove-Item -Recurse -Force $deployArea\msys64
    Write-Host " Done."
}

Install-MSYS2
Read-Host -Prompt ": Press enter to close "
