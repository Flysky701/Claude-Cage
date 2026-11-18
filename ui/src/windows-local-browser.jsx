import React, { useEffect, useRef, useState } from "react";
import { ArrowLeft, ArrowRight, RotateCw } from "lucide-react";
import { runtimeSocketURL } from "./client-context.mjs";
import "./windows-local-browser.css";

export function WindowsLocalBrowserPane({ initialURL = "", active = true, bridge }) {
  const [attempt, setAttempt] = useState(0);
  const [phase, setPhase] = useState("opening");
  const [address, setAddress] = useState("");
  const [notice, setNotice] = useState("");
  const [frame, setFrame] = useState(null);
  const socket = useRef(null), ready = useRef(false), viewport = useRef(null);
  const addressInput = useRef(null), typing = useRef(null), url = useRef(initialURL);
  const focused = useRef(active), composing = useRef(false);
  focused.current = active;
  url.current = initialURL;

  function send(action) {
    if (ready.current && socket.current?.readyState === WebSocket.OPEN) {
      socket.current.send(JSON.stringify(action));
    }
  }

  function navigate(raw) {
    if (!raw.trim()) return;
    try {
      const value = raw.trim();
      const next = new URL(/^[a-z][a-z\d+.-]*:/i.test(value) ? value : "https://" + value);
      if (!["http:", "https:"].includes(next.protocol) || next.username || next.password || value.includes("\\")) {
        throw new Error();
      }
      setAddress(next.href);
      setNotice("");
      send({ type: "navigate", url: next.href });
      typing.current?.focus();
    } catch { setNotice("请输入 HTTP 或 HTTPS 网页地址。"); }
  }

  useEffect(() => {
    let alive = true, timer, resizing;
    // A login flow can host Edge in the same isolated worker as its callback
    // listener. Its bridge replays the ready frame once the listener is attached.
    const ws = bridge || new WebSocket(runtimeSocketURL("/windows-local/browser"));
    socket.current = ws;
    ready.current = false;
    setPhase("opening"); setNotice(""); setFrame(null);
    const requestFrame = () => {
      clearTimeout(timer);
      if (!alive || !ready.current) return;
      if (document.hidden || !focused.current) {
        timer = setTimeout(requestFrame, 350);
        return;
      }
      send({ type: "frame" });
    };
    const resize = () => {
      const box = viewport.current?.getBoundingClientRect();
      if (box?.width > 0 && box?.height > 0) {
        send({ type: "resize", width: Math.max(320, Math.min(1600, Math.floor(box.width))),
          height: Math.max(180, Math.min(1000, Math.floor(box.height))) });
      }
    };
    const observer = new ResizeObserver(() => {
      clearTimeout(resizing);
      resizing = setTimeout(resize, 120);
    });
    if (viewport.current) observer.observe(viewport.current);
    const message = event => {
      if (!alive) return;
      try {
        const data = JSON.parse(event.data);
        switch (data.type) {
          case "ready":
            ready.current = true; setPhase("ready");
            resize();
            if (url.current && url.current !== "about:blank") navigate(url.current);
            requestFrame();
            break;
          case "frame":
            setFrame(data);
            if (addressInput.current !== document.activeElement) setAddress(data.url === "about:blank" ? "" : data.url);
            timer = setTimeout(requestFrame, 260);
            break;
          case "refreshing":
            setFrame(null);
            timer = setTimeout(requestFrame, 100);
            break;
          case "notice": setNotice(data.message); break;
          case "error": ready.current = false; setNotice(data.message); setPhase("closed"); break;
          case "exit": if (!bridge) ws.close(); else closed(); break;
        }
      } catch { setNotice("浏览器画面无法读取。"); close(); }
    };
    const closed = () => {
      if (!alive) return;
      ready.current = false; setPhase("closed");
    };
    const close = () => {
      if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: "close" }));
      if (!bridge) ws.close();
    };
    ws.addEventListener("close", closed);
    ws.addEventListener("message", message);
    window.addEventListener("pagehide", close);
    return () => {
      alive = false; ready.current = false; clearTimeout(timer); clearTimeout(resizing);
      ws.removeEventListener("message", message); ws.removeEventListener("close", closed);
      observer.disconnect(); window.removeEventListener("pagehide", close); close();
    };
  }, [attempt, bridge]);

  useEffect(() => {
    if (ready.current && initialURL && initialURL !== "about:blank") navigate(initialURL);
  }, [initialURL]);

  function point(event) {
    const bounds = event.currentTarget.getBoundingClientRect();
    return { view: frame.view, x: Math.max(0, Math.min(frame.width - 1, Math.floor((event.clientX - bounds.left) * frame.width / bounds.width))),
      y: Math.max(0, Math.min(frame.height - 1, Math.floor((event.clientY - bounds.top) * frame.height / bounds.height))) };
  }

  function key(event) {
    if (event.nativeEvent.isComposing || composing.current || event.keyCode === 229) return;
    if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) return;
    // Pasting into the local input transfers only the text explicitly supplied by the user.
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "v") return;
    event.preventDefault(); event.stopPropagation();
    send({ type: "key", view: frame?.view, key: event.key, code: event.code, vk: event.keyCode || 0,
      modifiers: Number(event.altKey) + 2 * Number(event.ctrlKey) + 4 * Number(event.metaKey) + 8 * Number(event.shiftKey) });
  }
  function insert() {
    if (!typing.current || composing.current) return;
    const text = typing.current.value;
    typing.current.value = "";
    if (text.length > 16384) { setNotice("一次可输入最多 16384 个字符。"); return; }
    if (text) send({ type: "text", view: frame?.view, text });
  }

  return <section className="windows-local-browser" aria-label="Windows 隔离浏览器">
    <form className="windows-local-browser-bar" onSubmit={event => { event.preventDefault(); navigate(address); }}>
      <button type="button" className="icon-button" title="后退" aria-label="后退" disabled={phase !== "ready"} onClick={() => send({ type: "back" })}><ArrowLeft size={16} /></button>
      <button type="button" className="icon-button" title="前进" aria-label="前进" disabled={phase !== "ready"} onClick={() => send({ type: "forward" })}><ArrowRight size={16} /></button>
      <button type="button" className="icon-button" title="刷新网页" aria-label="刷新网页" disabled={phase !== "ready"} onClick={() => send({ type: "refresh" })}><RotateCw size={15} /></button>
      <input ref={addressInput} aria-label="隔离浏览器地址" placeholder="输入网址" autoComplete="off" spellCheck={false} value={address}
        onChange={event => setAddress(event.target.value)} disabled={phase !== "ready"} />
      <button disabled={phase !== "ready" || !address.trim()}>前往</button>
      {frame?.popup && phase === "ready" && <button type="button" onClick={() => send({ type: "close-popup" })}>关闭弹出页</button>}
    </form>
    {notice && <p className="windows-local-browser-note" role="alert">{notice}</p>}
    {phase !== "ready" && <div className="windows-local-browser-note" role="status">
      {phase === "opening" ? "正在打开隔离 Edge…" : "浏览器已关闭。"}
      {phase === "closed" && <button onClick={() => setAttempt(previous => previous + 1)}>重新打开</button>}
    </div>}
    <div className="windows-local-browser-viewport" ref={viewport}>
      {frame && phase === "ready" && <img src={"data:image/jpeg;base64," + frame.image}
        alt={frame.title || "隔离 Edge 网页"} aria-label="隔离 Edge 网页" draggable={false}
        onClick={event => { typing.current?.focus(); send({ type: "click", ...point(event) }); }}
        onWheel={event => send({ type: "wheel", ...point(event), dx: Math.round(Math.max(-2048, Math.min(2048, event.deltaX))),
          dy: Math.round(Math.max(-2048, Math.min(2048, event.deltaY))) })} />}
      <textarea ref={typing} className="windows-local-browser-keyboard" aria-label="向隔离网页输入文字"
        disabled={phase !== "ready"} onKeyDown={key} onInput={insert} onCompositionStart={() => { composing.current = true; }}
        onCompositionEnd={() => { composing.current = false; queueMicrotask(insert); }} />
    </div>
  </section>;
}
