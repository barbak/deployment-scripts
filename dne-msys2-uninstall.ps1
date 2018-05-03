$deployAera="D:\dne_seeds\DeployAera"

# Uninstall
# Remove-Item -Recurse -Force PS7Zip

if (Test-Path "$deployAera\msys64") {
    Write-Output "Removing $deployAera\msys64 ..."
    Remove-Item -Recurse -Force $deployAera\msys64
    Write-Output "Done."
} 
else {
    Write-Output "Nothing to remove in $deployAera."
}

Start-Sleep 3
