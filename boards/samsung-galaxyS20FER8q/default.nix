{ config, lib, pkgs, ... }:

let
  sourceRevision = "0c3c827df9272308930f798ca0c9d85b7fa3f8b7";
  towBootSource = pkgs.fetchFromGitHub {
    owner = "Tow-Boot";
    repo = "U-Boot";
    rev = "d2a22065a42791c056db08e61758aefab87f8890";
    hash = "sha256-qEVvvnKy3fdFmU7Qn1U2PMqhf8p228v6+4XtkVGgQgk=";
  };
  isTowBoot = !config.Tow-Boot.buildUBoot;
  environment = pkgs.writeText "r8q-tow-boot.env" (builtins.readFile ./tow-boot.env);
in
{
  device = {
    manufacturer = "Samsung";
    name = "Galaxy S20 FE (R8Q)";
    identifier = "samsung-galaxyS20FER8q";
    supportLevel = "experimental";
    inRelease = false;
  };

  hardware.soc = "qualcomm-sm8250";

  Tow-Boot = {
    uBootVersion = "2026.10";
    src = pkgs.fetchurl {
      name = "u-boot-r8q-${sourceRevision}.tar.gz";
      url = "https://codeload.github.com/ben443/u-boot-r8q/tar.gz/${sourceRevision}";
      hash = "sha256-mLQDRxrL1zlQwaSjnS02Nn62MvbEDo9vMXCkgLNAY6o=";
    };
    defconfig = "qcom_defconfig";
    patches = lib.mkForce (lib.optional isTowBoot ./modern-tow-boot.patch);
    withLogo = false;
    # This modern, UFS-based phone uses bootstd, not legacy distro_bootcmd.
    config = lib.mkForce [
      (helpers: with helpers; {
        DEFAULT_DEVICE_TREE = freeform ''"qcom/sm8250-samsung-r8q"'';
        OF_SEPARATE = yes;
        ENV_IS_NOWHERE = yes;
        BAUDRATE = freeform "115200";
        BOOTSTD = yes;
        BOOTSTD_FULL = yes;
        BOOTMETH_EXTLINUX = yes;
        BOOTMETH_EFILOADER = yes;
        CMD_BOOTFLOW = yes;
        CMD_BUTTON = yes;
        CMD_PAUSE = yes;
        EFI_RUNTIME_UPDATE_CAPSULE = no;
        EFI_CAPSULE_ON_DISK = no;
        EFI_CAPSULE_ON_DISK_EARLY = no;
      } // lib.optionalAttrs isTowBoot {
        TOW_BOOT_MENU = yes;
        PDCURSES_PREFER_VIDCONSOLE = yes;
        IDENT_STRING = freeform ''"${config.Tow-Boot.towBootIdentifier} [variant: ${config.Tow-Boot.variant}]"'';
        ENV_DEFAULT_ENV_TEXT_FILE = freeform ''"${environment}"'';
      })
    ];
    builder = {
      environmentFile = null;
      additionalArguments = lib.mkIf isTowBoot {
        passthru.towBootSource = towBootSource;
        prePatch = ''
          cp -prf "$PWD" "$PWD.orig"
          cp -r ${towBootSource}/lib/PDCursesMod lib/
          cp -r ${towBootSource}/cmd/tow-boot cmd/
          chmod -R u+w lib/PDCursesMod cmd/tow-boot
        '';
      };
      nativeBuildInputs = [ pkgs.buildPackages.xxd ];
      configFragments = [
        "board/qualcomm/qcom-phone.config"
        "configs/samsung-sm8250.config"
        "configs/samsung-r8q.config"
      ];
      installPhase = ''
        make $makeFlags "''${makeFlagsArray[@]}" dtbs
        mkdir -p "$out/r8q-build/dts/upstream/src/arm64/qcom"
        cp -v u-boot.bin "$out/binaries/${config.Tow-Boot.outputName}.$variant.bin"
        cp -v u-boot.dtb "$out/binaries/${config.Tow-Boot.outputName}.$variant.control.dtb"
        cp -v u-boot.bin "$out/r8q-build/u-boot.bin"
        cp -v u-boot-nodtb.bin "$out/r8q-build/u-boot-nodtb.bin"
        cp -v u-boot.dtb "$out/r8q-build/u-boot.dtb"
        cp -v dts/upstream/src/arm64/qcom/sm8250-samsung-r8q.dtb \
          "$out/r8q-build/dts/upstream/src/arm64/qcom/sm8250-samsung-r8q.dtb"
      '';
    };
  };

  build.default = lib.mkForce config.Tow-Boot.outputs.firmware;

  documentation.sections.installationInstructions =
    builtins.readFile ./INSTALLING.md;
}
