[CmdletBinding()]
param(
    [string]$ProfilePath,
    [string]$OutPath,
    [switch]$UseDefaultDesktop
)

$ErrorActionPreference = 'Stop'
if (-not $ProfilePath) { $ProfilePath = Join-Path $PSScriptRoot '../../tmp/windows-local/profile/local-profile.json' }
if (-not $OutPath) { $OutPath = Join-Path $PSScriptRoot 'verification-phase1.json' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildDir = Join-Path $repo 'tmp/windows-local'
$exe = Join-Path $buildDir 'CageLocal.exe'
$resolvedProfile = [IO.Path]::GetFullPath($ProfilePath)

if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Missing CageLocal.exe. Run build.ps1 first."
}
if (-not (Test-Path -LiteralPath $resolvedProfile -PathType Leaf)) {
    throw "Missing provisioned profile at $resolvedProfile. Run Initialize-CageLocal.ps1 -Elevate first."
}

$utf8 = [Text.UTF8Encoding]::new($false)
$profileObj = [IO.File]::ReadAllText($resolvedProfile, $utf8) | ConvertFrom-Json
$toolsRoot = $profileObj.toolsDir
$binExe = Join-Path $profileObj.binDir 'CageLocal.exe'
if (-not (Test-Path -LiteralPath $binExe -PathType Leaf) -or ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $binExe -Algorithm SHA256).Hash)) {
    Copy-Item -LiteralPath $exe -Destination $binExe -Force
}

function Copy-PlainTree([string]$Source, [string]$Destination, [string[]]$ExcludeNames) {
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $Source -Force) {
        if ($ExcludeNames -and ($ExcludeNames -contains $entry.Name)) { continue }
        if ($entry.Name -like 'unins*') { continue }
        if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Redirected entry encountered during staging: $($entry.FullName)"
        }
        $destEntry = Join-Path $Destination $entry.Name
        if ($entry.PSIsContainer) {
            $reparse = @(Get-ChildItem -LiteralPath $entry.FullName -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
            if ($reparse.Count -gt 0) {
                throw "Redirected descendant encountered during staging: $($reparse[0].FullName)"
            }
            Copy-Item -LiteralPath $entry.FullName -Destination $destEntry -Recurse
        } else {
            Copy-Item -LiteralPath $entry.FullName -Destination $destEntry
        }
    }
}

# 1. Stage read-only copies of local applications under toolsDir (owned by controller user, readable by CageLocal + Ring2)
$stagedTools = [ordered]@{}

$claudeSrc = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/bin/claude.exe'
if (Test-Path -LiteralPath $claudeSrc -PathType Leaf) {
    $claudeDir = Join-Path $toolsRoot 'claude'
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
    $claudeDst = Join-Path $claudeDir 'claude.exe'
    Copy-Item -LiteralPath $claudeSrc -Destination $claudeDst -Force
    $stagedTools.claude = $claudeDst
}

$nodeSrc = 'D:\DevTools\node-v24.21.0-win-x64\node.exe'
if (Test-Path -LiteralPath $nodeSrc -PathType Leaf) {
    $nodeDir = Join-Path $toolsRoot 'node'
    New-Item -ItemType Directory -Force -Path $nodeDir | Out-Null
    $nodeDst = Join-Path $nodeDir 'node.exe'
    Copy-Item -LiteralPath $nodeSrc -Destination $nodeDst -Force
    $stagedTools.node = $nodeDst
}

$edgeSrc = Join-Path ${env:ProgramFiles(x86)} 'Microsoft/Edge/Application/msedge.exe'
if (Test-Path -LiteralPath $edgeSrc -PathType Leaf) {
    $stagedTools.edge = $edgeSrc
}

$vscodeDir = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'AppData/Local/Programs/Microsoft VS Code'
if (Test-Path -LiteralPath (Join-Path $vscodeDir 'Code.exe') -PathType Leaf) {
    $vscodeStage = Join-Path $toolsRoot 'vscode'
    if (-not (Test-Path -LiteralPath (Join-Path $vscodeStage 'Code.exe') -PathType Leaf)) {
        Write-Host 'Staging VS Code into toolsDir...'
        Copy-PlainTree $vscodeDir $vscodeStage @('data', 'User', 'profiles', 'user-data', 'extensions', '.vscode')
    }
    $cliMatches = @(Get-ChildItem -LiteralPath $vscodeStage -Filter 'cli.js' -File -Recurse | Where-Object FullName -Match '[\\/]resources[\\/]app[\\/]out[\\/]cli\.js$')
    if ($cliMatches.Count -eq 1) {
        $stagedTools.vscodeExe = Join-Path $vscodeStage 'Code.exe'
        $stagedTools.vscodeCliJs = $cliMatches[0].FullName
    }
}

