# nixos/nvidia: fix suspend-then-hibernate support
#
# This file contains the proposed changes to nixos/modules/hardware/video/nvidia.nix
# in nixpkgs to fix three bugs that break suspend-then-hibernate on NVIDIA systems.
#
# Bug 1: nvidia-suspend/hibernate/resume not wired to systemd-suspend-then-hibernate
# Bug 2: NVIDIA's shipped system-sleep hook not deployed
# Bug 3: SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false not set (systemd 256+)
#
# Related:
#   - PR #440422 (partial fix, different approach)
#   - Issue #371058 (SYSTEMD_SLEEP_FREEZE_USER_SESSIONS)
#   - NVIDIA open-gpu-kernel-modules #472 (S3 resume bug)
#   - NVIDIA open-gpu-kernel-modules #834 (systemd freeze regression)
#
# Tested on: NixOS 25.11, kernel 6.12.75, NVIDIA open 580.119.02, systemd 258.3
#            Full suspend → hibernate → resume-from-disk cycle verified working.
#
# =============================================================================
# HOW TO APPLY
# =============================================================================
#
# Replace the relevant sections in nixos/modules/hardware/video/nvidia.nix
# (around lines 579-609 in the current nixpkgs unstable as of 2026-03-18).
#
# The diff below is against commit context of nixpkgs unstable.
#
# =============================================================================
# DIFF (apply with: git apply <this-file>.patch)
# =============================================================================
#
# --- a/nixos/modules/hardware/video/nvidia.nix
# +++ b/nixos/modules/hardware/video/nvidia.nix
# @@ -578,6 +578,22 @@
#
#            systemd.packages = lib.optional cfg.powerManagement.enable nvidia_x11.out;
#
# +          # Deploy NVIDIA's shipped system-sleep hook.
# +          # NixOS's systemd.packages only picks up .service/.timer units from
# +          # lib/systemd/system/, not lib/systemd/system-sleep/ hooks.
# +          # This hook handles suspend-then-hibernate mid-cycle GPU transitions:
# +          #   post:* → lightweight procfs resume (no VT switch)
# +          #   pre:hibernate → hibernate prep via procfs
# +          #   pre:suspend-after-failed-hibernate → suspend prep via procfs
# +          environment.etc."systemd/system-sleep/nvidia".source = lib.mkIf cfg.powerManagement.enable (
# +            pkgs.writeShellScript "nvidia-sleep" ''
# +              export PATH=${
# +                lib.makeBinPath [
# +                  pkgs.coreutils
# +                  pkgs.kbd
# +                ]
# +              }:$PATH
# +              exec "${nvidia_x11.out}/lib/systemd/system-sleep/nvidia" "$@"
# +            ''
# +          );
# +
# +          # systemd 256+ freezes user sessions before nvidia-sleep.sh can write to
# +          # /proc/driver/nvidia/suspend, breaking NVIDIA's suspend preparation.
# +          # All major distros ship this workaround (Arch, Debian, Gentoo, openSUSE).
# +          # See: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/834
# +          systemd.services.systemd-suspend.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# +          systemd.services.systemd-hibernate.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# +          systemd.services.systemd-suspend-then-hibernate.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# +          systemd.services.systemd-hybrid-sleep.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# +
#            systemd.services =
#              let
#                nvidiaService = state: {
# @@ -588,22 +604,38 @@
#                    ExecStart = "${nvidia_x11.out}/bin/nvidia-sleep.sh '${state}'";
#                  };
#                  before = [ "systemd-${state}.service" ];
#                  requiredBy = [ "systemd-${state}.service" ];
#                };
#              in
#              lib.mkMerge [
#                (lib.mkIf cfg.powerManagement.enable {
# -                nvidia-suspend = nvidiaService "suspend";
# +                nvidia-suspend = (nvidiaService "suspend") // {
# +                  before = [
# +                    "systemd-suspend.service"
# +                    "systemd-suspend-then-hibernate.service"
# +                    "systemd-hybrid-sleep.service"
# +                  ];
# +                  requiredBy = [
# +                    "systemd-suspend.service"
# +                    "systemd-suspend-then-hibernate.service"
# +                    "systemd-hybrid-sleep.service"
# +                  ];
# +                };
#                  nvidia-hibernate = nvidiaService "hibernate";
#                  nvidia-resume = (nvidiaService "resume") // {
#                    before = [ ];
#                    after = [
#                      "systemd-suspend.service"
#                      "systemd-hibernate.service"
# +                    "systemd-suspend-then-hibernate.service"
# +                    "systemd-hybrid-sleep.service"
#                    ];
#                    requiredBy = [
#                      "systemd-suspend.service"
#                      "systemd-hibernate.service"
# +                    "systemd-suspend-then-hibernate.service"
# +                    "systemd-hybrid-sleep.service"
#                    ];
#                  };
#                })


# =============================================================================
# COMPLETE REPLACEMENT BLOCK
# =============================================================================
#
# For easier application, here is the complete replacement for the systemd
# section (lines 579-609) plus the new additions before it.
#
# Copy-paste this block to replace the existing code:

# --- START REPLACEMENT (after line 578: systemd.packages = ...) ---

