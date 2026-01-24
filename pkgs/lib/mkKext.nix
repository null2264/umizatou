{ pname, version, src, stdenv
, installPhase ? ''
    mkdir -p $out/Kexts
    cp -r ./*.kext $out/Kexts
  ''
, passthru ? {}
}:

let
  finalInstallPhase = ''
    runHook preInstall
  '' + installPhase + ''
    runHook postInstall
  '';
in
stdenv.mkDerivation rec
{
  inherit pname version src passthru;

  installPhase = finalInstallPhase;
}
