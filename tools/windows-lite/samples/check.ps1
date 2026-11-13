param([string]$QueryName,[string]$Result,[string]$HttpsDnsUrl,[switch]$CheckFallback)
$ErrorActionPreference='Stop'
$process=[Diagnostics.Process]::GetCurrentProcess()
$sample=[ordered]@{pid=$PID;image=$process.MainModule.FileName;x64=[Environment]::Is64BitProcess;domain=$QueryName}
try {
    $sample.addresses=@([Net.Dns]::GetHostAddresses($QueryName) | ForEach-Object { $_.IPAddressToString })
} catch { $sample.dnsError=$_.Exception.GetBaseException().Message }
if ($CheckFallback) {
    $sample.freshName='cl'+[Guid]::NewGuid().ToString('N')+'.cage.test.'
    try { $sample.fresh=@([Net.Dns]::GetHostAddresses($sample.freshName) | ForEach-Object IPAddressToString) }
    catch { $sample.freshError=$_.Exception.GetBaseException().Message }
    $client=[Net.Sockets.TcpClient]::new()
    try {
        $op=$client.BeginConnect('127.0.0.1',39483,$null,$null)
        if ($op.AsyncWaitHandle.WaitOne(2000)) { $client.EndConnect($op); $sample.direct='connected' }
        else { $sample.direct='timeout' }
    } catch { $sample.direct=$_.Exception.GetBaseException().Message }
    finally { $client.Dispose() }
}
$before=[datetime]::UtcNow
$local=Get-Date
$after=[datetime]::UtcNow
$sample.local=$local.ToString('yyyy-MM-dd HH:mm:ss.fff')
$sample.utcBefore=$before.ToString('yyyy-MM-dd HH:mm:ss.fff')
$sample.utcAfter=$after.ToString('yyyy-MM-dd HH:mm:ss.fff')
$sample.observedOffsetMinutes=[math]::Round(($local.Ticks-$before.Ticks)/[timespan]::TicksPerMinute)
$sample.runtimeZone=[TimeZoneInfo]::Local.Id
try {$sample.getTimeZone=(Get-TimeZone).Id} catch {$sample.timeZoneError=$_.Exception.GetBaseException().Message}
$sample.adapterStatus=$env:CAGE_LITE_STATUS
$sample.dataProxySet=[bool]$env:CAGE_LITE_PROXY
$sample.dataSessionCredentialPresent=[bool]$env:CAGE_LITE_PASSWORD
$sample.loaded=@($process.Modules | Where-Object {$_.ModuleName -in 'SbieDll.dll','CageRegion.dll'}|ForEach-Object ModuleName)
if ($HttpsDnsUrl) {
    # One ordinary HTTPS transaction with the configured DNS service, through the data proxy.
    try {
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        . (Join-Path $PSScriptRoot 'Set-SessionProxy.ps1')
        $uri=$HttpsDnsUrl+'?dns=EjQBAAABAAAAAAAAB2V4YW1wbGUDY29tAAABAAE'
        $req=[Net.HttpWebRequest]::Create($uri)
        $req.Accept='application/dns-message'
        $req.Timeout=18000
        $r=$req.GetResponse()
        try {
            $stream=New-Object IO.MemoryStream
            $r.GetResponseStream().CopyTo($stream)
            $wire=$stream.ToArray()
            $sample.httpsStatus=[int]$r.StatusCode
        } finally {$r.Dispose()}
        $sample.dnsReplyId=256*[int]$wire[0]+$wire[1]
        $sample.dnsReplyCode=$wire[3] -band 15
        $sample.dnsAnswerCount=256*[int]$wire[6]+$wire[7]
    } catch { $sample.httpsError=$_.Exception.GetBaseException().Message; $sample.errorType=$_.Exception.GetBaseException().GetType().FullName; $sample.errorLine=$_.InvocationInfo.ScriptLineNumber }
}
[IO.File]::WriteAllText($Result,($sample|ConvertTo-Json -Depth 4))
