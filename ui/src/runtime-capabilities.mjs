export function isWindowsLite(status) {
  return status?.runtime_kind === "windows-lite" || status?.guest_system === "windows-lite";
}

export function workbenchCapabilities(status) {
  const lite = isWindowsLite(status);
  const supports = name => !lite || status?.runtime_capabilities?.[name] === true;
  return {
    lite,
    browser: supports("embedded_browser"),
    terminals: supports("terminal_stream"),
    claudeTerminal: supports("claude_terminal"),
    terminalLogin: supports("terminal_login"),
    cliSessions: supports("cli_sessions"),
    editor: supports("embedded_editor"),
    desktop: supports("embedded_desktop"),
    audio: supports("audio"),
    clipboard: supports("shared_clipboard"),
    files: supports("file_transfer"),
    projects: supports("project_sharing"),
  };
}

export function terminalCapability(status, kind) {
  const capabilities = workbenchCapabilities(status);
  if (!capabilities.terminals) return false;
  if (kind === "shell") return true;
  if (kind === "claude") return capabilities.claudeTerminal;
  if (kind === "claude-login") return capabilities.terminalLogin;
  return !capabilities.lite;
}

export function windowsLiteMonitor(status, now = Date.now()) {
  const monitor = status?.windows_lite?.monitor || {};
  const checkedAt = Date.parse(monitor.lastCheckedAt);
  const validUntil = Date.parse(monitor.validUntil);
  const valid = monitor.phase === "healthy" && Number.isFinite(checkedAt) && Number.isFinite(validUntil) && checkedAt <= now + 5000 && validUntil > now;
  const phase = monitor.phase === "healthy" && !valid ? "expired" : monitor.phase || "unknown";
  return { ...monitor, phase, valid, reason: phase === "expired" ? "应用监控结果已失效，重新检查通过前禁止运行。" : monitor.reason || (valid ? "应用正在持续监控沙箱与网络出口。" : "尚未取得有效的应用监控结果，运行保持关闭。") };
}

export function windowsLiteAdmitted(status, now = Date.now()) {
  return isWindowsLite(status) && status.ready === true && status.vm_running === true &&
    !(status.job?.running && ["start", "windows-lite-setup"].includes(status.job.kind)) &&
    status.windows_lite?.phase === "running" && status.windows_lite?.acceptance === "verified" && status.windows_lite?.network === "open" &&
    status.runtime_capabilities?.sandbox_verified === true && status.runtime_capabilities?.network_verified === true && windowsLiteMonitor(status, now).valid;
}
