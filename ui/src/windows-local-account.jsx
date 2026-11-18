import React, { useEffect, useRef, useState } from "react";
import { api } from "./api";
import { runtimeSocketURL } from "./client-context.mjs";
import "./windows-local-account.css";

function inspectAccount(signal) {
  return api("/windows-local/status", undefined, undefined, {}, { signal });
}

export function WindowsLocalAccount({ onEnter }) {
  const [account, setAccount] = useState(null);
  const [error, setError] = useState("");
  const [checking, setChecking] = useState(true);
  const [entering, setEntering] = useState(false);
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    const request = new AbortController();
    setChecking(true);
    setError("");
    setAccount(null);
    inspectAccount(request.signal)
      .then(result => { if (!request.signal.aborted) setAccount(result); })
      .catch(err => { if (!request.signal.aborted) setError(err.message); })
      .finally(() => { if (!request.signal.aborted) setChecking(false); });
    return () => request.abort();
  }, [attempt]);

  async function enter() {
    setEntering(true);
    setError("");
    try { await onEnter(); }
    catch (err) { setError(err.message); setEntering(false); }
  }

  return <section className="environment-versions" aria-label="Windows 原生本地账户">
    {onEnter ? <h1>Windows 原生本地账户</h1> : <h4>Windows 原生本地账户</h4>}
    <p role="status" className="field-help">{checking ? "正在检查本地账户档案…" : account?.message}</p>
    {error && <p role="alert" className="error-message">{error}</p>}
    {account?.worker_username && <div className="setting-summary-row"><span>本地账户</span><strong>{account.worker_username}</strong></div>}
    {account?.worker_sid && <div className="setting-summary-row"><span>账户 SID</span><strong>{account.worker_sid}</strong></div>}
    <div className="environment-version-actions">
      {onEnter && <button type="button" className="primary" onClick={enter}
        disabled={checking || entering || !account?.available || !account.rules_verified}>{entering ? "正在进入…" : "进入工作台"}</button>}
      <button type="button" disabled={checking || entering} onClick={() => setAttempt(value => value + 1)}>检查账户档案</button>
    </div>
  </section>;
}

function closeSocket(socket) {
  if (!socket || socket.readyState >= WebSocket.CLOSING) return;
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: "close" }));
  socket.close();
}

