{
  version,
  sha256,
  url,
  lib,
  stdenv,
  fetchzip,
  ...
}:
stdenv.mkDerivation rec {
  inherit version;
  pname = "opencore";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../standard_updater.py
    "acidanthera"
    "OpenCorePkg"
    "--filename=OpenCore"
  ];

  installPhase = ''
    mkdir $out
    cp -r . $out
  '';
}
