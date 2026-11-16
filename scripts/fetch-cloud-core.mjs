// Cache the pinned Linux Mihomo archive used by the SSH deployment kit.
import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { setTimeout } from "node:timers/promises";

const run = promisify(execFile);
const manifest = new URL("../packaging/linux/dependencies.json", import.meta.url);
const defaultCache = fileURLToPath(new URL("../_output/linux-deps/", import.meta.url));

async function matches(file, expected) {
  if (!fs.existsSync(file)) return false;
  const hash = createHash("sha256");
  for await (const chunk of fs.createReadStream(file)) hash.update(chunk);
  return hash.digest("hex") === expected;
}

export async function fetchCloudCore(dependency = JSON.parse(fs.readFileSync(manifest)).mihomo, directory = defaultCache) {
  const cache = path.resolve(directory, dependency.file);
  if (fs.existsSync(cache)) {
    if (!await matches(cache, dependency.sha256))
      throw Error(`Linux Mihomo checksum mismatch: ${cache}. Remove the cached file and retry.`);
    return cache;
  }
  fs.mkdirSync(directory, { recursive: true });
  const partial = cache + ".part";
  for (let attempt = 0; attempt < 4; attempt++) {
    // An earlier build may have finished downloading before it was interrupted.
    if (await matches(partial, dependency.sha256)) {
      fs.renameSync(partial, cache);
      return cache;
    }
    try {
      // Retry in separate curl processes: curl's own --retry can truncate the
      // output back to its initial size. A slow but progressing transfer has no
      // total time limit; only connection setup and stalled transfers time out.
      await run("curl", ["--fail", "--location", "--silent", "--show-error",
        "--connect-timeout", "15", "--speed-limit", "1", "--speed-time", "60",
        "--continue-at", "-", "--output", partial, "--write-out", "%{http_code}", dependency.url],
      { windowsHide: true, encoding: "utf8" });
    } catch (error) {
      // Unsupported ranges and stale, oversized partials need a fresh request.
      if (error.code === 33 || error.stdout?.trim() === "416") fs.rmSync(partial, { force: true });
      if (!Number.isInteger(error.code) || attempt === 3) throw error;
      await setTimeout(1000 * (attempt + 1));
      continue;
    }
    if (await matches(partial, dependency.sha256)) {
      // Publish on the same filesystem only after verifying the pinned digest.
      fs.renameSync(partial, cache);
      return cache;
    }
    fs.rmSync(partial, { force: true });
    if (attempt === 3) throw Error("Linux Mihomo checksum mismatch");
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  console.log(`Verified Linux Mihomo at ${await fetchCloudCore()}`);
}
