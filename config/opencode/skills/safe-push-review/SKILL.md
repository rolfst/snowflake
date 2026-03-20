---
name: safe-push-review
description: Safe git push workflow with sensitive file detection and PR enforcement. **Use for**: git push, commits, PRs, sensitive files (credentials/secrets), main branch protection, force push checks.
license: Proprietary
compatibility: opencode
metadata:
  audience: maintainers
  workflow: git
  category: governance
  risk: high
  owner: Foundation department at DHL eCommerce BNL, IT & Digital
---

# Safe Push Review

This skill enforces strict controls over committing, adding files, and pushing:

1. **User Confirmation Gate**  
   Never push until the user explicitly confirms the feature/bugfix has been validated end‑to‑end.

2. **Sensitive Content Gate**  
   Before staging or committing files, evaluate whether any new/modified file contains sensitive data:
   - GDPR special‑category personal data (racial/ethnic origin, political opinions, religious/philosophical beliefs, trade‑union membership, genetic/biometric data for identification, health data, sex life/sexual orientation) [2](https://blog.wenhaofree.com/en/posts/articles/opencode-installation-guide/)[3](https://github.com/opencode-ai/opencode/blob/main/internal/llm/tools/sourcegraph.go)  
   - Secrets (API keys, access tokens, passwords, private keys, connection strings). GitHub secret scanning and tools like TruffleHog detect such leaked credentials across full git history. [4](https://numman-ali.github.io/opencode-openai-codex-auth/development/CONFIG_FLOW.html)[5](https://opencode.ai/docs/skills)  
   If any file is risky, do **not** add/commit until the user decides how to resolve it.

3. **No Direct Pushes to `main`**  
   Never push directly to the `main` branch.  
   Instead:
   - Create or use a **feature branch**.  
   - Push only to that branch.  
   - Require the user to **open a PR**, review it, and merge via the PR interface.  
   Rationale: Git workflows often use pre‑push checks to prevent unsafe direct pushes to protected branches, similar to guardrails implemented in Git pre‑push hooks that block direct pushes to `master/main`. [6](https://opencode.ai/)

4. **PR‑Only Integration**  
   It is acceptable to push updates **to the feature branch that is already linked to an open PR**, but:
   - The user must always be the one reviewing and merging via the PR.  
   - The agent must never auto‑merge.

---

## When to Use Me

- Whenever the agent is about to:
  - Stage (`git add`) or commit files.
  - Propose pushing code.
  - Create new files whose sensitivity should be reviewed.
  - Update a PR branch.

---

## Guardrails (Hard Rules)

- **Pushing:**  
  - Allowed only to **non‑main** branches.  
  - Never run `git push` without explicit user confirmation:  
    “Confirmed to push.”

- **Merging:**  
  - Agent must not merge PRs.  
  - Only the user merges to `main`.

- **Sensitive File Review:**  
  Per file, check for:
  - GDPR special‑category personal data. [2](https://blog.wenhaofree.com/en/posts/articles/opencode-installation-guide/)[3](https://github.com/opencode-ai/opencode/blob/main/internal/llm/tools/sourcegraph.go)  
  - Secrets or credentials. GitHub and TruffleHog scanning background supports this risk. [4](https://numman-ali.github.io/opencode-openai-codex-auth/development/CONFIG_FLOW.html)[5](https://opencode.ai/docs/skills)  
  - Logs, data dumps, screenshots, user files, fixtures with real data, or any PII.

  If sensitive, pause and ask the user whether to:
  - Exclude (`.gitignore`)
  - Scrub/redact
  - Store outside git (secret manager / env vars)
  - Keep locally and not commit

---

## Step‑by‑Step Workflow

1. **Before staging files**  
   - List files to be added.  
   - Run the sensitivity checklist per file.  
   - Stop if risk is detected and ask for instructions.

2. **Branch Check**  
   - Detect current branch.  
   - If `main`:  
     - Refuse to push.  
     - Suggest creating a feature branch:  
       `git switch -c <feature-name>`

3. **Push Gate**  
   - Ask:  
     > “Please confirm the feature/bugfix works end-to-end. Reply ‘Confirmed to push’ to proceed.”  
   - If user confirms, push **only to the feature branch**.

4. **PR Enforcement**  
   - If no PR exists, suggest opening one.  
   - If a PR exists, allow pushing updates to the PR branch.  
   - Do not merge the PR yourself.

---

## Sensitive Content Checklist

### A. GDPR Special‑Category Data  
Treat as **high‑risk**:  
- Racial/ethnic origin  
- Political opinions  
- Religious/philosophical beliefs  
- Trade‑union membership  
- Genetic/biometric data for identifying a person  
- Health data  
- Sex life/sexual orientation[2](https://blog.wenhaofree.com/en/posts/articles/opencode-installation-guide/)[3](https://github.com/opencode-ai/opencode/blob/main/internal/llm/tools/sourcegraph.go)

### B. Secrets / Credentials  
- API keys  
- Access tokens  
- Private keys  
- DB credentials  
- OAuth tokens  
- Cloud provider keys  
Background: GitHub secret scanning finds exposed secrets across full history; TruffleHog scans entire git histories and validates leaked credentials. [4](https://numman-ali.github.io/opencode-openai-codex-auth/development/CONFIG_FLOW.html)[5](https://opencode.ai/docs/skills)

### C. PII or Risky Artifacts  
- Logs  
- User data  
- Real analytics/event dumps  
- Images/screenshots  
- Configuration with embedded credentials

---

## Example Dialog Prompts

**Risk Example:**  
> “`config/dev.json` appears to contain a credential-like string. It may be a secret. Should we exclude, scrub, or relocate it?”

**Main Branch Blocker:**  
> “You’re on `main`. Direct pushes are prohibited. Should I create a feature branch?”

**Push Confirmation:**  
> “If you have verified your change, reply: **Confirmed to push**.”

**PR Reminder:**  
> “A PR is required for merging to `main`. Would you like me to prepare instructions for opening one?”

---

If you want, I can also generate:

- A **matching `/safe-push` slash command**  
- A **`.git/hooks/pre-push`** local script enforcing the same rules  
- A **repository template** including this skill, commands, and recommended `.gitignore` patterns.

Just tell me what you'd like next!