{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkBefore
    mkOption
    types
  ;
in
{
  options = {
    Tow-Boot = {
      outputs = {
        diskImage = mkOption {
          type = types.package;
          description = ''
            Output of the disk image configuration.
          '';
        };
      };
      diskImage = config.helpers.mkImageBuilderEvalOption {
        description = ''
          Configuration for the disk image.
        '';
      };
      firmwarePartition = mkOption {
        type = types.attrsOf types.anything;
        description = ''
          Configuration for the firmware partition.
        '';
      };
      writeBinaryToFirmwarePartition = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether the firmware binary is directly written to the partition.

          When disabled, the platform **must** handle configuring the firmwarePartition accordingly.
        '';
      };
    };
  };

  config = {
    Tow-Boot = {
      diskImage = {
        name = "${config.Tow-Boot.outputName}.${config.device.identifier}.${config.Tow-Boot.variant}.img";
        gpt = {
          # In theory this shouldn't be static, every partition should have a
          # unique identifier, but that's not really possible here.
          diskID = "E0CA6E57-39B2-4482-9838-21E2785CD93D";
        };
        mbr = {
          # In theory this shouldn't be static, every partition should have a
          # unique identifier, but that's not really possible here.
          diskID = "01234567";
        };
        partitioningScheme = lib.mkDefault "gpt";
        partitions = mkBefore [
          config.Tow-Boot.firmwarePartition
        ];
      };

      firmwarePartition = {
        name = "${config.Tow-Boot.outputName}.${config.device.identifier}.bin";
        partitionLabel = "Firmware (Tow-Boot)";
        # > Protective partitions are entries in the partition table that cover
        # > the LBA region occupied by firmware and have the ‘Required Partition’
        # > attribute set.
        # — EBBR chapter 4.1.1
        requiredPartition = true;
        # In theory this shouldn't be static, every partition should have a
        # unique identifier, but that's not really possible here.
        partitionUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";
        # > A protective partition must use a PartitionTypeGUID that identifies
        # > it as a firmware protective partition. (e.g., don’t reuse a GUID
        # > used by non-protective partitions).
        # — EBBR chapter 4.1.1
        partitionType = lib.mkDefault (
          if config.Tow-Boot.diskImage.partitioningScheme == "gpt"
          # https://github.com/ARM-software/ebbr/issues/84
          # For now, we're "owning" this GUID.
          then "67401509-72E7-4628-B1AF-EDD128E4316A"
          # https://arm-software.github.io/ebbr/#mbr-partitioning
          # May be overriden by platforms.
          else "F8"
        );
        raw = lib.mkIf config.Tow-Boot.writeBinaryToFirmwarePartition "${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.${config.Tow-Boot.variant}.bin";
      };

      outputs = {
        # For androidboot variant, create Android boot image instead of disk image
        diskImage =
          if config.Tow-Boot.variant == "androidboot"
          then pkgs.callPackage (
            { runCommand, android-tools }:
            runCommand "${config.Tow-Boot.outputName}.${config.device.identifier}.androidboot.img" {} ''
              mkdir -p $out

              # Follow official U-Boot Qualcomm docs:
              # https://docs.u-boot.org/en/stable/board/qualcomm/board.html
              #
              # 1. Gzip u-boot-nodtb.bin
              # 2. Append DTB to create u-boot-nodtb.bin.gz-dtb
              # 3. Package with mkbootimg

              echo "Creating Android boot image for SDM845..."

              # Gzip the U-Boot binary (use u-boot-nodtb.bin if available, otherwise the full binary)
              if [ -f ${config.Tow-Boot.outputs.firmware}/binaries/u-boot-nodtb.bin ]; then
                UBOOT_BIN="${config.Tow-Boot.outputs.firmware}/binaries/u-boot-nodtb.bin"
              else
                UBOOT_BIN="${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.${config.Tow-Boot.variant}.bin"
              fi

              echo "Compressing U-Boot binary..."
              gzip -n -9 -k -c "$UBOOT_BIN" > u-boot-nodtb.bin.gz

              # Create Android boot image with mkbootimg
              echo "Building without ramdisk (U-Boot standalone)..."
              ${android-tools}/bin/mkbootimg \
                --kernel u-boot-nodtb.bin.gz \
                --output $out/Tow-Boot.androidboot.img \
                --pagesize 4096 \
                --base 0x00000000 \
                --kernel_offset 0x00008000 \
                --ramdisk_offset 0x01000000 \
                --tags_offset 0x00000100 \
                --board ""

              echo "Created Android boot image:"
              ls -lh $out/
            ''
          ) {}
          else config.Tow-Boot.diskImage.output;
      };
    };
  };
}
