parentArgs@{ config, lib, pkgs, baseModules, modules, ... }:

let
  # Keep modules from this eval around
  modules' = modules;

  inherit (config.nixpkgs.localSystem) system;

  # We can make use of the normal NixOS evalConfig here.
  evalConfig = import "${toString pkgs.path}/nixos/lib/eval-config.nix";
in
{
  options.helpers = {
    verbosely = lib.mkOption {
      type = lib.types.unspecified;
      internal = true;
      default = msg: val: if config.verbose then msg val else val;
      description = ''
        Function to use to *maybe* builtins.trace things out.

        Usage:

        ```
        { config, /* ..., */ ... }:
        let
          inherit (config) verbosely;
        in
          /* ... */
        ```
      '';
    };

    composeConfig = lib.mkOption {
      type = lib.types.unspecified;
      internal = true;
      default =
        { config ? {}, modules ? [], ... }@args:
        let
          filteredArgs = lib.filterAttrs (k: v: k != "config") args;
        in
        evalConfig (
          filteredArgs // {
          # Needed for hermetic eval, otherwise `eval-config.nix` will try
          # to use `builtins.currentSystem`.
          inherit system;
          inherit baseModules;
          # Newer versions of the modules system pass specialArgs to modules, so try
          # to pass that to eval if possible.
          specialArgs = parentArgs.specialArgs or { };
          # Merge in this eval's modules with the argument's modules, and finally
          # with the given config.
          modules = modules' ++ modules ++ [ config ];
        });
      description = ''
        `config.helpers.composeConfig` is the supported method used to
        re-evaluate a configuration with additional configuration.

        Can be used exactly like `evalConfig`, with one additional param.

        The `config` param directly takes a module (attrset or function).
      '';
    };

    mkImageBuilderEvalOption = lib.mkOption {
      type = lib.types.unspecified;
      internal = true;
      default = args: lib.mkOption ({
        type = lib.types.submodule ({
          imports = import (../support/image-builder/disk-image/module-list.nix);
          _module.args.pkgs = pkgs;
        });
        description = ''
          A disk image configuration.
        '';
      } // args);
      description = ''
        Helper to add a disk image evaluation.
      '';
    };
  };
}
