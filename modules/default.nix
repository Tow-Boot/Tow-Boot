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
    ./tow-boot
    ./build.nix
    ./device.nix
    ./documentation.nix
    ./helpers.nix
    ./kconfig.nix
    ./metadata.nix
    ./overlays.nix
    ./system.nix
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
    };
  };
  config = {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.system = "aarch64-linux";
  };
}
