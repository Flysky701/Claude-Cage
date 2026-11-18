import React, { useEffect, useRef, useState } from "react";
import { CircleUserRound, FolderOpen, Globe2, Home, Monitor, Network, PanelLeftOpen, Plus, Server, ShieldCheck, SquareTerminal, X, Code2 } from "lucide-react";
import { api } from "./api";
import { guestCapability } from "./guest-capabilities.mjs";
import { WindowsLocalBrowserPane } from "./windows-local-browser";
import { WindowsLocalAppPane, WindowsLocalDesktopImport } from "./windows-local-apps";
import { WindowsLocalSSH } from "./windows-local-ssh";
import { WindowsLocalServices } from "./windows-local-services";
import { WindowsLocalStatus } from "./windows-local-status";
import "./windows-local-workbench.css";

export const windowsPageNames = {
  home: ["工作台", Home], new: ["新标签页", Plus], projects: ["连接主机项目", FolderOpen],
  terminal: ["PowerShell", SquareTerminal], browser: ["浏览器", Globe2], editor: ["Visual Studio Code", Code2],
  desktop: ["Claude Desktop", Monitor], accounts: ["Claude 账号管理", CircleUserRound],
  "ssh-client": ["SSH", Server], tailnet: ["Tailscale", Network], status: ["Windows 本地账户", ShieldCheck],
};
const home = { id: "local-home", kind: "home", title: "工作台" };
export function WindowsLocalWorkbench({ status, collapsed, setCollapsed, settingsOpen, connectionError, onSettings,
  onConfirm, notify, onRefresh, toast, tabs, selected, open, close, select, renderTerminal, newTerminal, terminalMenuAt, project }) {
  const network = status.local_network || {};
  const current = tabs.find(tab => tab.id === selected) || home;
  const strip = useRef(null);
  const [sshView, setSSHView] = useState(false);
  function incomingSSH() { setSSHView(true); open("tailnet"); }
  function selectTailnet() { setSSHView(false); open("tailnet"); }
  useEffect(() => { strip.current?.querySelector('[aria-selected="true"]')?.scrollIntoView({block: "nearest", inline: "nearest"}); }, [current.id]);
  const networkSettings = () => onSettings("network");
  function content(tab, visible) {
    const { kind, target } = tab;
    if (kind === "home" || kind === "new") return <section className="local-launcher">
      <h1>{kind === "home" ? "Windows 本地工作台" : "新标签页"}</h1>
      <div className="local-launch-grid">{["projects", "terminal", "browser", "editor", "desktop", "accounts", "tailnet", "ssh-client", "status"].map(page => {
        const [label, Icon] = windowsPageNames[page];
        if (page === "terminal") return <div className="local-terminal-choice" key={page}><button aria-haspopup="menu" data-terminal-location={"launcher-" + tab.id}
          onClick={event => newTerminal(project, event.currentTarget)}><Icon size={19}/>新建终端</button>{terminalMenuAt("launcher-" + tab.id)}</div>;
        return <button key={page} onClick={() => page === "tailnet" ? selectTailnet() : open(page)}><Icon size={19}/>{page === "projects" ? "打开项目" : label}</button>;
      })}</div>
    </section>;
    if (kind === "terminal") return renderTerminal(tab, visible);
    if (kind === "status") return <WindowsLocalStatus status={status} active={visible} onOpen={open} onNetwork={networkSettings}/>;
    const capability = { accounts: "claude-accounts", tailnet: "tailscale", "ssh-client": "terminal" }[kind] || kind;
    if (!guestCapability(status, capability)) return <section className="native-service"><h2>{windowsPageNames[kind][0]}</h2>
      <p>当前隔离账户尚未就绪或缺少此组件。</p>
      {kind === "desktop" && <WindowsLocalDesktopImport selected={Boolean(network.selected)} visible={visible} onInstalled={onRefresh}/>}
      <button onClick={async () => { try { await api("/windows-local/status"); await onRefresh(); } catch (error) { notify(error.message); } }}>重新检查</button>
      <button onClick={() => open("status")}>查看账户状态</button></section>;
    if (kind === "browser") return <WindowsLocalBrowserPane initialURL={target} navigation={tab.navigation} active={visible}/>;
    if (kind === "editor" || kind === "desktop") return <WindowsLocalAppPane app={kind} project={tab.workspace === "~" ? "" : tab.workspace} active={visible}/>;
    if (kind === "ssh-client") return <><nav className="native-ssh-nav"><button onClick={incomingSSH}>其他设备登录本机</button></nav>
      <WindowsLocalSSH active={visible} onExit={() => close(tab, true)} network={network} onNetwork={networkSettings}/></>;
    if (kind === "tailnet" || kind === "accounts") return <>{kind === "tailnet" && sshView &&
      <nav className="native-ssh-nav"><button onClick={() => open("ssh-client")}>连接远程主机</button><button onClick={selectTailnet}>返回 Tailscale</button></nav>}
      <WindowsLocalServices service={kind} sshView={kind === "tailnet" && sshView} onSSH={incomingSSH} active={visible}
        onConfirm={onConfirm} network={Boolean(network.open)} networkMessage={network.message} onNetwork={networkSettings}/></>;
  }
  const visibleTabs = [home, ...tabs];
  return <main className="workbench-main local-workbench">
      <header className="local-tab-bar">
        {collapsed && <button className="icon-button" title="展开侧栏" aria-label="展开侧栏" onClick={() => setCollapsed(false)}><PanelLeftOpen size={17}/></button>}
        <div ref={strip} role="tablist" aria-label="工作台标签" className="local-tab-strip">{visibleTabs.map((tab, index) => {
          const Icon = windowsPageNames[tab.kind][1];
          return <div key={tab.id} className="local-tab" data-current={current.id === tab.id}>
            <button id={tab.id} role="tab" aria-controls={tab.id + "-panel"} aria-selected={current.id === tab.id} tabIndex={current.id === tab.id ? 0 : -1}
              title={tab.workspace && tab.workspace !== "~" ? tab.workspace : tab.title} onClick={() => select(tab.id)}
              onKeyDown={e => {
                const next = { ArrowLeft: index - 1, ArrowRight: index + 1, Home: 0, End: visibleTabs.length - 1 }[e.key];
                if (next === undefined) return;
                e.preventDefault(); const id = visibleTabs[(next + visibleTabs.length) % visibleTabs.length].id; select(id); document.getElementById(id)?.focus();
              }}><Icon size={14}/><span>{tab.title}</span></button>
            {tab.kind !== "home" && <button className="local-tab-close" aria-label={"关闭 " + tab.title} onClick={() => close(tab)}><X size={13}/></button>}
          </div>;
        })}</div><button className="icon-button" aria-label="新建标签页" title="新建标签页" onClick={() => open("new")}><Plus size={17}/></button>
      </header>
      {connectionError && <div className="connection-banner" role="alert">工作台连接中断，正在重新连接。</div>}
      {visibleTabs.map(tab => <div key={tab.id} id={tab.id + "-panel"} role="tabpanel" aria-labelledby={tab.id}
        hidden={current.id !== tab.id} className="local-tab-panel">{content(tab, current.id === tab.id && !settingsOpen)}</div>)}
      <footer className="status-bar">
        <button onClick={networkSettings}>{network.open ? "已连接所选节点" : network.selected ? "已选择 Cage 节点" : "选择 Cage 节点"}</button>
        <span className="status-spacer"/><span role="status" className="status-feedback">{toast}</span>
      </footer>
    </main>;
}
