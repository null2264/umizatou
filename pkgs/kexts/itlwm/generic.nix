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
  pname = "itlwm";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "OpenIntelWireless"
    "itlwm"
  ];

  inherit stdenv;
}
