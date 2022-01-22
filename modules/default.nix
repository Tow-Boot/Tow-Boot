{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  imports = [
    ./hardware
    ./build.nix
    ./device.nix
    ./overlays.nix
    ./system.nix
    ./temp.nix # legacy builder support during migration
  ];

  options = {
    verbose = mkOption {
      description = ''
        Used to print more information during the system evaluation.

        Build results **should not be different**. If they are, it is a bug.
      '';
      type = types.bool;
      default = false;
      internal = true;
    };
    helpers = {
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
    };
  };
}
