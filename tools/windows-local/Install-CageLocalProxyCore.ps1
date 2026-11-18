#requires -Version 5.1
[CmdletBinding()]
param([string]$ArchivePath)

$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$pin = (Get-Content -Raw -LiteralPath (Join-Path $repo 'packaging/windows/dependencies.json') | ConvertFrom-Json).mihomo
$output = Join-Path $repo '_output/windows-local'
$destination = Join-Path $output 'mihomo.exe'
if (!$ArchivePath) {
    foreach ($cache in @('_output/windows-local/dependencies', '_output/windows-lite/dependencies', '_output/windows/dependencies')) {
        $candidate = Join-Path (Join-Path $repo $cache) $pin.file
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $ArchivePath = $candidate; break }
    }
}
if (!$ArchivePath) { throw "Supply the pinned $($pin.file) with -ArchivePath." }
$archive = (Resolve-Path -LiteralPath $ArchivePath).Path
Add-Type -AssemblyName System.IO.Compression
$source = [IO.File]::OpenRead($archive)
$hash = [Security.Cryptography.SHA256]::Create()
try {
    if ([BitConverter]::ToString($hash.ComputeHash($source)).Replace('-', '') -ne $pin.hash) {
        throw 'The proxy core archive does not match the Cage release manifest.'
    }
    $source.Position = 0
    $zip = [IO.Compression.ZipArchive]::new($source, 'Read', $true)
    try {
        $entry = $zip.GetEntry('mihomo-windows-amd64-compatible.exe')
        if (!$entry) { throw 'The archive does not contain the expected Windows proxy core.' }
        [IO.Directory]::CreateDirectory($output) | Out-Null
        $stage = Join-Path $output ([guid]::NewGuid().ToString('N') + '.core')
        try {
            $writer = [IO.File]::Open($stage, 'CreateNew', 'Write', 'None')
            try {
                $reader = $entry.Open()
                try { $reader.CopyTo($writer) } finally { $reader.Dispose() }
            } finally { $writer.Dispose() }
            if ([IO.File]::Exists($destination)) {
                $current = [IO.File]::OpenRead($destination)
                $new = [IO.File]::OpenRead($stage)
                try {
                    $same = [Convert]::ToBase64String($hash.ComputeHash($current)) -ceq [Convert]::ToBase64String($hash.ComputeHash($new))
                } finally { $new.Dispose(); $current.Dispose() }
                if (!$same) { [IO.File]::Replace($stage, $destination, $null) }
            } else { [IO.File]::Move($stage, $destination) }
        } finally { if ([IO.File]::Exists($stage)) { [IO.File]::Delete($stage) } }
        Write-Output "Cage proxy core $($pin.version) ready."
    } finally { $zip.Dispose() }
} finally { $hash.Dispose(); $source.Dispose() }
