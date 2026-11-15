import assert from "node:assert/strict";
import test from "node:test";
import { workbenchCapabilities, terminalCapability, windowsLiteAdmitted } from "./runtime-capabilities.mjs";

test("a ready Lite space does not imply an implemented application transport", () => {
  const status = { runtime_kind: "windows-lite", ready: true, vm_running: true, windows_lite: { acceptance: "verified", network: "open" } };
  const features = workbenchCapabilities(status);
  assert.equal(features.browser, false);
  assert.equal(features.terminals, false);
  assert.equal(features.editor, false);
  assert.equal(features.desktop, false);
  assert.equal(features.files, false);
});

test("shell support does not admit managed Claude login or session restore", () => {
  const status = { guest_system: "windows-lite", runtime_capabilities: { terminal_stream: true } };
  assert.equal(terminalCapability(status, "shell"), true);
  assert.equal(terminalCapability(status, "claude"), false);
  assert.equal(terminalCapability(status, "claude-login"), false);
  assert.equal(workbenchCapabilities(status).cliSessions, false);
  status.runtime_capabilities.claude_terminal = true;
  assert.equal(terminalCapability(status, "claude"), true);
  assert.equal(terminalCapability(status, "claude-login"), false);
});

test("browser and terminal transports are independently admitted", () => {
  const status = { runtime_kind: "windows-lite", runtime_capabilities: { embedded_browser: true, terminal_stream: false, embedded_desktop: "true" } };
  assert.equal(workbenchCapabilities(status).browser, true);
  assert.equal(workbenchCapabilities(status).terminals, false);
  assert.equal(workbenchCapabilities(status).desktop, false);
});

test("the existing macOS, Windows guest and Linux workbench retain their interfaces", () => {
  for (const guest_system of ["macos", "windows-11", "debian-13", "ubuntu-22.04"]) {
    const features = workbenchCapabilities({ guest_system });
    assert.equal(features.lite, false);
    assert.equal(features.browser, true);
    assert.equal(features.terminals, true);
    assert.equal(features.cliSessions, true);
    assert.equal(features.files, true);
    assert.equal(terminalCapability({ guest_system }, "claude-login"), true);
  }
});

test("Lite application admission closes for every missing or invalid current check", () => {
  const now = Date.now();
  const monitor = { phase: "healthy", lastCheckedAt: new Date(now - 1000).toISOString(), validUntil: new Date(now + 10000).toISOString() };
  const admitted = { runtime_kind: "windows-lite", ready: true, vm_running: true,
    windows_lite: { phase: "running", acceptance: "verified", network: "open", monitor },
    runtime_capabilities: { sandbox_verified: true, network_verified: true } };
  assert.equal(windowsLiteAdmitted(admitted), true);
  for (const override of [
    { ready: false }, { vm_running: false },
    { job: { kind: "start", running: true } },
    { job: { kind: "windows-lite-setup", running: true } },
    { windows_lite: { acceptance: "not-verified", network: "open" } },
    { windows_lite: { acceptance: "verified", network: "unknown" } },
    { windows_lite: { acceptance: "verified", network: "closed" } },
    { runtime_capabilities: { sandbox_verified: false, network_verified: true } },
    { runtime_capabilities: { sandbox_verified: true } },
  ]) assert.equal(windowsLiteAdmitted({ ...admitted, ...override }), false);
  assert.equal(windowsLiteAdmitted(admitted, now + 10001), false);
  for (const phase of ["checking", "blocked", "stopped", "error", "unknown"])
    assert.equal(windowsLiteAdmitted({ ...admitted, windows_lite: { ...admitted.windows_lite, monitor: { ...monitor, phase } } }, now), false);
});
