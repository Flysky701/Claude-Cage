import React, { useEffect, useState } from "react";
import { api, native, nativeAvailable } from "./api";

export function WindowsLocalProjects({ onOpenEditor }) {
  const [projects, setProjects] = useState([]);
  const [path, setPath] = useState("");
  const [access, setAccess] = useState("ro");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(true);
  useEffect(() => {
    let live = true;
    api("/windows-local/projects").then(data => { if (live) setProjects(data.projects); })
      .catch(err => { if (live) setError(err.message); }).finally(() => { if (live) setBusy(false); });
    return () => { live = false; };
  }, []);
  async function change(target, permission) {
    setBusy(true);
    setError("");
    try {
      const result = await api("/windows-local/projects", { path: target, access: permission });
      setProjects(result.projects);
      setPath("");
      setAccess("ro");
    } catch (err) { setError(err.message); }
    finally { setBusy(false); }
  }
  async function choose() {
    setBusy(true);
    try {
      const selected = nativeAvailable() ? await native("chooseFolder") :
        (await api("/windows-local/projects", { action: "choose" })).selected;
      if (selected) setPath(selected);
    }
    catch (err) { setError(err.message); }
    finally { setBusy(false); }
  }
  const labels = { ro: "只读", rw: "读写", unconfirmed: "授权待核对" };
  return <section className="environment-versions" aria-label="本地项目共享">
    <h3>本地项目共享</h3>
    <p className="field-help">选择你要共享给专用 Windows 账户的文件夹。终端和编辑器使用低完整性权限，通常只能写入隔离工作目录。</p>
    <form className="project-form" onSubmit={event => { event.preventDefault(); if (path.trim()) change(path.trim(), access); }}>
      <label>项目文件夹<input value={path} onChange={event => setPath(event.target.value)} placeholder="输入项目的完整 Windows 路径" spellCheck={false}/></label>
      <button type="button" onClick={choose} disabled={busy}>选择文件夹</button>
      <label>账户权限<select value={access} onChange={event => setAccess(event.target.value)}>
        <option value="ro">只读</option><option value="rw">读写</option>
      </select></label>
      <button type="submit" className="primary" disabled={busy || !path.trim()}>保存项目授权</button>
    </form>
    {error && <p role="alert" className="error-message">{error}</p>}
    {projects.map(item => <div key={item.path} className="environment-version">
      <div><strong>{item.path}</strong><span> · {labels[item.access]}</span></div>
      <div className="environment-version-actions">
        {onOpenEditor && item.access !== "unconfirmed" &&
          <button type="button" disabled={busy} onClick={() => onOpenEditor(item.path)}>用 VS Code 打开</button>}
        <button type="button" disabled={busy} onClick={() => { setPath(item.path); setAccess(item.access === "rw" ? "rw" : "ro"); }}>调整权限</button>
        <button type="button" disabled={busy} onClick={() => change(item.path, "revoke")}>撤销授权</button>
      </div>
    </div>)}
  </section>;
}
