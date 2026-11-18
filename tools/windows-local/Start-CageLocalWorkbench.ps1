#requires -Version 5.1
[CmdletBinding(DefaultParameterSetName='Start')]
param(
    [Parameter(ParameterSetName='Start')]
    [string]$ProfilePath,
    [Parameter(ParameterSetName='Start')]
    [string]$ResumeConfigPath,
    [Parameter(ParameterSetName='Start')]
    [switch]$RebuildBackend,
    [Parameter(ParameterSetName='Start')]
    [switch]$NoBrowser,
    [Parameter(Mandatory, ParameterSetName='Stop')]
    [string]$StopConfigPath
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $builtinModules = Join-Path $PSHOME 'Modules'
    if (($env:PSModulePath -split ';') -notcontains $builtinModules) {
        $env:PSModulePath = $builtinModules + ';' + $env:PSModulePath
    }
}
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$output = Join-Path $repo '_output/windows-local'
$backend = Join-Path $output 'cage.exe'
$helper = Join-Path $repo 'tmp/windows-local/CageLocal.exe'

function Assert-LocalPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    if ($current -notmatch '^[A-Za-z]:\\') { throw "A local drive path is required: $Path" }
    while ($current) {
        try {
            if ([IO.File]::GetAttributes($current) -band [IO.FileAttributes]::ReparsePoint) {
                throw "Redirected paths are not supported: $current"
            }
        } catch [IO.FileNotFoundException] {
        } catch [IO.DirectoryNotFoundException] {
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Get-PrototypeEntry([switch]$IfRunning) {
    # A stale record from a stopped process can be replaced by serve's own lock.
    $ErrorActionPreference = 'Continue'
    $reply = & $backend server-entry --json 2>$null
    if ($LASTEXITCODE -ne 0) {
        if ($IfRunning) { return }
        throw 'The prototype could not issue a launch ticket.'
    }
    $entry = $reply | ConvertFrom-Json -ErrorAction Stop
    if ($entry.runtime -ne 'windows-local') {
        throw 'A different or older controller is running for this configuration. Close its window before reopening it.'
    }
    if ($entry.origin -notmatch '^http://localhost:[0-9]+$' -or $entry.ticket -notmatch '^[0-9a-f]{64}$') {
        throw 'Invalid local workbench entry.'
    }
    return $entry
}

function Stop-Prototype([string]$ConfigPath) {
    $previousConfig = $env:CLAUDE_CAGE_CONFIG
    try {
        $env:CLAUDE_CAGE_CONFIG = $ConfigPath
        # The controller authenticates the handoff and refuses to quit while busy.
        & $backend prepare-update
        if ($LASTEXITCODE -ne 0) { throw "Could not close the workbench at $ConfigPath. Finish any active work and try -StopConfigPath again." }
    } finally {
        $env:CLAUDE_CAGE_CONFIG = $previousConfig
    }
}

function Resolve-PrototypeConfig([string]$ConfigPath) {
    $file = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigPath)
    $directory = [IO.DirectoryInfo]::new([IO.Path]::GetDirectoryName($file))
    if ([IO.Path]::GetFileName($file) -ne 'config.json' -or $directory.Name -notmatch '^(run|account)-[0-9a-f]{32}$' -or
        $directory.Parent.FullName -ne $output -or !(Test-Path -LiteralPath $file -PathType Leaf)) {
        throw 'Use the ConfigPath returned by this prototype launcher.'
    }
    Assert-LocalPath $file
    Assert-LocalPath (Join-Path $directory.FullName 'control.json')
    return $file
}

if ($PSCmdlet.ParameterSetName -eq 'Stop') {
    Assert-LocalPath $backend
    Stop-Prototype (Resolve-PrototypeConfig $StopConfigPath)
    return
}

if (!$ProfilePath) { $ProfilePath = Join-Path $repo 'tmp/windows-local/profile/local-profile.json' }
$profileFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)
foreach ($path in @($profileFile, $helper, $backend)) { Assert-LocalPath $path }
if (!(Test-Path -LiteralPath $profileFile -PathType Leaf)) { throw 'The configured Windows isolation profile does not exist.' }
& (Join-Path $PSScriptRoot 'build.ps1') -IfNeeded | Out-Host
$inspection = & $helper workbench-inspect --profile $profileFile
if ($LASTEXITCODE -ne 0) { throw 'The Windows account or its isolation rules could not be verified.' }
$verified = $inspection | ConvertFrom-Json
$instance = [guid]::Empty
if (![guid]::TryParseExact($verified.instanceId, 'D', [ref]$instance) -or $instance -eq [guid]::Empty -or
    $verified.rulesVerified -ne $true -or $verified.installedFilters -ne 7) { throw 'Invalid isolation account binding.' }
