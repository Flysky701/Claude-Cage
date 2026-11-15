import React, { useEffect, useRef, useState } from "react";
import { Check, CircleAlert, FolderOpen, LoaderCircle, RefreshCw, Settings, Shield } from "lucide-react";
import { api } from "./api";
import { BrowserFavorites } from "./browser-favorites";
import { workbenchCapabilities, windowsLiteAdmitted, windowsLiteMonitor } from "./runtime-capabilities.mjs";
import { SetupProgress } from "./setup-progress";
import { InitializationDetails } from "./initialization-checks";
import { Modal } from "./modal";
export { isWindowsLite } from "./runtime-capabilities.mjs";
import "./windows-lite-panel.css";

const applications = [
  ["browser", "浏览器（含 Claude 网页）"],
  ["claude_desktop", "Claude Desktop"],
  ["shell", "普通终端"],
  ["claude", "Claude 终端"],
  ["editor", "项目编辑器"],
];
const phases = { stopped: "空间已停止", starting: "正在启动空间", running: "空间运行中", blocked: "应用启动受阻", stopping: "正在停止空间", error: "空间需要处理" };

function LiteChecks({ state }) {
  const checks = [...(Array.isArray(state?.checks) ? state.checks : []), ...(Array.isArray(state?.monitor?.checks) ? state.monitor.checks : [])];
  return <details className="windows-lite-checks">
    <summary>组件与应用监控检查 <span>{checks.filter(item => item.ok === true).length} / {checks.length}</span></summary>
    {checks.length ? <ul>{checks.map((item, index) => <li key={`${item.id}-${index}`}>
      {item.ok === true ? <Check size={16} /> : <CircleAlert size={16} />}
      <div><strong>{item.label}</strong>{item.message && <p>{item.message}</p>}</div>
      <small>{item.ok === true ? "已通过" : "待处理"}</small>
    </li>)}</ul> : <p className="field-help">尚未收到检查结果，请重新检查。</p>}
  </details>;
}

export function WindowsLiteMonitorDetails({ status, now = Date.now(), disconnected }) {
  const monitor = windowsLiteMonitor(status, now);
  const admitted = !disconnected && windowsLiteAdmitted(status, now);
  const formatTime = value => Number.isFinite(Date.parse(value)) ? new Date(value).toLocaleString("zh-CN", { hour12: false }) : "尚无记录";
  return <div className="modal-body">
    <h3>{admitted ? "应用监控有效" : monitor.phase === "checking" ? "应用正在检查" : "运行保持关闭"}</h3>
    <p>{disconnected ? "监控连接中断，不能确认当前沙箱与网络状态。" : monitor.reason}</p>
    <div className="setting-summary-row"><span>最近检查</span><strong>{formatTime(monitor.lastCheckedAt)}</strong></div>
    <div className="setting-summary-row"><span>有效至</span><strong>{formatTime(monitor.validUntil)}</strong></div>
    <p className="field-help">Cage 自身持续检查沙箱与出口。结果失效或检查失败会阻断运行，重新检查通过后才恢复。</p>
    <LiteChecks state={status.windows_lite} />
  </div>;
}