export function WindowsLocalTerminalPane({ onExit, closing = false, active = true, sshControls }) {
  const [attempt, setAttempt] = useState(0);
  const [phase, setPhase] = useState("opening");
  const [error, setError] = useState("");
  const [output, setOutput] = useState("");
  const [command, setCommand] = useState("");
  const [user, setUser] = useState("");
  const connection = useRef(null);
  const input = useRef(null);
  const log = useRef(null);
  const followOutput = useRef(true);
  const history = useRef([]);
  const historyIndex = useRef(0);
  const draft = useRef("");
  const onExitRef = useRef(onExit);
  const closingRef = useRef(closing);
  onExitRef.current = onExit;
  closingRef.current = closing;

  function append(text) {
    setOutput(previous => (previous + text).slice(-(128 * 1024)));
  }

  useEffect(() => {
    const request = new AbortController();
    let socket;
    let exited = false;
    let failed = false;
    const leave = () => closeSocket(socket);
    window.addEventListener("pagehide", leave);
    setPhase("opening");
    setError("");
    setOutput("");
    setCommand("");
    setUser("");
    history.current = [];
    historyIndex.current = 0;
    draft.current = "";
    followOutput.current = true;
    (async () => {
      const account = await inspectAccount(request.signal);
      if (request.signal.aborted || closingRef.current) return;
      if (!account.available || !account.rules_verified) throw new Error(account.message || "隔离账户尚未就绪。");
      socket = new WebSocket(runtimeSocketURL("/windows-local/terminal"));
      connection.current = socket;
      socket.onmessage = event => {
        if (request.signal.aborted || exited || failed) return;
        try {
          const message = JSON.parse(event.data);
          switch (message.type) {
            case "ready":
              if (message.workerSid !== account.worker_sid || message.instanceId !== account.instance_id) {
                throw new Error("隔离账户档案已变化，请重新连接。");
              }
              if (!closingRef.current) {
                setUser(account.worker_username);
                setPhase("ready");
              }
              break;
            case "output":
              if (typeof message.text !== "string") throw new Error("终端输出格式无效。");
              append(message.text);
              break;
            case "error":
              throw new Error(message.message || "终端运行失败。");
            case "exit":
              exited = true;
              socket.close();
              break;
            default:
              throw new Error("终端返回了无法识别的消息。");
          }
        } catch (err) {
          failed = true;
          setError(err instanceof SyntaxError ? "终端消息格式无效。" : err.message);
          closeSocket(socket);
        }
      };
      socket.onclose = () => {
        if (request.signal.aborted) return;
        connection.current = null;
        if (exited || closingRef.current) { onExitRef.current?.(); return; }
        if (!failed) setError("终端连接已断开。");
        setPhase("closed");
      };
    })().catch(err => {
      if (!request.signal.aborted) { setError(err.message); setPhase("closed"); }
    });
    return () => {
      request.abort();
      window.removeEventListener("pagehide", leave);
      connection.current = null;
      leave();
    };
  }, [attempt]);

  useEffect(() => {
    if (!closing) return;
    const socket = connection.current;
    if (!socket) { onExitRef.current?.(); return; }
    setPhase("closing");
    if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: "close" }));
    else socket.close();
  }, [closing]);

  useEffect(() => {
    if (active && phase === "ready") input.current?.focus();
  }, [active, phase]);

  useEffect(() => {
    if (log.current && followOutput.current) log.current.scrollTop = log.current.scrollHeight;
  }, [output]);

  function sendLine(line, label) {
    const socket = connection.current;
    if (phase !== "ready" || socket?.readyState !== WebSocket.OPEN || !line.trim()) return false;
    if (new TextEncoder().encode(line).length > 16 * 1024) {
      setError("单行命令最多可输入 16 KiB 文本。");
      return false;
    }
    socket.send(JSON.stringify({ type: "input", text: line }));
    followOutput.current = true;
    append(label + "\n");
    setError("");
    return true;
  }
  function submit(event) {
    event.preventDefault();
    if (!sendLine(command, "PS> " + command)) return;
    if (history.current.at(-1) !== command) history.current = [...history.current, command].slice(-50);
    historyIndex.current = history.current.length;
    draft.current = "";
    setCommand("");
    setError("");
    input.current?.focus();
  }

  function browseHistory(event) {
    if (event.nativeEvent.isComposing || event.nativeEvent.keyCode === 229) return;
    if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return;
    const commands = history.current;
    if (!commands.length) return;
    event.preventDefault();
    if (historyIndex.current === commands.length) draft.current = command;
    historyIndex.current = Math.max(0, Math.min(commands.length,
      historyIndex.current + (event.key === "ArrowUp" ? -1 : 1)));
    setCommand(commands[historyIndex.current] ?? draft.current);
  }

  return <section className="windows-local-terminal" aria-label={sshControls ? "隔离账户 SSH 客户端" : "Windows PowerShell 终端"}>
    <div className="windows-local-terminal-status">
      <span role="status">{phase === "opening" ? "正在连接隔离账户…" : phase === "ready" ? user :
        phase === "closing" ? "正在关闭终端…" : "终端已断开"}</span>
      {phase === "closed" && <button type="button" onClick={() => setAttempt(value => value + 1)}>重新连接</button>}
    </div>
    {error && <p role="alert" className="error-message">{error}</p>}
    {sshControls?.(sendLine, phase === "ready")}
    <div className="windows-local-console">
      <pre ref={log} role="log" aria-label={sshControls ? "SSH 输出" : "PowerShell 输出"} tabIndex={0} onScroll={event => {
        const element = event.currentTarget;
        followOutput.current = element.scrollHeight - element.scrollTop - element.clientHeight < 20;
      }}>{output}</pre>
      {phase === "ready" && !sshControls && <form onSubmit={submit}>
        <span aria-hidden="true">PS&gt;</span>
        <input ref={input} aria-label="PowerShell 命令" placeholder="输入命令，按 Enter 运行"
          autoComplete="off" autoCapitalize="off" spellCheck={false} value={command}
          onKeyDown={browseHistory} onChange={event => {
            historyIndex.current = history.current.length;
            setCommand(event.target.value);
          }} />
        <button type="submit" disabled={!command.trim()}>运行</button>
      </form>}
    </div>
  </section>;
}
