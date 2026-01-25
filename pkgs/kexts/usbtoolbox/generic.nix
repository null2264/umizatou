{
  version,
  sha256,
  url,
  lib,
  stdenv,
  fetchzip,
  ...
}:
let
  mkKext = import ../../lib/mkKext.nix;
in mkKext rec {
  inherit version;
  pname = "usbtoolbox";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "USBToolBox"
    "kext"
    "--filename=USBToolBox"
    "--pname=usbtoolbox"
  ];

  inherit stdenv;
}
