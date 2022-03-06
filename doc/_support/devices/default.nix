{ pkgs
, glibcLocales
, runCommandNoCC
, symlinkJoin
, ruby
}:

let
  src = builtins.fetchGit ../../..;
  release-tools = import (src + "/support/nix/release-tools.nix") { inherit pkgs; };
  devicesDir = src + "/boards";
  devicesInfo = symlinkJoin {
    name = "Tow-Boot-devices-metadata";
    paths = (map (device: device.config.build.device-metadata) release-tools.releasedDevicesEvaluations);
  };
in

runCommandNoCC "Tow-Boot-docs-devices" {
  nativeBuildInputs = [
    ruby
    glibcLocales
  ];
  inherit devicesDir devicesInfo;
}
''
  mkdir -vp $out/devices
  export LC_CTYPE=en_US.UTF-8
  ruby ${./generate-devices-listing.rb}
''
