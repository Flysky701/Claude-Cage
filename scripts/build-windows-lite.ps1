#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$Go,
    [string]$Dotnet,
    [string]$Python,
    [string]$ModuleCache,
    [string]$NuGetCache,
    [string]$OutputDirectory,
    [switch]$SkipUI
)
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
function Find-Tool([string]$given, [string]$name) {
    if ($given) { return (Get-Item -LiteralPath $given -ErrorAction Stop).FullName }
    return (Get-Command $name -ErrorAction Stop).Source
}
$goTool = Find-Tool $Go 'go.exe'
$dotnetTool = Find-Tool $Dotnet 'dotnet.exe'
$pythonTool = Find-Tool $Python 'python.exe'
$nodeTool = Find-Tool '' 'node.exe'
$version = (Get-Content -LiteralPath (Join-Path $repository 'VERSION') -Raw).Trim()
$outputRoot = [IO.Path]::GetFullPath((Join-Path $repository '_output/windows-lite'))
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $outputRoot ('build-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)) }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $OutputDirectory.StartsWith($outputRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Choose a new build directory under this repository _output/windows-lite.' }
if (Test-Path -LiteralPath $OutputDirectory) { throw 'The output directory already exists; existing builds and data are never replaced.' }
$app = Join-Path $OutputDirectory 'app'
$resources = Join-Path $app 'resources'
New-Item -ItemType Directory -Path $resources -Force | Out-Null
$saved = @{}
foreach ($key in @('GOOS','GOARCH','CGO_ENABLED','GOTOOLCHAIN','GOCACHE','GOMODCACHE','DOTNET_CLI_HOME','NUGET_PACKAGES','DOTNET_SKIP_FIRST_TIME_EXPERIENCE','DOTNET_CLI_TELEMETRY_OPTOUT','UV_CACHE_DIR','UV_PYTHON','UV_PYTHON_DOWNLOADS')) { $saved[$key] = [Environment]::GetEnvironmentVariable($key,'Process') }
function Invoke-Tool([string]$tool, [string[]]$arguments) { & $tool @arguments; if ($LASTEXITCODE -ne 0) { throw "Build tool failed: $tool (exit $LASTEXITCODE)" } }
function Get-LiteArtifact($artifact) {
    $cache=Join-Path $outputRoot 'dependencies'
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
    $file=Join-Path $cache $artifact.file
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        $partial=$file+'.'+[guid]::NewGuid().ToString('N')+'.partial'
        Invoke-WebRequest -Uri $artifact.url -OutFile $partial -TimeoutSec 180 -MaximumRedirection 5
        if ((Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.sha256) { throw 'Component download digest mismatch; the untrusted partial file was preserved.' }
        Move-Item -LiteralPath $partial -Destination $file
    }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.sha256) { throw 'Cached component digest mismatch; the existing file was preserved.' }
    return $file
}
Push-Location $repository
try {
    $env:UV_CACHE_DIR=Join-Path $outputRoot 'uv-cache'
    $env:UV_PYTHON=$pythonTool
    $env:UV_PYTHON_DOWNLOADS='never'
    if (-not $SkipUI) {
        Push-Location (Join-Path $repository 'ui')
        try {
            Invoke-Tool $nodeTool @('scripts/prepare-vnc.mjs')
            Invoke-Tool $nodeTool @('scripts/prepare-xterm.mjs')
            Invoke-Tool $nodeTool @('node_modules/vite/bin/vite.js','build')
            Invoke-Tool $nodeTool @('scripts/verify-build.mjs')
        } finally { Pop-Location }
    }
    $env:GOOS='windows'; $env:GOARCH='amd64'; $env:CGO_ENABLED='0'; $env:GOTOOLCHAIN='local'
    $env:GOCACHE=Join-Path $outputRoot 'go-cache'
    if ($ModuleCache) { $env:GOMODCACHE=[IO.Path]::GetFullPath($ModuleCache) }
    $tags='external_hcs,external_wsl2,yq_noxml,yq_nolua,yq_noini,yq_nohcl,yq_notoml,yq_noprops,yq_nocsv,yq_nouri,yq_nobase64,yq_nosh,yq_noshell'
    Invoke-Tool $goTool @('build','-trimpath','-tags',$tags,'-ldflags',"-s -w -X github.com/sylvinus/agent-vm/internal/version.Version=$version",'-o',(Join-Path $resources 'cage.exe'),'./cmd/cage')
    Invoke-Tool (Join-Path $resources 'cage.exe') @('verify-web-assets')
    $env:DOTNET_CLI_HOME=Join-Path $outputRoot 'dotnet-home'
    $env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1'; $env:DOTNET_CLI_TELEMETRY_OPTOUT='1'
    if ($NuGetCache) { $env:NUGET_PACKAGES=[IO.Path]::GetFullPath($NuGetCache) }
    Invoke-Tool $dotnetTool @('publish','desktop/windows/Cage.Windows.csproj','--no-restore','-c','Release','-r','win-x64','--self-contained','true','-p:EnableWindowsTargeting=true','-p:PublishSingleFile=true',"-p:Version=$version","-p:InformationalVersion=$version",'-o',$app)
    $worker = New-Item -ItemType Directory -Path (Join-Path $resources 'windows-lite')
    foreach ($name in @('space.py','setup.py','runtime.py','shell.py','broker.py','fixed_tcp.py','dns.zip','LICENSE')) { Copy-Item -LiteralPath (Join-Path $repository ('tools/windows-lite/'+$name)) -Destination $worker.FullName }
    Invoke-Tool $pythonTool @('-B',(Join-Path $repository 'tools/windows-lite/build_runtime.py'),'--output',(Join-Path $worker.FullName 'runtime-bin'))
    $components=Get-Content (Join-Path $repository 'internal/windowslite/dependencies.json') -Raw | ConvertFrom-Json
    $pythonArchive=Get-LiteArtifact $components.python
    Expand-Archive -LiteralPath $pythonArchive -DestinationPath (Join-Path $resources 'python')
    [IO.File]::AppendAllText((Join-Path $resources 'python/python313._pth'),"../windows-lite"+[Environment]::NewLine)
    $proxyArchive=Get-LiteArtifact $components.mihomo
    $proxyStage=Join-Path $OutputDirectory 'proxy-component'
    Expand-Archive -LiteralPath $proxyArchive -DestinationPath $proxyStage
    $proxyFiles=@(Get-ChildItem -LiteralPath $proxyStage -File -Filter '*.exe' -Recurse)
    if ($proxyFiles.Count -ne 1) { throw 'Unexpected proxy component layout.' }
    Copy-Item -LiteralPath $proxyFiles[0].FullName -Destination (Join-Path $resources 'mihomo.exe')
    & (Join-Path $PSScriptRoot 'prepare-windows-lite-browser.ps1') -Resources $resources
    [IO.File]::WriteAllText((Join-Path $resources 'windows-lite-workbench'),'')
    [IO.File]::WriteAllText((Join-Path $app 'DEVELOPMENT-BUILD.txt'),"Windows Lite local review build. Browser and terminal require successful application-owned active checks and a live, expiring monitor. A saved test report never grants admission. No release or update installation.`n")
    [IO.File]::WriteAllText((Join-Path $app 'version.txt'),$version)
    Copy-Item -LiteralPath (Join-Path $repository 'LICENSE') -Destination (Join-Path $app 'LICENSE.txt')
    Copy-Item -LiteralPath (Join-Path $repository 'tools/windows-lite/PREVIEW.md') -Destination (Join-Path $app '使用说明.md')
    Copy-Item -LiteralPath (Join-Path $repository 'tools/windows-lite/THIRD-PARTY-NOTICES.txt') -Destination (Join-Path $app 'THIRD-PARTY-NOTICES.txt')
    $files = Get-ChildItem -LiteralPath $app -File -Recurse | ForEach-Object { @{path=[IO.Path]::GetRelativePath($app,$_.FullName);sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash;bytes=$_.Length} }
    @{kind='windows-lite-integrated-workbench-review';version=$version;runtimeDependency='bundled Python, Node, browser controller and proxy; Sandboxie downloaded by setup';applicationExecution='requires-current-application-monitor';files=@($files)} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest.json') -Encoding utf8
    Compress-Archive -LiteralPath $app -DestinationPath (Join-Path $OutputDirectory 'Cage-Windows-Lite-review.zip') -CompressionLevel Optimal
    Write-Host "Built Windows Lite review: $OutputDirectory"
} finally {
    Pop-Location
    foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key,$saved[$key],'Process') }
}
