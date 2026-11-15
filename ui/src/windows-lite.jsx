import React, { useCallback, useEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  ArrowUpRight, Check, ChevronRight, CircleHelp, FileCode2, FolderOpen,
  Globe2, LayoutGrid, LoaderCircle, LockKeyhole, Monitor, Play, Power,
  RefreshCw, Settings2, Shield, Square, TerminalSquare, TriangleAlert, X,
} from "lucide-react";
import logo from "./logo.png";
import "./windows-lite.css";

const entries = [
  { id: "browser", label: "浏览器", icon: Globe2, note: "打开空间内的浏览器" },
  { id: "claude_web", label: "Claude 网页", icon: Globe2, note: "在空间内访问 Claude", config: "browser" },
  { id: "claude_desktop", label: "Claude Desktop", icon: Monitor, note: "打开桌面应用" },
  { id: "shell", label: "普通终端", icon: TerminalSquare, note: "打开空间内的命令行" },
  { id: "claude", label: "Claude 终端", icon: TerminalSquare, note: "启动 Claude Code" },
  { id: "editor", label: "项目编辑器", icon: FileCode2, note: "打开已配置的编辑器" },
];
const configurableEntries = entries.filter(entry => !entry.config);
const phases = {
  stopped: "空间已停止", starting: "正在启动", running: "空间运行中",
  blocked: "启动受阻", stopping: "正在停止", error: "需要处理",
};

const bridge = () => window.cageNativeBridge || window.webkit?.messageHandlers?.cage;
async function native(action) {
  const target = bridge();
  if (!target) return false;
  return target.postMessage({ action, connection_id: "" });
}

async function request(path, body, signal) {
  let response;
  try {
    response = await fetch(path, {
      method: body === undefined ? "GET" : "POST",
      credentials: "same-origin",
      cache: "no-store",
      headers: body === undefined ? {} : { "Content-Type": "application/json", "X-Cage-Lite": "1" },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal,
    });
  } catch (error) {
    if (signal?.aborted) throw error;
    throw new Error("暂时无法连接空间后台。请检查后台状态后重试。");
  }
  let value;
  try { value = await response.json(); }
  catch { throw new Error("后台返回的结果无法读取，请重新检查连接。"); }
  if (!response.ok || value.ok !== true) {
    const error = new Error(typeof value.error === "string" ? value.error : "操作未完成，请查看空间状态。");
    error.state = value.state;
    throw error;
  }
  return value;
}

function settingsDraft(settings = {}) {
  return {
    sandboxieDirectory: settings.sandboxieDirectory || "",
    proxyCore: settings.proxyCore || "",
    connectionFile: settings.connectionFile || "",
    projectDirectory: settings.projectDirectory || "",
    applications: Object.fromEntries(configurableEntries.map(({ id }) => [id, {
      program: settings.applications?.[id]?.program || "",
      argumentsText: (settings.applications?.[id]?.arguments || []).join("\n"),
    }])),
  };
}

