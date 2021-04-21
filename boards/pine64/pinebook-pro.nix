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
  defconfig = "pinebook-pro-rk3399_defconfig";
  postPatch =
    let
      setup_leds = "led green:power on; led red:standby on";
    in
  ''
    substituteInPlace include/tow-boot_env.h \
      --replace 'setup_leds=\0' 'setup_leds=${setup_leds}\0'
  '';
  patches = [
    ./0001-rk3399-light-pinebook-power-and-standby-leds-during-.patch
    ./0001-rk3399-pinebook-pro-Support-SPI-flash-boot.patch
    (fetchpatch {
      url = "https://patchwork.ozlabs.org/series/232334/mbox/";
      sha256 = "0abmc82dccwmf8fjg7lyxx33r0dfc9h2hrx5d32sjl6mfj88hkj7";
    })
    (fetchpatch {
      url = "https://patchwork.ozlabs.org/series/237654/mbox/";
      sha256 = "0aiw9zk8w4msd3v8nndhkspjify0yq6a5f0zdy6mhzs0ilq896c3";
    })
  ];
  BL31 = "${TF-A}/bl31.elf";
}
