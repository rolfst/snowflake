#!/usr/bin/env bun

import { tmpdir } from "node:os";
import { join } from "node:path";
import puppeteer from "puppeteer-core";

const b = await puppeteer.connect({
  browserURL: "http://localhost:9222",
  defaultViewport: null,
});

const pages = await b.pages();
const p = pages.at(-1);

if (!p) {
  console.error("✗ No active tab found");
  process.exit(1);
}

const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
const filepath = join(tmpdir(), `screenshot-${timestamp}.png`);

await p.screenshot({ path: filepath });
console.log(filepath);

await b.disconnect();
