{ runCommandNoCC, vboot_reference, util-linux }:

{ partitionOffset # in 512 bytes sectors
, partitionSize   # in bytes
, size ? (partitionSize + 512*partitionOffset) + 2*1024*1024 # 2MiB more than the minimum size
}:

runCommandNoCC "gpt-image" {
  inherit partitionOffset;
  inherit size;
  partitionSize = partitionSize / 512;
  # "Linux reserved" partition type
  partType = "8DA63339-0007-60C0-C436-083AC8230908";

  # An arbitrary partition UUID for reproducible builds.
  partUUID = "CE8F2026-17B1-4B5B-88F3-3E239F8BD3D8";

  nativeBuildInputs = [
    util-linux
    vboot_reference
  ];
} ''
  echo ":: Creating a GPT image"
  echo "   with partition at $partitionOffset, $partitionSize sectors long"
  (PS4=" $ "; set -x
  fallocate -l $size $out
  cgpt create $out
  cgpt add -b $partitionOffset -s $partitionSize -l "Firmware (Tow-Boot)" -t $partType -u $partUUID $out
  cgpt boot -p $out
  cgpt show -v $out
  )
''
