#requires -Version 5.1
[CmdletBinding(DefaultParameterSetName='Import')]
param(
    [Parameter(Mandatory,ParameterSetName='Import')]
    [string]$PackagePath,
    [Parameter(Mandatory,ParameterSetName='Choose')]
    [switch]$ChoosePackage,
    [string]$ProfilePath = (Join-Path $PSScriptRoot '../../tmp/windows-local/profile/local-profile.json'),
    [string]$BoundInstance,
    [string]$BoundWorkerSid
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
if ($ChoosePackage) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = [Windows.Forms.OpenFileDialog]::new()
    $owner = [Windows.Forms.Form]::new()
    try {
        $owner.TopMost = $true
        $owner.ShowInTaskbar = $false
        $dialog.Title = 'Choose the official Claude Desktop x64 package'
        $dialog.Filter = 'Claude Desktop x64 (*.msix)|*.msix'
        $dialog.CheckFileExists = $true
        $dialog.RestoreDirectory = $true
        $chosen = if ($dialog.ShowDialog($owner) -eq 'OK') { $dialog.FileName } else { '' }
        @{ package = $chosen } | ConvertTo-Json -Compress
    } finally { $dialog.Dispose(); $owner.Dispose() }
    return
}
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ($BoundInstance) {
    $helper = $env:CAGE_WINDOWS_LOCAL_HELPER
    $verifier = Join-Path $PSScriptRoot 'claude-desktop-windows.ps1'
} else {
    & (Join-Path $PSScriptRoot 'build.ps1') -IfNeeded | Out-Host
    $helper = Join-Path $repo 'tmp/windows-local/CageLocal.exe'
    $verifier = Join-Path $repo 'scripts/guest-os/claude-desktop-windows.ps1'
}
$selectedProfile = (Resolve-Path -LiteralPath $ProfilePath).ProviderPath
$inspection = & $helper workbench-inspect --profile $selectedProfile
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the isolated account and its protected application directory.' }
$receipt = $inspection | ConvertFrom-Json
$instance = [guid]$receipt.instanceId
if ($BoundInstance -and ($instance -ne [guid]$BoundInstance -or $receipt.workerSid -ne $BoundWorkerSid -or !$receipt.rulesVerified)) {
    throw 'The isolated account binding has changed.'
}
$toolsRoot = [IO.Path]::Combine([Environment]::GetFolderPath('CommonApplicationData'), 'CageLocal', $instance.ToString('D'), 'tools')

# This existing verifier checks both the trusted Anthropic signing certificate
# and the exact x64 package manifest. Dot-sourcing does not install the MSIX.
. $verifier
if ($BoundInstance) {
    if ($PackagePath -notmatch '^[A-Za-z]:\\' -or ([IO.DriveInfo]::new($PackagePath.Substring(0,3))).DriveType -ne 'Fixed') {
        throw 'Select a package from a local fixed drive.'
    }
    $part = [IO.Path]::GetPathRoot($PackagePath)
    foreach ($name in ($PackagePath.Substring($part.Length) -split '\\')) {
        if (!$name -or $name -in '.', '..' -or $name.Contains(':')) { throw 'Invalid package path.' }
        $part = [IO.Path]::Combine($part, $name)
        if ([IO.File]::GetAttributes($part) -band [IO.FileAttributes]::ReparsePoint) { throw 'Select a package outside redirected folders.' }
    }
}
$file = Get-Item -LiteralPath $PackagePath
if ($file -isnot [IO.FileInfo] -or $file.Extension -ine '.msix' -or $file.FullName -notmatch '^[A-Za-z]:\\' -or
    [IO.DriveInfo]::new($file.Directory.Root.FullName).DriveType -eq 'Network') { throw 'Select a local Claude Desktop x64 .msix file.' }
$handle = [IO.File]::Open($file.FullName, 'Open', 'Read', 'Read')
$releases = Join-Path $toolsRoot 'claude-desktop-versions'
$stage = $null
try {
    $version = Get-VerifiedClaudeMsixVersion $file $handle
    $parent = [IO.Directory]::CreateDirectory($releases)
    if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected release directory.' }
    $destination = Join-Path $releases ($version.ToString())
    if ([IO.Directory]::Exists($destination)) {
        if (((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -or
            !(Test-Path -LiteralPath (Join-Path $destination 'Claude.exe') -PathType Leaf)) { throw 'Invalid existing staged application.' }
        Write-Output "Claude Desktop $version already available."
        return
    }
    $stageName = '.import-' + [guid]::NewGuid().ToString('N')
    $stage = [IO.Directory]::CreateDirectory((Join-Path $releases $stageName)).FullName
    $prefix = $stage.TrimEnd('\') + '\'
    $handle.Position = 0
    $zip = [IO.Compression.ZipArchive]::new($handle, 'Read', $true)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if (!$name.StartsWith('app/', [StringComparison]::OrdinalIgnoreCase) -or $name.EndsWith('/')) { continue }
            $relative = $name.Substring(4).Replace('/', '\')
            if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains(':') -or ($relative.Split('\') -contains '..')) { throw 'Invalid signed package path.' }
            $target = [IO.Path]::GetFullPath((Join-Path $stage $relative))
            if (!$target.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Package entry outside the application directory.' }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
            $inputStream = $entry.Open()
            try {
                $copy = [IO.File]::Open($target, 'CreateNew', 'Write', 'None')
                try { $inputStream.CopyTo($copy) } finally { $copy.Dispose() }
            } finally { $inputStream.Dispose() }
        }
    } finally { $zip.Dispose() }
    if (!(Test-Path -LiteralPath (Join-Path $stage 'Claude.exe') -PathType Leaf)) { throw 'Missing Claude.exe in the signed package.' }
    [IO.Directory]::Move($stage, $destination)
    $stage = $null
    Write-Output "Claude Desktop $version available to this Cage account."
} finally {
    $handle.Dispose()
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        $owned = (Get-Item -LiteralPath $stage -Force)
        if ($owned.Parent.FullName -ne $releases -or $owned.Name -ne $stageName -or
            ($owned.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unrecognized import directory.' }
        Remove-Item -LiteralPath $owned.FullName -Recurse -Force
    }
}
