{ buildPythonPackage
, fetchPypi

, cbor2
, lxml
, pefile
}:

buildPythonPackage rec {
  pname = "uswid";
  version = "0.4.5";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-pCZwa6IB2XgFHP8opzdtp5B015v4dqmvRt2s2mlXhLM=";
  };

  propagatedBuildInputs = [
    cbor2
    lxml
    pefile
  ];
}
