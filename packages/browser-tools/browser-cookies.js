#!/usr/bin/env bun

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

const cookies = await p.cookies();

console.log(JSON.stringify(cookies));

await b.disconnect();
