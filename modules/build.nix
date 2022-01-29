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
  };
  config = {
    build = {
      archive = pkgs.callPackage (
        { runCommandNoCC, Tow-Boot, name }:
          runCommandNoCC "${name}.tar.xz" {
            dir = name;
          } ''
            PS4=" $ "
          
            (
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
