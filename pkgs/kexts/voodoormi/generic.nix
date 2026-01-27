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
  pname = "voodoormi";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "VoodooSMBus"
    "VoodooRMI"
  ];

  installPhase = ''
    mkdir -p $out/Kexts
    cp -r ./VoodooRMI-*/*.kext $out/Kexts || \
      cp -r ./*.kext $out/Kexts
  '';

  inherit stdenv;
}