$accountDir = 'account-' + $instance.ToString('N')
if ($ResumeConfigPath) {
    $runDir = [IO.Path]::GetDirectoryName((Resolve-PrototypeConfig $ResumeConfigPath))
    $name = [IO.Path]::GetFileName($runDir)
    if ($name.StartsWith('account-') -and $name -ne $accountDir) { throw 'Select the configuration for this isolation account.' }
} else {
    $name = if ($NoBrowser) { 'run-' + [guid]::NewGuid().ToString('N') } else { $accountDir }
    $runDir = Join-Path $output $name
}
$config = Join-Path $runDir 'config.json'
$tempDir = Join-Path $runDir 'temp'
$recordFile = Join-Path $runDir 'control.json'
$browserDir = Join-Path $runDir 'edge'
$lockFile = Join-Path $runDir 'launcher.lock'
foreach ($path in @($config, $tempDir, $recordFile, $browserDir, $lockFile, (Join-Path $runDir 'startup.log'))) { Assert-LocalPath $path }
$isNew = !(Test-Path -LiteralPath $runDir)
if ($isNew) { New-Item -ItemType Directory -Path $runDir | Out-Null }
# A checkout on a shared drive may grant its owner only Modify. Child fixtures
# set their own file owner and DACL, so give the controller FullControl here.
$callerSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($isNew) {
    & (Join-Path $env:WINDIR 'System32/icacls.exe') $runDir /inheritance:r /grant:r "*${callerSid}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not protect the private prototype directory.' }
}
$acl = Get-Acl -LiteralPath $runDir
$trusted = @($callerSid, 'S-1-5-18', 'S-1-5-32-544')
if ($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $callerSid -or !$acl.AreAccessRulesProtected) {
    throw 'The prototype directory is not private to the current Windows user.'
}
foreach ($rule in $acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier])) {
    if ($rule.AccessControlType -eq 'Allow' -and $rule.IdentityReference.Value -notin $trusted) {
        throw 'The prototype directory grants access to another user.'
    }
}
[IO.Directory]::CreateDirectory($tempDir) | Out-Null
$saved = @{}
foreach ($name in @('CLAUDE_CAGE_CONFIG', 'CAGE_WINDOWS_LOCAL_HELPER', 'CAGE_WINDOWS_LOCAL_PROFILE', 'TEMP', 'TMP', 'GOCACHE', 'GOMODCACHE', 'npm_config_cache')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$controller = $null
$lease = $null
$opened = $false
Push-Location $repo
try {
    try { $lease = [IO.File]::Open($lockFile, 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] { throw 'This prototype window is already open. Return to its Edge window.' }
    $env:TEMP = $tempDir
    $env:TMP = $tempDir
    if ($RebuildBackend -or !(Test-Path -LiteralPath $backend -PathType Leaf)) {
        $go = Get-Command 'go.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (!$go) { throw 'Go is required for the first backend build. Add the Go version from go.mod to PATH.' }
        $npm = (Get-Command 'npm.cmd' -CommandType Application | Select-Object -First 1).Source
        if (!$env:npm_config_cache) { $env:npm_config_cache = Join-Path $output 'npm-cache' }
        if (!(Test-Path -LiteralPath 'ui/node_modules/.bin/vite.cmd' -PathType Leaf)) {
            & $npm --prefix ui ci --no-audit --no-fund | Out-Host
            if ($LASTEXITCODE -ne 0) { throw 'Could not install the workbench frontend dependencies.' }
        }
        & $npm --prefix ui run build | Out-Host
        if ($LASTEXITCODE -ne 0) { throw 'Could not build the workbench frontend.' }
        if (!$env:GOCACHE) { $env:GOCACHE = Join-Path $output 'go-build-cache' }
        if (!$env:GOMODCACHE) { $env:GOMODCACHE = Join-Path $output 'go-module-cache' }
        $tags = 'external_hcs,external_wsl2,yq_noxml,yq_nolua,yq_noini,yq_nohcl,yq_notoml,yq_noprops,yq_nocsv,yq_nouri,yq_nobase64,yq_nosh,yq_noshell'
        & $go.Source build -tags $tags -o $backend ./cmd/cage
        if ($LASTEXITCODE -ne 0) { throw 'Could not build the workbench backend.' }
        & $backend verify-web-assets
        if ($LASTEXITCODE -ne 0) { throw 'The backend is missing valid workbench frontend assets.' }
    }
    $env:CLAUDE_CAGE_CONFIG = $config
    $env:CAGE_WINDOWS_LOCAL_HELPER = $helper
    $env:CAGE_WINDOWS_LOCAL_PROFILE = $profileFile
    $entry = if (Test-Path -LiteralPath $recordFile -PathType Leaf) { Get-PrototypeEntry -IfRunning }
    if (!$entry) {
        $startupLog = Join-Path $runDir 'startup.log'
        $controller = Start-Process -FilePath $backend -ArgumentList 'serve' -WindowStyle Hidden -WorkingDirectory $runDir -RedirectStandardError $startupLog -PassThru
        $deadline = [DateTime]::UtcNow.AddSeconds(30)
        do {
            $controller.Refresh()
            if ($controller.HasExited) { throw "The prototype stopped during startup. See $startupLog" }
            if ([DateTime]::UtcNow -ge $deadline) { throw "Timed out waiting for the prototype. See $startupLog" }
            Start-Sleep -Milliseconds 100
            $record = if (Test-Path -LiteralPath $recordFile -PathType Leaf) { Get-Content -Raw -LiteralPath $recordFile | ConvertFrom-Json }
        } until ($record.pid -eq $controller.Id)
        $entry = Get-PrototypeEntry
    }
    $url = $entry.origin + '/#' + $entry.ticket

    if (!$NoBrowser) {
        $edge = @(${env:ProgramFiles(x86)}, $env:ProgramFiles) | Where-Object { $_ } | ForEach-Object {
            Join-Path $_ 'Microsoft/Edge/Application/msedge.exe'
        } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if (!$edge) { throw 'Microsoft Edge was not found. Use -NoBrowser to obtain a one-time local URL.' }
        $window = Start-Process -FilePath $edge -PassThru -ArgumentList @('--no-first-run', '--disable-sync', '--disable-background-mode', "--user-data-dir=`"$browserDir`"", "--app=$url")
        $opened = $true
        try {
            Write-Host "Windows local workbench: $config"
            $window.WaitForExit()
        } finally {
            $window.Dispose()
            if ($controller -and !$controller.HasExited -and (Test-Path -LiteralPath $recordFile)) {
                $record = Get-Content -Raw -LiteralPath $recordFile | ConvertFrom-Json
                if ($record.pid -eq $controller.Id) { Stop-Prototype $config }
            }
        }
        return
    }
    $record = Get-Content -Raw -LiteralPath $recordFile | ConvertFrom-Json
    [pscustomobject]@{ Origin = $entry.origin; ProcessID = $record.pid; ConfigPath = $config; URL = $url }
} catch {
    if (!$opened -and $controller -and !$controller.HasExited) { $controller.Kill(); $controller.WaitForExit() }
    throw
} finally {
    if ($controller) { $controller.Dispose() }
    if ($lease) { $lease.Dispose() }
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    Pop-Location
}
