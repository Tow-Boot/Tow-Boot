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
          "2021.01" = "sha256-tI80LPNs8jY8Ir78VdHP0NOMZvjkgICWTE1dVUruVIg=";
          "2021.04" = "sha256-QxrTPcx0n0NWUJ990EuIWyOBtknW/fHDRcrYP0yQzTo=";
          "2021.07" = "sha256-e7sXjV+O1BFDtKAhU8kdAk2mWxPTGOvJ5RU3upMM1VM=";
          "2021.10" = "sha256-2CcIHGbm0HPmY63Xsjaf/Yy78JbRPNhmvZmRJAyla2U=";
          "2022.01" = "sha256-kKxo62/TI0HD8uZaL39FyJc783JsErkfspKsQ6uvEMU=";
          "2022.04" = "sha256-iQNy28xMlixQJLc97hfOBwJ0bod1XYRjgIE1UhFslCw=";
          "2022.07" = "sha256-1EONRmYLsD0uxo+kpE6mLIYkYMU09Yt0EvSbHhj5prw=";
          "2022.10" = "sha256-L6AXbJEDx+KoMvqBuJYyIyK2Xn2zyF21NH5mMNvygmM=";
          "2023.01" = "sha256-30fe8klLHRsEtEQ1VpYh4S+AflG5yCQYWlGmpWyFL8w=";
          "2023.04" = "sha256-k4CgiG6rOdgex+YxMRXqyJF7NFqAN9R+UKc3Y/+7jV0=";
          "2023.07" = "sha256-hd9ySV4uUczfigtwrupVlEs8JkK9yX44kaBJgDAykk4=";
          "2023.10" = "sha256-f0xDGxTatRtCxwuDnmsqFLtYLIyjA5xzyQcwfOy3zEM=";
          "2024.01" = "sha256-0Da7Czy9cpQ+D5EICc3/QSZhAdCBsmeMvBgykYhAQFw=";
          "2024.04" = "sha256-IlaDdjKq/Pq2orzcU959h93WXRZfvKBGDO/MFw9mZMg=";
        };
        Tow-Boot = {
          "tb-2023.07-007" = "sha256-qEVvvnKy3fdFmU7Qn1U2PMqhf8p228v6+4XtkVGgQgk=";
        };
      };

      src = if config.Tow-Boot.buildUBoot then
        let knownHashes = config.Tow-Boot.knownHashes.U-Boot; in
        mkDefault (pkgs.Tow-Boot.fetchzip {
          url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${uBootVersion}.tar.bz2";
          hash =
            if knownHashes ? ${uBootVersion}
            then knownHashes.${uBootVersion}
            else builtins.throw "No known hashes for upstream release U-Boot version ${uBootVersion}"
          ;
        })
      else
        let knownHashes = config.Tow-Boot.knownHashes.Tow-Boot; in
        mkDefault (pkgs.Tow-Boot.fetchFromGitHub {
          repo = "U-Boot";
          owner = "Tow-Boot";
          rev = "${tag}";
          hash =
            if knownHashes ? ${tag}
            then knownHashes.${tag}
            else builtins.throw "No known hashes for Tow-Boot-flavoured U-Boot matching tag ${tag}"
          ;
        })
      ;
    };
  };
}
