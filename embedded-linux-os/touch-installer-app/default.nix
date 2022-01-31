let
  celunPath = import ../celun.nix;
in
{ device ? null
, configuration
}@args:

import (celunPath + "/lib/eval-with-configuration.nix") (args // {
  inherit device;
  verbose = true;
  configuration = {
    imports = [
      ./configuration.nix
      configuration
      (
        { lib, ... }:
        {
          celun.system.automaticCross = lib.mkDefault true;
        }
      )
    ];
  };
})
