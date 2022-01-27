{ config, lib, ... }:

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
        name = "Tow-Boot.${config.device.identifier}.${config.Tow-Boot.variant}.img";
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
        name = "Tow-Boot.${config.device.identifier}.bin";
        partitionLabel = "Firmware (Tow-Boot)";
        # In theory this shouldn't be static, every partition should have a
        # unique identifier, but that's not really possible here.
        partitionUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";
        partitionType = lib.mkDefault (
          if config.Tow-Boot.diskImage.partitioningScheme == "gpt"
          # https://github.com/ARM-software/ebbr/issues/84
          # For now, we're "owning" this GUID.
          then "67401509-72E7-4628-B1AF-EDD128E4316A"
          # https://arm-software.github.io/ebbr/#mbr-partitioning
          # May be overriden by platforms.
          else "F8"
        );
        raw = lib.mkIf config.Tow-Boot.writeBinaryToFirmwarePartition "${config.Tow-Boot.outputs.firmware}/binaries/Tow-Boot.noenv.bin";
      };

      outputs = {
        # Round-about, but this is our stable interface now.
        diskImage = config.Tow-Boot.diskImage.output;
      };
    };
  };
}
