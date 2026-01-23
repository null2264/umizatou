{ lib, stdenv, fetchzip,
  release ? true,
  version,
  hash,
  ...
}:
let
  mkKext = import ../../lib/mkKext.nix;
in mkKext rec {
  inherit version;
  pname = "voodoops2controller-${if release then "release" else "debug"}";

  src = fetchzip {
    inherit hash;
    url =
      "https://github.com/acidanthera/VoodooPS2/releases/download/${
        if (builtins.compareVersions version "2.3.0") >= 0 && (builtins.compareVersions version "2.3.5") < 0 then
          ("v" + version)
        else
          version
      }/VoodooPS2Controller-${version}-${
        if release then "RELEASE" else "DEBUG"
      }.zip";
    stripRoot = false;
  };

  inherit stdenv;
}
