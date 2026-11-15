# Prepare the same pinned browser controller used by the Windows guest, without
# installing or launching anything. Output must be a newly owned resource tree.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Resources)
$ErrorActionPreference='Stop'
$repository=Split-Path $PSScriptRoot -Parent
$Resources=[IO.Path]::GetFullPath($Resources)
$allowed=[IO.Path]::GetFullPath((Join-Path $repository '_output/windows-lite'))
if (!$Resources.StartsWith($allowed+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Resource directory must be inside the Windows Lite build output.' }
$target=Join-Path $Resources 'windows-lite/browser'
if (Test-Path -LiteralPath $target) { throw 'Browser resources already exist; choose a new resource tree.' }
$null=New-Item -ItemType Directory -Path $target -Force
$cache=Join-Path $allowed 'dependencies'
$null=New-Item -ItemType Directory -Path $cache -Force
$packages=Get-Content -LiteralPath (Join-Path $repository 'scripts/guest-os/windows-workbench-packages.json') -Raw | ConvertFrom-Json
function Get-Component($spec) {
    $file=Join-Path $cache $spec.filename
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) {
        $partial=$file+'.'+[guid]::NewGuid().ToString('N')+'.partial'
        Invoke-WebRequest -Uri $spec.url -OutFile $partial -TimeoutSec 180
        if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant() -ne $spec.sha256) { throw 'Browser component digest mismatch; partial file retained.' }
        Move-Item -LiteralPath $partial -Destination $file
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $spec.sha256) { throw 'Cached browser component digest mismatch; original retained.' }
    return $file
}
$archives=@{}
foreach ($key in @('node','playwright','playwrightCore')) { $archives[$key]=Get-Component $packages.$key }
$archive=[IO.Compression.ZipFile]::OpenRead($archives.node)
try {
    foreach ($entry in @('node.exe','LICENSE')) {
        [IO.Compression.ZipFileExtensions]::ExtractToFile($archive.GetEntry('node-v24.22.2-win-x64/'+$entry),(Join-Path $Resources $(if($entry -eq 'LICENSE'){'NODE-LICENSE.txt'}else{$entry})))
    }
} finally { $archive.Dispose() }
foreach ($pair in @(@('playwright','playwright'),@('playwrightCore','playwright/node_modules/playwright-core'))) {
    $directory=Join-Path $target $pair[1]
    $null=New-Item -ItemType Directory -Path $directory -Force
    & (Join-Path $env:SystemRoot 'System32/tar.exe') -xf $archives[$pair[0]] -C $directory --strip-components 1
    if ($LASTEXITCODE -ne 0) { throw 'Cannot extract pinned browser components.' }
}
foreach ($name in @('windows-browser.mjs','windows-browser-extensions.mjs','browser-protocol.mjs')) { Copy-Item -LiteralPath (Join-Path $repository ('scripts/guest-os/'+$name)) -Destination $target }
Copy-Item -LiteralPath (Join-Path $repository 'internal/cage/tailnet-client.mjs') -Destination $target
$modules=Join-Path $target 'modules'
$null=New-Item -ItemType Directory -Path $modules
foreach ($name in @('browser-clipboard.mjs','browser-uploads.mjs','browser-downloads.mjs','browser-cookies.mjs','browser-extensions.mjs','browser-vault.mjs','browser-extension-archive.py')) { Copy-Item -LiteralPath (Join-Path $repository ('internal/cage/'+$name)) -Destination $modules }
Copy-Item -LiteralPath (Join-Path $repository 'tools/windows-lite/browser-controller.mjs') -Destination (Join-Path $Resources 'windows-lite/browser-controller.mjs')
Write-Output ('Browser components prepared: '+$Resources)
