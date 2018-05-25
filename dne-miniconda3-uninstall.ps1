<#
.SYNOPSIS
    Uninstall Miniconda 3 on your system.

.DESCRIPTION
    cf. synopsis.

.PARAMETER deployArea
    Specify where the miniconda3 directory is.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea
)

$condaDir="$deployArea\miniconda3"
$uninstallerName="$condaDir\Uninstall-Miniconda3.exe"

if (Test-Path "$condaDir") {
    Write-Host -NoNewline "Removing $condaDir ..."
    Start-Process -Wait -FilePath $uninstallerName -ArgumentList "/S"
    Write-Host " Done."
} else {
    Write-Host "Nothing to remove in $deployArea."
}

Start-Sleep 3
