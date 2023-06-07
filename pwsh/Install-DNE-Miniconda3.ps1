<#
.SYNOPSIS
    Install Miniconda 3 on your system.

.DESCRIPTION
    Install Miniconda3 on your system in the deploy area by downloading the
    installer to installerName and executing it with some options.

.PARAMETER deployArea
    Specify where the target directory to install Miniconda is.

.PARAMETER installerName
    Fullpath where the installer should be or where it will be be downloaded.

.PARAMETER $useCanaryChannel
    Does the update use the canary-channel instead of the stable channel on `conda update conda`.
    (Can fix some stalling installation sometimes / https://github.com/conda/conda/issues/8937)

.PARAMETER $pauseAtEnd
    Tell if the script should invoke a pause command before exiting completely.

.NOTES
    Originally, the script was intended to be used by Patoune.
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string] $deployArea,
    [Alias("in")]
    [string] $installerName = "$deployArea\mc3-install.exe",
    [Alias("ucc")]
    [bool] $useCanaryChannel = $False,
    [Alias("pae")]
    [bool] $pauseAtEnd = $false
)

# Utility function(s)
function Force-Resolve-Path {
    <#
    .SYNOPSIS
        Calls Resolve-Path but works for files that don't exist.
    .REMARKS
        From http://devhawk.net/blog/2010/1/22/fixing-powershells-busted-resolve-path-cmdlet
        Copied from https://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist
    #>
    param (
        [string] $FileName
    )

    $FileName = Resolve-Path $FileName -ErrorAction SilentlyContinue `
                                       -ErrorVariable _frperror
    if (-not($FileName)) {
        $FileName = $_frperror[0].TargetObject
    }

    return $FileName
}

# Sanitize Paths (Some functions does not work properly with relative paths ... BISTADMIN / Start-Process)
$deployArea = $(Force-Resolve-Path $deployArea)
$installerName = $(Force-Resolve-Path $installerName)
$condaDir = "$deployArea\miniconda3"

function Install-Miniconda3 {

    if (Test-Path $deployArea\dne_install_miniconda3.lock) {
        Write-Warning "Lock file already present. A previous installation has been started but have not finished successfully."
        $confirm = Read-Host -Prompt "Do you want to continue ? [Y/n] "
        if ($confirm -notIn "", "Y", "y") {
            Exit
        }
    }
    $channelLabel = if ($useCanaryChannel) {"(conda-canary)"} else {"(stable)"}

    New-Item -itemType File -Force $deployArea\dne_install_miniconda3.lock >> $null

    # step 1
    Write-Progress -Id 1 -Activity "Install MiniConda 3 $channelLabel" -Status "Check requirements" -PercentComplete 33
    check-requirements
    # step 2
    Write-Progress -Id 1 -Activity "Install MiniConda 3 $channelLabel" -Status "Update conda base env"  -PercentComplete 66
    update-conda-base
    # step 3
    Write-Progress -Id 1 -Activity "Install MiniConda 3 $channelLabel" -Status "Install packages in conda base env"  -PercentComplete 100
    install-packages-base

    Remove-Item -Force $deployArea\dne_install_miniconda3.lock

    Write-Progress -Id 1 -Activity "Install MiniConda 3" -Completed
}

# internal functions
function check-requirements {

    if (-not(Test-Path $installerName)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe' in '$installerName'."
        Start-BitsTransfer `
            -Source https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe `
            -Destination $installerName
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip' in '$installerName'."
    } else {
        Write-Warning "Installer already downloaded in '$installerName'."
    }

    # Adding clink to have a pseudo readline behaviour ... IMOO, a must have.
    if (-not(Test-Path $deployArea/clink_0.4.9.zip)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Downloading archive 'https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip' in '$deployArea'."
        # Start-BitsTransfer `
        #     -Source https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip `
        #     -Destination $deployArea
        # Start-BitsTransfer has difficulties with redirections
        # see https://powershell.org/forums/topic/bits-transfer-with-github/ for details.
        BITSADMIN /TRANSFER "Downloading Clink ..." /DYNAMIC /DOWNLOAD /priority FOREGROUND `
            https://github.com/mridgers/clink/releases/download/0.4.9/clink_0.4.9.zip `
            "$deployArea\clink_0.4.9.zip"
    } else {
        Write-Warning "Clink archive already downloaded in '$deployArea\clink_0.4.9.zip'."
    }

    if (-not(Test-Path $condaDir)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Starting installer in silent mode ..."
        Start-Process -Wait `
            -FilePath $installerName `
            -Args "/S",
            "/InstallationType=0",
            "/RegisterPython=0",
            "/AddToPath=0",
            "/NoRegistry=1",
            "/D=$condaDir"
    } else {
        Write-Warning "'$condaDir' path exists, skipping installer."
    }

    if (-not(Test-Path $deployArea\clink_0.4.9)) {
        Write-Progress -Id 1 -Activity "Install MiniConda 3" -Status "Check requirements" -CurrentOperation "Unzipping clink archive ..."
        Expand-Archive -Path $deployArea\clink_0.4.9.zip -DestinationPath $deployArea
    } else {
        Write-Warning "'$deployArea\clink_0.4.9' path exists, skipping uncompress."
    }
}

function update-conda-base {
    $customChannelUpdate = if ($useCanaryChannel) {"-c conda-canary"} else {""}
    $channelLabel = if ($useCanaryChannel) {"(conda-canary channel)"} else {"(stable channel)"}
    Write-Host -NoNewline "Updating conda in base env $channelLabel... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda update conda -y $customChannelUpdate"
    Write-Host "Done."
}

function install-packages-base {

    Write-Host -NoNewline "Installing git, pip, ipython in base env ... "
    Start-Process -Wait -FilePath CMD `
        -ArgumentList "/C",
        "$condaDir\Scripts\activate.bat & ",
        "conda install git pip ipython -y"
    Write-Host "Done."
}

# Entry Point
Install-Miniconda3
if ($pauseAtEnd) {
    Read-Host -Prompt ": Press enter to close "
}
