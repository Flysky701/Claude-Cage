import assert from "node:assert/strict";
import { createWorkbench, chooseInline } from "./workbench-fixture.mjs";

const f = await createWorkbench({
  clientContext: { mode: "local", connection_id: "local", client_platform: "windows", server_platform: "windows", connection: { state: "disconnected" } },
});
const { page, state } = f;
const saved = {
  active: true, running: true, core_available: true, port: 17896,
  selected: "T", route: ["T"], explicit_route: false,
  sources: [{ id: "chain", name: "Imported chain", nodes: [
    { id: "T", name: "Transit T", type: "socks5" },
    { id: "A", name: "Exit A", type: "socks5", dialer_proxy: "T" },
    { id: "B", name: "Exit B", type: "socks5", dialer_proxy: "T" },
  ] }],
};
const submissions = [];
try {
  await page.route("**/api/proxy", r => r.fulfill({ json: saved }));
  for (const action of ["select", "route"]) {
    await page.route(`**/api/proxy/${action}`, r => {
      const body = r.request().postDataJSON();
      submissions.push({ action, body });
      saved.selected = action === "select" ? body.node_id : body.node_ids.at(-1);
      saved.explicit_route = action === "route";
      saved.route = action === "route" ? body.node_ids : saved.selected === "T" ? ["T"] : ["T", saved.selected];
      const job = { id: `route-${submissions.length}`, running: false, message: "已完成" };
      state.status.job = job;
      return r.fulfill({ json: job });
    });
  }
  await page.getByRole("button", { name: /^设置/ }).click();
  await page.getByRole("button", { name: "网络与代理", exact: true }).click();
  const exit = () => page.getByRole("combobox", { name: "最终出口", exact: true });
  const preview = page.getByLabel("待应用链路", { exact: true });
  const apply = async () => {
    await page.getByRole("button", { name: /^(应用代理|重新应用)$/ }).click();
    await page.locator(".proxy-progress").waitFor({ state: "hidden" });
  };
  for (const id of ["A", "B", "A"]) {
    await chooseInline(exit(), id);
    assert.deepEqual(await preview.locator("strong").allTextContents(), ["Transit T", `Exit ${id}`]);
    await apply();
    assert.deepEqual(submissions.at(-1), { action: "select", body: { node_id: id, port: 17896 } });
    assert.equal(await page.getByRole("button", { name: "单节点", exact: true }).getAttribute("aria-pressed"), "true");
    assert.equal(await page.locator(".proxy-current-route").innerText(), `当前链路：Transit T → Exit ${id}`);
  }
  await apply();
  assert.equal(submissions.at(-1).action, "select", "reapply must not convert imported transit into an override");
  await page.getByRole("button", { name: "链式代理", exact: true }).click();
  await chooseInline(page.getByRole("combobox", { name: "中转节点", exact: true }), "B");
  assert.deepEqual(await preview.locator("strong").allTextContents(), ["Exit B", "Exit A"]);
  await apply();
  assert.deepEqual(submissions.at(-1), { action: "route", body: { node_ids: ["B", "A"], port: 17896 } });
  await page.getByRole("button", { name: "单节点", exact: true }).click();
  assert.deepEqual(await preview.locator("strong").allTextContents(), ["Transit T", "Exit A"]);
  await apply();
  assert.equal(submissions.at(-1).action, "select");
  assert.deepEqual(f.errors, []);
  console.log("Imported proxy chains: selection, switching, reapply, explicit override and restoration passed.");
} finally {
  await f.browser.close();
}
