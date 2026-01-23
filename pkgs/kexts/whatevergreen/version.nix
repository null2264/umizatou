# Upstream: https://github.com/acidanthera/WhateverGreen/releases/
{ lib }: rec {
  latest = v1_6_6;

  v1_6_6 = {
    canonicalVersion = "1.6.6";
    debug = "sha256-pwiYpseKCYUc0cWqljT3h38uMEhAqurpEjZaFzpih4g=";
    release = "sha256-fD2xwSmVtdd2B8fwtWOGQiklgD/6BaiNoYF2Rh0HIak=";
  };

  v1_6_1 = {
    canonicalVersion = "1.6.1";
    debug = "sha256-ukaWI6gzfNPjDOKoWMAJ5jrjj2/Bb4fxNHEyZI8P4j4=";
    release = "sha256-OjE1Ot6f2wlyiUY2Qu+0IU1vRgVveZXil8PBLuz8StA=";
  };
}
