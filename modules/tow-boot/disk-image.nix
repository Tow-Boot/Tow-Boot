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
        partitioningScheme = "gpt";
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
        # https://github.com/ARM-software/ebbr/issues/84
        # For now, we're "owning" this GUID.
        partitionType = "67401509-72E7-4628-B1AF-EDD128E4316A";
        raw = "${config.Tow-Boot.firmwareBuild}/binaries/Tow-Boot.noenv.bin";
      };

      outputs = {
        # Round-about, but this is our stable interface now.
        diskImage = config.Tow-Boot.diskImage.output;
      };
    };
  };
}
