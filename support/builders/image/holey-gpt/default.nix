{ runCommandNoCC, vboot_reference, util-linux }:

{ pad ? 2 * 1024 * 1024 / 512 # Defaults to 2MiB; in sectors
, size ? 8 * 1024 * 1024 # 8 MiB image
}:

runCommandNoCC "holey-gpt-base-image" {
  inherit pad;
  inherit size;

  nativeBuildInputs = [
    util-linux
    vboot_reference
  ];
} ''
  echo ":: Creating base holey GPT image"
  (PS4=" $ "; set -x
  fallocate -l $size $out
  cgpt create -z $out
  cgpt create -p $pad $out
  cgpt boot -p $out
  cgpt show -v $out
  )
''
