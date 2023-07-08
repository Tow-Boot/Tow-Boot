{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    optionals
    types
  ;
  inherit (config.Tow-Boot) uBootVersion variant;
in

{
  options = {
    Tow-Boot = {
      knownHashes = {
        U-Boot = mkOption {
          type = with types; attrsOf str;
          default = {};
          description = ''
            Attrset of known hases for upstream U-Boot release tarballs.

            Known versions of stock U-Boot.
            This attrset prevents accidental misuse of `uBootVersion`.
            It will break the build if changed to an unknown version, and src has not been overriden.

            > **NOTE**: Presence of a U-Boot version in this attrset does not guarantee it will build and work.
          '';
          internal = true;
        };
        Tow-Boot = mkOption {
          type = with types; attrsOf str;
          default = {};
          description = ''
            Attrset of known hases for Tow-Boot tags release tags.

            This attrset is used to document known Tow-Boot-flavoured U-Boot source trees.
            This prevents uBootVersion being set to a version for which there is no Tow-Boot tree.

            > **NOTE**: Presence of a U-Boot version in this attrset does not guarantee it will build
            >       and work past the releases in which it was used.
          '';
          internal = true;
        };
      };
    };
  };
  config = {
    Tow-Boot = {
      uBootVersion = mkDefault "2022.07";

      knownHashes = {
        U-Boot = {
          "2021.01" = "sha256-tAfhUQp06GO4tctCokYlNE8ODC/HWC2MhmvYmTZ9BFQ=";
          "2021.04" = "sha256-DUOLG7XM61ehjqLeSg1R975bBbmHF98Fk4Y24Krf4Ro=";
          "2021.07" = "sha256-MSt+6uRFgdE2LDo/AsKNgGZHdWyCuoxyJBx82+aLp34=";
          "2021.10" = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
          "2022.01" = "sha256-gbRUMifbIowD+KG/XdvIE7C7j2VVzkYGTvchpvxoBBM=";
          "2022.04" = "sha256-aOBlQTkmd44nbsOr0ouzL6gquqSmiY1XDB9I+9sIvNA=";
          "2022.07" = "sha256-krCOtJwk2hTBrb9wpxro83zFPutCMOhZrYtnM9E9z14=";
        };
        Tow-Boot = {
          "2022.07" = "sha256-AMnY5gzvN66vVJAIlJNzEreNxi0NeVStD55F8u+sm1Q=";
        };
      };

      src = if config.Tow-Boot.buildUBoot then
        let knownHashes = config.Tow-Boot.knownHashes.U-Boot; in
        mkDefault (pkgs.fetchurl {
          url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${uBootVersion}.tar.bz2";
          sha256 =
            if knownHashes ? ${uBootVersion}
            then knownHashes.${uBootVersion}
            else builtins.throw "No known hashes for upstream release U-Boot version ${uBootVersion}"
          ;
        })
      else
        let knownHashes = config.Tow-Boot.knownHashes.Tow-Boot; in
        mkDefault (pkgs.fetchFromGitHub {
          repo = "U-Boot";
          owner = "Tow-Boot";
          rev = "tow-boot/${uBootVersion}/_all";
          sha256 =
            if knownHashes ? ${uBootVersion}
            then knownHashes.${uBootVersion}
            else builtins.throw "No known hashes for Tow-Boot-flavoured U-Boot matching U-Boot version ${uBootVersion}"
          ;
        })
      ;
    };
  };
}
