<#
.SYNOPSIS
    Uninstall MSYS2 on your system.

.DESCRIPTION
    cf. synopsis.

.PARAMETER deployArea
    Specify where the MSYS2 directory is.

.PARAMETER removeInstaller
    Specify if installer should be removed from disk.

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

$msys2Installer="$deployArea/msys2-base-x86_64-20180531.tar.xz";

if (Test-Path "$deployArea\msys64") {
    Write-Host -NoNewline "Removing '$deployArea\msys64' ...";
    Remove-Item -Recurse -Force $deployArea\msys64;
    Write-Host " Done.";
} else {
    Write-Host "Nothing to remove in $deployArea.";
}

if ($removeInstaller -eq $true) {
    Write-Host "Removing installers ...";
    if (Test-Path $msys2Installer) {
        Remove-Item -Force $msys2Installer;
        Write-Host "  '$msys2Installer' removed.";
    }
    Write-host "Done.";
}

Start-Sleep 3;
