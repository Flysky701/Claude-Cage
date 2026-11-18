#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ProfilePath,
    [string]$CageResources,
    [string]$ClaudeCLI,
    [string]$GitDirectory
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (!$ProfilePath) { $ProfilePath = Join-Path $repo 'tmp/windows-local/profile/local-profile.json' }
$helper = Join-Path $repo 'tmp/windows-local/CageLocal.exe'
$receipt = & $helper workbench-inspect --profile $ProfilePath
if ($LASTEXITCODE -ne 0) { throw 'The Windows isolation account could not be verified.' }
$instance = [guid]($receipt | ConvertFrom-Json).instanceId
$toolsDir = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) ("CageLocal/" + $instance.ToString('D') + "/tools")
if (!$ClaudeCLI) { $cli = Get-Command claude.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1; if ($cli) { $ClaudeCLI = $cli.Source } }

function Install-ProgramFile([string]$Source, [string]$Component, [string]$Name) {
    $parent = Join-Path $toolsDir $Component
    $dest = Join-Path $parent $Name
    foreach ($path in @($parent,$dest)) {
        if ((Test-Path -LiteralPath $path) -and ([IO.File]::GetAttributes($path) -band [IO.FileAttributes]::ReparsePoint)) { throw "Redirected tool directory: $Component" }
    }
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    # Existing deployments may grant the worker read/execute only. Validate the
    # directory and executable before a controller writes into the deployment.
    $trust = @([Security.Principal.WindowsIdentity]::GetCurrent().User.Value,'S-1-5-18','S-1-5-32-544')
    $read = [Security.AccessControl.FileSystemRights]::ReadAndExecute -bor [Security.AccessControl.FileSystemRights]::Synchronize
    foreach ($path in @($parent,$dest)) {
        if (!(Test-Path -LiteralPath $path)) { continue }
        $acl = Get-Acl -LiteralPath $path
        if ($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -notin $trust) { throw "Untrusted tool owner: $Component" }
        foreach ($rule in $acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier])) {
            if ($rule.AccessControlType -eq 'Allow' -and $rule.IdentityReference.Value -notin $trust -and ($rule.FileSystemRights -band (-bnot $read))) { throw "Untrusted tool permissions: $Component" }
        }
    }
    $expected = (Get-FileHash -LiteralPath $Source).Hash
    if ((Test-Path -LiteralPath $dest) -and (Get-FileHash -LiteralPath $dest).Hash -eq $expected) { return }
    $stage = Join-Path $parent ([guid]::NewGuid().ToString('N') + '.new')
    try {
        [IO.File]::Copy($Source,$stage)
        if ((Get-FileHash -LiteralPath $stage).Hash -ne $expected) { throw "Component verification failed: $Component" }
        if ([IO.File]::Exists($dest)) { [IO.File]::Replace($stage,$dest,$null) } else { [IO.File]::Move($stage,$dest) }
    } finally { if ([IO.File]::Exists($stage)) { [IO.File]::Delete($stage) } }
}
if ($ClaudeCLI) {
    $sig = Get-AuthenticodeSignature -LiteralPath $ClaudeCLI
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch '(^|, )O="?(Anthropic, PBC|Anthropic PBC)"?(,|$)') { throw 'Select the official signed Claude Code executable.' }
    Install-ProgramFile $ClaudeCLI 'claude' 'claude.exe'
    if (!$GitDirectory) {
        $git = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($git) { $GitDirectory = Split-Path (Split-Path $git.Source -Parent) -Parent }
    }
    if ($GitDirectory) {
        $runtime = Join-Path $GitDirectory 'usr/bin'
        $bash = Join-Path $runtime 'bash.exe'
        $signature = Get-AuthenticodeSignature -LiteralPath $bash
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Johannes Schindelin|Git for Windows') {
            throw 'Select the signed Bash executable from Git for Windows.'
        }
        Install-ProgramFile (Join-Path $runtime 'msys-2.0.dll') 'git-bash' 'msys-2.0.dll'
        Install-ProgramFile $bash 'git-bash' 'bash.exe'
    }
}
if ($CageResources) {
    $payload = (Resolve-Path -LiteralPath (Join-Path $CageResources 'guest-os/payload/cage-tailnet.exe')).Path
    Install-ProgramFile $payload 'tailnet' 'cage-tailnet.exe'
}
