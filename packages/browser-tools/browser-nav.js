#!/usr/bin/env bun

import puppeteer from "puppeteer-core";

const url = process.argv[2];
const newTab = process.argv[3] === "--new";

if (!url) {
  console.error("Usage: browser-nav.js <url> [--new]");
  console.error("\nExamples:");
  console.error("  browser-nav.js https://example.com");
  console.error("  browser-nav.js https://example.com --new");
  process.exit(1);
}

const b = await puppeteer.connect({
  browserURL: "http://localhost:9222",
  defaultViewport: null,
});

if (newTab) {
  const p = await b.newPage();
  await p.goto(url, { waitUntil: "domcontentloaded" });
  console.log("✓ Opened:", url);
} else {
  const pages = await b.pages();
  const p = pages.at(-1);
  await p.goto(url, { waitUntil: "domcontentloaded" });
  console.log("✓ Navigated to:", url);
}

await b.disconnect();
