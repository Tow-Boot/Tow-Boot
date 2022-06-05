{ config, lib, pkgs, ... }:

let
  inherit (pkgs)
    writeText
  ;

  # Close enough semantics to C semantics and thus DT strings.
  escape = builtins.toJSON;

  # Fallback values used if the device description has none.
  smbios_dtsi = writeText "${config.device.identifier}-smbios.dtsi" ''
    / {
      smbios: smbios {
          compatible = "u-boot,sysinfo-smbios";

          smbios {
              system {
                  manufacturer = ${escape config.device.manufacturer};
                  product = ${escape config.device.name};
              };

              baseboard {
                  manufacturer = ${escape config.device.manufacturer};
                  product = ${escape config.device.name};
              };

              chassis {
                  manufacturer = ${escape config.device.manufacturer};
                  product = ${escape config.device.name};
              };
          };
      };
    };
  '';
in
{
  Tow-Boot = {
    config = [
      (helpers: with helpers; {
        # Used to provide SMBIOS information, mainly for UEFI boot.
        SYSINFO = yes;
        SYSINFO_SMBIOS = yes;
      })
    ];
    builder = {
      # This forcibly adds fallback values for SMBIOS support in device tree files.
      # This will ensure no "unknown vendor" and such are present, but will instead
      # force a board-specific value in sysinfo.
      #
      # Boards should still add the appropriate DT entries to their `u-boot.dtsi` files.
      # Especially if the build is shared across different hardware
      # like for the Pinephone (A64) and Raspberry Pi.
      #
      # The fallback values are added only to the "tip-most" *u-boot.dtsi files.
      postPatch = ''
        echo " :: Adding build-specific defaults for SMBIOS support..."
        for f in $(grep -L '#include.*u-boot.dtsi' arch/arm/dts/*u-boot.dtsi); do
          (
            echo '#include "smbios.dtsi"'
            cat "$f"
          ) > tmp.dts
          mv tmp.dts "$f"
        done
        cp ${smbios_dtsi} arch/arm/dts/smbios.dtsi
      '';
    };
  };
}
