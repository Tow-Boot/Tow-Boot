# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2003-2021 Eelco Dolstra and the Nixpkgs/NixOS contributors
# SPDX-FileCopyrightText: Copyright (c) 2021 Samuel Dionne-Riel and respective contributors
#
# This builder function is heavily based off of the buildUBoot function from
# Nixpkgs.
#
# It does not need to be kept synchronized.
#
# Origin: https://github.com/NixOS/nixpkgs/blob/a4b21085fa836e545dcbd905e27329563c389c6e/pkgs/misc/uboot/default.nix

{ stdenv
, lib
, fetchurl
, fetchpatch
, fetchFromGitHub
, bc
, bison
, dtc
, flex
, openssl
, swig
, meson-tools
, armTrustedFirmwareAllwinner
, armTrustedFirmwareRK3328
, armTrustedFirmwareRK3399
, armTrustedFirmwareS905
, buildPackages
, runCommandNoCC
}:

{
    extraConfig ? ""
  , makeFlags ? []

  , filesToInstall ? []
  , boardIdentifier
  , defconfig
  , patches ? []
  , postPatch ? ""
  , nativeBuildInputs ? []
  , meta ? {}
  , passthru ? {}

  # Either "spi" or "noenv" for now.
  # The variant for environment storage.
  , variant ? null

  , SPISize ? null

  # The platform-specific builder needs to copy binary files
  # to the `binaries` folder, using `Tow-Boot.$variant.bin` for the name.
  , installPhase ? null

  # The following options should only be disabled when it breaks a build.
  , withLogo ? true
  , withTTF ? false # Too many issues for the time being...
  , withPoweroff ? true
  , ...
} @ args:

if variant != "spi" && variant != "noenv" then
  builtins.throw ''A Tow-Boot build requires `variant` to be either "spi" or "noenv".''
else

if installPhase == null then
  builtins.throw "A Tow-Boot build requires `installPhase` to be implemented."
else

if filesToInstall != [] then
  builtins.throw "filesToInstall shouldn't be used anymore for Tow-Boot."
else

