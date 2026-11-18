[CmdletBinding()]
param(
    [string]$ProfilePath,
    [switch]$Elevate
)

$ErrorActionPreference = 'Stop'
if (-not $ProfilePath) { $ProfilePath = Join-Path $PSScriptRoot '../../tmp/windows-local/profile/local-profile.json' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$resolvedProfile = [IO.Path]::GetFullPath($ProfilePath)
$exe = Join-Path $repo 'tmp/windows-local/CageLocal.exe'

if (-not (Test-Path -LiteralPath $resolvedProfile -PathType Leaf)) {
    Write-Output "Profile does not exist; nothing to tear down: $resolvedProfile"
    exit 0
}
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Build CageLocal.exe first using build.ps1."
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (-not $Elevate) {
        throw "Teardown requires Windows Administrator consent. Re-run with -Elevate."
    }
    $engine = (Get-Process -Id $PID).Path
    $outPath = Join-Path (Split-Path -Parent $resolvedProfile) 'teardown-result.json'
    $errOut = Join-Path (Split-Path -Parent $resolvedProfile) 'teardown-error.log'
    if (Test-Path -LiteralPath $errOut) { Remove-Item -LiteralPath $errOut -Force }
    $helperScript = Join-Path (Split-Path -Parent $resolvedProfile) 'elevated-teardown-runner.ps1'
    $scriptBody = @"
`$ErrorActionPreference = 'Continue'
`$out = & '$exe' teardown --profile '$resolvedProfile' 2> '$errOut'
`$rc = `$LASTEXITCODE
if (`$rc -ne 0) { exit `$rc }
[IO.File]::WriteAllText('$outPath', (`$out -join "`n"), [Text.UTF8Encoding]::new(`$false))
exit 0
"@
    [IO.File]::WriteAllText($helperScript, $scriptBody, [Text.UTF8Encoding]::new($false))
    try {
        $proc = Start-Process -FilePath $engine -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $helperScript + '"') -Verb RunAs -WindowStyle Hidden -PassThru
        $proc.WaitForExit()
        if ($proc.ExitCode -ne 0) {
            $errText = if (Test-Path -LiteralPath $errOut) { [IO.File]::ReadAllText($errOut) } else { '' }
            throw ("Elevated teardown exited with code {0}: {1}" -f $proc.ExitCode, $errText.Trim())
        }
    } finally {
        if (Test-Path -LiteralPath $helperScript) { Remove-Item -LiteralPath $helperScript -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path -LiteralPath $outPath -PathType Leaf) {
        Get-Content -LiteralPath $outPath -Raw | Write-Output
    }
    exit 0
}

& $exe teardown --profile $resolvedProfile
exit $LASTEXITCODE
