{ runCommandNoCC, fetchurl, xxd }:

#
# Notes about serial baud rate change:
#
# > Find `60e3 16__`; 0x16e360, 1500000; it might be "packed" with another value.
# > Then change to 0x1c200, 115200, `00c2 01__`
# > Finding the offset: `grep '60 \?e3 \?16'`
# > It's likely wou will find two. Guess which one.
#

{
  ram_init-1_24-666 = 
    runCommandNoCC "rk3399-patched-666-1.24-ram_init" {
      nativeBuildInputs = [
        xxd
      ];
      ram_init = fetchurl {
        url = "https://github.com/rockchip-linux/rkbin/blob/cc30c9a0bf291d604e7ceb91ddeb5f472270a31b/bin/rk33/rk3399_ddr_666MHz_v1.24.bin?raw=true";
        sha256 = "sha256-GlBVqL4o/u8VoFbWDl6t5ew+i7asCrh9pQafHDypRnI=";
      };
    } ''
      cat $ram_init > $out
      xxd -r - $out <<EOF
      00014d70: 2003 0000 00c2 0123 0000 0000 0000 0103
      EOF
    ''
  ;
  ram_init-1_24-800 = 
    runCommandNoCC "rk3399-patched-800-1.24-ram_init" {
      nativeBuildInputs = [
        xxd
      ];
      ram_init = fetchurl {
        url = "https://github.com/rockchip-linux/rkbin/blob/cc30c9a0bf291d604e7ceb91ddeb5f472270a31b/bin/rk33/rk3399_ddr_800MHz_v1.24.bin?raw=true";
        sha256 = "sha256-AYQPFRZ9deKneQIQx0moPODyHw2JHMoV+djY3kypxr8=";
      };
    } ''
      cat $ram_init > $out
      xxd -r - $out <<EOF
      00014d50: 2003 0000 00c2 0123 0000 0000 0000 0103
      EOF
    ''
  ;
  ram_init-1_24-933 = 
    runCommandNoCC "rk3399-patched-933-1.24-ram_init" {
      nativeBuildInputs = [
        xxd
      ];
      ram_init = fetchurl {
        url = "https://github.com/rockchip-linux/rkbin/blob/cc30c9a0bf291d604e7ceb91ddeb5f472270a31b/bin/rk33/rk3399_ddr_933MHz_v1.24.bin?raw=true";
        sha256 = "sha256-ODYuxYxYHA2gdakzJDZ3ah/OPJ0WQHrWO4RQ+rAUGUQ=";
      };
    } ''
      cat $ram_init > $out
      xxd -r - $out <<EOF
      00014d50: 2003 0000 00c2 0123 0000 0000 0000 0103
      EOF
    ''
  ;
}
