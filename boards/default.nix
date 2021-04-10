{ pkgs }: let pkgs' = pkgs; in # Break cycle

let
  addOverlay = pkgs: pkgs.extend (final: super: {
    # FIXME: I don't actually want to directly use buildUBoot...
    #        but this is a starting point for the nix interface.
    buildTowBoot =
    let
      inherit (final) lib;
    in
    {
        extraConfig ? ""
      , extraMakeFlags ? []

      # The following options should only be disabled when it breaks a build.
      , withLogo ? true
      , withTTF ? true
      , withPoweroff ? true
      , ...
    } @ args: final.buildUBoot ({
      pname = "tow-boot-${args.defconfig}";
      version = "tbd";
    } // args // {

      # Inject defines for things lacking actual configuration options.
      NIX_CFLAGS_COMPILE = lib.optionals withLogo [
        "-DCONFIG_SYS_VIDEO_LOGO_MAX_SIZE=${toString (1920*1080*4)}"
        "-DCONFIG_VIDEO_LOGO"
      ];

      extraMakeFlags =
        let
          # To produce the bitmap image:
          #     convert input.png -depth 8 -colors 256 -compress none output.bmp
          # This tiny build produces the `.gz` file that will actually be used.
          compressedLogo = super.runCommandNoCC "uboot-logo" {} ''
            mkdir -p $out
            cp ${../assets/tow-boot-splash.bmp} $out/logo.bmp
            (cd $out; gzip -9 -k logo.bmp)                          
          '';
        in
        lib.optionals withLogo [
          # Even though the build will actively use the compressed bmp.gz file,
          # we have to provide the uncompressed file and file name here.
          "LOGO_BMP=${compressedLogo}/logo.bmp"
        ] ++ extraMakeFlags
      ;

      extraConfig = ''
        # Behaviour
        # ---------

        # Boot menu required for the menu (duh)
        CONFIG_CMD_BOOTMENU=y

        # Boot menu and default boot configuration

        # Gives *some* time for the user to act.
        # Though an already-knowledgeable user will know they can use the key
        # before the message is shown.
        # Conversely, CTRL+C can cancel the default boot, showing the menu as
        # expected In reality, this gives us MUCH MORE slop in the time window
        # than 1 second.
        CONFIG_BOOTDELAY=1

        # This would be escape, but the USB drivers don't really play well and
        # escape doesn't work from the keyboard.
        CONFIG_AUTOBOOT_MENUKEY=27

        # So we'll fake that using CTRL+C is what we want...
        # It's only a side-effect.
        CONFIG_AUTOBOOT_PROMPT="Press CTRL+C for the boot menu."

        # And this ends up causing the menu to be used on CTRL+C (or escape)
        CONFIG_AUTOBOOT_USE_MENUKEY=y

        ${lib.optionalString withPoweroff ''
        # Additional commands
        CONFIG_CMD_CLS=y
        CONFIG_CMD_POWEROFF=y
        ''}

        # Looks
        # -----

        # Ensures white text on black background
        CONFIG_SYS_WHITE_ON_BLACK=y

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
    });
  });

  pkgs = addOverlay pkgs';

  #
  # Targets setup
  # =============
  #

  crossPackageSets = {
    aarch64-linux = pkgs.pkgsCross.aarch64-multiplatform;
    armv7l-linux  = pkgs.pkgsCross.armv7l-hf-multiplatform;
    i686-linux    =
      if pkgs.system == "x86_64-linux"
      then pkgs.pkgsi686Linux
      else pkgs.pkgsCross.gnu32
    ;
    x86_64-linux  = pkgs.pkgsCross.gnu64;
  };

  pkgsFor = wanted:
    if pkgs.system == wanted then pkgs
    else crossPackageSets.${wanted}
  ;

  # Hmmm... `.extend` (and similar) won't work for `pkgsCross` and friend :(
  aarch64 = addOverlay (pkgsFor "aarch64-linux");
  armv7l  = addOverlay (pkgsFor  "armv7l-linux");
  i686    = addOverlay (pkgsFor    "i686-linux");
  x86_64  = addOverlay (pkgsFor  "x86_64-linux");

  #
  # Builder functions
  # =================
  #

  # When the output is `u-boot.bin`, and requires no additional inputs.
  simpleAArch64 = { pkgs, defconfig, ... } @ args: pkgs.buildTowBoot ({
    extraMeta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  } // (removeAttrs args [ "pkgs" ]));

  # For Allwinner A64 based hardware
  allwinnerA64 = { defconfig }: aarch64.buildTowBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.armTrustedFirmwareAllwinner}/bl31.bin";
    filesToInstall = ["u-boot-sunxi-with-spl.bin" ".config"];
  };

  # For Rockchip RK3399 based hardware
  rk3399 = { defconfig, postPatch ? "", postInstall ? "" }: aarch64.buildTowBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.armTrustedFirmwareRK3399}/bl31.elf";
    filesToInstall = [
      ".config"
      "u-boot.itb"
      "idbloader.img"
    ];

    postPatch = ''
      patchShebangs arch/arm/mach-rockchip/
    '' + postPatch;

    postInstall = ''
      tools/mkimage -n rk3399 -T rkspi -d tpl/u-boot-tpl-dtb.bin:spl/u-boot-spl-dtb.bin spl.bin
      cat <(dd if=spl.bin bs=512K conv=sync) u-boot.itb > $out/u-boot.spiflash.bin
    '' + postInstall;

    extraConfig = ''
      # SPI boot Support
      CONFIG_MTD=y
      CONFIG_DM_MTD=y
      CONFIG_SPI_FLASH_SFDP_SUPPORT=y
      CONFIG_SPL_DM_SPI=y
      CONFIG_SPL_SPI_FLASH_TINY=n
      CONFIG_SPL_SPI_FLASH_SFDP_SUPPORT=y
      CONFIG_SYS_SPI_U_BOOT_OFFS=0x80000
      CONFIG_SPL_DM_SEQ_ALIAS=y
    '';
  };
