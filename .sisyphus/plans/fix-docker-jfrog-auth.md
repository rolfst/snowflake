# Fix Docker JFrog Registry Auth Module

## TL;DR

> **Quick Summary**: Update the Docker `registryAuth` module to match JFrog's actual auth format — token is pre-encoded (no base64 needed), and `config.json` needs an `email` field instead of `username`.
>
> **Deliverables**:
> - Updated `modules/desktop/virtual/docker.nix` with corrected auth logic
> - Updated `hosts/hp-zero/default.nix` host config to match new options
>
> **Estimated Effort**: Quick
> **Parallel Execution**: NO — 2 sequential edits in same concern
> **Critical Path**: Task 1 → Task 2

---

## Context

### Original Request
User configured Docker registry auth for JFrog Artifactory (`dhlparcel.pe.jfrog.io`). The initial implementation assumed Docker auth requires base64-encoding `username:token`. However, JFrog provides a **pre-encoded** auth token directly, and the Docker `config.json` format includes an `email` field rather than deriving auth from a username.

### JFrog's actual config.json format
```json
{
  "auths": {
    "dhlparcel.pe.jfrog.io": {
      "auth": "<JFROG_TOKEN_ALREADY_ENCODED>",
      "email": "youremail@email.com"
    }
  }
}
```

---

## Work Objectives

### Core Objective
Fix the `registryAuth` options and activation script to match JFrog's actual Docker auth format.

### Concrete Deliverables
- `modules/desktop/virtual/docker.nix` — corrected options and activation script
- `hosts/hp-zero/default.nix` — updated config to use `email` instead of `username`

### Definition of Done
- [ ] `nix eval` or `nixos-rebuild build` succeeds without errors
- [ ] Generated `~/.config/docker/config.json` contains `auth` (raw token, no re-encoding) and `email` fields

### Must Have
- `email` option replaces `username` option
- Token used as-is from the secret (no base64 wrapping)
- `email` field present in generated `config.json`

### Must NOT Have (Guardrails)
- No base64 encoding of the token — it arrives pre-encoded from JFrog
- No `username` option — replaced by `email`
- Do NOT touch any other module or host config

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: N/A (NixOS module, not application code)
- **Automated tests**: None — verified via nix eval and visual inspection
- **Framework**: N/A

### QA Policy
Agent-executed verification via nix build command and file inspection.

---

## Execution Strategy

### Sequential (2 tasks, same concern)

```
Task 1: Fix the docker.nix module (options + activation script)
Task 2: Update hp-zero host config
```

---

## TODOs

- [ ] 1. Fix registryAuth options and activation script in docker.nix

  **What to do**:

  In `modules/desktop/virtual/docker.nix`:

  **A) Replace `username` option with `email` option:**

  Change this option block (lines 32-36):
  ```nix
  username = mkOption {
    type = str;
    default = "";
    description = "Username for Docker registry authentication";
  };
  ```
  To:
  ```nix
  email = mkOption {
    type = str;
    default = "";
    description = "Email address for Docker registry authentication";
  };
  ```

  Also update the `tokenSecretPath` description (line 40) from:
  ```
  "Path to the agenix-decrypted file containing the registry token (read at activation time)"
  ```
  To:
  ```
  "Path to the agenix-decrypted file containing the pre-encoded registry auth token (read at activation time)"
  ```

  **B) Fix the activation script** (lines 77-105):

  Replace the entire `text = let ... in ''...''` block with:
  ```nix
  text = let
    registryUrl = cfg.registryAuth.registry;
    email = cfg.registryAuth.email;
    tokenKey = cfg.registryAuth.tokenKey;
    secretPath = cfg.registryAuth.tokenSecretPath;
    grep = "${pkgs.gnugrep}/bin/grep";
    chmod = "${pkgs.coreutils}/bin/chmod";
    chown = "${pkgs.coreutils}/bin/chown";
    jq = "${pkgs.jq}/bin/jq";
  in ''
    DOCKER_CONFIG_DIR="${userHome}/.config/docker"
    DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/config.json"

    mkdir -p "$DOCKER_CONFIG_DIR"

    TOKEN=$(${grep} -oP '^${tokenKey}=\K[^#]*' "${secretPath}" | head -1 | xargs)

    if [ -n "$TOKEN" ]; then
      ${jq} -n --arg registry "${registryUrl}" --arg auth "$TOKEN" --arg email "${email}" \
        '{ auths: { ($registry): { auth: $auth, email: $email } } }' \
        > "$DOCKER_CONFIG_FILE"

      ${chmod} 600 "$DOCKER_CONFIG_FILE"
      ${chown} ${userName}:users "$DOCKER_CONFIG_FILE"
    fi
  '';
  ```

  Key changes from the current version:
  - Removed `base64` variable and the `AUTH=$(printf ... | base64 ...)` line
  - Token (`$TOKEN`) is passed directly to jq `--arg auth` — no re-encoding
  - Added `--arg email` to jq and included `email: $email` in the JSON template
  - Renamed `username` references to `email`

  **Must NOT do**:
  - Do NOT touch the base docker options (`enable`, `daemonSettings`)
  - Do NOT change the `virtualisation.docker` block
  - Do NOT add base64 encoding

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: [Task 2]
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - `modules/desktop/virtual/docker.nix` — The entire file; this is what we're editing. Current state has the incorrect `username` option (line 32) and base64 encoding logic (line 96).

  **API/Type References**:
  - `modules/options.nix:29` — `mkOpt` and `mkOpt'` helpers (not needed here, but FYI for the codebase pattern)

  **External References**:
  - JFrog Docker config format: auth token is pre-encoded, includes `email` field

  **Acceptance Criteria**:

  ```
  Scenario: Module evaluates without errors
    Tool: Bash
    Steps:
      1. Run: nix eval --raw '.#nixosConfigurations.hp-zero.config.modules.virtualize.docker.registryAuth.email' 2>&1
      2. Assert: output is "rolf.strijdhorst@dhl.com" (after Task 2 applies)
      3. Run: nix eval --raw '.#nixosConfigurations.hp-zero.config.modules.virtualize.docker.registryAuth.registry' 2>&1
      4. Assert: output is "dhlparcel.pe.jfrog.io"
    Expected Result: Both eval commands succeed with correct values
    Evidence: .sisyphus/evidence/task-1-nix-eval.txt

  Scenario: username option no longer exists
    Tool: Bash
    Steps:
      1. Run: grep -n 'username' modules/desktop/virtual/docker.nix
      2. Assert: no matches (exit code 1)
    Expected Result: Zero occurrences of 'username' in docker.nix
    Evidence: .sisyphus/evidence/task-1-no-username.txt

  Scenario: base64 encoding removed
    Tool: Bash
    Steps:
      1. Run: grep -n 'base64' modules/desktop/virtual/docker.nix
      2. Assert: no matches (exit code 1)
    Expected Result: Zero occurrences of 'base64' in docker.nix
    Evidence: .sisyphus/evidence/task-1-no-base64.txt
  ```

  **Commit**: YES
  - Message: `fix(docker): use pre-encoded JFrog auth token and email field`
  - Files: `modules/desktop/virtual/docker.nix`

