{ imageBuilder }:

# This is a thin wrapper around `makeGPT`.
# Its main purpose is to pre-configure a couple of desired values.
{ name
, partitionOffset # in `sectorSize` bytes sectors
, partitionSize   # in bytes
, sectorSize
, size ? (partitionSize + sectorSize*partitionOffset) + 2*1024*1024 # 2MiB more than the minimum size
, firmwareFile
, partitions ? []
}:

let
  firmwarePartition = imageBuilder.firmwarePartition {
    inherit
      firmwareFile
      partitionOffset
      partitionSize
    ;
  };
in

imageBuilder.diskImage.makeGPT {
  inherit name;
  diskID = "01234567";

  partitions = [
    firmwarePartition
  ] ++ partitions;
}
