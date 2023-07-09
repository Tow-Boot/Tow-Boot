# This is used to check all stock U-Boot versions don't have unexpected default options regressions.
# E.g. configuration options not properly gated behind a version.
# Again, not a guarantee of usefulness, used to keep us more honest.
{ device ? "uBoot-sandbox"
}:

let
  eval = configuration:
    (import ../. { inherit configuration; })."${device}"
  ;

  # Used to extract known versions.
  bogus-eval = (eval {});

  evalUBoot = version: eval { Tow-Boot = { buildUBoot = true; uBootVersion = version; }; };

  dropDot = builtins.replaceStrings ["."] ["_"];
in

builtins.map
(ver: (evalUBoot ver))
(builtins.attrNames bogus-eval.config.Tow-Boot.knownHashes.U-Boot)
