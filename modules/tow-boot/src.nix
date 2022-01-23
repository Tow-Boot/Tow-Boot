{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
  ;
  inherit (config.Tow-Boot) uBootVersion;
in

{
  Tow-Boot = {
    uBootVersion = mkDefault "2021.10";

    patches = mkIf (config.Tow-Boot.useDefaultPatches) (
      let
        patchSets = {
          "2021.10" = let base = ../../support/u-boot/2021.10/patches; in [
            # Misc patches to upstream
            (base + "/0001-cmd-Add-pause-command.patch")
            (base + "/0001-cmd-env-Add-indirect-to-indirectly-set-values.patch")
            (base + "/0001-lib-export-vsscanf.patch")

            # Misc patches, not upstreamable as-is
            (base + "/0001-bootmenu-improvements.patch")
            (base + "/0001-autoboot-show-menu-only-on-menu-key.patch")
            (base + "/0001-autoboot-Prevent-C-from-affecting-menucmd.patch")
            (base + "/0001-splash-improvements.patch")
            (base + "/0001-drivers-video-Add-dependency-on-GZIP.patch")

            # Tow-Boot specific patches, not upstreamable as-is
            (base + "/0001-pdcurses.patch")
            (base + "/0001-tow-boot-menu.patch")
            (base + "/0001-Tow-Boot-Provide-opinionated-boot-flow.patch")
            (base + "/0001-Tow-Boot-treewide-Identify-as-Tow-Boot.patch")

            # Intrusive non-upstreamable workarounds
            (base + "/0001-HACK-video-sync-dirty.patch")

            # Intrusive opinionated patches
            (base + "/0001-Tow-Boot-sunxi-ignore-mmc_auto-force-SD-then-eMMC.patch")
          ];
        };
      in
        if patchSets ? ${uBootVersion}
        then patchSets.${uBootVersion}
        else builtins.trace "Warning: No patch set for U-Boot version ${uBootVersion}"
    );

    src =
      let
        # This attrset prevents accidental misuse of `uBootVersion`.
        # It will break the build if changed to an unknown version, and src has not been overriden.
        knownHashes = {
          "2021.10" = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
        };
      in
      mkDefault (pkgs.fetchurl {
        url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${uBootVersion}.tar.bz2";
        sha256 =
          if knownHashes ? ${uBootVersion}
          then knownHashes.${uBootVersion}
          else builtins.throw "No known hashes for upstream release U-Boot version ${uBootVersion}"
        ;
      })
    ;
  };
}
