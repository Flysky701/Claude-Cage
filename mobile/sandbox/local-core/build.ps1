[CmdletBinding()]
param([string]$Sdk=$env:ANDROID_HOME,[string]$Jdk=$env:JAVA_HOME,[string]$BuildTools)
$ErrorActionPreference='Stop'
$dest=[IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot '../../.build/on-device-core')).FullName
$classes=[IO.Directory]::CreateDirectory((Join-Path $dest 'classes')).FullName
$env:JAVA_HOME=$Jdk
$android=Join-Path $Sdk 'platforms/android-35/android.jar'
$bin=if($BuildTools){$BuildTools}else{Join-Path $Sdk 'build-tools/34.0.0'}
$asset='mihomo-android-arm64-v8-v1.19.33.gz'
$archive=Join-Path $dest $asset
if (!(Test-Path $archive)) {Invoke-WebRequest "https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/$asset" -OutFile $archive}
if((Get-FileHash $archive).Hash.ToLowerInvariant() -ne '2ddbd3aaa884f52b4568f406876ec81dddeef9f1bb67b90d4004d356e2c6a708'){throw 'Mihomo archive digest mismatch'}
$inputStream=[IO.File]::OpenRead($archive)
try {
    $gz=[IO.Compression.GZipStream]::new($inputStream,[IO.Compression.CompressionMode]::Decompress)
    $out=[IO.File]::Create((Join-Path $dest 'libmihomo.so'))
    try {$gz.CopyTo($out)} finally {$out.Dispose();$gz.Dispose()}
} finally {$inputStream.Dispose()}
function Run([string]$exe,[string[]]$arguments) {
    & $exe @arguments
    if($LASTEXITCODE){throw "$exe exited with $LASTEXITCODE"}
}
$sources=@(Get-ChildItem $PSScriptRoot -Filter '*.java' | ForEach-Object FullName)
$sources+=Join-Path $PSScriptRoot '../shared/SpaceSites.java'
Run "$Jdk/bin/javac.exe" (@('--release','8','-encoding','UTF-8','-classpath',$android,'-d',$classes)+$sources)
Run "$Jdk/bin/jar.exe" @('cf',"$dest/helper.jar",'-C',$classes,'.')
Run "$bin/d8.bat" @('--min-api','28','--lib',$android,'--output',$dest,"$dest/helper.jar")
Run "$bin/aapt2.exe" @('link','-I',$android,'--manifest',"$PSScriptRoot/AndroidManifest.xml",'-o',"$dest/unsigned.apk")
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::Open("$dest/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update)
try {
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$dest/classes.dex",'classes.dex')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$dest/libmihomo.so",'lib/arm64-v8a/libmihomo.so')
} finally {$zip.Dispose()}
Run "$bin/zipalign.exe" @('-f','4',"$dest/unsigned.apk","$dest/aligned.apk")
$key=(Resolve-Path "$PSScriptRoot/../../.build/sandbox/development.p12").Path
Run "$bin/apksigner.bat" @('sign','--ks',$key,'--ks-pass','pass:android','--out',"$dest/Cage-LocalCore.apk","$dest/aligned.apk")
Run "$bin/apksigner.bat" @('verify',"$dest/Cage-LocalCore.apk")
Write-Output "$dest/Cage-LocalCore.apk"
