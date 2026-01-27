{ lib, pkgs }:

{
  applemcereporterdisabler = (lib.oc.mkKext rec {
    pname = "applemcereporterdisabler";
    version = "1.0.0";

    src = pkgs.fetchzip {
      url = "https://github.com/acidanthera/bugtracker/files/3703498/AppleMCEReporterDisabler.kext.zip";
      hash = "sha256-I1PcfchLqRXJAu5TEjK1wrgPL91pLCgEunxwlvhbueM=";
      stripRoot = false;
    };

    inherit (pkgs) stdenv;
  });
}
