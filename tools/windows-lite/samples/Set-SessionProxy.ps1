# Windows PowerShell 5.1's .NET Framework does not use HTTP_PROXY by default.
# This sets the default only for the running process.
$sessionProxy = New-Object Net.WebProxy($env:CAGE_LITE_PROXY, $false)
$sessionProxy.Credentials = New-Object Net.NetworkCredential($env:CAGE_LITE_USER, $env:CAGE_LITE_PASSWORD)
[Net.WebRequest]::DefaultWebProxy = $sessionProxy
