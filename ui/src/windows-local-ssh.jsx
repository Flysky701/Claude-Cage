import React, { useState } from "react";
import { WindowsLocalTerminalPane } from "./windows-local-account";

export function WindowsLocalSSH({ network, onNetwork }) {
  const [host, setHost] = useState("");
  const [port, setPort] = useState("22");
  const [user, setUser] = useState("");
  const [hostKey, setHostKey] = useState("");
  const [command, setCommand] = useState("");
  function run(event, send) {
    event.preventDefault();
    if (!network?.open) return;
    const spec = {host:host.trim(), port, user:user.trim(), hostKey:hostKey.trim(), command};
    const payload = btoa(String.fromCharCode(...new TextEncoder().encode(JSON.stringify(spec))));
    send("& $env:CAGE_SSH_CLIENT ssh-run " + payload + "; [Console]::WriteLine(('SSH exit {0}' -f $LASTEXITCODE))",
      spec.user + "@" + spec.host + "> " + command);
  }
  return <WindowsLocalTerminalPane sshControls={(send, ready) => <section className="native-service native-ssh-client">
    <p>输入目标主机提供的 SSH 公钥。每次运行一条远程命令，使用专用 Windows 账户的密钥认证。</p>
    {!network?.open && <p role="status">{network?.message || "请先选择 Cage 代理节点。"} <button onClick={onNetwork}>网络与代理</button></p>}
    <button disabled={!ready} onClick={() => send("& $env:CAGE_SSH_CLIENT ssh-key", "专用账户公钥")}>创建或查看专用账户公钥</button>
    <small>首次使用时，将输出的公钥添加到目标主机的授权列表。</small>
    <form className="native-ssh-form" onSubmit={e => run(e, send)}>
      <label>主机<input required maxLength={253} value={host} onChange={e => setHost(e.target.value)} placeholder="域名或 IPv4 地址" /></label>
      <label>端口<input required type="number" min="1" max="65535" value={port} onChange={e => setPort(e.target.value)} /></label>
      <label>用户<input required maxLength={64} value={user} onChange={e => setUser(e.target.value)} autoComplete="off" /></label>
      <label>主机公钥<input required maxLength={3500} value={hostKey} onChange={e => setHostKey(e.target.value)} placeholder="ssh-ed25519 …" /></label>
      <label>远程命令<input required maxLength={4096} value={command} onChange={e => setCommand(e.target.value)} autoComplete="off" /></label>
      <button disabled={!ready || !network?.open}>连接并运行</button>
    </form>
  </section>} />;
}