function App() {
  const [page, setPage] = useState("workspace");
  const [state, setState] = useState(null);
  const [connected, setConnected] = useState(false);
  const [pending, setPending] = useState("");
  const [error, setError] = useState("");
  const [connectionError, setConnectionError] = useState("");
  const [notice, setNotice] = useState("");
  const [draft, setDraft] = useState(() => settingsDraft());
  const [dirty, setDirty] = useState(false);
  const [confirmation, setConfirmation] = useState(null);
  const [closed, setClosed] = useState(false);
  const alive = useRef(true);
  const dirtyRef = useRef(false);
  const requestBusy = useRef(false);
  const pollController = useRef(null);
  const generation = useRef(0);
  const authenticated = useRef(false);
  const statusReceived = useRef(false);
  const nativeReady = useRef(false);
  const closedRef = useRef(false);

  const accept = useCallback(next => {
    if (!alive.current || !next) return;
    setState(next);
    if (!dirtyRef.current) setDraft(settingsDraft(next.settings));
  }, []);

  const refresh = useCallback(async () => {
    if (!alive.current || requestBusy.current || pollController.current || closedRef.current) return;
    const controller = new AbortController();
    const currentGeneration = generation.current;
    pollController.current = controller;
    const timeout = setTimeout(() => controller.abort(), 12000);
    try {
      if (!authenticated.current) {
        const token = window.location.hash.slice(1);
        if (token) {
          await request("/api/session", { token }, controller.signal);
          history.replaceState(null, "", window.location.pathname + window.location.search);
        }
        authenticated.current = true;
      }
      const result = await request("/api/lite/status", undefined, controller.signal);
      if (!result.state || !Object.hasOwn(phases, result.state.phase)
        || !["closed", "open", "unknown"].includes(result.state.network)
        || !Array.isArray(result.state.checks) || !Array.isArray(result.state.applications)) {
        throw new Error("后台返回的空间状态不完整，请重新检查连接。");
      }
      if (alive.current && currentGeneration === generation.current) {
        statusReceived.current = true;
        accept(result.state);
        setConnected(true);
        setConnectionError("");
      }
    } catch (failure) {
      if (alive.current && currentGeneration === generation.current) {
        setConnected(false);
        setConnectionError(controller.signal.aborted ? "连接检查超时，请重试。" : failure.message);
      }
    } finally {
      clearTimeout(timeout);
      if (pollController.current === controller) pollController.current = null;
    }
  }, [accept]);

  useEffect(() => {
    alive.current = true;
    let timer;
    const poll = async () => {
      await refresh();
      if (alive.current && !closedRef.current) timer = setTimeout(poll, 2500);
    };
    void poll();
    return () => { alive.current = false; clearTimeout(timer); pollController.current?.abort(); };
  }, [refresh]);

  useEffect(() => {
    const onNative = command => {
      if (command === "quit") setConfirmation("exit");
    };
    window.cageNativeAction = onNative;
    return () => { if (window.cageNativeAction === onNative) delete window.cageNativeAction; };
  }, []);

  useEffect(() => {
    if (!state || !connected || !authenticated.current || !statusReceived.current || nativeReady.current || !bridge()) return;
    // The native smoke acknowledgement must follow the first authenticated,
    // validated status render, not merely mounting an empty workbench.
    let paintedFrame;
    const frame = requestAnimationFrame(() => {
      paintedFrame = requestAnimationFrame(() => {
        nativeReady.current = true;
        native("workbenchReady").catch(failure => setError(failure.message || "窗口连接未就绪。"));
      });
    });
    return () => { cancelAnimationFrame(frame); cancelAnimationFrame(paintedFrame); };
  }, [state, connected]);

  async function perform(action, body = {}) {
    if (requestBusy.current || closedRef.current) return;
    requestBusy.current = true;
    generation.current += 1;
    pollController.current?.abort();
    setPending(action);
    setError("");
    setNotice("");
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 90000);
    try {
      const result = await request(`/api/lite/${action}`, body, controller.signal);
      accept(result.state);
      setConnected(true);
      if (action === "configure") {
        dirtyRef.current = false;
        setDirty(false);
        setDraft(settingsDraft(result.state?.settings || body.settings));
        setNotice("设置已保存，依赖状态已更新。");
      }
      if (action === "launch") setNotice("已提交打开请求，请查看空间内的应用窗口。");
      if (action === "shutdown") {
        closedRef.current = true;
        setClosed(true);
        setNotice("空间已停止，可以关闭窗口。");
        if (bridge()) await native("quitNow");
      }
    } catch (failure) {
      accept(failure.state);
      setError(controller.signal.aborted
        ? "操作等待超时，请先检查空间状态，避免重复启动。"
        : failure.message);
      if (!failure.state) setConnected(false);
    } finally {
      clearTimeout(timeout);
      requestBusy.current = false;
      setPending("");
    }
  }

  const phase = state?.phase || "stopped";
  const busy = Boolean(pending) || ["starting", "stopping"].includes(phase);
  const processCount = Number.isFinite(state?.processCount) ? state.processCount : 0;
  const running = phase === "running";
  const previewOnly = state?.acceptance !== "verified";
  const checks = Array.isArray(state?.checks) ? state.checks : [];
  const checkReady = checks.length > 0 && checks.every(check => check.ok === true);
  const startReady = connected && !busy && !closed && !running && processCount === 0 && checkReady;
  const stopReady = connected && !busy && !closed && (running || processCount > 0 || phase === "blocked");
  const editable = connected && !busy && !closed && !running && processCount === 0;
  const network = !connected ? "unknown" : state?.network || "unknown";
  const networkLabel = network === "open" ? "出口已连接" : network === "closed" ? "联网已关闭" : "出口待确认";
  const statusLabel = closed ? "空间已停止" : !state ? "正在读取状态" : !connected ? "后台连接中断" : phases[phase] || "状态待确认";

  function changeSetting(name, value) {
    dirtyRef.current = true;
    setDirty(true);
    setDraft(previous => ({ ...previous, [name]: value }));
  }
  function changeApplication(id, name, value) {
    dirtyRef.current = true;
    setDirty(true);
    setDraft(previous => ({ ...previous, applications: {
      ...previous.applications, [id]: { ...previous.applications[id], [name]: value },
    } }));
  }
  function save(event) {
    event.preventDefault();
    const settings = {
      sandboxieDirectory: draft.sandboxieDirectory.trim(),
      proxyCore: draft.proxyCore.trim(),
      connectionFile: draft.connectionFile.trim(),
      projectDirectory: draft.projectDirectory.trim(),
      applications: Object.fromEntries(configurableEntries.map(({ id }) => [id, {
        program: draft.applications[id].program.trim(),
        arguments: draft.applications[id].argumentsText.split(/\r?\n/).filter(value => value.length > 0),
      }])),
    };
    void perform("configure", { settings });
  }

  return <div className="lite-app">
    <aside className="lite-sidebar">
      <div className="lite-brand"><img src={logo} alt="" /><strong>Cage</strong><span>实验</span></div>
      <div className="lite-space"><Shield size={19} /><div><strong>Windows 轻量空间</strong><small>一个空间，继续上次的工作</small></div></div>
      <nav aria-label="工作台导航">
        <button className={page === "workspace" ? "selected" : ""} aria-current={page === "workspace" ? "page" : undefined} onClick={() => setPage("workspace")}><LayoutGrid size={17} />工作台</button>
        <button className={page === "settings" ? "selected" : ""} aria-current={page === "settings" ? "page" : undefined} onClick={() => setPage("settings")}><Settings2 size={17} />设置{dirty && <span className="lite-unsaved" title="有未保存的设置" />}</button>
      </nav>
      <div className="lite-sidebar-bottom"><span><LockKeyhole size={14} />空间数据持续保留</span><button onClick={() => setConfirmation("exit")} disabled={busy || closed}><Power size={16} />停止空间并退出</button></div>
    </aside>

    <main className="lite-main">
      <header className="lite-header"><div><span className="lite-eyebrow">WINDOWS LITE</span><h1>{page === "workspace" ? "Windows 轻量空间" : "空间设置"}</h1></div><button className="lite-icon-button" title="刷新状态" aria-label="刷新状态" disabled={busy || closed} onClick={() => { setError(""); void refresh(); }}><RefreshCw size={18} /></button></header>
      <div className="lite-content">
        <div className="lite-preview"><CircleHelp size={16} /><span>依赖与启动项检查版 · 真实应用运行未开放</span></div>
        {(error || connectionError) && <div className="lite-alert error" role="alert"><TriangleAlert size={17} /><span>{error || connectionError}</span><button aria-label="关闭提示" onClick={() => { setError(""); setConnectionError(""); }}><X size={16} /></button></div>}
        {notice && <div className="lite-alert notice" role="status"><Check size={17} /><span>{notice}</span></div>}

        {page === "workspace" ? <>
          <section className="lite-status-panel" aria-labelledby="space-status-title">
            <div className="lite-status-top"><div className="lite-status-title"><span className={`lite-state-dot ${connected && running ? "running" : ""}`} /><div><h2 id="space-status-title">{statusLabel}</h2><p>{state?.message || "正在检查空间及所需组件。"}</p></div></div>
              <div className="lite-actions">
                <button className="lite-primary" disabled={!startReady} onClick={() => void perform("start")} title={!checkReady ? "请先完成下方依赖检查；本版尚未开放真实运行" : "检查启动条件；本版尚未开放真实运行"}>{pending === "start" || phase === "starting" ? <LoaderCircle className="lite-spin" size={16} /> : <Play size={16} />}{previewOnly ? "检查启动条件" : "启动空间"}</button>
                <button disabled={!stopReady} onClick={() => setConfirmation("stop")}><Square size={15} />停止</button>
              </div>
            </div>
            <div className="lite-metrics"><div><span>空间进程</span><strong>{connected ? processCount : "—"}<small> 个</small></strong></div><div><span>网络状态</span><strong className={network === "open" ? "lite-network-open" : ""}><Globe2 size={16} />{networkLabel}</strong></div><div><span>数据保存</span><strong><FolderOpen size={16} />保留原空间</strong></div></div>
          </section>

          <section className="lite-section" aria-labelledby="applications-title"><div className="lite-section-heading"><div><h2 id="applications-title">应用启动项</h2><p>沿用 Cage 的常用入口。本版可配置和检查路径，暂不打开真实应用。</p></div><button className="lite-text-button" onClick={() => setPage("settings")}>配置启动项<ChevronRight size={15} /></button></div>
            <div className="lite-application-grid">{entries.map(entry => {
              const application = state?.applications?.find(item => item.id === entry.id) || state?.applications?.find(item => item.id === (entry.config || entry.id));
              const available = application?.available === true;
              const Icon = entry.icon;
              const canLaunch = !previewOnly && connected && running && network === "open" && available && !busy && !closed;
              return <article className="lite-application" key={entry.id}><div className="lite-app-icon"><Icon size={20} /></div><div><h3>{entry.label}</h3><p>{!available ? "需要配置程序路径" : previewOnly ? "路径已配置 · 运行未开放" : application.running ? "已在空间内运行" : entry.note}</p></div><button className="lite-icon-button" aria-label={previewOnly ? `${entry.label}运行未开放` : `打开${entry.label}`} title={previewOnly ? "此检查版尚未开放真实应用运行" : !available ? "请先在设置中配置程序" : !running ? "请先启动空间" : network !== "open" ? "出口尚未就绪" : `打开${entry.label}`} disabled={!canLaunch} onClick={() => void perform("launch", { entry: entry.id })}><ArrowUpRight size={18} /></button></article>;
            })}</div>
          </section>

          <section className="lite-section" aria-labelledby="checks-title"><div className="lite-section-heading"><div><h2 id="checks-title">启动检查</h2><p>检查组件和配置是否齐备；检查通过也不代表完整隔离验收通过。</p></div><span className="lite-count">{checks.filter(check => check.ok).length} / {checks.length}</span></div><div className="lite-check-list">{checks.length ? checks.map(check => <div className="lite-check" key={check.id}>{check.ok ? <Check size={17} className="lite-pass" /> : <TriangleAlert size={17} className="lite-warning" />}<div><strong>{check.label}</strong>{check.message && <p>{check.message}</p>}</div><span>{check.ok ? "已就绪" : "待处理"}</span></div>) : <div className="lite-empty"><LoaderCircle size={17} className={connected ? "" : "lite-spin"} />{connected ? "暂未收到检查结果" : "等待后台返回检查结果"}</div>}</div></section>
          <footer className="lite-location"><FolderOpen size={15} /><span>空间数据</span><code title={state?.profile}>{state?.profile || "读取中…"}</code></footer>
        </> : <form onSubmit={save} className="lite-settings">
          <div className="lite-section-heading"><div><h2>运行组件</h2><p>填写本机已有组件和连接配置的位置。停止空间后可以修改。</p></div></div>
          {!editable && <div className="lite-alert notice"><LockKeyhole size={16} /><span>{!connected ? "连接后台后可编辑设置。" : "请先停止空间，再修改启动设置。"}</span></div>}
          <fieldset disabled={!editable}>
            <label className="lite-field"><span>Sandboxie 安装目录</span><input value={draft.sandboxieDirectory} onChange={event => changeSetting("sandboxieDirectory", event.target.value)} placeholder="C:\Program Files\Sandboxie-Plus" autoComplete="off" spellCheck="false" /></label>
            <label className="lite-field"><span>代理程序路径</span><input value={draft.proxyCore} onChange={event => changeSetting("proxyCore", event.target.value)} placeholder="选择已有的 Mihomo 程序路径" autoComplete="off" spellCheck="false" /></label>
            <label className="lite-field"><span>连接配置文件</span><input value={draft.connectionFile} onChange={event => changeSetting("connectionFile", event.target.value)} placeholder="Cage 连接配置文件的完整路径" autoComplete="off" spellCheck="false" /><small>只指定文件位置，账号和代理密码不会在此显示。</small></label>
            <label className="lite-field"><span>项目目录（可选）</span><input value={draft.projectDirectory} onChange={event => changeSetting("projectDirectory", event.target.value)} placeholder="需要在空间内使用的项目目录" autoComplete="off" spellCheck="false" /><small>仅选择准备交给空间内应用使用的项目。</small></label>
            <div className="lite-section-heading lite-settings-app-heading"><div><h2>应用启动项</h2><p>填写程序的完整路径；Claude 网页共用浏览器配置。</p></div></div>
            <div className="lite-settings-apps">{configurableEntries.map(entry => <details key={entry.id} className="lite-app-settings"><summary><entry.icon size={17} /><strong>{entry.label}</strong><span>{draft.applications[entry.id].program ? "已配置路径" : "未配置"}</span><ChevronRight size={16} /></summary><div><label className="lite-field"><span>程序路径</span><input value={draft.applications[entry.id].program} onChange={event => changeApplication(entry.id, "program", event.target.value)} placeholder="Windows 程序的完整路径" spellCheck="false" autoComplete="off" /></label><label className="lite-field"><span>启动参数（可选，每行一个）</span><textarea rows={3} value={draft.applications[entry.id].argumentsText} onChange={event => changeApplication(entry.id, "argumentsText", event.target.value)} placeholder="每行作为一个完整参数传入" spellCheck="false" /></label></div></details>)}</div>
          </fieldset>
          <div className="lite-save-row"><span>{dirty ? "设置尚未保存" : "设置已同步"}</span><button className="lite-primary" type="submit" disabled={!editable || !dirty}>{pending === "configure" ? <LoaderCircle size={16} className="lite-spin" /> : <Check size={16} />}保存设置</button></div>
          <div className="lite-settings-note"><Shield size={18} /><p>本版仅保存配置、检查依赖与启动项，真实应用运行尚未开放。应用、子进程、断线及数据隔离验收仍待完成。</p></div>
        </form>}
      </div>
    </main>
    {confirmation && <ConfirmDialog action={confirmation} busy={busy} onCancel={() => setConfirmation(null)} onConfirm={() => { const action = confirmation; setConfirmation(null); void perform(action === "exit" ? "shutdown" : "stop"); }} />}
  </div>;
}

