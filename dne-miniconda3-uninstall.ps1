$deployAera= if ($env:PTN_DEPLOY_AERA) {$env:PTN_DEPLOY_AERA} else {"D:\dne_seeds\DeployAera"}
$condaDir="$deployAera\miniconda3"
$uninstallerName="$condaDir\Uninstall-Miniconda3.exe"

if (Test-Path "$condaDir") {
    Write-Output "Removing $condaDir ..."
    Start-Process -Wait -FilePath $uninstallerName -ArgumentList "/S"
    Write-Output "Done."
} else {
    Write-Output "Nothing to remove in $deployAera."
}

Start-Sleep 3