# environment.etc."systemd/system-sleep/nvidia".source = lib.mkIf cfg.powerManagement.enable (
#   pkgs.writeShellScript "nvidia-sleep" ''
#     export PATH=${
#       lib.makeBinPath [
#         pkgs.coreutils
#         pkgs.kbd
#       ]
#     }:$PATH
#     exec "${nvidia_x11.out}/lib/systemd/system-sleep/nvidia" "$@"
#   ''
# );
#
# # systemd 256+ freezes user sessions before nvidia-sleep.sh can write to
# # /proc/driver/nvidia/suspend, breaking NVIDIA's suspend preparation.
# # Workaround shipped by all major distros. See: NVIDIA/open-gpu-kernel-modules#834
# systemd.services.systemd-suspend.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# systemd.services.systemd-hibernate.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# systemd.services.systemd-suspend-then-hibernate.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
# systemd.services.systemd-hybrid-sleep.serviceConfig.Environment = lib.mkIf cfg.powerManagement.enable "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false";
#
# systemd.services =
#   let
#     nvidiaService = state: {
#       description = "NVIDIA system ${state} actions";
#       path = [ pkgs.kbd ];
#       serviceConfig = {
#         Type = "oneshot";
#         ExecStart = "${nvidia_x11.out}/bin/nvidia-sleep.sh '${state}'";
#       };
#       before = [ "systemd-${state}.service" ];
#       requiredBy = [ "systemd-${state}.service" ];
#     };
#   in
#   lib.mkMerge [
#     (lib.mkIf cfg.powerManagement.enable {
#       nvidia-suspend = (nvidiaService "suspend") // {
#         before = [
#           "systemd-suspend.service"
#           "systemd-suspend-then-hibernate.service"
#           "systemd-hybrid-sleep.service"
#         ];
#         requiredBy = [
#           "systemd-suspend.service"
#           "systemd-suspend-then-hibernate.service"
#           "systemd-hybrid-sleep.service"
#         ];
#       };
#       nvidia-hibernate = nvidiaService "hibernate";
#       nvidia-resume = (nvidiaService "resume") // {
#         before = [ ];
#         after = [
#           "systemd-suspend.service"
#           "systemd-hibernate.service"
#           "systemd-suspend-then-hibernate.service"
#           "systemd-hybrid-sleep.service"
#         ];
#         requiredBy = [
#           "systemd-suspend.service"
#           "systemd-hibernate.service"
#           "systemd-suspend-then-hibernate.service"
#           "systemd-hybrid-sleep.service"
#         ];
#       };
#     })

# --- END REPLACEMENT (continue with existing code from line 610+) ---


# =============================================================================
# DESIGN NOTES
# =============================================================================
#
# Why extend existing services instead of creating new ones (as PR #440422 does):
#
#   PR #440422 creates a separate nvidia-suspend-then-hibernate service that
#   calls `nvidia-sleep.sh 'is-suspend-then-hibernate-supported'` followed by
#   `nvidia-sleep.sh 'suspend'`. This is functionally equivalent to what
#   nvidia-suspend already does — it runs `nvidia-sleep.sh 'suspend'`.
#
#   The suspend-then-hibernate systemd target works as follows:
#   1. First phase: suspends (s2idle or S3) — nvidia-suspend prep is needed
#   2. RTC alarm wakes system after HibernateDelaySec
#   3. Second phase: hibernates — NVIDIA's system-sleep hook handles this
#   4. Resume from hibernate — nvidia-resume handles final VT switch
#
#   Since nvidia-suspend already does the right thing for phase 1, we just
#   need to wire it to the suspend-then-hibernate target. No new service needed.
#
# Why requiredBy (not wantedBy):
#
#   If NVIDIA's suspend prep fails, the system should NOT proceed to suspend.
#   With wantedBy, a failed nvidia-suspend would still allow the system to
#   suspend, potentially corrupting GPU state. requiredBy ensures suspend is
#   aborted on NVIDIA failure, which is the correct safety behavior.
#
# Why the system-sleep hook is critical for suspend-then-hibernate:
#
#   The monolithic systemd-suspend-then-hibernate service doesn't complete
#   until the entire cycle (suspend → wake → hibernate → resume) finishes.
#   This means nvidia-resume (After= suspend-then-hibernate) only fires at
#   the very end. The mid-cycle transitions need the system-sleep hook:
#
#   - After s2idle wakes (pre-hibernate): hook writes "hibernate" to procfs
#   - After hibernate resume: hook writes lightweight "resume" to procfs
#     (no VT switch — that's handled by nvidia-resume at cycle end)
#
# Why SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false:
#
#   systemd 256 (2024-06) added session freezing before sleep. The freeze
#   happens before ExecStart of sleep services, which means nvidia-sleep.sh
#   (running in user context via the system-sleep hook) gets frozen before
#   it can write to /proc/driver/nvidia/suspend.
#
#   This affects ALL NVIDIA systems (open and proprietary drivers), not just
#   suspend-then-hibernate. It should be gated on powerManagement.enable
#   since that's what activates the nvidia-sleep.sh flow.
#
#   Note: systemd warns about this being "not recommended" but every major
#   distro ships it. Upstream NVIDIA hasn't provided an alternative mechanism.
