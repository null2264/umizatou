{
  version,
  sha256,
  url,
  lib,
  stdenv,
  fetchzip,
  ...
}:

lib.oc.mkKext rec {
  inherit version;
  pname = "voodooi2c";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "VoodooI2C"
    "VoodooI2C"
  ];

  inherit stdenv;
}
