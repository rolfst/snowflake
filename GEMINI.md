# Snowflake - NixOS Configuration

## Project Overview

**Snowflake** is a declarative NixOS configuration repository managed with [Nix Flakes](https://nixos.wiki/wiki/Flakes).
It provides a modular and reproducible system setup for multiple hosts, integrating [Home Manager](https://github.com/nix-community/home-manager)
for user environment management.

The primary user for this configuration is `rolfst`.

## Directory Structure

*   **`flake.nix`**: The entry point of the configuration. Defines inputs (Nixpkgs, Home Manager, etc.) and outputs (system configurations).
*   **`flake.lock`**: Lock file pinning dependency versions for reproducibility.
*   **`default.nix`**: The base system configuration shared across all hosts. Sets up common options, Nix settings, and imports modules.
*   **`hosts/`**: Contains per-machine configurations. Each directory (e.g., `cleo`, `thinkpad-e595`) represents a distinct system.
    *   `default.nix`: The main configuration file for the host.
    *   `hardware-configuration.nix`: Hardware-specific settings (filesystems, kernel modules).
*   **`modules/`**: Contains reusable configuration modules organized by category (e.g., `desktop`, `develop`, `hardware`, `services`). These modules define options that can be enabled/disabled in host configurations.
    *   `options.nix`: Defines core project options (paths, user settings).
*   **`lib/`**: Custom Nix library functions used throughout the configuration (e.g., for recursively importing modules).
*   **`bin/`**: Custom shell scripts available in the system PATH (via `SNOWFLAKE_BIN`). Examples: `autoclicker`, `batstat`, `brightctl`.
*   **`config/`**: Dotfiles and configuration files for various applications (e.g., `hyprland`, `nvim`, `wezterm`), often symlinked or referenced by Home Manager.
*   **`overlays/`**: Nix overlays to modify or extend package definitions.
*   **`packages/`**: Custom package definitions specific to this repository.

## Key Files

*   **`flake.nix`**: Defines the `nixosConfigurations` output which generates the system.
*   **`hosts/cleo/default.nix`**: An example of a host configuration showing how to enable specific modules (e.g., `modules.desktop.niri.enable = true`).
*   **`modules/options.nix`**: Sets the default user (`rolfst`) and project directories.

## Usage

### Building and Switching

To apply the configuration for a specific host (e.g., `cleo`):

```bash
# From the repository root
sudo nixos-rebuild switch --flake .#cleo --show-trace --impure
```

### Managing Dependencies

Update all flake inputs to their latest versions:

```bash
nix flake update
```

Check the flake for errors:

```bash
nix flake check
```

### Adding a New Host

1.  Create a new directory in `hosts/` (e.g., `hosts/new-machine`).
2.  Generate a hardware configuration: `nixos-generate-config --show-hardware-config > hosts/new-machine/hardware-configuration.nix`.
3.  Create a `hosts/new-machine/default.nix` file. You can copy an existing host's `default.nix` as a template.
4.  Import `hardware-configuration.nix` in `default.nix`.
5.  The new host will be automatically detected by `mapHosts` in `flake.nix` (assuming the standard project structure is followed).

### adding a New Module

1.  Create a `.nix` file in the appropriate subdirectory of `modules/`.
2.  Define options using `mkOption` (often wrapped in project-specific helpers).
3.  Implement the configuration using `mkIf config.modules.path.to.option.enable { ... }`.
4.  Enable the module in your host's `default.nix`.

## Custom Scripts

Scripts in `bin/` are automatically added to the user's PATH.

*   `autoclicker`: A script to automate mouse clicks.
*   `batstat`: Battery status indicator.
*   `brightctl`: Brightness control utility.
*   `micvol`: Microphone volume control.
*   `ocr-region`: OCR utility for a selected screen region.
*   `scrcapy`: Wrapper/utility for scrcpy (Android screen mirroring).
*   `volctl`: Volume control utility.
