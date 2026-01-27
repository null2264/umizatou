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
  pname = "voltageshift";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "xCuri0"
    "VoltageShiftSecure"
    "--filename=VoltageShift"
    "--pname=voltageshift"
  ];

  inherit stdenv;
}
