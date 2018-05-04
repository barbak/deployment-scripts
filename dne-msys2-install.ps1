$deployAera= if ($env:PTN_DEPLOY_AERA) { $env:PTN_DEPLOY_AERA } else { "D:\dne_seeds\DeployAera" }
$msysXzArchive="$deployAera\msys2-base-x86_64-20161025.tar.xz"
$msysTarName="$deployAera\msys2-base-x86_64-20161025.tar"
$shCmd="$deployAera\msys64\msys2.exe"
$sleepTimeBeforeKill = if ($env:PTN_TIMEOUT) { $env:PTN_TIMEOUT } else { 60 }

# Expand-Archive -Path $msysZipArchive -DestinationPath $deployAera
# Save-Module -Name 7Zip4Powershell -Path .
# $pathToModule = ".\7Zip4Powershell\1.8.0\7Zip4PowerShell.psd1"

# if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
#     Import-Module $pathToModule
# }

# Expand-7Zip $msysXzArchive . #$deployAera
# Expand-7Zip $msysTarName .
## 7Zip4Powershell est super lent a la decompression :/

New-Item -itemType File -Force $deployAera\dne_install_msys2.lock >> $null

if (-not(Test-Path $msysXzArchive)) {
    Write-Output "Downloading archive 'http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20161025.tar.xz' in '$msysXzArchive'."
    Start-BitsTransfer `
        -Source http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20161025.tar.xz `
        -Destination $msysXzArchive
    Write-Output "Done."
} else {
  Write-Output "Archive already downloaded in '$msysXzArchive'"
}

if (-not(Test-Path PS7Zip)) {
    Write-Output "Dependency not found, downloading it ..."
    Save-Module -Name PS7Zip -Path .
    Write-Output "Done."
}

$pathToModule = ".\PS7Zip\2.2.0\PS7Zip.psd1"
if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
    Write-Output "Importing dependency ..."
    Import-Module $pathToModule
    Write-Output "Done."
}

Write-Output "Extracting archives '$msysXzArchive' to '$deployAera' ..."
Expand-7Zip -FullName $msysXzArchive -DestinationPath $deployAera
Expand-7Zip -FullName $msysTarName -DestinationPath $deployAera -Remove
Write-Output "Done."

# Need a first launch to make default files in order.
Write-Output "Running msys2.exe for the first time ..."
Start-Process -Wait -FilePath $shCmd -ArgumentList "exit"
Write-Output "Done."

# Patching path ...
Write-Output "Patching bash path to have mingw%2d/bin in path ..."
Start-Process -Wait -FilePath $shCmd `
    -ArgumentList 'dash -c "echo ''PATH=/mingw64/bin:/mingw32/bin:$PATH; export PATH'' >> ~/.bash_profile"'
Write-Output "Done."

Write-Output "Updating base install with potentially downgraded elements ..."
# To update the system with some conflicts we have to do this ...
Start-Process -Wait -FilePath $shCmd `
    -ArgumentList "dash -c '(echo $sleepTimeBeforeKill seconds before exiting && sleep $sleepTimeBeforeKill && kill `$`$)& yes | pacman -Suy'"
Write-Output "Done."

# Now we can use it as expected
Write-Output "Updating base install ..."
Start-Process -Wait -FilePath $shCmd `
    -ArgumentList "pacman -Syu --noconfirm"
Write-Output "Done."

Write-Output "Installing pacman packages ..."
Start-Process -Wait -FilePath $shCmd `
    -ArgumentList "pacman -S mingw-w64-x86_64-python3-pip git --noconfirm"
Write-Output "Done."
Write-Output "Pip step ..."
Start-Process -Wait -FilePath $shCmd `
    -ArgumentList "/mingw64/bin/python3 -m pip  install --upgrade", 
    "pip",
    "git+https://github.com/dontnod/nimp.git",
    "git+https://github.com/dontnod/bittornado.git",
    "requests"
Write-Output "Done."

# # Uninstall
Write-Output "Cleaning PS module ..."
Remove-Item -Recurse -Force PS7Zip
# Remove-Item -Recurse -Force $deployAera\msys64
Write-Output "Done."

Remove-Item -Force $deployAera\dne_install_msys2.lock

Start-Sleep 3

Pause
# Set-ExecutionPolicy Bypass # to execute from the powershell prompt
# Set-ExecutionPolicy Undefined # restoring the default value
