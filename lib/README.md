# Library Functions

This directory contains custom Nix library functions used throughout the configuration.

## `attrs.nix`

Utilities for manipulating attribute sets.

*   `attrsToList attrs`: Converts an attribute set `{ a = 1; b = 2; }` into a list of key-value pairs `[ { name = "a"; value = 1; } { name = "b"; value = 2; } ]`.
*   `mapFilterAttrs pred f attrs`: Maps function `f` over attributes and then filters them using predicate `pred`.
*   `genAttrs' values f`: Generates an attribute set by applying function `f` to a list of `values`. `f` should return `{ name = ...; value = ...; }`.
*   `anyAttrs pred attrs`: Returns `true` if any attribute satisfies the predicate `pred`.
*   `countAttrs pred attrs`: Returns the count of attributes that satisfy the predicate `pred`.

## `generators.nix`

Functions for generating file artifacts.

*   `toCSSFile file`: Compiles a given `.scss` file to a CSS file using `sass`. Returns the path to the generated CSS file.
*   `toFilteredImage imageFile options`: Applies ImageMagick transformations to an image. `options` is a string of command-line arguments for `convert`. Returns the path to the resulting image.

## `modules.nix`

Utilities for automatically importing and mapping Nix modules.

*   `mapModules dir fn`: Maps function `fn` over all `.nix` files and directories (containing `default.nix`) in `dir`. Ignores files starting with `_` or named `default.nix`. Returns an attribute set.
*   `mapModules' dir fn`: Like `mapModules`, but returns a list of the results.
*   `mapModulesRec dir fn`: Recursively maps `fn` over modules in `dir` and its subdirectories. Returns a nested attribute set.
*   `mapModulesRec' dir fn`: Recursively maps `fn` over modules, returning a flat list of results.

## `options.nix`

Helpers for defining NixOS options.

*   `mkOpt type default`: Creates a `mkOption` with the specified `type` and `default` value.
*   `mkOpt' type default description`: Creates a `mkOption` with `type`, `default`, and `description`.

## `nixos.nix`

Functions for constructing NixOS system configurations.

*   `mkHost path attrs`: Defines a NixOS system configuration.
    *   `path`: Path to the host's directory (containing `default.nix`).
    *   `attrs`: Extra arguments, including `system` (defaults to `x86_64-linux`).
    *   Automatically imports `default.nix`, `hardware-configuration.nix` (if present and imported by the host), and the project's root `default.nix`.
*   `mapHosts dir attrs`: Maps `mkHost` over all host directories in `dir`.

## `homemanager.nix`

*Note: This file appears to contain similar functionality to `nixos.nix` but includes NUR (Nix User Repository) modules.*

*   `mkHost`: Similar to `nixos.nix`'s `mkHost` but includes `inputs.nur.modules.nixos.default` and `inputs.nur.repos.charmbracelet.modules.crush`.
*   `mapHosts`: Maps `mkHost` over a directory.
