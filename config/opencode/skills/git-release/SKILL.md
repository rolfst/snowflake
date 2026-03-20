---
name: git-release
description: Create consistent releases and changelogs from merged PRs; propose semver bumps and generate a release command.
license: Proprietary
compatibility: opencode
metadata:
  category: release-management
  risk: medium
  owner: Foundation department at DHL eCommerce BNL, IT & Digital
  audience: maintainers
  workflow: github
---

## What I do
- Scan merged PRs since the last tag and draft release notes.
- Suggest a semantic version bump (major/minor/patch) based on changes.
- Provide a ready-to-run `gh release create` command with notes.

## When to use me
Use this skill when preparing a tagged release. If the versioning scheme is unclear, **ask for clarification** before proceeding.

## Required context
- Access to git history and tags.
- (Optional) Conventional Commits to improve version bump accuracy.

## Guardrails
- Never push tags without explicit confirmation.
- If multiple PRs are ambiguous, list alternatives and ask which to include.

## Example interaction
- *You:* “Prepare a 1.4.0 release.”
- *Skill:* Proposes notes, shows the diff range, and outputs the `gh release create v1.4.0 -F NOTES.md` command.
``