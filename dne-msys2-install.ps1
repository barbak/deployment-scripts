<#
.SYNOPSIS
    Install MSYS2 on your system.

.DESCRIPTION
    Install MSYS2 on your system in the deploy area by downloading the archive
    and deploying it in the deploy aera.

.PARAMETER deployArea
    Specify where the target directory to install MSYS2 is.

.PARAMETER sleepTimeBeforeKill
    Set the timeout for the update base install with potentially downgraded
    elements. (Should not be this way but MSYS2 doesn't exit properly during
    this stage)

.PARAMETER installNimp
    Does Nimp will be installed.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea,
    [Alias("timeout")]
    [int]$sleepTimeBeforeKill=60,
    [Alias("nimp")]
    [bool]$installNimp=$true
)

# $msysXzArchive="$deployArea\msys2-base-x86_64-20161025.tar.xz"
# $msysTarName="$deployArea\msys2-base-x86_64-20161025.tar"
$msysXzArchive="$deployArea\msys2-base-x86_64-20180531.tar.xz"
$msysTarName="$deployArea\msys2-base-x86_64-20180531.tar"
$shCmd="$deployArea\msys64\msys2.exe"

# Expand-Archive -Path $msysZipArchive -DestinationPath $deployArea
# Save-Module -Name 7Zip4Powershell -Path .
# $pathToModule = ".\7Zip4Powershell\1.8.0\7Zip4PowerShell.psd1"

# if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
#     Import-Module $pathToModule
# }

# Expand-7Zip $msysXzArchive . #$deployArea
# Expand-7Zip $msysTarName .
## 7Zip4Powershell est super lent a la decompression :/

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
    # step 5
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Install packages" -PercentComplete (100.0/7.0 * 5)
    install-packages
    # step 6
    if ($installNimp) {
        Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Install Nimp" -PercentComplete (100.0/7.0 * 6)
        install-nimp
    }
    # step 7
    Write-Progress -Id 1 -Activity "Install MSYS2" -Status "Cleaning" -PercentComplete (100.0/7.0 * 7)
    clean-deps
    Remove-Item -Force $deployArea\dne_install_msys2.lock
    Write-Progress -Id 1 -Activity "Install MSYS2" -Completed
}

function materialize-dependencies {
    if (-not(Test-Path $msysXzArchive)) {
        # Write-Host -NoNewline "Downloading archive 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20161025.tar.xz' in '$msysXzArchive'."
        # http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20180531.tar.xz
        Write-Host -NoNewline "Downloading archive 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20180531.tar.xz' in '$msysXzArchive'."
        Start-BitsTransfer `
            -Source http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20180531.tar.xz `
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

function setup-install {
    # Need a first launch to make default files in order.
    Write-Host -NoNewline "Running msys2.exe for the first time ..."
    Start-Process -Wait -FilePath $shCmd -ArgumentList "exit"
    Write-Host " Done."

    # Patching path ...
    Write-Host -NoNewline "Patching bash path to have mingw%2d/bin and C:\\Program Files\\Perforce in path ..."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList 'dash -c "grep -q ''^PATH.*mingw64'' ~/.bash_profile || echo ''PATH=/mingw64/bin:/mingw32/bin:$PATH:/c/Program\ Files/Perforce:/c/Program\ Files/Perforce/DVCS; export PATH'' >> ~/.bash_profile"'
    Write-Host " Done."

    Write-Host -NoNewline "Customize mintty cursor ..."
    # Making custom cursor to have a visual marker (blocky cool cyan cursor)
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList 'dash -c "echo \"CursorColour=0,128,255\nCursorType=block\nTerm=xterm-256color\" > ~/.minttyrc"'
    Write-Host " Done."
}

function update-install {
    Write-Host "/!\ Kludgy part ..."
    Write-Host -NoNewline "Updating base install with potentially downgraded elements ..."
    # To update the system with some conflicts we have to do this ...
    Write-Host " If the msys2 windows is stucked, it will be automatically closed in $sleepTimeBeforeKill seconds."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList "dash -c '(echo $sleepTimeBeforeKill seconds before exiting && sleep $sleepTimeBeforeKill && kill `$`$)& yes | pacman -Suy'"
    Write-Host " Done."

    # Now we can use it as expected
    # (Almost :/ -- Pseudo-Fix: 2018/06/25)
    # Still necessary at 2018/10/22
    # We are stuck because a gpg-agent process is spawned and is never returning.
    Write-Host "/!\ Kludgier ..."
    Write-Host "Updating base install ..."
    $msProc = Start-Process -FilePath $shCmd `
        -ArgumentList "pacman -Syu --noconfirm"
    Write-Host "Tryin to get gpg-agent to be spawned in $sleepTimeBeforeKill seconds ..."
    Start-Sleep $sleepTimeBeforeKill;
    $gpgProc = $null;
    # $msProc seem empty trying something without it ...
    Write-Host "Start hunting gpg-agent process on $(Get-Date -UFormat "%Y/%m/%d-%H:%M:%S")"
    Write-Host "If script is stuck for too long, check https://confluence.dont-nod.com/display/TD/Patoune."
    while ($gpgProc -eq $null) {
        $gpgProc = Get-Process gpg-agent -ErrorAction SilentlyContinue;
        if ($gpgProc) {
            Write-Host;
            Write-Host "Found a gpgProcess.";
            break;
        } else {
            Write-Host -NoNewline "Not yet spawned ? $(Get-Date -UFormat "%Y/%m/%d-%H:%M:%S")`r";
            Start-Sleep 1;
        }
    }
    Write-Host;
    Write-Host -NoNewline "Killing gpgProcess id ";
    Write-Host -NoNewline $gpgProc.id;
    Write-Host -NoNewline " in $($sleepTimeBeforeKill / 2.0) seconds ...";
    Start-Sleep ($sleepTimeBeforeKill / 2.0);
    Stop-Process -id $gpgProc.id -Force
    Write-Host " Done."

    # The previous should be only the following lines
    # Write-Host "Updating base install ..."
    # Start-Process -Wait -FilePath $shCmd `
    #     -ArgumentList "pacman -Syu --noconfirm"
    # Write-Host " Done."
}

function install-packages {
    Write-Host -NoNewline "Installing pacman packages ..."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList "pacman -S mingw-w64-x86_64-python3-pip git --noconfirm"
    Write-Host " Done."
}

function install-nimp {
    Write-Host -NoNewline "Pip step ..."
    Start-Process -Wait -FilePath $shCmd `
        -ArgumentList "/mingw64/bin/python3 -m pip  install --upgrade",
        "pip",
        "git+https://github.com/dontnod/nimp.git",
        "git+https://github.com/dontnod/bittornado.git",
        "requests"
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
