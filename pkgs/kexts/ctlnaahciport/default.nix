{ lib, pkgs }:

{
  ctlnaahciport = (lib.oc.mkKext rec {
    pname = "ctlnaahciport";
    version = "1.0.0";

    src = pkgs.fetchzip {
      url = "https://github.com/dortania/OpenCore-Install-Guide/raw/refs/heads/master/extra-files/CtlnaAHCIPort.kext.zip";
      hash = "sha256-JvUE6Qd0/7EkTK33v4zXAYkk5T2FvJEXf3EfTaL1eHY=";
      stripRoot = false;
    };

    inherit (pkgs) stdenv;
  });
}
