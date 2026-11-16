import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fetchCloudCore } from "./fetch-cloud-core.mjs";

const payload = Buffer.from("cloud-core-fixture\n".repeat(4096));
const sha256 = createHash("sha256").update(payload).digest("hex");
process.env.NO_PROXY = [process.env.NO_PROXY, "127.0.0.1"].filter(Boolean).join(",");
process.env.no_proxy = process.env.NO_PROXY;

function respond(request, response, data = payload) {
  const offset = Number(request.headers.range?.match(/^bytes=(\d+)-$/)?.[1] || 0);
  response.writeHead(offset ? 206 : 200, {
    "Content-Length": data.length - offset,
    ...(offset ? { "Content-Range": `bytes ${offset}-${data.length - 1}/${data.length}` } : {}),
  });
  response.end(data.subarray(offset));
}

async function fixture(t, handler = (request, response) => respond(request, response)) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "cage-cloud-core-"));
  const directory = path.join(root, "cache with spaces");
  const requests = [];
  const server = http.createServer((request, response) => {
    requests.push(request.headers.range || "full");
    handler(request, response, requests.length);
  });
  await new Promise(resolve => server.listen(0, "127.0.0.1", resolve));
  t.after(async () => {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    fs.rmSync(root, { recursive: true, force: true });
  });
  const dependency = { file: "mihomo.gz", sha256, url: `http://127.0.0.1:${server.address().port}/mihomo.gz` };
  const cache = path.join(directory, dependency.file);
  return { directory, requests, cache, partial: cache + ".part", dependency,
    fetch: () => fetchCloudCore(dependency, directory),
    handler: next => { handler = next; },
    seed: (file, data) => { fs.mkdirSync(directory, { recursive: true }); fs.writeFileSync(file, data); },
  };
}

test("downloads to the persistent cache and reuses verified bytes without another request", async t => {
  const f = await fixture(t, (request, response) => respond(request, response));
  assert.equal(await f.fetch(), f.cache);
  assert.deepEqual(fs.readFileSync(f.cache), payload);
  assert.equal(fs.existsSync(f.partial), false);
  assert.equal(await f.fetch(), f.cache);
  assert.deepEqual(f.requests, ["full"]);
});

test("resumes the bytes received before a connection drops", async t => {
  const f = await fixture(t, (request, response, number) => {
    if (number > 1) return respond(request, response);
    response.writeHead(200, { "Content-Length": payload.length });
    response.write(payload.subarray(0, 4096));
    setTimeout(() => response.destroy(), 30);
  });
  await f.fetch();
  assert.deepEqual(f.requests, ["full", "bytes=4096-"]);
  assert.deepEqual(fs.readFileSync(f.cache), payload);
});

test("restarts cleanly when the server ignores Range or returns 416", async t => {
  for (const status of [200, 416]) await t.test(String(status), async t => {
    const f = await fixture(t, (request, response) => {
      if (request.headers.range && status === 416) {
        response.writeHead(416, { "Content-Range": `bytes */${payload.length}` });
        return response.end();
      }
      response.writeHead(200, { "Content-Length": payload.length });
      response.end(payload);
    });
    f.seed(f.partial, payload.subarray(0, 4096));
    await f.fetch();
    assert.deepEqual(f.requests, ["bytes=4096-", "full"]);
    assert.deepEqual(fs.readFileSync(f.cache), payload);
  });
});

test("discards a corrupt partial after verification and downloads a fresh copy", async t => {
  const f = await fixture(t, (request, response) => respond(request, response));
  f.seed(f.partial, Buffer.alloc(4096, "x"));
  await f.fetch();
  assert.deepEqual(f.requests, ["bytes=4096-", "full"]);
  assert.deepEqual(fs.readFileSync(f.cache), payload);
});

test("never publishes bytes with the wrong checksum and bounds the retries", async t => {
  const f = await fixture(t, (request, response) => respond(request, response, Buffer.alloc(payload.length, "x")));
  await assert.rejects(f.fetch(), /checksum mismatch/);
  assert.equal(f.requests.length, 4);
  assert.equal(fs.existsSync(f.cache), false);
  assert.equal(fs.existsSync(f.partial), false);
});

test("keeps interrupted progress after retry exhaustion for the next build", async t => {
  const f = await fixture(t, (request, response) => {
    const offset = Number(request.headers.range?.match(/^bytes=(\d+)-$/)?.[1] || 0);
    response.writeHead(offset ? 206 : 200, {
      "Content-Length": payload.length - offset,
      ...(offset ? { "Content-Range": `bytes ${offset}-${payload.length - 1}/${payload.length}` } : {}),
    });
    response.write(payload.subarray(offset, offset + 4096));
    setTimeout(() => response.destroy(), 30);
  });
  await assert.rejects(f.fetch());
  assert.deepEqual(f.requests, ["full", "bytes=4096-", "bytes=8192-", "bytes=12288-"]);
  assert.equal(fs.existsSync(f.cache), false);
  assert.equal(fs.statSync(f.partial).size, 16384);
  f.handler((request, response) => respond(request, response));
  await f.fetch();
  assert.equal(f.requests.at(-1), "bytes=16384-");
  assert.deepEqual(fs.readFileSync(f.cache), payload);
});

test("promotes a complete verified partial without contacting the server", async t => {
  const f = await fixture(t);
  f.seed(f.partial, payload);
  assert.equal(await f.fetch(), f.cache);
  assert.deepEqual(f.requests, []);
  assert.equal(fs.existsSync(f.partial), false);
});

test("rejects a corrupt existing cache without using or replacing it", async t => {
  const f = await fixture(t);
  f.seed(f.cache, "bad cache");
  await assert.rejects(f.fetch(), /checksum mismatch/);
  assert.deepEqual(f.requests, []);
  assert.equal(fs.readFileSync(f.cache, "utf8"), "bad cache");
});
