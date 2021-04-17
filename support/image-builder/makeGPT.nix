{ stdenvNoCC, lib
, imageBuilder
, gptfdisk
, utillinux
}:

/*  */ let scope = { "diskImage.makeGPT" =

let
  inherit (lib) concatMapStringsSep optionalString;

  # List of known mappings of GPT partition types to filesystems.
  # This is not exhaustive, only used as a default.
  # See also: https://sourceforge.net/p/gptfdisk/code/ci/master/tree/parttypes.cc
  types = {
    "FAT32" = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
    "ESP"   = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
    "LUKS"  = "CA7D7CCB-63ED-4C53-861C-1742536059CC";
    "ext2"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
    "ext3"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
    "ext4"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
  };
in
{
  name
  , partitions
  , diskID
  , headerHole ? 0 # in bytes
  , postBuild ? ""
  # Default alignment at 1MiB
  , alignment ? imageBuilder.size.MiB 1
  , sectorSize ? 512
}:

let
  alignment' = alignment;
  sectorSize' = sectorSize;
in

let
  _name = name;

  eachPart = partitions: fn: (
    concatMapStringsSep "\n" (partition:
      fn partition
  ) partitions);

  alignment = toString alignment';
  sectorSize = toString sectorSize';

  image = partition: 
    if lib.isDerivation partition then
      "${partition}/${partition.filename}"
    else
      partition.filename
  ;
in
stdenvNoCC.mkDerivation rec {
  name = "disk-image-${_name}";
  filename = "${_name}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
    gptfdisk
    utillinux
  ];

  buildCommand = let
    # This fragment is used to compute the (aligned) size of the partition.
    # It is used *only* to track the tally of the space used, thus the starting
    # offset of the next partition. The filesystem sizes are untouched.
    sizeFragment = partition: ''
      # If a partition asks to start at a specific offset, restart tally at
      # that location.
      ${optionalString (partition ? offset) ''
        offset=$((${toString partition.offset}))

        if (( offset < totalSize )); then
          echo "Partition wanted to start at $offset while we were already at $totalSize"
          echo "As of right now, partitions need to be in order."
          exit 1
        else
          totalSize=$offset
        fi
      ''}
      start=$totalSize
      ${
        if partition ? length then
        ''size=$((${toString partition.length}))''
        else
        ''size=$(($(du --apparent-size -B 512 "$input_img" | awk '{ print $1 }') * 512))''
      }
      size=$(( $(if (($size % ${alignment})); then echo 1; else echo 0; fi ) + size / ${alignment} ))
      size=$(( size * ${alignment} ))
      totalSize=$(( totalSize + size ))
      echo "Partition: start $start | size $size | totalSize $totalSize"
    '';

    # This fragment is used to add the desired gap to `totalSize`.
    # We're setting `start` and `size` only to mirror the information shown
    # for partitions.
    # Do note that gaps are always aligned, so two gaps sized half the alignment
    # would create 2× the space expected.
    # What may *instead* be done at one point is always align `start` for partitions.
    gapFragment = partition: ''
      start=$totalSize
      size=${toString partition.length}
      size=$(( $(if (($size % ${alignment})); then echo 1; else echo 0; fi ) + size / ${alignment} ))
      totalSize=$(( totalSize + size ))
      echo "Gap: start $start | size $size | totalSize $totalSize"
    '';
  in ''
    mkdir -p $out

    # LBA0 and LBA1 contains the PMBR and GPT.
    #
    #  2 is LBA2, where the header hole starts.
    # 32 is the default GPT header size in sectors.
    gptSize=$((${toString headerHole} + 2*512 + 32*512))

    cat <<EOF > script.sfdisk
    label: gpt
    label-id: 0x${diskID}
    unit: sectors
    first-lba: $((gptSize / ${sectorSize}))
    sector-size: ${sectorSize}
    EOF

    totalSize=$((gptSize))
    echo
    echo "Gathering information about partitions."
    ${eachPart partitions (partition:
      if partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${image partition}"
          ${sizeFragment partition}
          echo " -> ${partition.name}: $size / ${if partition ? filesystemType then partition.filesystemType else ""}"

          (
          # The size is /1024; otherwise it's in sectors.
          echo -n 'start='"$((start/${sectorSize}))"
          echo -n ', size='"$((size/${sectorSize}))"
          echo -n ', type=${
            if partition ? partitionType then
              partition.partitionType
            else
              types.${partition.filesystemType}
          }'
          ${optionalString (partition ? partitionUUID)
              "echo -n ', uuid=${partition.partitionUUID}'"}
          ${optionalString (partition ? bootable && partition.bootable)
              ''echo -n ', attrs="LegacyBIOSBootable"' ''}
          ${optionalString (partition ? partitionLabel)
              ''echo -n ', name="${partition.partitionLabel}"' ''}
          echo "" # Finishes the command
          ) >> script.sfdisk
        ''
    )}

    # Allow space for secondary partition table / header.
    totalSize=$(( totalSize + 34*512 ))

    echo "--- script ----"
    cat script.sfdisk
    echo "--- script ----"

    echo
    echo "Making image, $totalSize bytes..."
    truncate -s $((totalSize)) $img

    sfdisk $img < script.sfdisk

    totalSize=$((gptSize))
    echo
    echo "Writing partitions into image"
    ${eachPart partitions (partition: 
      if partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${image partition}"
          ${sizeFragment partition}
          echo " -> ${partition.name}: $size / ${if partition ? filesystemType then partition.filesystemType else ""}"

          echo "$start / $size"
          dd conv=notrunc if=$input_img of=$img seek=$((start/512)) count=$((size/512)) bs=512
        ''
    )}

    echo
    echo "Moving GPT partitions"
    # We add 2 here since we have the size of the hole, which starts at LBA2.
    # Note that this assumes the reserved hole in the GPT header has to be
    # before the actual GPT header. It is desirable here.
    sgdisk -j $((${toString (headerHole)}/512+2)) $img

    echo
    echo "Information about the image:"
    ls -lh $img
    sfdisk -V --list $img
    ${postBuild}
  '';
}

/*  */ ;}; in scope."diskImage.makeGPT"
