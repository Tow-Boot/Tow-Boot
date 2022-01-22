{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    build = {
      default = mkOption {
        description = ''
          Default output for Tow-Boot.

          This contains the unarchived content of the `archive` output.
        '';
        type = types.package;
      };
      archive = mkOption {
        description = ''
          Archived Tow-Boot build.

          The unarchived content are available in the `default` output.
        '';
        type = types.package;
      };
    };
    Tow-Boot = {
      defconfig = mkOption {
        type = types.str;
      };
      # XXX review how we handle this kind of board-specific customization
      setup_leds = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      patches = mkOption {
        type = with types; listOf (oneOf [path package]);
        default = [];
      };
    };
  };
  config = {
    build = {
      archive = pkgs.callPackage (
        { runCommandNoCC, Tow-Boot, name }:
          runCommandNoCC "${name}.tar.xz" {
            inherit name;
          } ''
            PS4=" $ "
          
            (
            dir=$name
            set -x
            cp --no-preserve=mode,owner -r ${Tow-Boot} $dir
            tar -vcJf $out $dir
            )
          ''
        ) {
        Tow-Boot = config.build.default;
        name = "${config.device.identifier}-${config.build.default.version}";
      };
    };
  };
}