$desktopSrc = Join-Path $repo 'tmp/windows-appcontainer/desktop-source/extracted/app'
$desktopExeSrc = Join-Path $desktopSrc 'Claude.exe'
if (Test-Path -LiteralPath $desktopExeSrc -PathType Leaf) {
    $sig = Get-AuthenticodeSignature -LiteralPath $desktopExeSrc
    if ($sig.Status -ne 'Valid') {
        throw "Claude Desktop signature invalid: $($sig.Status)"
    }
    $desktopStage = Join-Path $toolsRoot 'claude-desktop'
    if (-not (Test-Path -LiteralPath (Join-Path $desktopStage 'Claude.exe') -PathType Leaf)) {
        Write-Host 'Staging official unpacked Claude Desktop into toolsDir...'
        Copy-PlainTree $desktopSrc $desktopStage @()
    }
    $stagedTools.claudeDesktopExe = Join-Path $desktopStage 'Claude.exe'
}

# 2. Prepare D:\ shared/private verification fixtures (no personal files)
$runId = 'verify-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$fixtureRoot = Join-Path $buildDir $runId
$privateDir = Join-Path $fixtureRoot 'private-host'
$sharedRwDir = Join-Path $fixtureRoot 'shared-rw'
$sharedRoDir = Join-Path $fixtureRoot 'shared-ro'
New-Item -ItemType Directory -Force -Path $privateDir, $sharedRwDir, $sharedRoDir | Out-Null

# Lock private-host strictly to current controller user + SYSTEM + Administrators
$privAcl = [Security.AccessControl.DirectorySecurity]::new()
$privAcl.SetAccessRuleProtection($true, $false)
$inherit = [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
foreach ($sid in @($profileObj.controllerSid, 'S-1-5-18', 'S-1-5-32-544')) {
    $privAcl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid), 'FullControl', $inherit, 'None', 'Allow'))
}
[IO.Directory]::SetAccessControl($privateDir, $privAcl)

$hostPrivateFile = Join-Path $privateDir 'secret.txt'
[IO.File]::WriteAllText($hostPrivateFile, 'HOST_PRIVATE_SECRET_DO_NOT_READ', $utf8)
[IO.File]::WriteAllText((Join-Path $sharedRwDir 'host-rw.txt'), 'HOST_RW_FIXTURE', $utf8)
[IO.File]::WriteAllText((Join-Path $sharedRoDir 'host-ro.txt'), 'HOST_RO_FIXTURE', $utf8)

& $exe grant-share --profile $resolvedProfile --target $sharedRwDir --access rw | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Failed to grant RW share.' }
& $exe grant-share --profile $resolvedProfile --target $sharedRoDir --access ro | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Failed to grant RO share.' }

# Node script exercising D:\ realpath, TZ, and ACL boundaries
$nodeScript = @'
const fs = require('node:fs');
const path = require('node:path');
const rwDir = process.argv[2];
const roDir = process.argv[3];
const privFile = process.argv[4];

const realRw = fs.realpathSync(rwDir);
const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
let privDenied = false;
try { fs.readFileSync(privFile, 'utf8'); } catch (e) { privDenied = ['EACCES', 'EPERM'].includes(e.code); }
let roWriteDenied = false;
try { fs.writeFileSync(path.join(roDir, 'node-deny.txt'), 'bad'); } catch (e) { roWriteDenied = ['EACCES', 'EPERM'].includes(e.code); }
const rwOut = path.join(rwDir, 'node-output.txt');
fs.writeFileSync(rwOut, 'CAGE_LOCAL_NODE_OK:' + tz);
const rwOk = fs.readFileSync(rwOut, 'utf8').startsWith('CAGE_LOCAL_NODE_OK:');

console.log(JSON.stringify({
  marker: 'CAGE_LOCAL_NODE_PASS',
  nodeVersion: process.version,
  realRw: realRw,
  tz: tz,
  privDenied: privDenied,
  roWriteDenied: roWriteDenied,
  rwOk: rwOk
}));
if (!privDenied || !roWriteDenied || !rwOk) {
  process.exit(1);
}
'@
$nodeScriptPath = Join-Path $sharedRwDir 'node-probe.cjs'
[IO.File]::WriteAllText($nodeScriptPath, $nodeScript, $utf8)

