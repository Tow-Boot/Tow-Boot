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
      tag = mkOption {
        type = types.str;
        internal = true;
        description = ''
          Tag used for the Tow-Boot source code.
        '';
      };
      src = mkOption {
        type = with types; oneOf [path package];
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

      outputName = mkOption {
        type = types.str;
        default = if config.Tow-Boot.buildUBoot then "U-Boot" else "Tow-Boot";
        description = ''
          Base name of the output, depending on what is being built.
        '';
        internal = true;
      };

      buildUBoot = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When false, Tow-Boot is built, which is the default.

          When true, the tooling is used to built U-Boot.

          This can be used to validate the tooling itself builds correct images
          when facing issues, and to more easily check upstream regressions.
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
      releaseRC = mkOption {
        type = types.str;
        default = "";
        internal = true;
        example = "-rc1";
        description = ''
          RC part of the tag, for pre-release management.
        '';
      };
      towBootIdentifier = mkOption {
        internal = true;
        readOnly = true;
        default = "${config.Tow-Boot.releaseNumber}${config.Tow-Boot.releaseRC}${config.Tow-Boot.releaseIdentifier}";
      };

      defconfig = mkOption {
        type = types.str;
      };
      variant = mkOption {
        # TIP: look for `composeConfig` for customizing `Tow-Boot.variant`.
        type = types.enum [ "noenv" "spi" "mmcboot" "boot-installer" ];
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

      VIDEO_LOGO_MAX_SIZE = mkOption {
        type = types.str;
        default = ''0x${lib.toHexString (1920*1080*4)}'';
        internal = true;
      };
    };
  };
}
