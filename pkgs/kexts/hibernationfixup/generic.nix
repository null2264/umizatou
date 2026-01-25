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
  pname = "hibernationfixup";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "acidanthera"
    "HibernationFixup"
  ];

  inherit stdenv;
}
