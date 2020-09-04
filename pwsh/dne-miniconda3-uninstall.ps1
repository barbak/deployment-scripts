<#
.SYNOPSIS
    Uninstall Miniconda 3 on your system.

.DESCRIPTION
    cf. synopsis.

.PARAMETER deployArea
    Specify where the miniconda3 directory is.

.PARAMETER removeInstaller
    Specify if installers should be removed from disk.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea,
    [Alias("ri")]
    [bool]$removeInstaller=$false
)

$condaDir="$deployArea\miniconda3";
$clinkDir="$deployArea\clink_0.4.9";
$uninstallerName="$condaDir\Uninstall-Miniconda3.exe";
$condaInstaller="$deployArea\mc3-install.exe";
$clinkInstaller="$deployArea\clink_0.4.9.zip";

if (Test-Path "$condaDir") {
    Write-Host -NoNewline "Removing '$condaDir' ...";
    Start-Process -Wait -FilePath $uninstallerName -ArgumentList "/S";
    Write-Host " Done.";
} else {
    Write-Host "Nothing to remove in '$condaDir'.";
}

if (Test-Path $clinkDir) {
    Write-Host -NoNewLine "Removing '$clinkDir'...";
    Remove-Item -Recurse -Force $clinkDir;
    Write-Host " Done."
} else {
    Write-Host "Nothing to remove in '$clinkDir'.";
}

if ($removeInstaller -eq $true) {
    Write-Host "Removing installers ...";
    if (Test-Path $clinkInstaller) {
        Remove-Item -Force $clinkInstaller;
        Write-Host "  '$clinkInstaller' removed.";
    }
    if (Test-Path $condaInstaller) {
        Remove-Item -Force $condaInstaller;
        Write-Host "  '$condaInstaller' removed.";
    }
    Write-host "Done."
}

Start-Sleep 3
