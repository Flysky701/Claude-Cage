[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Sdk,
    [Parameter(Mandatory)][string]$Jdk,
    [Parameter(Mandatory)][string]$Gradle,
    [string]$ReadOnlyGradleCache
)
$ErrorActionPreference = 'Stop'
$buildRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../.build/integrity-test'))
$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = $Sdk
$env:GRADLE_USER_HOME = Join-Path $buildRoot 'gradle'
$env:ANDROID_USER_HOME = Join-Path $buildRoot '.android'
$env:ANDROID_PREFS_ROOT = $buildRoot
$env:TEMP = Join-Path $buildRoot 'temp'
$env:TMP = $env:TEMP
if ($ReadOnlyGradleCache) { $env:GRADLE_RO_DEP_CACHE = $ReadOnlyGradleCache }
[void][IO.Directory]::CreateDirectory($env:ANDROID_USER_HOME)
[void][IO.Directory]::CreateDirectory($env:TEMP)
$key = Join-Path $buildRoot 'development.p12'
if (!(Test-Path -LiteralPath $key)) {
    & (Join-Path $Jdk 'bin/keytool.exe') -genkeypair -alias development -keyalg RSA -keysize 2048 -validity 3650 -storetype PKCS12 -storepass android -keypass android -dname 'CN=Flysky701 Integrity Test Development' -keystore $key
    if ($LASTEXITCODE -ne 0) { throw 'Development signing key creation failed.' }
}
Push-Location $PSScriptRoot
try {
    & $Gradle --no-daemon --console=plain :app:assembleDebug
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    $destination = Join-Path $buildRoot 'Flysky701-Integrity-Test.apk'
    Copy-Item -LiteralPath 'app/build/outputs/apk/debug/app-debug.apk' -Destination $destination -Force
    Write-Output $destination
} finally { Pop-Location }
