# Agent Context

## System Environment

- **OS**: NixOS
- **Possible hosts**: `clea`, `hp-zero`

### Host Detection

At the start of a session, determine the current host by running `hostname` if not already known. When the user explicitly states the host, use that directly. This matters for host-specific NixOS configurations, paths, and hardware differences.

### Source Control

- **SCM Tool**: [Jujutsu (`jj`)](https://github.com/martinvonz/jj)
- When looking up history, diffs, or changes, use `jj` commands instead of `git`.
- Key commands:
  - `jj log` — view commit history
  - `jj diff` — show changes
  - `jj show <change-id>` — inspect a specific change
  - `jj status` — working copy status
