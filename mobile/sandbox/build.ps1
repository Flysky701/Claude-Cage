# Build only the on-device experiment. No Go bindings or desktop runtime are required.
[CmdletBinding()]
param(
    [string]$Sdk = $env:ANDROID_HOME,
    [string]$Jdk = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
if (!$Sdk -or !$Jdk) { throw 'Set ANDROID_HOME and JAVA_HOME, or pass -Sdk and -Jdk.' }
$platform = Join-Path $Sdk 'platforms/android-35/android.jar'
$buildTools = Get-ChildItem (Join-Path $Sdk 'build-tools') -Directory |
    Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' -and [version]$_.Name -ge [version]'34.0.0' } |
    Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (!$buildTools -or !(Test-Path -LiteralPath $platform)) { throw 'Install SDK Platform 35 and Build Tools 34 or newer.' }
$bin = $buildTools.FullName
$dest = [IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot '../.build/sandbox')).FullName
$stage = [IO.Directory]::CreateDirectory((Join-Path $dest ('build-' + [guid]::NewGuid()))).FullName
$previousJdk = $env:JAVA_HOME
$previousPath = $env:PATH
function Run([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "$exe exited with $LASTEXITCODE." }
}
try {
    $env:JAVA_HOME = $Jdk
    $env:PATH = (Join-Path $Jdk 'bin') + [IO.Path]::PathSeparator + $previousPath
    foreach ($dir in 'res/drawable-nodpi','res/xml','classes','dex') {
        [void][IO.Directory]::CreateDirectory((Join-Path $stage $dir))
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../../ui/src/logo.png') -Destination "$stage/res/drawable-nodpi/cage_icon.png"
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'res/xml/admin.xml') -Destination "$stage/res/xml/admin.xml"
    Run "$bin/aapt2.exe" @('compile','--dir',"$stage/res",'-o',"$stage/res.zip")
    Run "$bin/aapt2.exe" @('link','-I',$platform,'--manifest',"$PSScriptRoot/AndroidManifest.xml",'-o',"$stage/base.apk","$stage/res.zip")
    $sources = @(Get-ChildItem "$PSScriptRoot/src" -Filter '*.java' | ForEach-Object FullName)
    Run "$Jdk/bin/javac.exe" (@('--release','8','-encoding','UTF-8','-classpath',$platform,'-d',"$stage/classes") + $sources)
    Run "$Jdk/bin/jar.exe" @('cf',"$stage/app.jar",'-C',"$stage/classes",'.')
    Run "$bin/d8.bat" @('--min-api','26','--lib',$platform,'--output',"$stage/dex","$stage/app.jar")
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::Open("$stage/base.apk", [IO.Compression.ZipArchiveMode]::Update)
    try {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, "$stage/dex/classes.dex", 'classes.dex')
    } finally { $archive.Dispose() }
    Run "$bin/zipalign.exe" @('-f','4',"$stage/base.apk","$stage/aligned.apk")
    $key = Join-Path $dest 'development.p12'
    if (!(Test-Path -LiteralPath $key)) {
        Run "$Jdk/bin/keytool.exe" @('-genkeypair','-alias','development','-keyalg','RSA','-keysize','2048','-validity','3650',
            '-storetype','PKCS12','-storepass','android','-keypass','android','-dname','CN=Cage sandbox development','-keystore',"$stage/development.p12")
        [IO.File]::Move("$stage/development.p12", $key)
    }
    Run "$bin/apksigner.bat" @('sign','--ks',$key,'--ks-pass','pass:android','--out',"$stage/signed.apk","$stage/aligned.apk")
    Run "$bin/apksigner.bat" @('verify',"$stage/signed.apk")
    $apk = Join-Path $dest 'Cage-Sandbox-debug.apk'
    Copy-Item -LiteralPath "$stage/signed.apk" -Destination $apk -Force
    Write-Output $apk
} finally {
    $env:JAVA_HOME = $previousJdk
    $env:PATH = $previousPath
    $actualStage = (Resolve-Path -LiteralPath $stage).ProviderPath
    if ([IO.Path]::GetDirectoryName($actualStage) -eq (Resolve-Path -LiteralPath $dest).ProviderPath -and
        [IO.Path]::GetFileName($actualStage) -match '^build-[a-f0-9-]{36}$') {
        Remove-Item -LiteralPath $actualStage -Recurse -Force
    }
}