in

# Board names here may differ from U-Boot naming.
# The scheme is as follows:
#
#     "${vendor}-${boardName}"
#
# Both identifiers are camelCase'd.
# The vendor identifier is the same for all of their boards.
# The board identifier *may* repeat the vendor name if it is part of the board name.
# The board identifier is generally not shortened.
{
  #
  # Orange Pi
  # ---------
  #
  orangePi-zeroPlus2H5 = allwinnerA64 { defconfig = "orangepi_zero_plus2_defconfig"; };

  #
  # Pine64
  # ------
  #
  pine64-pineA64LTS = allwinnerA64 { defconfig = "pine64-lts_defconfig"; };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };
  pine64-pinebookPro = rk3399 { defconfig = "pinebook-pro-rk3399_defconfig"; };

  #
  # Raspberry Pi
  # -------------
  #
  raspberryPi-3 = simpleAArch64 {
    pkgs = aarch64;
    defconfig = "rpi_3_defconfig";
    withPoweroff = false;
  };
  raspberryPi-4 = simpleAArch64 {
    pkgs = aarch64;
    defconfig = "rpi_4_defconfig";
    withPoweroff = false;
  };

  #
  # Sandbox
  # -------
  #
  uBoot-sandbox = pkgs.buildTowBoot {
    # doc/arch/sandbox.rst
    defconfig = "sandbox_defconfig";
    filesToInstall = ["u-boot" "u-boot.dtb" ".config"];
    buildInputs = with pkgs; [
      SDL2
      perl
    ];
  };

  # ### Virtualized targets

  uBoot-qemuArm = armv7l.buildTowBoot {
    # doc/board/emulation/qemu-arm.rst
    # qemu-system-arm -nographic -machine virt -bios result/u-boot.bin
    defconfig = "qemu_arm_defconfig";
    extraMeta.platforms = ["armv7l-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };

  uBoot-qemuArm64 = aarch64.buildTowBoot {
    # doc/board/emulation/qemu-arm.rst
    # qemu-system-aarch64 -nographic -machine virt -cpu cortex-a57 -bios result/u-boot.bin
    defconfig = "qemu_arm64_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };

  uBoot-qemuX86 = i686.buildTowBoot {
    # doc/board/emulation/qemu-x86.rst
    # qemu-system-i386 -nographic -bios result/u-boot.rom
    defconfig = "qemu-x86_defconfig";
    extraMeta.platforms = ["i686-linux"];
    filesToInstall = ["u-boot.rom" ".config"];
    withPoweroff = false;
  };

  uBoot-qemuX86_64 = x86_64.buildTowBoot {
    # doc/board/emulation/qemu-x86.rst
    # qemu-system-x86_64 -nographic -bios result/u-boot.rom
    defconfig = "qemu-x86_64_defconfig";
    extraMeta.platforms = ["x86_64-linux"];
    filesToInstall = ["u-boot.rom" ".config"];

    # Enabling the logo breaks things left and right
    withLogo = false;

    # STB Truetype can't be used on qemu-x86_64 with U-Boot
    #     error: SSE register return with SSE disabled
    withTTF = false;
    withPoweroff = false;
  };

  # ### EFI payloads

  uBoot-efiX86 = i686.buildTowBoot {
    # doc/uefi/u-boot_on_efi.rst
    # ```
    #  # Somehow get a 32 bit OVMF.fd
    #  $ env -i nix-build -A efi-x86
    #  $ mkdir -p tmp/EFI/BOOT
    #  $ cp result/u-boot-payload.efi tmp/EFI/BOOT/BOOTIA32.EFI
    #  $ chmod +rw -R tmp/
    #  $ qemu-system-i386 -nographic -bios ???/bios32.bin -drive file=fat:rw:tmp
    # ```
    # Using `-drive file=fat` seems to not work as expected with a read-only store path.
    defconfig = "efi-x86_payload32_defconfig";
    extraMeta.platforms = ["i686-linux"];
    filesToInstall = ["u-boot-payload.efi" ".config"];
    withPoweroff = false;
  };

  uBoot-efiX86_64 = x86_64.buildTowBoot {
    # doc/uefi/u-boot_on_efi.rst
    # ```
    #  $ env -i nix-build -I nixpkgs=channel:nixos-unstable '<nixpkgs>' -A OVMF.fd --out-link ovmf-x86_64
    #  $ env -i nix-build -A efi-x86_64
    #  $ mkdir -p tmp/EFI/BOOT
    #  $ cp result/u-boot-payload.efi tmp/EFI/BOOT/BOOTX64.EFI
    #  $ chmod +rw -R tmp/
    #  $ qemu-system-x86_64 -nographic -bios ovmf-x86_64-fd/FV/OVMF.fd -drive file=fat:rw:tmp/
    # ```
    # Using `-drive file=fat` seems to not work as expected with a read-only store path.
    defconfig = "efi-x86_payload64_defconfig";
    extraMeta.platforms = ["x86_64-linux"];
    filesToInstall = ["u-boot-payload.efi" ".config"];
    withPoweroff = false;
  };
}
