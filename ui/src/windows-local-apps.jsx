import React, { useEffect, useRef, useState } from "react";
import { api } from "./api";
import { runtimeSocketURL } from "./client-context.mjs";
import "./windows-local-apps.css";

const appKeys = new Set(["Enter", "Tab", "Backspace", "Escape", "Delete", "ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "Home", "End", "PageUp", "PageDown"]);

export function WindowsLocalDesktopImport({ selected, visible, onInstalled }) {
  const [applied, setApplied] = useState(false);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  useEffect(() => {
    let live = true;
    setApplied(false);
    if (selected && visible) {
      api("/proxy").then(proxy => {
        if (live) setApplied(Boolean(proxy.selected && proxy.active && proxy.running));
      }).catch(() => { if (live) setApplied(false); });
    }
    return () => { live = false; };
  }, [selected, visible]);
  async function choosePackage() {
    setBusy(true);
    setMessage("正在核验所选节点…");
    try {
      const result = await api("/windows-local/apps/desktop/import", {});
      setMessage("");
      if (result.imported) await onInstalled();
    } catch (error) { setMessage(error.message); }
    finally { setBusy(false); }
  }
  return <div>
    <p>{applied ? "请选择已下载的官方 Windows x64 安装包（.msix）。" : "请先在网络与代理中选择并应用 Cage 节点。"}</p>
    <button disabled={!selected || !applied || busy} onClick={choosePackage}>选择官方安装包</button>
    {message && <p role="status">{message}</p>}
  </div>;
}

export function WindowsLocalAppPane({ app, project = "" }) {
  const label = app === "editor" ? "Visual Studio Code" : "Claude Desktop";
  const [attempt, setAttempt] = useState(0);
  const [frame, setFrame] = useState(null);
  const [error, setError] = useState("");
  const [text, setText] = useState("");
  const channel = useRef(null);
  useEffect(() => {
    if (app !== "editor" && app !== "desktop") return;
    setFrame(null);
    setError("");
    setText("");
    let alive = true, timer;
    const url = new URL(runtimeSocketURL("/windows-local/apps/" + app), window.location.href);
    if (app === "editor" && project) url.searchParams.set("project", project);
    const socket = new WebSocket(url);
    channel.current = socket;
    function requestFrame() {
      if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: "frame" }));
    }
    socket.onmessage = event => {
      if (!alive) return;
      try {
        const packet = JSON.parse(event.data);
        if (packet.type === "error") {
          setError(packet.message || "应用连接失败。");
        } else if (packet.type === "exit") {
          setError("应用已关闭。");
        } else {
          if (packet.type === "frame") setFrame(packet);
          timer = setTimeout(requestFrame, document.hidden ? 1000 : 200);
        }
      } catch {
        setError("无法读取应用画面。");
        socket.close();
      }
    };
    socket.onclose = () => { if (alive) setError(previous => previous || "应用窗口已断开。"); };
    return () => { alive = false; clearTimeout(timer); channel.current = null; socket.close(); };
  }, [app, project, attempt]);
  function send(packet) {
    if (channel.current?.readyState === WebSocket.OPEN) channel.current.send(JSON.stringify(packet));
  }
  function pointer(event, type) {
    const rect = event.currentTarget.getBoundingClientRect();
    const x = Math.min(frame.width - 1, Math.max(0, Math.floor((event.clientX - rect.left) / rect.width * frame.width)));
    const y = Math.min(frame.height - 1, Math.max(0, Math.floor((event.clientY - rect.top) / rect.height * frame.height)));
    send({ type, x, y, ...(type === "wheel" ? { delta: -Math.sign(event.deltaY) } : {}) });
  }
  return <section className="windows-local-app" aria-label={label}>
    {error ? <div className="windows-local-app-message"><p role="alert">{error}</p>
      <button onClick={() => setAttempt(v => v + 1)}>重新打开 {label}</button></div> :
      !frame ? <p className="windows-local-app-message" role="status">正在隔离账户中打开 {label}…</p> :
      <><div className="windows-local-app-view"><img src={"data:image/jpeg;base64," + frame.image}
        draggable="false" alt={label + " 窗口"} tabIndex={0}
        onClick={event => { event.currentTarget.focus(); pointer(event, "click"); }}
        onWheel={event => pointer(event, "wheel")}
        onKeyDown={event => {
          if (event.isComposing || event.ctrlKey || event.altKey || event.metaKey) return;
          if (appKeys.has(event.key)) { event.preventDefault(); send({ type: "key", key: event.key }); }
          else if ([...event.key].length === 1) { event.preventDefault(); send({ type: "text", text: event.key }); }
        }} /></div>
        <form onSubmit={event => { event.preventDefault(); if (text) { send({ type: "text", text }); setText(""); } }}>
          <input aria-label="发送到应用的文字" placeholder="点选应用中的输入位置后，可在此输入中文" maxLength={1024}
            autoComplete="off" value={text} onChange={event => setText(event.target.value)} />
          <button disabled={!text}>发送文字</button>
        </form></>}
  </section>;
}