function ConfirmDialog({ action, busy, onCancel, onConfirm }) {
  const button = useRef(null);
  const dialog = useRef(null);
  const cancel = useRef(onCancel);
  cancel.current = onCancel;
  useEffect(() => {
    const previous = document.activeElement;
    button.current?.focus();
    const keydown = event => {
      if (event.key === "Escape") { event.preventDefault(); cancel.current(); }
      if (event.key === "Tab") {
        const items = [...dialog.current.querySelectorAll("button:not(:disabled)")];
        if (!items.length) return;
        const first = items[0], last = items.at(-1);
        if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
        else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
      }
    };
    document.addEventListener("keydown", keydown);
    return () => { document.removeEventListener("keydown", keydown); previous?.focus(); };
  }, []);
  return <div className="lite-modal-backdrop"><section ref={dialog} className="lite-dialog" role="dialog" aria-modal="true" aria-labelledby="lite-confirm-title"><div className="lite-dialog-icon"><Power size={21} /></div><h2 id="lite-confirm-title">{action === "exit" ? "停止空间并退出？" : "停止这个空间？"}</h2><p>请先保存应用中的工作。空间内的应用和子进程会结束，已保存的数据会保留。</p><div className="lite-dialog-actions"><button ref={button} disabled={busy} onClick={onCancel}>取消</button><button className="lite-primary" disabled={busy} onClick={onConfirm}>{action === "exit" ? "停止并退出" : "停止空间"}</button></div></section></div>;
}

createRoot(document.getElementById("root")).render(<App />);
