<#
.SYNOPSIS
    LAST RESORT !

.DESCRIPTION
    Because having trouble with clink and C#.
    Following examples does not work, clink injection seem ignored but python env
    is correctly activated :/

        PowerShell
            .Create()
            .AddScript(@"$deployArea=""C:\Patoune\deployArea"")
            .AddScript(@"Start-Process C:\Windows\System32\cmd.exe -ArgumentList ""/K $deployArea\clink_0.4.9\clink_x64.exe inject & $deployArea\miniconda3\Scripts\activate.bat""")
            .Invoke();

        string deployDirectory = @"C:\Patoune\deployArea";
        string windir = Environment.GetEnvironmentVariable("WINDIR");
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = $@"{windir}\System32\cmd.exe";
        psi.Arguments = $@"/K {deployDirectory}\clink_0.4.9\clink_x64.exe inject && {deployDirectory}\miniconda3\Scripts\activate.bat";
        Process p = new Process();
        p.StartInfo = psi;
        p.Start();

    The two examples have exactly the same behaviour.
    So to dodge the problem, we start a process that start a powershel that execute a script which 
    start a cmd and it works exactly has if you have done it by hand. Crazy world ...

.PARAMETER execPowerShell
    To have a PowerShell spawn with the miniconda environment.
    (reason: no activate.ps1 available in miniconda to launch directly the PowerShell with the conda env)
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployArea,
    [Alias("wd")]
    [string]$workingDirectory=$deployArea,
    [Alias("ps")]
    [bool]$execPowerShell=$false
)

Write-Host "Sorry for showing me ..."

$logDirectory = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine("$workingDirectory", ".nimp", "logs"))
if ( -Not (Test-Path $logDirectory) ) {
	New-Item -ItemType directory $logDirectory | Out-Null
}
$env:NIMP_LOG_FILE = [System.IO.Path]::Combine("$logDirectory", "patoune-nimp.log")

Push-Location $workingDirectory
$arg = "/K $deployArea\clink_0.4.9\clink_x64.exe inject & $deployArea\miniconda3\Scripts\activate.bat"
if ($execPowerShell -eq $true) {
    Write-Host "Will have a PowerShell."
    $arg += " & $env:windir\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -Command ""Set-PSReadLineOption -EditMode Emacs"""
} else {
    Write-Host "Will have a CMD."
}
Start-Process  $env:windir\System32\cmd.exe -ArgumentList $arg
Pop-Location