let
  uBootVersion = "2021.04";

  # For now, monotonically increasing number.
  # Represents released versions.
  towBootIdentifier = "002${additionalIdentifier}";

  # Identify as "pre-release", as we are still working on this.
  additionalIdentifier = "-pre";

  # To produce the bitmap image:
  #     convert input.png -depth 8 -colors 256 -compress none output.bmp
  # This tiny build produces the `.gz` file that will actually be used.
  compressedLogo = runCommandNoCC "uboot-logo" {} ''
    mkdir -p $out
    cp ${../../../assets/splash.bmp} $out/logo.bmp
    (cd $out; gzip -9 -k logo.bmp)
  '';

  # Not actually configurable. This is a constant in Tow-Boot.
  # Changing this will require handling the migration to a larger size.
  envSizeInKiB = 128;
  envSize = envSizeInKiB * 1024;
  envSPIOffset = SPISize - envSize;

  tow-boot = stdenv.mkDerivation ({
    pname = "tow-boot-${defconfig}-${variant}";
    inherit variant;

    version = "${uBootVersion}-${towBootIdentifier}";

    src = fetchurl {
      url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${uBootVersion}.tar.bz2";
      sha256 = "06p1vymf0dl6jc2xy5w7p42mpgppa46lmpm2ishmgsycnldqnhqd";
    };

    patches = [
      # Misc patches to upstream
      ./patches/0001-cmd-Add-pause-command.patch
      ./patches/0001-cmd-env-Add-indirect-to-indirectly-set-values.patch
      ./patches/0001-lib-export-vsscanf.patch

      # Misc patches, not upstreamable as-is
      ./patches/0001-bootmenu-improvements.patch
      ./patches/0001-Libretech-autoboot-correct-config-naming-only-allow-.patch
      ./patches/0001-autoboot-Prevent-C-from-affecting-menucmd.patch
      ./patches/0001-splash-improvements.patch
      ./patches/0001-drivers-video-Add-dependency-on-GZIP.patch

      # Tow-Boot specific patches, not upstreamable as-is
      ./patches/0001-pdcurses.patch
      ./patches/0001-tow-boot-menu.patch
      ./patches/0001-Tow-Boot-Provide-opinionated-boot-flow.patch
      ./patches/0001-Tow-Boot-treewide-Identify-as-Tow-Boot.patch

      # Intrusive non-upstreamable workarounds
      ./patches/0001-HACK-video-sync-dirty.patch

      # Intrusive opinionated patches
      ./patches/0001-Tow-Boot-sunxi-ignore-mmc_auto-force-SD-then-eMMC.patch
    ] ++ patches;

    postPatch = ''
      patchShebangs tools
      patchShebangs arch/arm/mach-rockchip

      echo ':: Patching baud rate'
      (PS4=" $ "
      for f in configs/*rk3399* configs/*rk3328*; do
        (set -x
        sed -i"" -e 's/CONFIG_BAUDRATE=1500000/CONFIG_BAUDRATE=115200/' "$f"
        )
      done
      for f in arch/arm/dts/*rk3399*.dts* arch/arm/dts/*rk3328*.dts*; do
        (set -x
        sed -i"" -e 's/serial2:1500000n8/serial2:15200n8/' "$f"
        )
      done
      )

      substituteInPlace include/tow-boot_env.h \
        --replace "@boardIdentifier@" "${boardIdentifier}"
    '' + postPatch;

    nativeBuildInputs = [
      bc
      bison
      dtc
      flex
      openssl
      (buildPackages.python3.withPackages (p: [
        p.libfdt
        p.setuptools # for pkg_resources
      ]))
      swig
    ] ++ nativeBuildInputs;

    depsBuildBuild = [ buildPackages.stdenv.cc ];

    hardeningDisable = [ "all" ];

    makeFlags = [
      "DTC=dtc"
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    ] ++ lib.optionals withLogo [
      # Even though the build will actively use the compressed bmp.gz file,
      # we have to provide the uncompressed file and file name here.
      "LOGO_BMP=${compressedLogo}/logo.bmp"
    ] ++ makeFlags
    ;

    extraConfig =
      let
        reset = "\\e[0m";
        bright = "\\e[1m";
      in
    ''
      # Identity
      # --------

      CONFIG_IDENT_STRING="${towBootIdentifier} [variant: ${variant}]"

      # Behaviour
      # ---------

      # Boot menu required for the menu (duh)
      CONFIG_TOW_BOOT_MENU=y

      # Boot menu and default boot configuration

      # Gives *some* time for the user to act.
      # Though an already-knowledgeable user will know they can use the key
      # before the message is shown.
      # Conversely, CTRL+C can cancel the default boot, showing the menu as
      # expected In reality, this gives us MUCH MORE slop in the time window
      # than 2 second.
      CONFIG_BOOTDELAY=2

      # 27 is ESCAPE
      CONFIG_AUTOBOOT_MENUKEY=27

      # So we'll fake that using CTRL+C is what we want...
      # It's only a side-effect.
      CONFIG_AUTOBOOT_PROMPT="${reset}Please press [${bright}ESCAPE${reset}] or [${bright}CTRL+C${reset}] to enter the boot menu."

      # And this ends up causing the menu to be used on ESCAPE (or CTRL+C)
      CONFIG_AUTOBOOT_USE_MENUKEY=y

      # Additional commands
      CONFIG_CMD_BDI=y
      CONFIG_CMD_CLS=y

      ${lib.optionalString withPoweroff ''
      CONFIG_CMD_POWEROFF=y
      ''}

      # Environment
      # -----------
      
      CONFIG_ENV_SIZE=0x${lib.toHexString envSize}
      ${
      if variant == "noenv" then ''
        # CONFIG_TPL_ENV_SUPPORT is not set
        # CONFIG_SPL_ENV_SUPPORT is not set
        CONFIG_ENV_IS_NOWHERE=y
        CONFIG_TPL_ENV_IS_NOWHERE=y
        CONFIG_SPL_ENV_IS_NOWHERE=y
        # CONFIG_ENV_IS_IN_EEPROM is not set
        # CONFIG_ENV_IS_IN_FAT is not set
        # CONFIG_ENV_IS_IN_EXT4 is not set
        # CONFIG_ENV_IS_IN_FLASH is not set
        # CONFIG_ENV_IS_IN_MMC is not set
        # CONFIG_ENV_IS_IN_NAND is not set
        # CONFIG_ENV_IS_IN_NVRAM is not set
        # CONFIG_ENV_IS_IN_ONENAND is not set
        # CONFIG_ENV_IS_IN_REMOTE is not set
        # CONFIG_ENV_IS_IN_SPI_FLASH is not set
        # CONFIG_ENV_IS_IN_UBI is not set
      ''
      else if variant == "spi" then ''
        # CONFIG_TPL_ENV_SUPPORT is not set
        # CONFIG_SPL_ENV_SUPPORT is not set
        # CONFIG_ENV_IS_NOWHERE is not set
        # CONFIG_ENV_IS_IN_EEPROM is not set
        # CONFIG_ENV_IS_IN_FAT is not set
        # CONFIG_ENV_IS_IN_EXT4 is not set
        # CONFIG_ENV_IS_IN_FLASH is not set
        # CONFIG_ENV_IS_IN_MMC is not set
        # CONFIG_ENV_IS_IN_NAND is not set
        # CONFIG_ENV_IS_IN_NVRAM is not set
        # CONFIG_ENV_IS_IN_ONENAND is not set
        # CONFIG_ENV_IS_IN_REMOTE is not set
        CONFIG_ENV_IS_IN_SPI_FLASH=y
        # CONFIG_ENV_IS_IN_UBI is not set
        CONFIG_ENV_SECT_SIZE=0x2000

        # Not the actual address
        CONFIG_ENV_ADDR=0x0
        # The actual address
        CONFIG_ENV_OFFSET=0x${lib.toHexString envSPIOffset}
      ''
      else
        (builtins.throw "variant is invalid")
      }

      # Looks
      # -----

      # Ensures white text on black background
      CONFIG_SYS_WHITE_ON_BLACK=y

      ${lib.optionalString (!withTTF) ''
      # CONFIG_CONSOLE_TRUETYPE is not set
      # CONFIG_CONSOLE_TRUETYPE_NIMBUS is not set
      ''}
      ${lib.optionalString withTTF ''
      # Truetype console configuration
      CONFIG_CONSOLE_TRUETYPE=y
      CONFIG_CONSOLE_TRUETYPE_NIMBUS=y
      CONFIG_CONSOLE_TRUETYPE_SIZE=26
      # Ensure the chosen font is used
      CONFIG_CONSOLE_TRUETYPE_CANTORAONE=n
      CONFIG_CONSOLE_TRUETYPE_ANKACODER=n
      CONFIG_CONSOLE_TRUETYPE_RUFSCRIPT=n
      ''}

      ${lib.optionalString withLogo ''
      # For the splash screen
      CONFIG_CMD_BMP=y
      CONFIG_SPLASHIMAGE_GUARD=y
      CONFIG_SPLASH_SCREEN=y
      CONFIG_SPLASH_SCREEN_ALIGN=y
      CONFIG_VIDEO_BMP_GZIP=y
      CONFIG_VIDEO_BMP_LOGO=y
      CONFIG_VIDEO_BMP_RLE8=n
      CONFIG_BMP_16BPP=y
      CONFIG_BMP_24BPP=y
      CONFIG_BMP_32BPP=y
      CONFIG_SPLASH_SOURCE=n
      ''}

      # Additional configuration (if needed)
      ${extraConfig}
    '';

    # Inject defines for things lacking actual configuration options.
    NIX_CFLAGS_COMPILE = lib.optionals withLogo [
      "-DCONFIG_SYS_VIDEO_LOGO_MAX_SIZE=${toString (1920*1080*4)}"
      "-DCONFIG_VIDEO_LOGO"
    ];

    passAsFile = [ "extraConfig" ];

    configurePhase = ''
      runHook preConfigure
      make ${defconfig}
      cat $extraConfigPath >> .config
      runHook postConfigure
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      mkdir -p $out/config
      cp .config $out/config/$variant.config
      mkdir -p $out/binaries
      ${installPhase}
      runHook postInstall
    '';

    enableParallelBuilding = true;

    dontStrip = true;

    meta = with lib; {
      homepage = "https://github.com/Tow-Boot/Tow-Boot";
      description = "Your boring SBC firmware";
      license = licenses.gpl2;
      maintainers = with maintainers; [ samueldr ];
    } // meta;

    passthru = passthru // {
      inherit
        mkOutput
        patchset
        variant
      ;
    };

  } // removeAttrs args [
    "extraConfig"
    "makeFlags"
    "meta"
    "nativeBuildInputs"
    "patches"
    "postPatch"
    "installPhase"
    "passthru"
  ]);

  mkOutput = commands: runCommandNoCC tow-boot.name { } ''
    (PS4=" $ "; set -x
    mkdir -p "$out"
    cp -rv ${tow-boot.patchset} $out/patches
    ${commands}
    )
  '';

  patchset = runCommandNoCC "patches-for-${tow-boot.name}" { } ''
    (PS4=" $ "; set -x
    mkdir -p $out
    cd $out
    ${lib.concatMapStringsSep "\n" (p: "cp ${p} ./${baseNameOf (toString p)}") tow-boot.patches}
    cat <<EOF > series
    ${lib.concatMapStringsSep "\n" (p: "${baseNameOf (toString p)}") tow-boot.patches}
    EOF
    )
  '';
in
  tow-boot
