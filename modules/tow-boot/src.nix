{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    optionals
  ;
  inherit (config.Tow-Boot) uBootVersion variant;
in

{
  Tow-Boot = {
    uBootVersion = mkDefault "2021.10";

    patches = mkIf (config.Tow-Boot.useDefaultPatches) (
      let
        patchSets = {
          "2021.10" = let base = ../../support/u-boot/2021.10/patches; in [
            # Patches backported from upstream
            (base + "/0001-usb-xhci-reset-endpoint-on-USB-stall.patch")

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
          ]

          #
          # Intrusive opinionated patches
          #

          # Patches to force eMMC OS boot to happen before SD OS boot
          ++ (optionals (variant != "boot-installer") [
            (base + "/0001-Tow-Boot-sunxi-ignore-mmc_auto-force-SD-then-eMMC.patch")
            (base + "/0001-Revert-rockchip-Fix-MMC-boot-order.patch")
            (base + "/0001-meson-Prefer-eMMC-to-SD-card-boot.patch")
          ])
          # Patches to force SD OS boot to happen before OS boot
          ++ (optionals (variant == "boot-installer") [
            # Allwinner detects the platform firmware location and prefers it first
            # Rockchip already prefers SD to eMMC (since b212ad24a604b00b240add35516b7381965deb31)
            # Amlogic already prefers SD to eMMC
          ])
          ;
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
        # NOTE: Presence of a U-Boot version in this attrset does not guarantee it will build and work.
        #       Furthermore, building older versions may require disabling the Tow-Boot patch set.
        #       This is made available as a feature to help diagnose issues against "mostly stock" U-Boot.
        knownHashes = {
          "2021.04" = "sha256-DUOLG7XM61ehjqLeSg1R975bBbmHF98Fk4Y24Krf4Ro=";
          "2021.07" = "sha256-MSt+6uRFgdE2LDo/AsKNgGZHdWyCuoxyJBx82+aLp34=";
          "2021.10" = "1m0bvwv8r62s4wk4w3cmvs888dhv9gnfa98dczr4drk2jbhj7ryd";
          "2022.01" = "sha256-gbRUMifbIowD+KG/XdvIE7C7j2VVzkYGTvchpvxoBBM=";
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
