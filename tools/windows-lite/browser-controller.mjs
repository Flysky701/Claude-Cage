// Trusted Cage control process. It attaches only to the browser already admitted
// and launched by the fixed-space worker; it never launches a host browser.
import { chromium } from "./browser/playwright/index.mjs";
import { createWindowsBrowserService, lines } from "./browser/windows-browser.mjs";
import path from "node:path";

const configuration = JSON.parse(process.env.CAGE_LITE_BROWSER_CONFIG || "null");
delete process.env.CAGE_LITE_BROWSER_CONFIG;
if (!configuration || !path.isAbsolute(configuration.directory)) throw new Error("Missing browser controller configuration");
const endpoint = new URL(configuration.cdpURL);
if (endpoint.protocol !== "http:" || endpoint.hostname !== "127.0.0.1" || !endpoint.port || endpoint.pathname !== "/" || endpoint.username || endpoint.password || endpoint.search || endpoint.hash)
  throw new Error("Invalid space-owned browser endpoint");
let attached;
const service = createWindowsBrowserService({
  headless: true,
  tailnet: false,
  directory: configuration.directory,
  downloadDirectory: path.join(configuration.directory, "SavedDownloads"),
  profileDirectory: path.join(configuration.directory, "Profile"),
  executablePath: configuration.executable,
  displayScale: configuration.displayScale || 1,
  chromium: {
    async launchPersistentContext() {
      attached = await chromium.connectOverCDP(configuration.cdpURL, { timeout: 15000, isLocal: true });
      const context = attached.contexts()[0];
      if (!context) throw new Error("Space browser did not return its persistent context");
      // CDP attachment has no launch-context viewport. Apply it before the
      // shared browser service binds targets and starts producing input frames.
      for (const page of context.pages()) await page.setViewportSize({ width: 1140, height: 700 });
      return context;
    },
  },
});
await service.request({ operation: "configure", input: { proxy: configuration.proxyURL, displayScale: configuration.displayScale || 1 } });
try {
  for await (const line of lines(process.stdin)) {
    let result;
    try { result = await service.request(JSON.parse(line)); }
    catch (error) {
      result = { error: error.safe ? error.message : "轻量沙箱浏览器操作失败，请检查空间状态后重试", code: error.safe ? error.code : "browser_operation_failed" };
      if (!error.safe) process.stderr.write(String(error?.stack || error) + "\n");
    }
    await new Promise((resolve, reject) => process.stdout.write(JSON.stringify(result) + "\n", error => error ? reject(error) : resolve()));
  }
} finally {
  await service.close();
  await attached?.close().catch(() => {});
}
