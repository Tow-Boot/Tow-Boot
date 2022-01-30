{
  imports = [
    ../radxa-RockPi4
  ];
  
  device = {
    name = "ROCK Pi 4 model C";
    identifier = "radxa-RockPi4C";
  };

  Tow-Boot = {
    defconfig = "rock-pi-4c-rk3399_defconfig";
  };
}
