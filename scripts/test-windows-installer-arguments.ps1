#requires -Version 7.0
# Compile the production argument functions into a fixture that only writes a
# result file. It never installs Cage, writes registration, or creates shortcuts.
[CmdletBinding()]
param([string]$Compiler = 'makensis.exe')
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
$testBase = [IO.Path]::GetFullPath((Join-Path $repository '_output/installer argument tests'))
$root = Join-Path $testBase ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    $source = Get-Content (Join-Path $repository 'packaging/windows/Cage.nsi') -Raw
    $functions = foreach ($name in @('SetDefaultInstallDirectory', 'LoadShortcutOptions')) {
        $match = [regex]::Match($source, '(?ms)^Function ' + [regex]::Escape($name) + '\r?$.*?^FunctionEnd\r?$')
        if (!$match.Success) { throw "Missing production function: $name" }
        $match.Value
    }
    $fixture = @'
Unicode true
RequestExecutionLevel user
SilentInstall silent
!include LogicLib.nsh
!include FileFunc.nsh
!define UNINSTALL_KEY "Software\CageInstallerArgumentsFixture"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\Cage"
Var DesktopShortcut
Var StartMenuShortcuts
'@ + "`n" + ($functions -join "`n") + "`n" + @'
Function .onInit
  Call SetDefaultInstallDirectory
  Call LoadShortcutOptions
FunctionEnd
Section
  FileOpen $0 "$EXEDIR\result.txt" w
  FileWriteUTF16LE $0 "$INSTDIR$\r$\n$DesktopShortcut$\r$\n$StartMenuShortcuts$\r$\n"
  FileClose $0
SectionEnd
'@
    $script = Join-Path $root 'arguments.nsi'
    $exe = Join-Path $root 'arguments.exe'
    $result = Join-Path $root 'result.txt'
    Set-Content -LiteralPath $script -Value $fixture -Encoding utf8
    & $Compiler /V2 /INPUTCHARSET UTF8 "/DOUTPUT_FILE=$exe" $script
    if ($LASTEXITCODE -ne 0) { throw 'Argument fixture compilation failed.' }

    $cases = @(
        @{Name='multiple shortcut options'; Args='/S /DESKTOPSHORTCUT=0 /STARTMENUSHORTCUT=1 /D=D:\Cage'; Path='D:\Cage'; Desktop='0'; Menu='1'},
        @{Name='spaces and Unicode'; Args='/S /STARTMENUSHORTCUT=0 /DESKTOPSHORTCUT=1 /D=D:\Cage 测试 path'; Path='D:\Cage 测试 path'; Desktop='1'; Menu='0'},
        @{Name='ordinary equals sign in path'; Args='/S /D=D:\Cage version=1'; Path='D:\Cage version=1'; Desktop='1'; Menu='1'},
        @{Name='quoted unrelated option'; Args='/S /DIAGNOSTICS="D:\logs\result with spaces.txt" /DESKTOPSHORTCUT=0 /D=D:\Cage'; Path='D:\Cage'; Desktop='0'; Menu='1'},
        @{Name='options without destination'; Args='/S /DESKTOPSHORTCUT=0 /STARTMENUSHORTCUT=0'; Desktop='0'; Menu='0'},
        @{Name='shortcut after destination'; Args='/S /D=D:\Cage /DESKTOPSHORTCUT=0 /STARTMENUSHORTCUT=0'; Reject=$true},
        @{Name='update after destination'; Args='/S /D=D:\Cage /UPDATE'; Reject=$true},
        @{Name='duplicate destination'; Args='/S /D=D:\Cage /D=D:\Other'; Reject=$true},
        @{Name='quoted destination'; Args='/S /D="D:\Cage path"'; Reject=$true},
        @{Name='quoted destination argument'; Args='/S "/D=D:\Cage path"'; Reject=$true},
        @{Name='empty destination'; Args='/S /D='; Reject=$true},
        @{Name='relative destination'; Args='/S /D=relative\Cage'; Reject=$true},
        @{Name='drive relative destination'; Args='/S /D=D:Cage'; Reject=$true},
        @{Name='invalid shortcut'; Args='/S /DESKTOPSHORTCUT=2 /D=D:\Cage'; Reject=$true}
    )
    foreach ($case in $cases) {
        Remove-Item -LiteralPath $result -Force -ErrorAction SilentlyContinue
        $start = [Diagnostics.ProcessStartInfo]::new($exe)
        $start.UseShellExecute = $false
        $start.CreateNoWindow = $true
        $start.Arguments = $case.Args
        $process = [Diagnostics.Process]::Start($start)
        try {
            if (!$process.WaitForExit(30000)) { $process.Kill($true); throw "Timed out: $($case.Name)" }
            $code = $process.ExitCode
        } finally { $process.Dispose() }
        if ($case.Reject) {
            if ($code -ne 2 -or (Test-Path -LiteralPath $result)) { throw "Invalid arguments accepted: $($case.Name) (exit $code)" }
        } else {
            if ($code -ne 0) { throw "Valid arguments rejected: $($case.Name) (exit $code)" }
            $values = [IO.File]::ReadAllLines($result, [Text.Encoding]::Unicode)
            if (($case.Path -and $values[0] -cne $case.Path) -or $values[1] -ne $case.Desktop -or $values[2] -ne $case.Menu) {
                throw "Unexpected parsed arguments for $($case.Name): $($values -join ', ')"
            }
        }
        Write-Output "PASS: $($case.Name)"
    }
    Write-Output "Passed $($cases.Count) installer argument cases; no application installation or registration was performed."
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    if (!$resolved.StartsWith($testBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected fixture cleanup path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
