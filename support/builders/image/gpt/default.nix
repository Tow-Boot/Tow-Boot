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
  firmwarePartition = {
    name = "Firmware (Tow-Boot)";
    partitionLabel = "Firmware (Tow-Boot)";
    partitionUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";
    partitionType = "8DA63339-0007-60C0-C436-083AC8230908";
    offset = partitionOffset * sectorSize;
    length = partitionSize;
    filename = firmwareFile;
  };
in

imageBuilder.diskImage.makeGPT {
  inherit name;
  diskID = "01234567";

  partitions = [
    firmwarePartition
  ] ++ partitions;
}
