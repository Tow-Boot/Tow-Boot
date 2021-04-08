{ pkgs }:

let
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

  aarch64 = pkgsFor "aarch64-linux";
  armv7l  = pkgsFor "armv7l-linux";
  i686    = pkgsFor "i686-linux";
  x86_64  = pkgsFor "x86_64-linux";

  #
  # Builder functions
  # =================
  #

  # FIXME: I don't actually want to directly use buildUBoot...
  #        but this is a starting point for the nix interface.
  inherit (aarch64) buildUBoot;

  allwinnerA64 = { defconfig }: buildUBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.armTrustedFirmwareAllwinner}/bl31.bin";
    filesToInstall = ["u-boot-sunxi-with-spl.bin" ".config"];
  };

  rk3399 = { defconfig }: buildUBoot {
    inherit defconfig;
    extraMeta.platforms = ["aarch64-linux"];
    BL31 = "${aarch64.armTrustedFirmwareRK3399}/bl31.elf";
    filesToInstall = ["u-boot.itb" "idbloader.img" ".config"];
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
#
# Note that some special identifiers are not actually following the scheme.
# Main ones are the qemu identifiers.
{
  #
  # Pine64 boards
  # -------------
  #
  pine64-pineA64LTS = allwinnerA64 { defconfig = "pine64-lts_defconfig"; };
  pine64-pinebookA64 = allwinnerA64 { defconfig = "pinebook_defconfig"; };

  #
  # Sandbox
  # -------
  #
  uBoot-sandbox = pkgs.buildUBoot {
    # doc/arch/sandbox.rst
    defconfig = "sandbox_defconfig";
    filesToInstall = ["u-boot" "u-boot.dtb" ".config"];
    buildInputs = with pkgs; [
      SDL2
      perl
    ];
  };

  #
  # Virtualized targets
  # -------------------
  #
  qemu-arm = armv7l.buildUBoot {
    # doc/board/emulation/qemu-arm.rst
    # qemu-system-arm -nographic -machine virt -bios result/u-boot.bin
    defconfig = "qemu_arm_defconfig";
    extraMeta.platforms = ["armv7l-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };

  qemu-arm64 = aarch64.buildUBoot {
    # doc/board/emulation/qemu-arm.rst
    # qemu-system-aarch64 -nographic -machine virt -cpu cortex-a57 -bios result/u-boot.bin
    defconfig = "qemu_arm64_defconfig";
    extraMeta.platforms = ["aarch64-linux"];
    filesToInstall = ["u-boot.bin" ".config"];
  };

  qemu-x86 = i686.buildUBoot {
    # doc/board/emulation/qemu-x86.rst
    # qemu-system-i386 -nographic -bios result/u-boot.rom
    defconfig = "qemu-x86_defconfig";
    extraMeta.platforms = ["i686-linux"];
    filesToInstall = ["u-boot.rom" ".config"];
  };

  qemu-x86_64 = x86_64.buildUBoot {
    # doc/board/emulation/qemu-x86.rst
    # qemu-system-x86_64 -nographic -bios result/u-boot.rom
    defconfig = "qemu-x86_64_defconfig";
    extraMeta.platforms = ["x86_64-linux"];
    filesToInstall = ["u-boot.rom" ".config"];
  };

  #
  # EFI payloads
  # -------------
  #

  efi-x86 = i686.buildUBoot {
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
  };

  efi-x86_64 = x86_64.buildUBoot {
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
  };
}
