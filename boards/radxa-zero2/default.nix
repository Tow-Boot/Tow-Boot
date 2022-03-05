{ lib, pkgs, ... }:

let
  # TODO: remove once imported in the LibreELEC FIP frmware packages
  #       alternatively reconsider how we handle vendor-provided blobs?
  radxa-fip = pkgs.callPackage (
    { stdenv
    , lib
    , fetchpatch
    , fetchFromGitHub
    }:

    stdenv.mkDerivation {
      pname = "radxa-fip";
      version = "2022-01-24";

      src = fetchFromGitHub {
        owner = "radxa";
        repo = "fip";
        rev = "4e7cacb68682bf2223974895d8e0d6368beac101";
        sha256 = "sha256-QZ1tqQpnvWrYrkxik3S9dXa0+KqmsH8huFqkw2iyOBk=";
      };

      installPhase = ''
        # We're lazy... this will allow us to *just* copy everything in $out
        rm -v LICENSE README.md
        # Remove unneeded files; we're not re-using the downstream build infra.
        rm -v Makefile
        mkdir -p $out
        mv -t $out/ *
      '';

      dontFixup = true;

      meta = with lib; {
        description = "Firmware Image Package (FIP) sources used to sign Amlogic U-Boot binaries";
        license = licenses.unfreeRedistributableFirmware;
        maintainers = with maintainers; [ samueldr ];
      };
    }
  ) { };
in
{
  device = {
    manufacturer = "Radxa";
    name = "Zero 2";
    identifier = "radxa-zero2";
    productPageURL = "https://wiki.radxa.com/Zero2";
  };

  hardware = {
    soc = "amlogic-a311d";
    mmcBootIndex = "1";
  };

  Tow-Boot = {
    defconfig = "radxa-zero2_defconfig";
    patches = [
      ./0001-radxa-zero2-board-enablement.patch
      ./0001-arch-arm-dts-Sync-amlogic-meson-DT-with-mainline.patch
    ];
    builder.additionalArguments = {
      FIPDIR = "${radxa-fip}/radxa-zero2";
    };
  };
}
