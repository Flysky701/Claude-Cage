param([Parameter(Mandatory)][string]$Work,[string]$SevenZip='7z.exe')
$ErrorActionPreference='Stop'
$dir=[IO.Path]::GetFullPath($Work)
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$url='https://github.com/InterceptSuite/ProxyBridge/releases/download/v4.3.0_Windows/ProxyBridge-Setup-4.3.0.exe'
$file=Join-Path $dir 'ProxyBridge-Setup-4.3.0.exe'
if(!(Test-Path -LiteralPath $file)){Invoke-WebRequest -UseBasicParsing $url -OutFile $file}
if((Get-FileHash $file).Hash -ne '64992B813E4B406466540F7CC01332EF90FFE3B234719694347175FD85A3F1F9'){throw 'Unexpected release SHA-256'}
if((Get-AuthenticodeSignature $file).Status -ne 'Valid'){throw 'Untrusted release signature'}
& $SevenZip x -y ("-o"+(Join-Path $dir 'official')) $file | Out-Null
if($LASTEXITCODE){throw '7-Zip extraction failed'}
$c="$env:windir\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$src=Join-Path $PSScriptRoot 'BridgeWorkload.cs'
& $c /nologo /target:winexe /platform:x64 /r:System.Web.Extensions.dll /define:PARENT ("/out:"+$dir+"\CagePBCheckParent.exe") $src
if($LASTEXITCODE){throw 'Parent build failed'}
& $c /nologo /target:winexe /platform:x64 /r:System.Web.Extensions.dll ("/out:"+$dir+"\CagePBCheckChild.exe") $src
if($LASTEXITCODE){throw 'Child build failed'}