$specPath = Join-Path $fixtureRoot 'suite-spec.json'
$spec = [ordered]@{
    timezone = 'Asia/Tokyo'
    useDefaultDesktop = [bool]$UseDefaultDesktop
    hostPrivateFile = $hostPrivateFile
    sharedRwDir = $sharedRwDir
    sharedRoDir = $sharedRoDir
    nodeScriptPath = $nodeScriptPath
    tools = $stagedTools
}
[IO.File]::WriteAllText($specPath, ($spec | ConvertTo-Json -Depth 6), $utf8)

function ConvertTo-PathRegex([string]$PathValue) {
    $norm = $PathValue.Replace('/', '\').TrimEnd('\')
    $parts = $norm.Split('\') | Where-Object { $_ -ne '' } | ForEach-Object { [regex]::Escape($_) }
    return ($parts -join '(?:\\+|/)')
}

function Protect-VerificationJson([string]$JsonText, [string]$WorkspacePath) {
    $scrubbed = $JsonText
    $scrubbed = [regex]::Replace($scrubbed, 'S-1-5-21-\d+-\d+-\d+', 'S-1-5-21-<REDACTED>')

    $hostUserProfile = [Environment]::GetFolderPath('UserProfile')
    if (-not [string]::IsNullOrEmpty($hostUserProfile)) {
        $scrubbed = [regex]::Replace($scrubbed, (ConvertTo-PathRegex $hostUserProfile), '<HOST_USERPROFILE>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    if (-not [string]::IsNullOrEmpty($WorkspacePath)) {
        $scrubbed = [regex]::Replace($scrubbed, (ConvertTo-PathRegex $WorkspacePath), '<WORKSPACE>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    $scrubbed = [regex]::Replace($scrubbed, 'C:(?:\\+|/)Users(?:\\+|/)CageLocal_[0-9a-fA-F]+', '<WORKER_USERPROFILE>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $scrubbed = [regex]::Replace($scrubbed, 'C:(?:\\+|/)ProgramData(?:\\+|/)CageLocal(?:\\+|/)[0-9a-fA-F-]+', '<PROGRAMDATA_CAGELOCAL>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)

    $hostMachine = [Environment]::MachineName
    $hostUser = [Environment]::UserName
    if (-not [string]::IsNullOrEmpty($hostMachine) -or -not [string]::IsNullOrEmpty($hostUser)) {
        $machinePat = if (-not [string]::IsNullOrEmpty($hostMachine)) { '(?<![A-Za-z0-9_-])' + [regex]::Escape($hostMachine) + '(?![A-Za-z0-9_-])' } else { $null }
        $userPat = $null
        if (-not [string]::IsNullOrEmpty($hostUser)) {
            $userPat = if ($hostUser -match '^\d+$') {
                '(?<![0-9a-fA-Fx.:T-])' + [regex]::Escape($hostUser) + '(?![0-9a-fA-F.:Z-])'
            } else {
                '(?<![A-Za-z0-9_-])' + [regex]::Escape($hostUser) + '(?![A-Za-z0-9_-])'
            }
        }
        $evaluator = [Text.RegularExpressions.MatchEvaluator]{
            param($m)
            $val = $m.Value
            if ($machinePat) {
                $val = [regex]::Replace($val, $machinePat, '<HOST_MACHINE>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
            }
            if ($userPat) {
                $val = [regex]::Replace($val, $userPat, '<HOST_USER>', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
            }
            return $val
        }
        $scrubbed = [regex]::Replace($scrubbed, '"(?:\\.|[^"\\])*"', $evaluator)
    }
    return $scrubbed
}

$rawReport = Join-Path $fixtureRoot 'raw-report.json'
try {
    & $exe run-suite --profile $resolvedProfile --spec $specPath --out $rawReport
    $suiteExit = $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $rawReport -PathType Leaf)) {
        throw "Suite did not produce output report (exit=$suiteExit)."
    }
    $report = [IO.File]::ReadAllText($rawReport, $utf8) | ConvertFrom-Json

    # Host-side verification of shared & private files after session end
    $hostPrivUnchanged = ([IO.File]::ReadAllText($hostPrivateFile, $utf8) -eq 'HOST_PRIVATE_SECRET_DO_NOT_READ')
    $rwWorkerFile = Join-Path $sharedRwDir 'worker-write.txt'
    $rwNodeFile = Join-Path $sharedRwDir 'node-output.txt'
    $roDenyFile = Join-Path $sharedRoDir 'worker-ro-deny.txt'

    $b = $report.boundaries
    $boundariesPassed = (
        $b.hostUserListCode -eq 5 -and
        $b.hostPrivateFileReadCode -eq 5 -and
        $b.credentialFileReadCode -eq 5 -and
        $b.sharedRwReadOk -eq $true -and
        $b.sharedRwWriteOk -eq $true -and
        $b.sharedRoReadOk -eq $true -and
        $b.sharedRoWriteCode -eq 5 -and
        $b.workerRegistryWriteOk -eq $true -and
        $b.directTcpV4Code -eq 10013 -and
        $b.directTcpV6Code -eq 10013 -and
        $b.directUdpCode -eq 10013 -and
        $b.otherHostLoopbackCode -eq 10013 -and
        $b.otherHostLoopbackPending -eq $false -and
        $b.nonWorkerBrokerRejected -eq $true -and
        $b.brokerHttpStatus -eq 200 -and
        $b.brokerHttpBodyMatch -eq $true -and
        $b.brokerConnectTunnelOk -eq $true -and
        $b.killSwitchPassed -eq $true
    )

    $hostChecks = [ordered]@{
        hostPrivateUnchanged = $hostPrivUnchanged
        hostWorkerWriteVisible = (Test-Path -LiteralPath $rwWorkerFile)
        hostNodeWriteVisible = (Test-Path -LiteralPath $rwNodeFile)
        hostRoDenyAbsent = (-not (Test-Path -LiteralPath $roDenyFile))
        hostHkcuUnchanged = ($report.hostHkcuUnchanged -eq $true)
        lingeringWorkerProcesses = $report.lingeringWorkerProcesses
    }
    $hostChecksOk = (
        $hostChecks.hostPrivateUnchanged -eq $true -and
        $hostChecks.hostWorkerWriteVisible -eq $true -and
        $hostChecks.hostNodeWriteVisible -eq $true -and
        $hostChecks.hostRoDenyAbsent -eq $true -and
        $hostChecks.hostHkcuUnchanged -eq $true -and
        $null -ne $hostChecks.lingeringWorkerProcesses -and
        $hostChecks.lingeringWorkerProcesses -eq 0
    )

    $apps = $report.apps
    $ring1 = if ($null -ne $apps) { $apps.ClaudeCodeRing1 } else { $null }
    $ring2 = if ($null -ne $apps) { $apps.ClaudeCodeRing2AppContainer } else { $null }
    $nodeApp = if ($null -ne $apps) { $apps.NodeSharedDDrive } else { $null }
    $edgeApp = if ($null -ne $apps) { $apps.EdgeHeadlessSandboxAndHkcuProxy } else { $null }
    $vscodeCli = if ($null -ne $apps) { $apps.VSCodeCli } else { $null }
    $vscodeGui = if ($null -ne $apps) { $apps.VSCodeGuiSandbox } else { $null }
    $claudeDesktop = if ($null -ne $apps) { $apps.ClaudeDesktopSandbox } else { $null }

    $claudeCodeRing1Passed = (
        $null -ne $ring1 -and
        $null -eq $ring1.error -and
        $null -ne $ring1.exitCode -and
        $ring1.exitCode -eq 0
    )
    $claudeCodeRing2Passed = (
        $null -ne $ring2 -and
        $null -eq $ring2.error -and
        $null -ne $ring2.exitCode -and
        $ring2.exitCode -eq 0 -and
        $null -ne $ring2.token -and
        $ring2.token.isAppContainer -eq $true -and
        $null -ne $ring2.token.capabilityCount -and
        $ring2.token.capabilityCount -eq 0
    )
    $nodeSharedDDrivePassed = (
        $null -ne $nodeApp -and
        $null -eq $nodeApp.error -and
        $null -ne $nodeApp.exitCode -and
        $nodeApp.exitCode -eq 0 -and
        ([string]$nodeApp.stdout -match 'CAGE_LOCAL_NODE_PASS')
    )
    $edgeHkcuProxyPassed = (
        $null -ne $edgeApp -and
        $null -eq $edgeApp.error -and
        $null -ne $edgeApp.exitCode -and
        $edgeApp.exitCode -eq 0 -and
        ([string]$edgeApp.stdout -match 'CAGE_LOCAL_EDGE_PROXY_OK')
    )
    $vscodeCliPassed = (
        $null -ne $vscodeCli -and
        $null -eq $vscodeCli.error -and
        $null -ne $vscodeCli.exitCode -and
        $vscodeCli.exitCode -eq 0
    )
    $vscodeGuiPassed = (
        $null -ne $vscodeGui -and
        $null -eq $vscodeGui.error -and
        $vscodeGui.visibleWindowDetected -eq $true -and
        $vscodeGui.stillAliveAtEnd -eq $true
    )
    $claudeDesktopObserved = [ordered]@{
        present = ($null -ne $claudeDesktop)
        error = if ($null -ne $claudeDesktop) { $claudeDesktop.error } else { $null }
        stillAliveAtEnd = if ($null -ne $claudeDesktop -and $null -ne $claudeDesktop.stillAliveAtEnd) { [bool]$claudeDesktop.stillAliveAtEnd } else { $false }
        visibleWindowDetected = if ($null -ne $claudeDesktop -and $null -ne $claudeDesktop.visibleWindowDetected) { [bool]$claudeDesktop.visibleWindowDetected } else { $false }
        exitCode = if ($null -ne $claudeDesktop) { $claudeDesktop.exitCode } else { $null }
        exitHex = if ($null -ne $claudeDesktop) { $claudeDesktop.exitHex } else { $null }
    }

    $appSummary = [ordered]@{
        claudeCodeRing1Passed = $claudeCodeRing1Passed
        claudeCodeRing2Passed = $claudeCodeRing2Passed
        nodeSharedDDrivePassed = $nodeSharedDDrivePassed
        edgeHkcuProxyPassed = $edgeHkcuProxyPassed
        vscodeCliPassed = $vscodeCliPassed
        vscodeGuiPassed = $vscodeGuiPassed
        claudeDesktopObserved = $claudeDesktopObserved
    }
    $coreAppsPassed = (
        $claudeCodeRing1Passed -and
        $claudeCodeRing2Passed -and
        $nodeSharedDDrivePassed -and
        $edgeHkcuProxyPassed -and
        $vscodeCliPassed -and
        $vscodeGuiPassed
    )

    $final = [ordered]@{
        schema = 1
        date = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
        desktopMode = $report.desktopMode
        wfpProvisionReceipt = $report.wfpProvisionReceipt
        workerInspect = $report.workerInspect
        boundaries = $b
        boundariesPassed = $boundariesPassed
        hostChecks = $hostChecks
        hostChecksPassed = $hostChecksOk
        apps = $apps
        appSummary = $appSummary
        coreAppsPassed = $coreAppsPassed
        brokerStats = $report.brokerStats
        suiteExitCode = $suiteExit
    }

    $finalJson = $final | ConvertTo-Json -Depth 10
    $redactedJson = Protect-VerificationJson -JsonText $finalJson -WorkspacePath $repo
    try {
        $null = ($redactedJson | ConvertFrom-Json)
    } catch {
        throw "Redacted verification JSON failed validation: $($_.Exception.Message)"
    }
    $outParent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutPath))
    if (-not [string]::IsNullOrEmpty($outParent)) {
        New-Item -ItemType Directory -Force -Path $outParent | Out-Null
    }
    [IO.File]::WriteAllText($OutPath, $redactedJson, $utf8)
    Write-Output "Verification written to: $OutPath"
    Write-Output ("Boundaries passed: {0}; Host checks passed: {1}; Core apps passed: {2}; Lingering processes: {3}; Host HKCU unchanged: {4}" -f $boundariesPassed, $hostChecksOk, $coreAppsPassed, $report.lingeringWorkerProcesses, $report.hostHkcuUnchanged)
    if (-not $boundariesPassed -or -not $hostChecksOk -or -not $coreAppsPassed -or $suiteExit -ne 0) {
        exit 1
    }
} finally {
    try { & $exe grant-share --profile $resolvedProfile --target $sharedRwDir --access revoke | Out-Null } catch { }
    try { & $exe grant-share --profile $resolvedProfile --target $sharedRoDir --access revoke | Out-Null } catch { }
}
