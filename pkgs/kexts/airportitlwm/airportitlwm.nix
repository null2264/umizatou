{ lib, stdenv, fetchzip,
  versionName ? "latest",
  canonicalVersion,
  osVer,
  url,
  hash,
  ...
}:

lib.oc.mkKext rec {
  pname = "airportitlwm";
  version = canonicalVersion;

  src = fetchzip {
    inherit hash url;
    stripRoot = false;
  };

  inherit stdenv;
}
