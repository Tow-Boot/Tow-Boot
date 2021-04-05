let
  rev = "04a2b269d8921505a2969fc9ec25c1f517f2b307";
  sha256 = "15hgx2i71pqgvzv56jwzfs8rkhjbm35wk1i6mxrqbq6wd0y10isv";
  tarball = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
builtins.trace "Using default Nixpkgs revision '${rev}'..." (import tarball)
