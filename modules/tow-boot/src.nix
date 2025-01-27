{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    optionals
    types
  ;
  inherit (config.Tow-Boot)
    releaseRC
    releaseNumber
    tag
    uBootVersion
    variant
  ;
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
      uBootVersion = mkDefault "2023.07";
      tag =
        let
          releaseNumber = "007"; # No tag yet in the split tree
        in
        mkDefault "tb-${uBootVersion}-${releaseNumber}${releaseRC}"
      ;

      knownHashes = {
        U-Boot = {
          "2021.01" = "sha256-tAfhUQp06GO4tctCokYlNE8ODC/HWC2MhmvYmTZ9BFQ=";
          "2021.04" = "sha256-DUOLG7XM61ehjqLeSg1R975bBbmHF98Fk4Y24Krf4Ro=";
          "2021.07" = "sha256-MSt+6uRFgdE2LDo/AsKNgGZHdWyCuoxyJBx82+aLp34=";
          "2021.10" = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
          "2022.01" = "sha256-gbRUMifbIowD+KG/XdvIE7C7j2VVzkYGTvchpvxoBBM=";
          "2022.04" = "sha256-aOBlQTkmd44nbsOr0ouzL6gquqSmiY1XDB9I+9sIvNA=";
          "2022.07" = "sha256-krCOtJwk2hTBrb9wpxro83zFPutCMOhZrYtnM9E9z14=";
          "2022.10" = "sha256-ULRIKlBbwoG6hHDDmaPCbhReKbI1ALw1xQ3r1/pGvfg=";
          "2023.01" = "sha256-aUI7rTgPiaCRZjbonm3L0uRRLVhDCNki0QOdHkMxlQ8=";
          "2023.04" = "sha256-4xyskVRf9BtxzsXYwir9aVZFzW4qRCzNrKzWBTQGk0E=";
          "2023.07" = "sha256-EukhtGaucxzbw1Xmgyt/IryQsBrs7vmIb5iquns5QwA=";
          "2023.10" = "sha256-4A5sbwFOBGEBc50I0G8yiBHOvPWuEBNI9AnLvVXOaQA=";
          "2024.01" = "sha256-uZYR8e0je/NUG9yENLaMlqbgWWcGH5kkQ8swqr6+9bM=";
          "2024.04" = "sha256-GKhT/jn6160DqQzC1Cda6u1tppc13vrDSSuAUIhD3Uo=";
          "2024.07" = "sha256-9ZHamrkO89az0XN2bQ3f+QxO1zMGgIl0hhF985DYPI8=";
          "2024.10" = "sha256-so2vSsF+QxVjYweL9RApdYQTf231D87ZsS3zT2GpL7A=";
        };
        Tow-Boot = {
          "tb-2023.07-007" = "sha256-qEVvvnKy3fdFmU7Qn1U2PMqhf8p228v6+4XtkVGgQgk=";
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
          rev = "${tag}";
          sha256 =
            if knownHashes ? ${tag}
            then knownHashes.${tag}
            else builtins.throw "No known hashes for Tow-Boot-flavoured U-Boot matching tag ${tag}"
          ;
        })
      ;
    };
  };
}
