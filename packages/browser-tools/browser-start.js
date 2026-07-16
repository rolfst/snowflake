#!/usr/bin/env bun

import { spawn, execSync } from "node:child_process";
import puppeteer from "puppeteer-core";

const useProfile = process.argv[2] === "--profile";

if (process.argv[2] && process.argv[2] !== "--profile") {
  console.error("Usage: browser-start.js [--profile]");
  console.error("\nOptions:");
  console.error("  --profile  Copy your default Chrome profile (cookies, logins)");
  console.error("\nExamples:");
  console.error("  browser-start.js            # Start with fresh profile");
  console.error("  browser-start.js --profile  # Start with your Chrome profile (ADO, Datadog, etc.)");
  process.exit(1);
}

// Kill existing Chrome
try {
  execSync("pkill -f 'google-chrome-stable.*remote-debugging-port=9222'", { stdio: "ignore" });
} catch {}

await new Promise((r) => setTimeout(r, 1000));

execSync("mkdir -p ~/.cache/browser-tools-profile", { stdio: "ignore" });

if (useProfile) {
  execSync(
    'rsync -a --delete "$HOME/.config/google-chrome/Default/" "$HOME/.cache/browser-tools-profile/"',
    { stdio: "pipe", shell: true }
  );
  console.error("✓ Profile synced from ~/.config/google-chrome/Default");
}

const profileDir = `${process.env["HOME"]}/.cache/browser-tools-profile`;

spawn(
  "google-chrome-stable",
  [
    "--remote-debugging-port=9222",
    `--user-data-dir=${profileDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-background-networking",
    "--disable-sync",
  ],
  { detached: true, stdio: "ignore" }
).unref();

let connected = false;
for (let i = 0; i < 30; i++) {
  try {
    const browser = await puppeteer.connect({
      browserURL: "http://localhost:9222",
      defaultViewport: null,
    });
    await browser.disconnect();
    connected = true;
    break;
  } catch {
    await new Promise((r) => setTimeout(r, 500));
  }
}

if (!connected) {
  console.error("✗ Failed to connect to Chrome on :9222");
  process.exit(1);
}

console.log(`✓ Chrome started on :9222${useProfile ? " with your profile (sessions preserved)" : " (fresh profile)"}`);
