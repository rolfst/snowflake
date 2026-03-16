# nixos/nvidia: suspend-then-hibernate broken — missing service wiring, missing system-sleep hook, missing SYSTEMD_SLEEP_FREEZE_USER_SESSIONS

## Description

The NixOS NVIDIA module has three gaps that prevent `suspend-then-hibernate` from working on NVIDIA systems. Together, they cause either error `-5` (EIO) suspend failures, black screens on resume, or both.

This issue covers all three; they're tightly coupled and should land together.

### Bug 1: NVIDIA sleep services not wired to `systemd-suspend-then-hibernate.service`

The NixOS NVIDIA module (when `powerManagement.enable = true`) wires `nvidia-suspend`, `nvidia-hibernate`, and `nvidia-resume` as dependencies of `systemd-suspend.service` and `systemd-hibernate.service`, but **not** `systemd-suspend-then-hibernate.service` (or `systemd-hybrid-sleep.service`).

When logind triggers `systemd-suspend-then-hibernate.service` (common laptop config via `HandleLidSwitch=suspend-then-hibernate`), the NVIDIA driver's procfs suspend interface (`/proc/driver/nvidia/suspend`) is never called. With `PreserveVideoMemoryAllocations=1` (injected by `powerManagement.enable`), the driver refuses to suspend:

```
NVRM: GPU 0000:01:00.0: PreserveVideoMemoryAllocations module parameter is set.
System Power Management attempted without driver procfs suspend interface.

nvidia 0000:01:00.0: PM: pci_pm_suspend(): nv_pmops_suspend [nvidia] returns -5
PM: Some devices failed to suspend, or early wake event detected
```

This causes an infinite retry loop — logind retries every ~30 seconds, each attempt fails, and the laptop runs all night with the screen off draining battery.

### Bug 2: NVIDIA's shipped `system-sleep/nvidia` hook not deployed

The NVIDIA driver package ships a system-sleep hook at `lib/systemd/system-sleep/nvidia` that handles suspend-then-hibernate mid-cycle GPU transitions:

- `post:*` in suspend-then-hibernate → lightweight `echo resume > /proc/driver/nvidia/suspend` (no VT switch)
- `pre:hibernate` → `echo hibernate > /proc/driver/nvidia/suspend`
- `pre:suspend-after-failed-hibernate` → `echo suspend > /proc/driver/nvidia/suspend`

NixOS does **not** deploy this hook because `systemd.packages` only picks up `.service`/`.timer` units from `lib/systemd/system/`, not `lib/systemd/system-sleep/` hooks.

Without this hook, the GPU never receives the mid-cycle `hibernate` prep command during the suspend→hibernate transition, nor the lightweight `resume` command between phases. This causes black screens on resume even when the service wiring is correct.

### Bug 3: Missing `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false` environment

systemd 256+ introduced user session freezing during sleep. This freezes user sessions **before** `nvidia-sleep.sh` can write to `/proc/driver/nvidia/suspend`, breaking NVIDIA's suspend preparation entirely. Every major distro ships a workaround:

- **Arch Linux**: nvidia-utils includes a drop-in override ([MR #24](https://gitlab.archlinux.org/archlinux/packaging/packages/nvidia-utils/-/merge_requests/24), landed July 2024)
- **Debian**: [Bug #1072722](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1072722)
- **Gentoo**: Patched in nvidia-drivers 550.127.05-r1+
- **openSUSE**: Patched systemd directly

NixOS does not ship this workaround. It affects both open and proprietary drivers.

**Note**: This is also reported independently as #371058, though that issue doesn't propose a module-level fix.

## Affected configuration

Any NixOS system with all of:
- `hardware.nvidia.powerManagement.enable = true`
- Logind or user config triggering `suspend-then-hibernate` or `hybrid-sleep`
- systemd 256+ (for bug 3)

Both open (`hardware.nvidia.open = true`) and proprietary drivers are affected.

## Steps to reproduce

1. Configure a laptop with NVIDIA GPU and `hardware.nvidia.powerManagement.enable = true`
2. Set `HandleLidSwitch = "suspend-then-hibernate"` in logind
3. Close the laptop lid
4. Observe `journalctl -u systemd-suspend-then-hibernate.service` — repeated failures
5. Observe `journalctl -k | grep nv_pmops_suspend` — error `-5` on every attempt

## Proposed fix

All three bugs should be fixed in `nixos/modules/hardware/video/nvidia.nix`:

### 1. Wire existing services to suspend-then-hibernate (and hybrid-sleep)

Rather than creating new separate services, extend the existing `nvidia-suspend` and `nvidia-resume` services:

```nix
nvidia-suspend = (nvidiaService "suspend") // {
  before = [
    "systemd-suspend.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-hybrid-sleep.service"
  ];
  requiredBy = [
    "systemd-suspend.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-hybrid-sleep.service"
  ];
};
nvidia-resume = (nvidiaService "resume") // {
  before = [ ];
  after = [
    "systemd-suspend.service"
    "systemd-hibernate.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-hybrid-sleep.service"
  ];
  requiredBy = [
    "systemd-suspend.service"
    "systemd-hibernate.service"
    "systemd-suspend-then-hibernate.service"
    "systemd-hybrid-sleep.service"
  ];
};
```

### 2. Deploy NVIDIA's system-sleep hook

```nix
environment.etc."systemd/system-sleep/nvidia".source = lib.mkIf cfg.powerManagement.enable (
  pkgs.writeShellScript "nvidia-sleep" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.kbd ]}:$PATH
    exec "${nvidia_x11.out}/lib/systemd/system-sleep/nvidia" "$@"
  ''
);
```

### 3. Set `SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false`

```nix
systemd.services.systemd-suspend.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
systemd.services.systemd-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
systemd.services.systemd-suspend-then-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
systemd.services.systemd-hybrid-sleep.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
```

A complete standalone fix file is provided separately.

## Tested on

- NixOS 25.11 (unstable), kernel 6.12.75, systemd 258.3
- NVIDIA open driver 580.119.02, RTX A2000 Mobile (GA107GLM Ampere) with Intel TigerLake PRIME offload
- Full suspend-then-hibernate cycle verified working: s2idle suspend → 15min timer → hibernate → resume from disk with session intact

## Related

- **PR #440422**: Addresses bug 1 and 2, but creates separate services instead of extending existing ones, and does not address bug 3 (`SYSTEMD_SLEEP_FREEZE_USER_SESSIONS`). A reviewer [commented](https://github.com/NixOS/nixpkgs/pull/440422#issuecomment-3609378931) suggesting the simpler approach of adding targets to existing services.
- **Issue #371058**: Reports bug 3 (`SYSTEMD_SLEEP_FREEZE_USER_SESSIONS`) independently, but doesn't propose a module-level fix. Comments confirm the issue affects AMD GPUs too (systemd-level, not NVIDIA-specific).
- **NVIDIA open-gpu-kernel-modules #472**: The underlying S3 resume bug with `PreserveVideoMemoryAllocations=1` (open since March 2023, 57+ thumbsup).
- **NVIDIA open-gpu-kernel-modules #834**: systemd session freeze regression report.

## Environment

- NixOS 25.11 (unstable)
- Kernel 6.12.75
- NVIDIA open driver 580.119.02
- systemd 258.3
- NVIDIA RTX A2000 Mobile (GA107GLM Ampere) with Intel PRIME offload
