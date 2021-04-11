{ Tow-Boot }:

let
  inherit (Tow-Boot.systems)
    aarch64
    armv7l
    i686
    x86_64
  ;

  #
  # Builder functions
  # =================
  #

  # When the output is `u-boot.bin`, and requires no additional inputs.
  simpleAArch64 = { defconfig, ... } @ args: aarch64.buildTowBoot ({
    extraMeta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  } // args);

  # For Allwinner A64 based hardware
  allwinnerA64 = { defconfig }: aarch64.buildTowBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.nixpkgs.armTrustedFirmwareAllwinner}/bl31.bin";
    filesToInstall = ["u-boot-sunxi-with-spl.bin" ".config"];
  };

  # For Rockchip RK3399 based hardware
  rk3399 = { defconfig, postPatch ? "", postInstall ? "" }: aarch64.buildTowBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.nixpkgs.armTrustedFirmwareRK3399}/bl31.elf";
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
    defconfig = "rpi_3_defconfig";
    withPoweroff = false;
  };
  raspberryPi-4 = simpleAArch64 {
    defconfig = "rpi_4_defconfig";
    withPoweroff = false;
  };

  #
  # Sandbox
  # -------
  #
  uBoot-sandbox = Tow-Boot.buildTowBoot {
    # doc/arch/sandbox.rst
    defconfig = "sandbox_defconfig";
    filesToInstall = ["u-boot" "u-boot.dtb" ".config"];
    buildInputs = with Tow-Boot.nixpkgs; [
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
