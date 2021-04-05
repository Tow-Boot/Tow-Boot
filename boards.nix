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
}
