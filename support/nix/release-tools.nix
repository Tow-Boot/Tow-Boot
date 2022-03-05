{ pkgs ? import ../../nixpkgs.nix {} }: 

let
  # Original `evalConfig`
  evalConfig = import "${toString pkgs.path}/nixos/lib/eval-config.nix";
  # Import modules from Nixpkgs
  fromNixpkgs = map (module: "${toString pkgs.path}/nixos/modules/${module}");
in
rec {
  # Evaluates Tow-Boot, and the device config with the given additional modules.
  evalWith =
    { modules
    , device
    , additionalConfiguration ? {}
    , baseModules ? (
      [
        ../../modules
      ] ++ (fromNixpkgs [
        # (Limit this to as much as possible)
        "misc/assertions.nix"
        "misc/nixpkgs.nix"
      ])
    )
  }: evalConfig {
    inherit baseModules;
    modules = []
      # `device` can be a couple of types.
      ++ (   if builtins.isAttrs device then [ device ]                    # An attrset is used directly
        else if builtins.isPath device then [ { imports = [ device ]; } ]  # A path added to imports
        else [ { imports = [(../../. + "/boards/${device}")]; } ])         # A string is looked-up locally
      # Our own modules
      ++ modules
      # Any additional optional configuration this should be evaluated with.
      ++ [ additionalConfiguration ]
    ;
  };

  evalFor = device: config: (
    import ./eval-with-configuration.nix {
      inherit
        pkgs
        device
      ;
      configuration = {
        # Special configs for imperative use only here
        system.automaticCross = true;
      } // config;
    }
  );

  keepEval = (eval: eval.config.device.inRelease);

  allDevices =
    builtins.filter
    (d: builtins.pathExists (../../. + "/boards/${d}/default.nix"))
    (builtins.attrNames (builtins.readDir ../../boards))
  ;

  evals = builtins.map (device: evalFor device { }) allDevices;

  releasedDevicesEvaluations = builtins.filter keepEval evals;
}
