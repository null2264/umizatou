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
  pname = "voodoops2";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "acidanthera"
    "VoodooPS2"
    "--filename=VoodooPS2Controller"
  ];

  inherit stdenv;
}
