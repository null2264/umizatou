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
  pname = "yogasmc";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "zhen-zen"
    "YogaSMC"
  ];

  inherit stdenv;
}