---

- [ ] 2. Update hp-zero host config to use email instead of username

  **What to do**:

  In `hosts/hp-zero/default.nix`, replace the `docker.registryAuth` block (lines 152-158):

  From:
  ```nix
  docker.registryAuth = {
    enable = true;
    registry = "dhlparcel.pe.jfrog.io";
    username = "rolf.strijdhorst@dhl.com";
    tokenSecretPath = config.age.secrets."private-tokens".path;
    tokenKey = "jfrog";
  };
  ```

  To:
  ```nix
  docker.registryAuth = {
    enable = true;
    registry = "dhlparcel.pe.jfrog.io";
    email = "rolf.strijdhorst@dhl.com";
    tokenSecretPath = config.age.secrets."private-tokens".path;
    tokenKey = "jfrog";
  };
  ```

  Only change: `username` → `email`.

  **Must NOT do**:
  - Do NOT change any other hp-zero config
  - Do NOT modify secrets or agenix setup

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Blocks**: None
  - **Blocked By**: [Task 1]

  **References**:

  **Pattern References**:
  - `hosts/hp-zero/default.nix:147-159` — The virtualize block containing the `docker.registryAuth` config to update

  **Acceptance Criteria**:

  ```
  Scenario: hp-zero config uses email not username
    Tool: Bash
    Steps:
      1. Run: grep -A7 'docker.registryAuth' hosts/hp-zero/default.nix
      2. Assert: output contains 'email = "rolf.strijdhorst@dhl.com"'
      3. Assert: output does NOT contain 'username'
    Expected Result: email field present, username absent
    Evidence: .sisyphus/evidence/task-2-hp-zero-config.txt

  Scenario: Full NixOS configuration builds
    Tool: Bash
    Steps:
      1. Run: nix build '.#nixosConfigurations.hp-zero.config.system.build.toplevel' --dry-run 2>&1
      2. Assert: exit code 0 (no evaluation errors)
    Expected Result: Dry-run build succeeds
    Failure Indicators: "error:" in output, non-zero exit code
    Evidence: .sisyphus/evidence/task-2-nix-build-dryrun.txt
  ```

  **Commit**: YES (group with Task 1)
  - Message: `fix(docker): use pre-encoded JFrog auth token and email field`
  - Files: `modules/desktop/virtual/docker.nix`, `hosts/hp-zero/default.nix`

---

## Commit Strategy

- **Single commit** combining Tasks 1 and 2: `fix(docker): use pre-encoded JFrog auth token and email field`

---

## Success Criteria

### Verification Commands
```bash
nix build '.#nixosConfigurations.hp-zero.config.system.build.toplevel' --dry-run  # Expected: exit 0
grep 'base64' modules/desktop/virtual/docker.nix  # Expected: no matches
grep 'username' modules/desktop/virtual/docker.nix  # Expected: no matches
grep 'email' modules/desktop/virtual/docker.nix  # Expected: matches for the email option
```

### Final Checklist
- [ ] `username` option replaced with `email`
- [ ] No base64 encoding in activation script
- [ ] `jq` template includes `email` field in config.json
- [ ] Token passed as-is from secret to `auth` field
- [ ] hp-zero uses `email` instead of `username`
- [ ] NixOS config evaluates without errors
