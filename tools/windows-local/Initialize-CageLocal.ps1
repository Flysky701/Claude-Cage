[CmdletBinding()]
param(
    [string]$ProfilePath,
    [int]$BrokerPort = 17981,
    [switch]$Elevate
)

$ErrorActionPreference = 'Stop'
if (-not $ProfilePath) { $ProfilePath = Join-Path $PSScriptRoot '../../tmp/windows-local/profile/local-profile.json' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$resolvedProfile = [IO.Path]::GetFullPath($ProfilePath)
$exe = Join-Path $repo 'tmp/windows-local/CageLocal.exe'
$receiptOut = Join-Path (Split-Path -Parent $resolvedProfile) 'provision-result.json'

if (Test-Path -LiteralPath $resolvedProfile -PathType Leaf) {
    Write-Output "Existing profile found at: $resolvedProfile"
    Get-Content -LiteralPath $resolvedProfile -Raw | Write-Output
    exit 0
}

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Build CageLocal.exe first using build.ps1."
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$callerSid = $identity.User.Value

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (-not $Elevate) {
        throw "Provisioning requires one-time Windows Administrator consent. Re-run with -Elevate."
    }
    $callerSidArg = $callerSid
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedProfile) | Out-Null
    $engine = (Get-Process -Id $PID).Path
    $cmdLine = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -ProfilePath "{1}" -BrokerPort {2} -CallerSid "{3}" -ElevatedWorker' -f $PSCommandPath, $resolvedProfile, $BrokerPort, $callerSidArg)
    # Use a helper script block invocation via Start-Process -Verb RunAs
    $helperScript = Join-Path (Split-Path -Parent $resolvedProfile) 'elevated-provision-runner.ps1'
    $errOut = Join-Path (Split-Path -Parent $resolvedProfile) 'provision-error.log'
    if (Test-Path -LiteralPath $errOut) { Remove-Item -LiteralPath $errOut -Force }
    $scriptBody = @"
`$ErrorActionPreference = 'Continue'
`$out = & '$exe' provision --controller-sid '$callerSidArg' --profile-out '$resolvedProfile' --broker-port $BrokerPort 2> '$errOut'
`$rc = `$LASTEXITCODE
if (`$rc -ne 0) { exit `$rc }
[IO.File]::WriteAllText('$receiptOut', (`$out -join "`n"), [Text.UTF8Encoding]::new(`$false))
exit 0
"@
    [IO.File]::WriteAllText($helperScript, $scriptBody, [Text.UTF8Encoding]::new($false))
    try {
        $proc = Start-Process -FilePath $engine -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $helperScript + '"') -Verb RunAs -WindowStyle Hidden -PassThru
        $proc.WaitForExit()
        if ($proc.ExitCode -ne 0) {
            $errText = if (Test-Path -LiteralPath $errOut) { [IO.File]::ReadAllText($errOut) } else { '' }
            throw ("Elevated provisioning exited with code {0}: {1}" -f $proc.ExitCode, $errText.Trim())
        }
    } finally {
        if (Test-Path -LiteralPath $helperScript) { Remove-Item -LiteralPath $helperScript -Force -ErrorAction SilentlyContinue }
    }
    if (-not (Test-Path -LiteralPath $resolvedProfile -PathType Leaf)) {
        throw "Provisioning completed without creating profile file."
    }
    if (Test-Path -LiteralPath $receiptOut -PathType Leaf) {
        Get-Content -LiteralPath $receiptOut -Raw | Write-Output
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $resolvedProfile) | Out-Null
$result = & $exe provision --controller-sid $callerSid --profile-out $resolvedProfile --broker-port $BrokerPort
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
[IO.File]::WriteAllText($receiptOut, ($result -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Output $result
