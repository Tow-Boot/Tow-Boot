{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    Tow-Boot = {
      uBootVersion = mkOption {
        type = types.str;
        description = ''
          Version of the underlying U-Boot version.
        '';
      };
      src = mkOption {
        type = types.package;
        description = ''
          Source archive for U-Boot.
        '';
      };
      patches = mkOption {
        type = with types; listOf (oneOf [path package]);
        default = [];
        description = ''
          List of patches to add on top of the source release.

          This includes base feature patches, and board-specific patches alike.
        '';
      };
      useDefaultPatches = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enables inclusion of the default Tow-Boot patch set.

          It is unlikely you want to disable this outright.
        '';
      };

      outputs.firmware = mkOption {
        type = types.package;
        description = ''
          Output of the firmware build (e.g. U-Boot).

          These components are used to build the disk images and other final build artifacts.
        '';
      };

      releaseNumber = mkOption {
        type = types.str;
        description = ''
          Monotonically increasing release number for Tow-Boot.

          This may be attached to various different U-Boot source releases.
        '';
      };
      releaseIdentifier = mkOption {
        type = types.str;
        description = ''
          Must be `-pre` for builds other than ones coming from the clean tagged version commit.
        '';
      };

      defconfig = mkOption {
        type = types.str;
      };
      variant = mkOption {
        # TIP: look for `composeConfig` for customizing `Tow-Boot.variant`.
        type = types.enum [ "noenv" "spi" "mmcboot" ];
        default = "noenv";
        description = ''
          Build variant for this eval.
        '';
      };

      withLogo = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Build with support for the logo.

          Some board builds fail unexpectedly with the logo enabled.
        '';
      };

      # FIXME review how we handle this kind of board-specific customization
      setup_leds = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
  };
}
