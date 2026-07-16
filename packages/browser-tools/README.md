# Browser Tools

Minimal browser tools for scraping external sites with persistent sessions.
All scripts are globally available on PATH. Use via Bash.

## Start Browser

```bash
browser-start.js              # Fresh profile
browser-start.js --profile    # Copy your real Chrome profile (ADO, Datadog, other logins)
```

Starts Chrome on `:9222` with remote debugging. Use `--profile` when you need to be logged in.
After starting with `--profile`, your sessions (cookies, auth) are available immediately.

## Navigate

```bash
browser-nav.js https://example.com         # Navigate current tab
browser-nav.js https://example.com --new   # Open in new tab
```

## Evaluate JavaScript

```bash
browser-eval.js 'document.title'
browser-eval.js 'document.querySelectorAll("a").length'
browser-eval.js 'Array.from(document.querySelectorAll(".item")).map(el => ({text: el.textContent.trim(), href: el.href}))'
```

Runs in page context (async). Use DOM APIs directly. Always returns raw JSON to stdout.

```nu
browser-eval.js 'Array.from(document.querySelectorAll(".item")).map(el => ({text: el.textContent.trim(), href: el.href}))' | from json | where text =~ "foo"
browser-eval.js 'document.title' | from json
```

## Screenshot

```bash
browser-screenshot.js
```

Screenshots current viewport, prints temp file path to stdout. Read the file to see the page visually.

## Cookies

```bash
browser-cookies.js
```

Returns all cookies for the current page as a JSON array to stdout.

```nu
browser-cookies.js | from json | where name == "session"
browser-cookies.js | from json | select name value domain
```

## Session Workflow for Authenticated Scraping

1. `browser-start.js --profile` — start with your real sessions
2. `browser-nav.js https://target.com` — navigate
3. `browser-eval.js '...'` — extract data
4. If session expired: close Chrome, re-run `browser-start.js --profile` to re-sync cookies

## Notes

- Only one Chrome instance runs at a time on `:9222`
- Active tab = last opened tab
- Profile is copied from `~/.config/google-chrome/Default` to `~/.cache/browser-tools-profile`
- The copy is yours to debug with; original profile is never modified
