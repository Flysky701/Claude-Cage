param([Parameter(Mandatory)][string]$Work,[Parameter(Mandatory)][string]$Session,[switch]$DriverOnly)
$ErrorActionPreference='Stop'
if ($Session -notmatch '^pb-[0-9a-f]{12}$') {throw 'Invalid session identifier'}
$base=(Resolve-Path -LiteralPath $Work).Path
$control=Join-Path $base $Session
$dir=Join-Path $env:ProgramFiles ("CageLite-"+$Session)
$state=[ordered]@{started=$false;stopped=$false;serviceInstalled=$false}
$proc=$null;$created=$false
function Publish($name,$value) {
    $dest=Join-Path $control $name
    $text=ConvertTo-Json -InputObject $value -Depth 5
    [IO.File]::WriteAllText($dest+'.new',$text)
    [IO.File]::Move($dest+'.new',$dest)
}
try{
    $prior=@(Get-CimInstance Win32_SystemDriver | Where-Object {$_.Name -match 'WinDivert' -or $_.PathName -match 'WinDivert'})
    if ($prior.Count -or (Get-Process -Name 'ProxyBridge*' -ErrorAction SilentlyContinue)){throw 'An existing ProxyBridge or WinDivert consumer is present; left untouched'}
    if(Test-Path -LiteralPath $dir){throw 'Staging path exists'}
    $null=New-Item -ItemType Directory -Path $dir;$created=$true
    $hashes=@{
        'ProxyBridge_CLI.exe'='DCFFFB8515603DB5FD3B52674C52CCE29EBE6F048D726587595D99AA2E219C0A'
        'ProxyBridgeCore.dll'='1996D5564A6C6F9B58A25E64781ACBC07720CBAC530E2706CE4A58F20EA18D14'
        'WinDivert64.sys'='8DA085332782708D8767BCACE5327A6EC7283C17CFB85E40B03CD2323A90DDC2'
        'WinDivert.dll'='C1E060EE19444A259B2162F8AF0F3FE8C4428A1C6F694DCE20DE194AC8D7D9A2'
    }
    foreach($file in $hashes.Keys){
        $dest=Join-Path $dir $file
        Copy-Item -LiteralPath (Join-Path "$base\official" $file) -Destination $dest
        if((Get-FileHash $dest).Hash -ne $hashes[$file]){throw "Release digest mismatch $file"}
    }
    foreach($file in 'ProxyBridge_CLI.exe','ProxyBridgeCore.dll','WinDivert64.sys'){
        if((Get-AuthenticodeSignature (Join-Path $dir $file)).Status -ne 'Valid'){throw "Untrusted signature $file"}
    }
    if ($DriverOnly) {
        # Isolate SCM/DriverEntry from ProxyBridge, its profiles, and all packet filters.
        $sys=Join-Path $dir 'WinDivert64.sys'
        $state.driverOnly=$true
        $state.createOutput=@(& sc.exe create WinDivert type= kernel start= demand binPath= ('"'+$sys+'"'))
        $state.createExit=$LASTEXITCODE
        if ($state.createExit -ne 0){throw 'SCM driver registration failed'}
        $state.startOutput=@(& sc.exe start WinDivert)
        $state.startExit=$LASTEXITCODE
        $state.serviceQuery=@(& sc.exe queryex WinDivert)
        $state.started=$state.startExit -eq 0
        return
    }
    # Read a bounded request once. Build the two rules here; no arbitrary rules or commands.
    $req=Get-Content "$control\private\route.json" -Raw -Encoding utf8 | ConvertFrom-Json
    if($req.port -notin (1..65535) -or $req.ticket -notmatch '^[0-9a-f]{40}$'){throw 'Invalid session route'}
    $rules=@(foreach($file in 'CagePBCheckParent.exe','CagePBCheckChild.exe'){
        @{ProcessName=(Join-Path $base $file);TargetHosts='1.1.1.1';TargetPorts='443';Protocol='TCP';Action='PROXY';IsEnabled=$true;ProxyConfigId=1;LocalhostViaProxy=$false}
    })
    $profile=@{ProxyConfigs=@(@{Id=1;Type='SOCKS5';Host='127.0.0.1';Port=[string]$req.port;Username='session';Password=$req.ticket});ProxyRules=$rules;LocalhostViaProxy=$false;IsTrafficLoggingEnabled=$true}
    $pf=Join-Path $dir 'test.pbprofile'
    # Profile includes only disposable credentials; restrict read access to current identity, admins, SYSTEM.
    $acl=New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true,$false)
    foreach($sid in [Security.Principal.WindowsIdentity]::GetCurrent().User,
        [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'),[Security.Principal.SecurityIdentifier]::new('S-1-5-18')){
        $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','Allow'))
    }
    [IO.File]::WriteAllText($pf,'{}');[IO.File]::SetAccessControl($pf,$acl)
    [IO.File]::WriteAllText($pf,($profile|ConvertTo-Json -Depth 5))
    $psi=[Diagnostics.ProcessStartInfo]::new((Join-Path $dir 'ProxyBridge_CLI.exe'),('--profile "'+$pf+'" --verbose 2'))
    $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WorkingDirectory=$dir
    $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
    Publish 'load-request.json' @{timeUtc=[DateTime]::UtcNow.ToString('o');driver='WinDivert64.sys'}
    $proc=[Diagnostics.Process]::Start($psi)
    $stdout=$proc.StandardOutput.ReadToEndAsync();$stderr=$proc.StandardError.ReadToEndAsync()
    $readyUntil=[DateTime]::UtcNow.AddMinutes(4)
    do {
        Start-Sleep -Milliseconds 350
        $loaded=@(Get-CimInstance Win32_SystemDriver | Where-Object {$_.PathName -like "*$Session*" -and $_.State -eq 'Running'})
    } while(!$proc.HasExited -and !$loaded.Count -and [DateTime]::UtcNow -lt $readyUntil -and !(Test-Path "$control\stop"))
    $state.pid=$proc.Id
    $state.driver=@(Get-CimInstance Win32_SystemDriver|Where-Object {$_.PathName -like "*$Session*"}|Select-Object Name,State)
    $state.started=!$proc.HasExited -and $loaded.Count -gt 0
    Publish 'engine.json' $state
    $until=[DateTime]::UtcNow.AddMinutes(6)
    while(!$proc.HasExited -and [DateTime]::UtcNow -lt $until -and !(Test-Path "$control\stop")){
        if ((Test-Path "$control\sample") -and !(Test-Path "$control\engine-mem.json")){
            $proc.Refresh()
            Publish 'engine-mem.json' @{pid=$proc.Id;privateBytes=$proc.PrivateMemorySize64;workingSet=$proc.WorkingSet64}
        }
        Start-Sleep -Milliseconds 150
    }
    if(!$proc.HasExited){$proc.Kill();$proc.WaitForExit()}
    $state.stopped=$proc.HasExited;$state.exitCode=$proc.ExitCode
    $lines=(($stdout.Result+"§"+$stderr.Result) -split '[\r\n§]+' | Where-Object {
        $_ -match 'CagePBCheck(Parent|Child)|ProxyBridge is running|failed|error|WinDivert' -and $_ -notmatch '(?i)password|username'
    }|Select-Object -First 150)
    $state.engineLog=@($lines)
}catch{$state.error=$_.Exception.Message}
finally{
    if($proc -and !$proc.HasExited){$proc.Kill();$proc.WaitForExit()}
    if($created){
        $drivers=@(Get-CimInstance Win32_SystemDriver|Where-Object {$_.PathName -like "*$Session*" -and $_.Name -match 'WinDivert'})
        foreach($driver in $drivers){
            if($driver.State -eq 'Running'){sc.exe stop $driver.Name|Out-Null;Start-Sleep -Milliseconds 600}
            $current=Get-CimInstance Win32_SystemDriver -Filter ("Name='"+$driver.Name+"'") -ErrorAction SilentlyContinue
            if($current -and $current.State -eq 'Stopped' -and $current.PathName -like "*$Session*"){sc.exe delete $driver.Name |Out-Null}
        }
        $left=@(Get-CimInstance Win32_SystemDriver|Where-Object {$_.PathName -like "*$Session*"})
        $state.remainingDrivers=@($left|Select-Object Name,State)
        $actual=[IO.Path]::GetFullPath($dir)
        if([IO.Path]::GetDirectoryName($actual) -eq [IO.Path]::GetFullPath($env:ProgramFiles) -and [IO.Path]::GetFileName($actual) -eq ('CageLite-'+$Session)){
            if(Test-Path (Join-Path $actual 'test.pbprofile')){Remove-Item -LiteralPath (Join-Path $actual 'test.pbprofile') -Force}
            if(!$left.Count){Remove-Item -LiteralPath $actual -Recurse -Force}
        }
    }
    $state.stageRemoved=!(Test-Path -LiteralPath $dir)
    Publish 'engine-final.json' $state
}