export function WindowsLiteHome({ status, monitorNow = Date.now(), disconnected, busy, onCheck, onStart, onSettings, onProject, onOpenPage }) {
  const state = status.windows_lite;
  const features = workbenchCapabilities(status);
  const monitor = windowsLiteMonitor(status, monitorNow);
  const admitted = !disconnected && windowsLiteAdmitted(status, monitorNow);
  const supported = [[features.browser, "浏览器与 Claude 网页"], [features.terminals, "普通终端"], [features.claudeTerminal && features.terminals, "Claude 终端"], [features.editor, "项目编辑器"], [features.desktop, "Claude Desktop"]];
  const network = disconnected || (!admitted && state?.network === "open") ? "unknown" : state?.network;
  const checkTime = value => Number.isFinite(Date.parse(value)) ? new Date(value).toLocaleTimeString("zh-CN", { hour12: false }) : "尚无记录";
  const monitorLabel = disconnected ? "监控连接中断" : { healthy: "应用持续监控中", checking: "应用正在检查", blocked: "应用已阻断运行", stopped: "监控已停止", expired: "监控结果已失效", error: "监控异常", unknown: "监控尚未就绪" }[monitor.phase] || "监控尚未就绪";
  return <section className="windows-lite-overview" aria-label="Windows 轻量空间">
    <h1>Windows 轻量空间</h1>
    <p className="welcome-subtitle">在同一个 Cage 工作台管理账户、代理和项目，继续使用原来的应用入口。</p>
    <div className="start-project-box">
      <div className="environment-summary"><Shield size={24} /><span>
        <strong>{disconnected ? "后台连接中断" : phases[state?.phase] || "正在读取空间状态"}</strong>
        <small>{disconnected ? "空间与网络状态尚未确认" : state?.message || "等待后台返回运行条件。"}</small>
      </span></div>
      <div className="windows-lite-facts">
        <span>网络 <strong>{network === "open" ? "出口已连接" : network === "closed" ? "联网已关闭" : "出口待确认"}</strong></span>
        <span>空间进程 <strong>{disconnected || !Number.isFinite(state?.processCount) || state.processCount < 0 ? "—" : state.processCount}</strong></span>
      </div>
      <div className="start-project-footer">
        <button onClick={onSettings} disabled={busy}><Settings size={16} />配置运行组件</button>
        <button className="primary" disabled={busy || disconnected || !state} onClick={status.vm_running ? onCheck : onStart}>
          {busy ? <LoaderCircle size={16} className="spin" /> : <RefreshCw size={16} />}
          {status.vm_running ? "重新检查空间" : "检查并启动"}
        </button>
      </div>
    </div>
    <section className="windows-lite-monitor" aria-label="应用实时监控" aria-live="polite">
      <strong>{monitorLabel}</strong>
      <div className="windows-lite-facts"><span>最近检查 <time dateTime={monitor.lastCheckedAt}>{checkTime(monitor.lastCheckedAt)}</time></span><span>有效至 <time dateTime={monitor.validUntil}>{checkTime(monitor.validUntil)}</time></span></div>
      <p>{disconnected ? "当前无法确认应用监控状态，浏览器和终端入口保持关闭。" : monitor.reason}</p>
    </section>
    <div className="windows-lite-capabilities">
      <p><strong>工作台管理</strong><span>账户、密码保险箱、外观、代理来源、项目记录与诊断使用 Cage 原有设置。</span></p>
      <p><strong>当前支持</strong><span>{supported.filter(([available]) => available).map(([, label]) => label).join("、") || "等待应用检查提供当前可用能力。"}{supported.some(([available]) => available) && "。监控有效时使用原侧栏入口打开。"}</span></p>
      {supported.some(([available]) => !available) && <p><strong>暂不可用</strong><span>{supported.filter(([available]) => !available).map(([, label]) => label).join("、")}。开放状态以对应适配和应用自身检查结果为准。</span></p>}
      <button className="text-button" onClick={onProject} disabled={busy}><FolderOpen size={15} />管理项目文件夹</button>
      <div className="windows-lite-favorites"><BrowserFavorites ready={features.browser && admitted && !busy} onOpen={onOpenPage} shortcuts={!busy} /><span>收藏夹 · 整理已保存的网站</span></div>
    </div>
    <LiteChecks state={state} />
    <p className="windows-lite-profile"><FolderOpen size={14} /><span>持久空间：{state?.profile || "读取中…"}</span></p>
  </section>;
}

function makeDraft(settings = {}) {
  return {
    sandboxieDirectory: settings.sandboxieDirectory || "",
    proxyCore: settings.proxyCore || "",
    applications: Object.fromEntries(applications.map(([id]) => [id, {
      program: settings.applications?.[id]?.program || "",
      argumentsText: (settings.applications?.[id]?.arguments || []).join("\n"),
    }])),
  };
}

