{ config, lib, ... }:

{
  Tow-Boot = {
    config = [
      (helpers: with helpers; {
        # Used to provide SMBIOS information, mainly for UEFI boot.
        SYSINFO = yes;
        SYSINFO_SMBIOS = yes;
      })
    ];
  };
}
