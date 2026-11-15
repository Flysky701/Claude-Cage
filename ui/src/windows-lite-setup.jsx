import React, { useEffect, useRef, useState } from "react";
import { Check, LoaderCircle } from "lucide-react";
import { api } from "./api";
import { useAccount } from "./account";
import { GuestSystemPicker } from "./guest-system-picker";
import { SetupProgress } from "./setup-progress";
import { InitializationDetails } from "./initialization-checks";
import { DiagnosticSettings } from "./diagnostics.jsx";
import { SafetyMessage } from "./safety-message";
import { Modal } from "./modal";

export function WindowsLiteSetup({ initial, onComplete }) {
  const { refresh } = useAccount();
  const [initialization, setInitialization] = useState(initial);
  const [status, setStatus] = useState(null);
  const [choice, setChoice] = useState(undefined);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [connectionError, setConnectionError] = useState("");
  const [details, setDetails] = useState(false);
  const [help, setHelp] = useState(false);
  const [confirmStop, setConfirmStop] = useState(false);
  const alive = useRef(true);
  const requestActive = useRef(false);
  const pollNow = useRef(null);
  const acceptedJob = useRef(null);
  const setupJob = status?.job?.kind === "windows-lite-setup" ? status.job : null;
  const job = acceptedJob.current && acceptedJob.current.id !== status?.job?.id ? acceptedJob.current : setupJob;
  const busy = submitting || Boolean(status?.job?.running || job?.running);
  const complete = initialization.prepared && initialization.required === false && !busy && !connectionError;

  useEffect(() => {
    alive.current = true;
    let timer;
    let polling = false;
    const poll = async () => {
      if (!alive.current || polling) return;
      polling = true;
      clearTimeout(timer);
      let running = false;
      try {
        const [nextStatus, nextInitialization] = await Promise.all([api("/status"), api("/environment/initialization")]);
        if (!alive.current) return;
        if (acceptedJob.current?.id === nextStatus.job?.id) acceptedJob.current = null;
        setStatus(nextStatus);
        setInitialization(nextInitialization);
        setConnectionError("");
        running = Boolean(nextStatus.job?.running);
      } catch (failure) {
        if (alive.current) setConnectionError(failure.message);
      } finally {
        polling = false;
        if (alive.current) timer = setTimeout(poll, running ? 1000 : 2500);
      }
    };
    pollNow.current = poll;
    void poll();
    return () => { alive.current = false; clearTimeout(timer); pollNow.current = null; };
  }, []);

  async function install() {
    if (requestActive.current || busy) return;
    requestActive.current = true;
    setSubmitting(true);
    setError("");
    try {
      const accepted = await api("/windows-lite/setup", {});
      const id = accepted.id || accepted.job_id;
      if (!id) throw new Error("安装操作未返回任务编号，请刷新状态后再继续。");
      if (!alive.current) return;
      acceptedJob.current = { ...accepted, id, kind: "windows-lite-setup", running: true };
      await pollNow.current?.();
    } catch (failure) {
      if (alive.current) setError(failure.message);
    } finally {
      requestActive.current = false;
      if (alive.current) setSubmitting(false);
    }
  }

  async function stop() {
    setConfirmStop(false);
    if (requestActive.current) return;
    requestActive.current = true;
    setSubmitting(true);
    setError("");
    try {
      await api("/stop", {});
      acceptedJob.current = null;
      await pollNow.current?.();
    } catch (failure) {
      if (alive.current) setError(failure.message);
    } finally {
      requestActive.current = false;
      if (alive.current) setSubmitting(false);
    }
  }

  async function enter() {
    if (requestActive.current) return;
    requestActive.current = true;
    setSubmitting(true);
    setError("");
    try {
      const next = await api("/environment/initialization");
      if (next.required || !next.prepared) throw new Error("沙箱组件尚未完成安装，请检查安装记录后继续。");
      await refresh();
      if (alive.current) onComplete();
    } catch (failure) {
      if (alive.current) setError(failure.message);
    } finally {
      requestActive.current = false;
      if (alive.current) setSubmitting(false);
    }
  }

  const failed = Boolean(job?.error || job?.canceled);
  const progress = job?.setup_progress && !complete ? job : null;
  return <>
    <section className="initialization-content">
      <div className="initialization-title"><h1>{complete ? "轻量沙箱组件已准备" : busy ? "正在安装 Windows 轻量沙箱" : failed ? "继续安装 Windows 轻量沙箱" : "安装 Windows 轻量沙箱"}</h1>
        <p>自动下载所需组件、安装轻量沙箱并检查启动条件，继续使用 Cage 原来的工作台。</p></div>
      {connectionError && <div className="initialization-notice" role="alert"><SafetyMessage message={connectionError} /><button onClick={() => pollNow.current?.()}>重新连接</button></div>}
      {!status ? <p role="status"><LoaderCircle size={18} className="spin" />正在读取安装状态…</p> : <>
        {!job && !complete && <GuestSystemPicker system={choice} onChange={setChoice} preserveOnUnmount />}
        {complete ? <div className="initialization-ready"><Check size={36} /><h2>下载与组件安装已完成</h2><p>账户、代理、项目和收藏可在原工作台继续管理。应用适配、隔离与出口检查仍以实际结果为准，未通过的运行能力会保持关闭。</p></div>
          : progress ? <SetupProgress job={progress} onDetails={() => setDetails(true)} onRetry={install} onStop={() => setConfirmStop(true)} disconnected={Boolean(connectionError) || submitting} />
          : job && <div className="initialization-operation" role="status">{busy && <LoaderCircle size={22} className="spin" />}<p><SafetyMessage message={job.error || job.message || "正在读取下载与安装阶段…"} /></p><button className="text-button" onClick={() => setDetails(true)}>操作详情</button>{job.running && <button disabled={submitting || Boolean(connectionError)} onClick={() => setConfirmStop(true)}>停止安装</button>}</div>}
        {!complete && <p className="field-help">隔离核心约 25 MB，另需运行组件。下载使用主机网络；出现 Windows 管理员授权时请确认。已有沙箱和个人数据会保留，安装失败后可以继续。</p>}
        {error && <p className="initialization-notice" role="alert"><SafetyMessage message={error} /></p>}
        <footer className="initialization-actions"><span />{complete
          ? <button className="primary" disabled={submitting} onClick={enter}>进入 Cage 工作台</button>
          : !progress && !busy && <button className="primary" disabled={Boolean(connectionError) || (!job && choice?.guest_system !== "windows-lite")} onClick={install}>{job || initialization.started ? "继续下载并安装" : "下载并安装轻量沙箱"}</button>}</footer>
      </>}
      <div className="initialization-support"><button className="text-button" aria-expanded={help} onClick={() => setHelp(!help)}>日志与诊断</button></div>
      {help && <DiagnosticSettings />}
    </section>
    {details && <Modal title="轻量沙箱安装详情" onClose={() => setDetails(false)}><InitializationDetails status={{ ...status, job: job || status?.job }} /></Modal>}
    {confirmStop && <Modal title="停止 Cage 下载与检查？" onClose={() => setConfirmStop(false)} footer={<><button onClick={() => setConfirmStop(false)}>继续等待</button><button onClick={stop}>停止 Cage 任务</button></>}><div className="modal-body"><p>Cage 会停止本次下载与检查。已通过 Windows 管理员授权启动的官方安装程序可能继续运行，请等待它结束后再重试。原空间、个人数据与已保存的下载会保留。</p></div></Modal>}
  </>;
}
