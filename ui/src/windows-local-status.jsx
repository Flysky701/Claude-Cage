import React, { useEffect, useState } from "react";
import { ChevronRight, RefreshCw } from "lucide-react";
import { api } from "./api";
import "./windows-local-workspace.css";

const capabilities = [
  ["terminal", "PowerShell"], ["projects", "主机项目"],
  ["browser", "Edge 浏览器", "browser_installed"], ["editor", "VS Code", "editor_installed"],
  ["desktop", "Claude Desktop", "desktop_installed"], ["accounts", "Claude 账号管理", "cli_installed"],
  ["tailnet", "Tailscale", "tailnet_installed"], ["ssh-client", "SSH"],
];

function egressLabel(network, proxy) {
  if (network?.open) return "已核验并放行";
  if (!network) return "等待读取";
  if (!network.selected) return "离线 · 未选择节点";
  if (proxy && !proxy.active) return "离线 · 节点尚未应用";
  if (proxy && !proxy.running) return "离线 · 代理已停止";
  if (network.in_use) return network.message || "应用尚未联网";
  if (!proxy) return "等待读取代理";
  return "空闲 · 打开隔离应用时核验出口";
}

export function WindowsLocalStatus({ status, active = true, onOpen, onNetwork }) {
  const [receipt, setReceipt] = useState(null);
  const [proxy, setProxy] = useState(null);
  const [accountError, setAccountError] = useState("");
  const [proxyError, setProxyError] = useState("");
  const [checking, setChecking] = useState(false);
  const [revision, setRevision] = useState(0);
  const network = status?.local_network;

  useEffect(() => {
    if (!active) return;
    const controller = new AbortController();
    setChecking(true);
    setAccountError("");
    api("/windows-local/status", undefined, "GET", {}, { signal: controller.signal })
      .then(result => { if (!controller.signal.aborted) setReceipt(result); })
      .catch(err => { if (!controller.signal.aborted) { setReceipt(null); setAccountError(err.message); } })
      .finally(() => { if (!controller.signal.aborted) setChecking(false); });
    return () => controller.abort();
  }, [active, revision]);

  useEffect(() => {
    if (!active) return;
    const controller = new AbortController();
    setProxyError("");
    api("/proxy", undefined, "GET", {}, { signal: controller.signal })
      .then(result => { if (!controller.signal.aborted) setProxy(result); })
      .catch(err => { if (!controller.signal.aborted) { setProxy(null); setProxyError(err.message); } });
    return () => controller.abort();
  }, [active, revision, network?.open, network?.selected]);

  const node = proxy?.sources?.flatMap(source => source.nodes || []).find(item => item.id === proxy.selected);
  const accountName = receipt?.worker_username || (checking ? "正在核验…" : "未能核验账户");
  return <section className="windows-local-workspace" aria-label="Windows 本地账户状态">
    <div className="windows-local-content">
      <header className="windows-status-heading"><div><h2>{accountName}</h2>
        <p className="windows-local-help">Windows 专用标准账户</p></div>
        <button type="button" onClick={() => setRevision(value => value + 1)} disabled={checking}><RefreshCw size={15}/>重新检查</button>
      </header>
      {(accountError || (receipt && !receipt.available)) && <p role="alert" className="error-message">{accountError || receipt.message}</p>}
      <dl className="windows-status-facts">
        <div><dt>网络隔离规则</dt><dd>{receipt?.rules_verified ? "7 / 7 已核验" : checking ? "正在核验…" : "未核验"}</dd></div>
        <div><dt>已选 Cage 节点</dt><dd>{node ? <>{node.name} <small>{node.type}</small></> :
          proxyError ? "无法读取" : !proxy ? "正在读取…" : proxy.selected ? "找不到已选节点" : "未选择"}</dd></div>
        <div><dt>应用网络出口</dt><dd>{egressLabel(network, proxy)}</dd></div>
      </dl>
      {proxyError && <p role="alert" className="error-message">{proxyError}</p>}
      <button type="button" onClick={onNetwork}>网络与代理</button>
      <h3>应用与功能</h3>
      <ul className="windows-status-tools">{capabilities.map(([page, label, key]) => {
        const installed = receipt?.available && (!key || receipt[key]);
        const detail = !receipt?.available ? "待核验" : !key ? "打开" :
          installed ? "已安装" : page === "desktop" ? "准备安装" : "未安装";
        return <li key={page}><button type="button" onClick={() => onOpen?.(page)}>
          <span>{label}</span><small>{detail}</small><ChevronRight size={15}/>
        </button></li>;
      })}</ul>
    </div>
  </section>;
}
