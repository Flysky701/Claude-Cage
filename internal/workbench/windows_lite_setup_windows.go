//go:build windows

package workbench

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"unicode/utf16"

	"github.com/sylvinus/agent-vm/internal/host"
)

func litePSLiteral(value string) string { return "'" + strings.ReplaceAll(value, "'", "''") + "'" }

func checkWindowsLiteInstaller(ctx context.Context, record string) error {
	if _, err := os.Stat(record); os.IsNotExist(err) {
		return nil
	}
	return runLitePowerShell(ctx, `$ErrorActionPreference='Stop'
$record=`+litePSLiteral(record)+`
if(Test-Path -LiteralPath $record) {
 $prior=Get-Content -LiteralPath $record -Raw | ConvertFrom-Json
 $running=Get-Process -Id $prior.pid -ErrorAction SilentlyContinue
 if($running -and $running.StartTime.ToUniversalTime().Ticks.ToString() -eq $prior.started) { throw '之前的安装程序仍在运行，请完成系统授权或等待安装结束后再试。' }
}
`)
}

func runLitePowerShell(ctx context.Context, script string) error {
	encoded := utf16.Encode([]rune(script))
	data := make([]byte, len(encoded)*2)
	for i, value := range encoded {
		binary.LittleEndian.PutUint16(data[i*2:], value)
	}
	cmd := exec.CommandContext(ctx, filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe"), "-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand", base64.StdEncoding.EncodeToString(data))
	host.HideCommandWindow(cmd)
	output, err := cmd.CombinedOutput()
	if err != nil {
		if ctx.Err() != nil {
			return errors.New("安装检查已取消；系统安装程序可能仍在运行，请等待它结束后重试，空间数据保留")
		}
		message := strings.TrimSpace(string(output))
		if len(message) > 1200 {
			message = message[:1200]
		}
		return fmt.Errorf("轻量沙箱安装未完成：%s", message)
	}
	return nil
}

func installWindowsLitePackage(ctx context.Context, packagePath, directory, logPath, digest string) error {
	script := `$ErrorActionPreference='Stop'
$package=` + litePSLiteral(packagePath) + `
$destination=` + litePSLiteral(directory) + `
$log=` + litePSLiteral(logPath) + `
$record=Join-Path (Split-Path $log) 'installer-running.json'
if(Test-Path -LiteralPath $record) {
  $prior=Get-Content -LiteralPath $record -Raw | ConvertFrom-Json
  $running=Get-Process -Id $prior.pid -ErrorAction SilentlyContinue
  if($running -and $running.StartTime.ToUniversalTime().Ticks.ToString() -eq $prior.started) { throw '之前的安装程序仍在运行，请先完成系统授权或等待安装结束。' }
}
if((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash.ToLowerInvariant() -ne ` + litePSLiteral(digest) + `) { throw '安装包校验失败，未执行。' }
$signature=Get-AuthenticodeSignature -LiteralPath $package
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notlike '*O=NOVASYNC LABS PTE. LTD.*') { throw '官方安装包签名校验未通过，未执行。' }
$arguments=@('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART','/TASKS=""',('/DIR="'+$destination+'"'),('/LOG="'+$log+'"'))
try { $installer=Start-Process -FilePath $package -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru }
catch { throw 'Windows 管理员授权未完成，请点击重新安装并确认系统授权。' }
@{pid=$installer.Id;started=$installer.StartTime.ToUniversalTime().Ticks.ToString()} | ConvertTo-Json | Set-Content -LiteralPath $record -Encoding UTF8
$installer.WaitForExit()
Remove-Item -LiteralPath $record -ErrorAction SilentlyContinue
if($installer.ExitCode -eq 3010) { throw '组件已安装，Windows 要求重新启动后再检查；不会自动重启电脑。' }
if($installer.ExitCode -ne 0) { throw ('官方安装程序返回错误 '+$installer.ExitCode+'，请查看安装记录。') }
`
	return runLitePowerShell(ctx, script)
}

func startWindowsLiteServices(ctx context.Context) error {
	return runLitePowerShell(ctx, `$ErrorActionPreference='Stop'
$service=Get-Service -Name SbieSvc -ErrorAction Stop
if($service.Status -ne 'Running') {
  try { $starter=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\sc.exe') -ArgumentList @('start','SbieSvc') -Verb RunAs -WindowStyle Hidden -PassThru -Wait }
  catch { throw '启动隔离服务需要 Windows 管理员授权。' }
  $service.WaitForStatus('Running',[TimeSpan]::FromSeconds(20))
}
`)
}
