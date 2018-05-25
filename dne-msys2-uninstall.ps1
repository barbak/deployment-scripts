<#
.SYNOPSIS
    Uninstall MSYS2 on your system.

.DESCRIPTION
    cf. synopsis.

.PARAMETER deployArea
    Specify where the MSYS2 directory is.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea
)

if (Test-Path "$deployArea\msys64") {
    Write-Host -NoNewline "Removing $deployArea\msys64 ..."
    Remove-Item -Recurse -Force $deployArea\msys64
    Write-Host " Done."
} 
else {
    Write-Host "Nothing to remove in $deployArea."
}

Start-Sleep 3
