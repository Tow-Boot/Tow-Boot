{ stdenv, fetchFromGitLab, fetchpatch }:

# This is not actually the build derivation...
# We're co-opting this derivation as a source of truth for the version and src.
stdenv.mkDerivation rec {
  version = "5.16.3";

  src = fetchFromGitLab {
    owner = "pine64-org";
    repo = "linux";
    rev = "53c2c5f0957fe68074c11115b7b8fec33e3e58e8";
    sha256 = "sha256-H+QFDyJDtG6JEJo4ZXKjPZF4hkNVWIK6D5BsA/1jCxQ=";
  };

  patches = [
    (fetchpatch {
      url = "https://gitlab.com/pine64-org/linux/-/merge_requests/29.patch";
      sha256 = "sha256-6OVV5urID1Brf39FBkfCKPIfbbXVy+GnvHaGHeJ65S0=";
    })
    (fetchpatch {
      url = "https://gitlab.com/pine64-org/linux/-/merge_requests/30.patch";
      sha256 = "sha256-cS31FDqgB4tbj+otZjMtjQk9syw5yQ8HjtVpwsq2BQM=";
    })
  ];
}
