#!/usr/bin/env bun

import puppeteer from "puppeteer-core";

const code = process.argv.slice(2).join(" ");

if (!code) {
  console.error("Usage: browser-eval.js 'javascript'");
  console.error("\nExamples:");
  console.error('  browser-eval.js "document.title"');
  console.error('  browser-eval.js "document.querySelectorAll(\'a\').length"');
  console.error('  browser-eval.js "Array.from(document.querySelectorAll(\'.item\')).map(el => el.textContent.trim())"');
  process.exit(1);
}

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

const result = await p.evaluate((c) => {
  const AsyncFunction = (async () => {}).constructor;
  return new AsyncFunction(`return (${c})`)();
}, code);

console.log(JSON.stringify(result));

await b.disconnect();
