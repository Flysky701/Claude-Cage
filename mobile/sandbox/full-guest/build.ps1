[CmdletBinding()]
param([Parameter(Mandatory)][string]$LimboApk,[Parameter(Mandatory)][string]$TunnelAar,[string]$Sdk=$env:ANDROID_HOME,[string]$Jdk=$env:JAVA_HOME)
$ErrorActionPreference='Stop'
$dest=[IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot '../../.build/full-guest')).FullName
$classes=[IO.Directory]::CreateDirectory((Join-Path $dest 'classes')).FullName
$env:JAVA_HOME=$Jdk
$android=Join-Path $Sdk 'platforms/android-35/android.jar'
$bin=Join-Path $Sdk 'build-tools/34.0.0'
function Run([string]$exe,[string[]]$arguments) {
    & $exe @arguments
    if($LASTEXITCODE){throw "$exe exited with $LASTEXITCODE"}
}
Run "$bin/apksigner.bat" @('verify',$LimboApk)
$sources=@(Get-ChildItem $PSScriptRoot -Filter '*.java' | ForEach-Object FullName)
if((Get-FileHash $TunnelAar).Hash.ToLowerInvariant() -ne 'ab6c581e6157680cfe5687ee7bbdcf95405c006c2db3701879ec44b9e5f83836'){throw 'HEV 2.19.3 AAR checksum mismatch'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$aar=[IO.Compression.ZipFile]::OpenRead((Resolve-Path $TunnelAar).Path)
try {
    [IO.Compression.ZipFileExtensions]::ExtractToFile($aar.GetEntry('classes.jar'),"$dest/hev.jar",$true)
    [IO.Compression.ZipFileExtensions]::ExtractToFile($aar.GetEntry('jni/arm64-v8a/libhev-socks5-tunnel.so'),"$dest/libhev-socks5-tunnel.so",$true)
} finally {$aar.Dispose()}
Run "$Jdk/bin/javac.exe" (@('--release','8','-encoding','UTF-8','-classpath',"$android;$dest/hev.jar",'-d',$classes)+$sources)
Run "$Jdk/bin/jar.exe" @('cf',"$dest/guest.jar",'-C',$classes,'.')
Run "$bin/d8.bat" @('--min-api','28','--lib',$android,'--output',$dest,"$dest/guest.jar","$dest/hev.jar")
Run "$bin/aapt2.exe" @('link','-I',$android,'--manifest',"$PSScriptRoot/AndroidManifest.xml",'-o',"$dest/unsigned.apk")
Add-Type -AssemblyName System.IO.Compression.FileSystem
$out=[IO.Compression.ZipFile]::Open("$dest/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update)
$up=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $LimboApk).Path)
try {
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($out,"$dest/classes.dex",'classes.dex')
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($out,"$dest/libhev-socks5-tunnel.so",'lib/arm64-v8a/libhev-socks5-tunnel.so')
    foreach($e in $up.Entries){
        if($e.FullName -like 'lib/arm64-v8a/*.so'){$name=$e.FullName}
        elseif($e.FullName.StartsWith('assets/roms/') -and $e.Name){$name='assets/bootrom/'+$e.Name}
        else{continue}
        $en=$out.CreateEntry($name); $inputStream=$e.Open();$outputStream=$en.Open()
        try{$inputStream.CopyTo($outputStream)}finally{$inputStream.Dispose();$outputStream.Dispose()}
    }
} finally {$up.Dispose();$out.Dispose()}
Run "$bin/zipalign.exe" @('-f','4',"$dest/unsigned.apk","$dest/aligned.apk")
$key=(Resolve-Path "$PSScriptRoot/../../.build/sandbox/development.p12").Path
Run "$bin/apksigner.bat" @('sign','--ks',$key,'--ks-pass','pass:android','--out',"$dest/Cage-GuestBench.apk","$dest/aligned.apk")
Run "$bin/apksigner.bat" @('verify',"$dest/Cage-GuestBench.apk")
Write-Output "$dest/Cage-GuestBench.apk"
