import React, { useEffect, useMemo, useRef, useState } from "react";
import { runtimeSocketURL } from "./client-context.mjs";
import { WindowsLocalBrowserPane } from "./windows-local-browser";

// The authorization page shares the service's worker and its selected proxy.
// Closing this embedded view leaves the pending sign-in process in place.
function loginBridge(socket) {
  const target = new EventTarget();
  const emit = data => target.dispatchEvent(new MessageEvent("message", { data: JSON.stringify(data) }));
  return {
    get readyState() { return socket.readyState; },
    send(raw) {
      if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: "browser", event: JSON.parse(raw) }));
    },
    addEventListener(name, listener) {
      target.addEventListener(name, listener);
      if (name === "message") queueMicrotask(() => listener(new MessageEvent("message", { data: '{"type":"ready"}' })));
    },
    removeEventListener: (...args) => target.removeEventListener(...args),
    emit,
  };
}

function NodeSSH({ data, disabled, send }) {
  const [pubkey, setPubkey] = useState("");
  const ips = data.ips || [];
  const keys = data.keys || [];
  const connected = data.backend === "Running";
  const address = ips.find(ip => ip.includes(".")) || ips[0];
  const validUser = /^[\w.-]+$/.test(data.user || "");
  return <>
    <p>同一 Tailscale 网络中的设备可通过公钥登录这个 Windows 账户。</p>
    <dl className="native-ssh-address">
      <dt>SSH 用户</dt><dd>{data.user || "暂未读取"}</dd>
      <dt>端口</dt><dd>{data.ssh_port || "暂未读取"}</dd>
      <dt>本节点地址</dt><dd>{connected && ips.length ? ips.join(" · ") : "连接私网后显示"}</dd>
      {connected && data.name && <><dt>节点域名</dt><dd>{data.name}</dd></>}
    </dl>
    {connected && address && validUser && data.ssh_port > 0 &&
      <p>在已授权的设备运行 <code>{`ssh -p ${data.ssh_port} ${data.user}@${address}`}</code></p>}
    <form onSubmit={e => { e.preventDefault(); if (!disabled && pubkey.trim()) send("add-key", {key:pubkey.trim()}); }}>
      <label>允许登录的 SSH 公钥 <input value={pubkey} maxLength={3500} placeholder="ssh-ed25519 …" onChange={e => setPubkey(e.target.value)} /></label>
      <button disabled={disabled || !pubkey.trim() || keys.includes(pubkey.trim())}>添加公钥</button>
    </form>
    {keys.length === 0 ? <small>尚未授权任何 SSH 公钥。</small> :
      keys.map(key => <p className="native-ssh-key" key={key}><code>{key}</code> <button disabled={disabled} onClick={() => send("remove-key", {key})}>移除公钥</button></p>)}
  </>;
}

