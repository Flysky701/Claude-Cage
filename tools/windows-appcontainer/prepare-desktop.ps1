param(
    [string]$Destination = (Join-Path $PSScriptRoot '../../tmp/windows-appcontainer/desktop-source'),
    [switch]$UseExistingPackage
)

# Download and unpack only. This script never installs or registers the MSIX,
# starts its services, changes Windows features, or launches Claude Desktop.
$ErrorActionPreference = 'Stop'
$destinationPath = [IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force -Path $destinationPath | Out-Null
$packagePath = Join-Path $destinationPath 'Claude-x64.msix'
$extractPath = Join-Path $destinationPath 'extracted'
$officialUri = 'https://claude.ai/api/desktop/win32/x64/msix/latest/redirect'

if (-not $UseExistingPackage) {
    if (Test-Path -LiteralPath $packagePath) {
        throw 'Package already exists. Use -UseExistingPackage to inspect it without downloading again.'
    }
    $partialPath = Join-Path $destinationPath 'Claude-x64.msix.partial'
    if (Test-Path -LiteralPath $partialPath) {
        throw 'An incomplete download exists. Keep it for inspection and choose another destination.'
    }
    $request = [Net.HttpWebRequest]::Create($officialUri)
    $request.Method = 'GET'
    $request.AllowAutoRedirect = $true
    $request.Timeout = 30000
    $request.ReadWriteTimeout = 60000
    $response = $request.GetResponse()
    try {
        if ($response.ResponseUri.Scheme -ne 'https' -or $response.ResponseUri.Host -ne 'downloads.claude.ai') {
            throw 'Unexpected official download redirect; package was not downloaded.'
        }
        $expectedLength = $response.ContentLength
        if ($expectedLength -le 0 -or $expectedLength -gt 1GB) {
            throw 'Unexpected package size; inspect the official download before proceeding.'
        }
        Write-Host ('Official MSIX: {0:N1} MiB' -f ($expectedLength / 1MB))
        $download = [IO.File]::Open($partialPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
        try {
            $response.GetResponseStream().CopyTo($download)
        } finally {
            $download.Dispose()
        }
        if ((Get-Item -LiteralPath $partialPath).Length -ne $expectedLength) {
            throw 'Downloaded package size differs from the response; incomplete file was retained.'
        }
        Move-Item -LiteralPath $partialPath -Destination $packagePath
    } finally {
        $response.Close()
    }
}

if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
    throw 'The downloaded Claude-x64.msix package is missing.'
}
$signature = Get-AuthenticodeSignature -LiteralPath $packagePath
if ($signature.Status -ne 'Valid') {
    throw ('MSIX signature verification did not pass: {0}' -f $signature.Status)
}
if ($signature.SignerCertificate.Subject -notmatch 'O="?Anthropic,? (Inc\.?|PBC)"?') {
    throw 'The MSIX signer is not the expected Anthropic publisher. Inspect it before extraction.'
}
if (Test-Path -LiteralPath $extractPath) {
    throw 'Extraction directory already exists. Preserve it and choose another destination.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($packagePath)
try {
    # Check all paths before writing any entries. Do not treat package paths as
    # shell commands or allow a malformed archive to leave its dedicated root.
    $extractPrefix = $extractPath.TrimEnd('\') + '\'
    foreach ($entry in $archive.Entries) {
        $entryPath = [IO.Path]::GetFullPath((Join-Path $extractPath $entry.FullName))
        if (-not $entryPath.StartsWith($extractPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'An archive entry leaves the extraction directory.'
        }
    }
} finally {
    $archive.Dispose()
}
[IO.Compression.ZipFile]::ExtractToDirectory($packagePath, $extractPath)

[xml]$manifest = Get-Content -LiteralPath (Join-Path $extractPath 'AppxManifest.xml') -Raw
$identity = $manifest.SelectSingleNode("/*[local-name()='Package']/*[local-name()='Identity']")
if ($identity.ProcessorArchitecture -ne 'x64') {
    throw 'The official package is not x64.'
}
$applications = @($manifest.SelectNodes("/*[local-name()='Package']/*[local-name()='Applications']/*[local-name()='Application']") | ForEach-Object {
    [ordered]@{ id=$_.Id; executable=$_.Executable; entryPoint=$_.EntryPoint }
})
$dependencies = @($manifest.SelectNodes("/*[local-name()='Package']/*[local-name()='Dependencies']/*") | ForEach-Object { $_.OuterXml })
$capabilities = @($manifest.SelectNodes("/*[local-name()='Package']/*[local-name()='Capabilities']/*") | ForEach-Object { $_.Name })
$extensions = @($manifest.SelectNodes("//*[local-name()='Extension']") | ForEach-Object {
    [ordered]@{ category=$_.Category; executable=$_.Executable; entryPoint=$_.EntryPoint; declaration=$_.OuterXml }
})
$executables = @(Get-ChildItem -LiteralPath $extractPath -Filter '*.exe' -Recurse -File | ForEach-Object {
    $_.FullName.Substring($extractPrefix.Length)
})
$report = [ordered]@{
    source=$officialUri
    bytes=(Get-Item -LiteralPath $packagePath).Length
    sha256=(Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash
    signature=[ordered]@{ status=[string]$signature.Status; signer=$signature.SignerCertificate.Subject; signerThumbprint=$signature.SignerCertificate.Thumbprint }
    identity=[ordered]@{ name=$identity.Name; publisher=$identity.Publisher; version=$identity.Version; architecture=$identity.ProcessorArchitecture }
    applications=$applications
    dependencies=$dependencies
    capabilities=$capabilities
    extensions=$extensions
    executables=$executables
    installed=$false
    registered=$false
    executed=$false
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $destinationPath 'package-report.json') -Encoding utf8
[pscustomobject]@{ Name=$identity.Name; Version=$identity.Version; Architecture=$identity.ProcessorArchitecture; Signature=$signature.Status; Installed=$false }
