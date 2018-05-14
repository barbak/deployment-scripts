<#
.SYNOPSIS
    Uninstall MSYS2 on your system.

.DESCRIPTION
    cf. synopsis.

.PARAMETER deployaera
    Specify where the MSYS2 directory is.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployAera
)

if (Test-Path "$deployAera\msys64") {
    Write-Host -NoNewline "Removing $deployAera\msys64 ..."
    Remove-Item -Recurse -Force $deployAera\msys64
    Write-Host " Done."
} 
else {
    Write-Host "Nothing to remove in $deployAera."
}

Start-Sleep 3
