{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  listEntrySubmodule = {
    options = {
    };
  };

  inherit (config) helpers;

  partitionSubmodule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          Identifier for the partition.
        '';
      };

      partitionLabel = mkOption {
        type = types.str;
        default = config.name;
        description = ''
          Partition label on supported partition schemes. Defaults to ''${name}.

          Not to be confused with _filesystem_ label.
        '';
      };

      partitionUUID = mkOption {
        type = types.nullOr helpers.types.uuid;
        default = null;
        description = ''
          Partition UUID, for supported partition schemes.

          Not to be confused with _filesystem_ UUID.

          Not to be confused with _partitionType_.
        '';
      };

      length = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Size in bytes for the partition.

          Defaults to the filesystem image length (computed at runtime).
        '';
      };

      offset = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Offset (in bytes) the partition starts at.

          Defaults to the next aligned location on disk.
        '';
      };

      partitionType = mkOption {
        type = helpers.types.uuid;
        default = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
        defaultText = "Linux filesystem data (0FC63DAF-8483-4772-8E79-3D69D8477DE4)";
        description = ''
          Partition type UUID.

          Not to be confused with _partitionUUID_.

          See: https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
        '';
      };

      bootable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Sets the "legacy bios bootable flag" on the partition.
        '';
      };

      filesystem = mkOption {
        type = types.submodule ({
          imports = import (../filesystem-image/module-list.nix);
          _module.args.pkgs = pkgs;
        });
        description = ''
          A filesystem image configuration.

          The filesystem image produced by this configuration is the default
          value for the `raw` submodule option, unless overriden.
        '';
      };

      isGap = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When set to true, only the length attribute is used, and describes
          an unpartitioned span in the disk image.
        '';
      };

      raw = mkOption {
        type = with types; oneOf [ package path ];
        defaultText = "[contents of the filesystem attribute]";
        description = ''
          Raw image to be used as the partition content.

          By default uses the output of the `filesystem` submodule.
        '';
      };
    };

    config = mkMerge [
      (mkIf (!config.isGap) {
        raw = lib.mkDefault config.filesystem.output;
      })
    ];
  };

in
{
  options = {
    partitions = mkOption {
      type = with types; listOf (submodule partitionSubmodule);
      description = ''
        List of partitions to include in the disk image.
      '';
    };
  };
}
