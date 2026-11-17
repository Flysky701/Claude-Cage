[CmdletBinding()]
param(
    [string]$Compiler,
    [string]$GitDirectory='D:\DevTools\Git\mingw64\bin',
    [string]$RunDirectory,
    [switch]$BuildOnly,
    [switch]$RelativePaths,
    [switch]$Reftable
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$build=Join-Path $repo 'tmp/windows-appcontainer'
if(-not $Compiler){$Compiler=Join-Path $build 'debugger-tools/w64devkit/bin/gcc.exe'}
if(-not(Test-Path -LiteralPath $Compiler -PathType Leaf)){throw 'Supply an existing local x64 MinGW compiler.'}
$dll=Join-Path $build 'NativePathCompat.dll'
$worker=Join-Path $build 'NativePathCompatWorker.exe'
& $Compiler -shared -O2 -Wall -Wextra -Werror -static-libgcc -o $dll (Join-Path $PSScriptRoot 'NativePathCompat.c') -ladvapi32
if($LASTEXITCODE -ne 0){throw 'Native path compatibility DLL compilation failed.'}
& $Compiler -O2 -Wall -Wextra -Werror -municode -static-libgcc -o $worker (Join-Path $PSScriptRoot 'NativePathCompatProbe.c') -ladvapi32
if($LASTEXITCODE -ne 0){throw 'Native path semantic probe compilation failed.'}
$probe=Join-Path $build 'NativePathCompatProbe.exe'
$csc=Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$sources=@('BoundaryProbe.cs','BoundaryNetwork.cs','BoundaryTerminal.cs','BoundaryTerminalRpc.cs','BrowserInputCompat.cs','NativePathCompatProbe.cs')|ForEach-Object{Join-Path $PSScriptRoot $_}
& $csc /nologo /target:exe /main:NativePathCompatEntry /platform:x64 /optimize+ /unsafe /r:System.Web.Extensions.dll "/out:$probe" @sources
if($LASTEXITCODE -ne 0){throw 'Native path candidate launcher compilation failed.'}
if($BuildOnly){Write-Output $probe;exit 0}
if(-not $RunDirectory){$RunDirectory=Join-Path $build ('native-path-'+[guid]::NewGuid().ToString('N'))}
$fixture=[IO.Path]::GetFullPath($RunDirectory)
if(-not $fixture.StartsWith($build+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Fixture must be below the candidate build directory.'}
if(Test-Path -LiteralPath $fixture){throw 'Choose a fresh fixture directory.'}
foreach($part in @('tools','tools/git','tools/check','work','out','private')){New-Item -ItemType Directory -Path (Join-Path $fixture $part) -Force|Out-Null}
Copy-Item -LiteralPath $dll -Destination (Join-Path $fixture 'tools/NativePathCompat.dll')
Copy-Item -LiteralPath $worker -Destination (Join-Path $fixture 'tools/check/git.exe')
$size=0L
foreach($entry in Get-ChildItem -LiteralPath $GitDirectory -File | Where-Object{$_.Name -eq 'git.exe' -or $_.Extension -eq '.dll'}){
    if($entry.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Git staging does not follow redirected files.'}
    $size+=$entry.Length
    Copy-Item -LiteralPath $entry.FullName -Destination (Join-Path $fixture ('tools/git/'+$entry.Name))
}
Write-Host ('Staged only Git executable/runtime DLLs: '+$size+' bytes')
if($Reftable){& $probe $fixture reftable}elseif($RelativePaths){& $probe $fixture relative}else{& $probe $fixture}
exit $LASTEXITCODE