export function WindowsLiteSettings({ status, onDirtyChange, onBusyChange, onSaved, onConfirm }) {
  const [state, setState] = useState(status.windows_lite);
  const [draft, setDraft] = useState(() => makeDraft(status.windows_lite?.settings));
  const [dirty, setDirty] = useState(false);
  const [pending, setPending] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [acceptedSetup, setAcceptedSetup] = useState(null);
  const [acceptedCheck, setAcceptedCheck] = useState(null);
  const [setupDetails, setSetupDetails] = useState(false);
  const alive = useRef(true);
  const dirtyRef = useRef(false);
  useEffect(() => {
    alive.current = true;
    api("/windows-lite").then(result => {
      if (!alive.current) return;
      setState(result.state);
      if (!dirtyRef.current) setDraft(makeDraft(result.state?.settings));
    }).catch(failure => { if (alive.current) setError(failure.message); });
    return () => { alive.current = false; onDirtyChange(false); onBusyChange(false); };
  }, [onDirtyChange, onBusyChange]);
  useEffect(() => {
    if (status.windows_lite) {
      setState(status.windows_lite);
      if (!dirtyRef.current) setDraft(makeDraft(status.windows_lite.settings));
    }
    if (acceptedSetup?.id === status.job?.id) setAcceptedSetup(null);
    if (acceptedCheck?.id === status.job?.id) setAcceptedCheck(null);
  }, [status.windows_lite, status.job?.id, acceptedSetup?.id, acceptedCheck?.id]);
  function change(next) {
    dirtyRef.current = true;
    setDirty(true);
    onDirtyChange(true);
    setNotice("");
    setDraft(next);
  }
  async function perform(operation) {
    if (pending) return;
    setPending(operation);
    onBusyChange(true);
    setError("");
    setNotice("");
    try {
      if (operation === "setup") {
        const result = await api("/windows-lite/setup", {});
        if (!result.id && !result.job_id) throw new Error("未收到组件检查的任务编号，请先核对操作详情。");
        if (!alive.current) return;
        setAcceptedSetup({ ...result, id: result.id || result.job_id, kind: "windows-lite-setup", running: true });
        setNotice("已开始检查并补齐沙箱组件；已有空间与个人数据会保留。");
        await onSaved();
        return;
      }
      const settings = {
        sandboxieDirectory: draft.sandboxieDirectory.trim(), proxyCore: draft.proxyCore.trim(),
        applications: Object.fromEntries(applications.map(([id]) => [id, {
          program: draft.applications[id].program.trim(),
          arguments: draft.applications[id].argumentsText.split(/\r?\n/).filter(value => value.length > 0),
        }])),
      };
      const result = await api(operation === "save" ? "/windows-lite" : "/windows-lite/check", operation === "save" ? { settings } : {});
      if (!alive.current) return;
      if (operation === "check" && result.id) {
        setAcceptedCheck({ ...result, kind: result.kind || "start", running: true });
        setNotice("应用正在自动检查沙箱与网络出口，请等待检查完成。");
        await onSaved();
        return;
      }
      if (result.state) setState(result.state);
      if (operation === "save") {
        dirtyRef.current = false;
        setDirty(false);
        onDirtyChange(false);
        setDraft(makeDraft(result.state?.settings || settings));
      }
      setNotice(operation === "save" ? "轻量空间设置已保存。" : "启动条件已更新，请查看检查结果。");
      await onSaved();
    } catch (failure) {
      if (alive.current) setError(failure.message);
    } finally {
      if (alive.current) { setPending(""); onBusyChange(false); }
    }
  }
  const setupJob = acceptedSetup || (status.job?.kind === "windows-lite-setup" ? status.job : null);
  const checkJob = acceptedCheck || (status.job?.kind === "start" ? status.job : null);
  const checkBusy = Boolean(checkJob?.running);
  const setupBusy = Boolean(setupJob?.running || status.job?.running || checkBusy);
  useEffect(() => { onBusyChange(Boolean(pending) || checkBusy); }, [pending, checkBusy, onBusyChange]);
  async function stopSetup() {
    if (!await onConfirm({ title: "停止 Cage 下载与检查？", body: "Cage 会停止本次下载与检查。已经通过管理员授权启动的官方安装程序可能继续，请等它结束后再重试。原空间、个人数据与已保存的下载会保留。", confirm: "停止 Cage 任务" })) return;
    setError("");
    try { await api("/stop", {}); setAcceptedSetup(null); }
    catch (failure) { setError(failure.message); }
  }
  const editable = Boolean(state) && !pending && !setupBusy && !status.vm_running && state?.processCount === 0 && !["starting", "stopping"].includes(state?.phase);
  return <section className="windows-lite-settings" aria-label="Windows 轻量空间设置">
    <h4>Windows 轻量空间</h4>
    <p className="field-help">为原工作台的应用入口指定本机组件和程序。空间身份与数据持续保留；请先停止空间再修改。</p>
    {state?.profile && <div className="setting-summary-row"><span>空间数据</span><strong title={state.profile}>{state.profile}</strong></div>}
    <div className="setting-summary-row"><span>当前连接配置</span><strong title={state?.settings?.connectionFile}>{state?.settings?.connectionFile || "读取中…"}</strong></div>
    <p className="field-help">轻量空间沿用 Cage 当前连接配置。请在“网络与代理”中保存并应用代理设置，这里不单独指定连接文件。</p>
    <div className="setting-summary-row"><span>当前项目目录</span><strong title={status.workspace}>{status.workspace || "尚未选择项目"}</strong></div>
    <p className="field-help">应用沿用工作台当前项目。返回工作台后，在侧栏“项目”入口添加或选择文件夹。</p>
    <fieldset disabled={!editable}>
      {[
        ["sandboxieDirectory", "Sandboxie 安装目录", "C:\\Program Files\\Sandboxie-Plus"],
        ["proxyCore", "代理程序路径", "Mihomo 程序的完整路径"],
      ].map(([key, label, placeholder]) => <label key={key}>{label}<input value={draft[key]} onChange={event => change(previous => ({ ...previous, [key]: event.target.value }))} placeholder={placeholder} spellCheck={false} autoComplete="off" /></label>)}
      <p className="field-help">此处只配置运行组件；代理密码不会显示在表单中。</p>
      <h4>工作台应用入口</h4>
      {applications.map(([id, label]) => <details key={id} className="windows-lite-app-setting"><summary>{label}<small>{draft.applications[id].program ? "已配置" : "待配置"}</small></summary>
        <label>程序路径<input value={draft.applications[id].program} spellCheck={false} autoComplete="off" onChange={event => change(previous => ({ ...previous, applications: { ...previous.applications, [id]: { ...previous.applications[id], program: event.target.value } } }))} /></label>
        <label>启动参数（每行一个）<textarea rows={3} value={draft.applications[id].argumentsText} spellCheck={false} onChange={event => change(previous => ({ ...previous, applications: { ...previous.applications, [id]: { ...previous.applications[id], argumentsText: event.target.value } } }))} /></label>
      </details>)}
    </fieldset>
    {error && <p className="error-message" role="alert">{error}</p>}
    {notice && <p className="field-help" role="status">{notice}</p>}
    <div className="windows-lite-settings-actions"><button disabled={!editable || !dirty} className="primary" onClick={() => perform("save")}>{pending === "save" ? <LoaderCircle size={15} className="spin" /> : <Check size={15} />}保存空间设置</button><button disabled={Boolean(pending) || setupBusy || dirty || !state} onClick={() => perform("check")}>{checkBusy ? <LoaderCircle size={15} className="spin" /> : <RefreshCw size={15} />}{checkBusy ? "应用正在自动检查…" : "检查启动条件"}</button><button disabled={Boolean(pending) || setupBusy || dirty || status.vm_running} onClick={() => perform("setup")}>检查并补齐组件</button></div>
    {checkJob && <p className={checkJob.error ? "error-message" : "field-help"} role={checkJob.error ? "alert" : "status"}>{checkJob.error || checkJob.message || (checkBusy ? "应用正在自动检查沙箱与网络出口…" : "检查任务已结束，请查看应用监控结果。")}<button className="text-button" onClick={() => setSetupDetails(true)}>操作详情</button></p>}
    <p className="field-help">停止空间后，可重新检查安装并自动补齐缺失组件；这不会重建空间或清空个人数据。</p>
    {setupJob?.setup_progress && (setupJob.running || setupJob.error || setupJob.canceled) && <SetupProgress job={setupJob} onDetails={() => setSetupDetails(true)} onRetry={() => perform("setup")} onStop={stopSetup} disconnected={Boolean(pending)} />}
    {setupJob && !setupJob.setup_progress && setupJob.running && <p className="field-help" role="status"><LoaderCircle size={15} className="spin" />{setupJob.message || "正在准备组件检查…"}<button className="text-button" onClick={() => setSetupDetails(true)}>操作详情</button></p>}
    {dirty && <p className="field-help">有尚未保存的空间设置，保存后再检查。</p>}
    <LiteChecks state={state} />
    {setupDetails && <Modal title="轻量沙箱检查详情" onClose={() => setSetupDetails(false)}><InitializationDetails status={{ ...status, job: checkJob || setupJob || status.job }} /></Modal>}
  </section>;
}
