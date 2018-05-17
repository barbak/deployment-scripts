<#
.SYNOPSIS
    LAST RESORT !

.DESCRIPTION
    Because having trouble with clink and C#.
    Following examples does not work, clink injection seem ignored but python env
    is correctly activated :/

        PowerShell
            .Create()
            .AddScript(@"$deployAera=""C:\Patoune\DeployAera"")
            .AddScript(@"Start-Process C:\Windows\System32\cmd.exe -ArgumentList ""/K $deployAera\clink_0.4.9\clink_x64.exe inject & $deployAera\miniconda3\Scripts\activate.bat""")
            .Invoke();

        string deployDirectory = @"C:\Patoune\DeployAera";
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
#>

param(
    [Parameter(Mandatory=$true)]
    [Alias("da")]
    [string]$deployAera,
    [string]$workingDirectory=$deployAera
)

Write-Host "Sorry for showing me ..."

Push-Location $workingDirectory
$env:NIMP_LOG_FILE="$workingDirectory\patoune-nimp.log"
Start-Process  $env:windir\System32\cmd.exe `
    -ArgumentList "/K $deployAera\clink_0.4.9\clink_x64.exe inject & $deployAera\miniconda3\Scripts\activate.bat"
Pop-Location