export function WindowsLocalServices({ service, network, networkMessage, onNetwork, sshView, onSSH, onConfirm }) {
  const accounts = service === "accounts";
  const [data, setData] = useState(null);
  const [connection, setConnection] = useState(null);
  const [attempt, setAttempt] = useState(0);
  const [busy, setBusy] = useState(true);
  const [closed, setClosed] = useState(false);
  const [error, setError] = useState("");
  const [label, setLabel] = useState("");
  const [code, setCode] = useState("");
  const [loginURL, setLoginURL] = useState("");
  const bridge = useMemo(() => connection && loginBridge(connection), [connection]);
  const bridgeRef = useRef(bridge);
  bridgeRef.current = bridge;

  useEffect(() => {
    let live = true;
    const socket = new WebSocket(runtimeSocketURL("/windows-local/services/" + service));
    setData(null); setConnection(null); setBusy(true); setClosed(false); setError(""); setLoginURL("");
    socket.onmessage = event => {
      if (!live) return;
      const frame = JSON.parse(event.data);
      if (frame.type === "ready") {
        setConnection(socket);
        socket.send(JSON.stringify({ type: "status" }));
      } else if (frame.type === "browser") {
        bridgeRef.current?.emit(frame.data);
      } else if (frame.type === "state") {
        if (accounts) setData(previous => ({ ...previous, usage: null, ...frame.data }));
        else if (!frame.data.error) setData(frame.data);
        setBusy(false); setError(frame.data.error || "");
      } else if (frame.type === "error" || frame.type === "notice") {
        setError(frame.message); setBusy(false);
      }
    };
    socket.onclose = () => {
      if (live) { setConnection(null); setBusy(false); setClosed(true); setLoginURL(""); }
    };
    return () => { live = false; socket.close(); };
  }, [service, attempt]);
  const send = (type, fields) => {
    if (connection?.readyState !== WebSocket.OPEN || busy) return;
    setBusy(true); setError("");
    connection.send(JSON.stringify({ type, ...fields }));
  };
  useEffect(() => {
    if (!connection || busy || !(accounts ? data?.signing_in : data?.enabled)) return;
    const timer = setTimeout(() => send(accounts ? "poll" : "status"), 2400);
    return () => clearTimeout(timer);
  }, [connection, busy, data, accounts]);
  function openLogin() {
    try {
      const url = new URL(data.auth_url);
      const hosts = accounts ? ["claude.ai", "platform.claude.com", "console.anthropic.com"] : ["login.tailscale.com"];
      if (url.protocol !== "https:" || url.username || url.password || url.port || !hosts.includes(url.hostname)) throw new Error();
      setLoginURL(url.href);
    } catch { setError("组件返回的登录页面地址无效。"); }
  }
  return <section className="native-service" aria-label={accounts ? "隔离 Claude 账号" : "隔离 Tailscale 节点"}>
    {error && <p role="alert" className="error-message">{error}</p>}
    {closed ? <button onClick={() => setAttempt(n => n + 1)}>重新连接</button>
      : !data && (error ? <button disabled={busy} onClick={() => send("status")}>重试读取状态</button> : <p role="status">正在读取隔离账户中的{accounts ? "Claude 登录状态" : "私网节点"}…</p>)}
    {!network && <p>{networkMessage || "联网需要在本原型中手动选择并应用节点。"} <button onClick={onNetwork}>网络与代理</button></p>}
    {data && accounts && <>
      <label>当前 Claude 账号 <select disabled={busy || data.signing_in} value={data.selected} onChange={e => send("select", { profile: e.target.value })}>
        {data.profiles?.map(item => <option value={item.id} key={item.id}>{item.label}</option>)}
      </select></label>
      <p role="status">{data.identity?.loggedIn ? ["已登录", data.identity.email, data.identity.subscriptionType].filter(Boolean).join(" · ") : "尚未登录 Claude"}</p>
      <form onSubmit={e => { e.preventDefault(); if (label.trim()) { send("add", {label: label.trim()}); setLabel(""); } }}>
        <label>新账号名称 <input value={label} maxLength={64} onChange={e => setLabel(e.target.value)} /></label>
        <button disabled={busy || data.signing_in || !label.trim()}>添加账号</button>
      </form>
      <small>切换账号后，新打开的 PowerShell 中的 Claude Code 会使用所选档案。</small>
      <div><button disabled={busy || !network || data.signing_in} onClick={() => send("login")}>登录所选账号</button>
        <button disabled={busy || !network || !data.identity?.loggedIn || data.signing_in} onClick={() => send("usage")}>查询额度</button>
        <button disabled={busy} onClick={() => send("status")}>刷新登录状态</button>
        {data.identity?.loggedIn && <button disabled={busy || data.signing_in} onClick={async () => {
          if (await onConfirm({title: "退出当前 Claude 账号？", body: data.identity.email || "所选档案需要重新登录才能使用 Claude。", confirm: "退出登录"})) send("logout");
        }}>退出当前账号</button>}</div>
      {data.usage && <p role="status">{Object.keys(data.usage).length ? [
        data.usage.five_hour != null && `近五小时已用 ${data.usage.five_hour}%`,
        data.usage.seven_day != null && `近七天已用 ${data.usage.seven_day}%`,
      ].filter(Boolean).join(" · ") : "Claude 未提供此账号的额度数据。"}</p>}
      {data.signing_in && <form onSubmit={e => { e.preventDefault(); send("code", {code}); setCode(""); }}>
        <label>若授权页面给出返回码，在此输入 <input type="password" autoComplete="off" value={code} onChange={e => setCode(e.target.value)} /></label>
        <button disabled={!code || busy}>提交返回码</button>
      </form>}
    </>}
    {data && !accounts && !closed && <>
      <p role="status">{({ Stopped:"未连接", Running:"已连接", NeedsLogin:"等待登录", NeedsMachineAuth:"等待批准", Starting:"正在连接" })[data.backend] || data.backend}
        {data.tailnet && " · " + data.tailnet}</p>
      <div><button disabled={busy || !network || data.backend === "Running"} onClick={() => send("connect")}>连接并登录</button>
        <button disabled={busy || !data.enabled} onClick={() => send("disconnect")}>断开连接</button>
        <button disabled={busy} onClick={() => send("status")}>刷新状态</button></div>
      {sshView ? <NodeSSH data={data} disabled={busy || !connection} send={send} /> : <>
        {data.backend === "Running" && data.ips?.length > 0 && <p>本节点地址　{data.ips.join(" · ")}</p>}
        {(data.peers || []).map(peer => <p key={peer.id || peer.ip}>{peer.name} · {peer.ip} · {peer.online ? "在线" : "离线"}</p>)}
        <button onClick={onSSH}>SSH 连接设置</button>
      </>}
      <small>关闭此页面会停止节点会话。设备身份保存在专用 Windows 账户中。</small>
    </>}
    {data?.auth_url && !closed && !loginURL && <button disabled={!network} onClick={openLogin}>在隔离浏览器中完成登录</button>}
    {loginURL && bridge && <><button onClick={() => {setLoginURL(""); send("status");}}>返回登录状态</button>
      <div className="native-service-login"><WindowsLocalBrowserPane initialURL={loginURL} bridge={bridge}/></div></>}
  </section>;
}
