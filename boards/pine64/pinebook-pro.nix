{ rockchipRK399, fetchpatch, armTrustedFirmwareRK3399 }:

let
  TF-A = armTrustedFirmwareRK3399.overrideAttrs({ patches ? [ ], ...}: {
    patches = [
      (fetchpatch {
        url = "https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/patch/?id=1738a04b588200d3e737382da07e4f967305b4f2";
        sha256 = "09rmwa9568wac9y8xf0jvnmhdga7j2hp02gk4451w0v2is3sfchg";
      })
    ] ++ patches;
  });
in
rockchipRK399 {
  boardIdentifier = "pine64-pinebookPro";
  defconfig = "pinebook-pro-rk3399_defconfig";
  SPISize = 16 * 1024 * 1024; # 16 MiB
  postPatch =
    let
      setup_leds = "led green:power on; led red:standby on";
    in
  ''
    substituteInPlace include/tow-boot_env.h \
      --replace 'setup_leds=echo\0' 'setup_leds=${setup_leds}\0'
  '';
  patches = [
    ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
    ./0001-rk3399-pinebook-pro-Support-SPI-flash-boot.patch
    ./0001-rk3399-pinebook-pro-Disable-cdn_dp.patch
    ./0005-PBP-Fix-Panel-reset.patch
    (fetchpatch {
      url = "https://patchwork.ozlabs.org/series/237654/mbox/";
      sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
    })
  ];
  BL31 = "${TF-A}/bl31.elf";
}
