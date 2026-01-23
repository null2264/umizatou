# Upstream: https://github.com/OpenIntelWireless/itlwm/releases

{ lib }:

let
  mkUrl = version: "https://github.com/OpenIntelWireless/itlwm/releases/download/${version}/itlwm_${version}_stable.kext.zip";
in rec {
  latest = v2_3_0;

  v2_3_0 = let
    canonicalVersion = "v2.3.0";
  in {
    inherit canonicalVersion;
    url = mkUrl canonicalVersion;
    sha256 = "sha256-TUDUdr7d2UCsGquJkV/Iecbj3HYoA7jeMhknd5Qfmiw=";
  };

  v2_2_0 = let
    canonicalVersion = "v2.2.0";
  in {
    inherit canonicalVersion;
    url = mkUrl canonicalVersion;
    sha256 = "sha256-QwoIj9JcCKxE/BQ2ebpaFpQUAy0OujcUAfd96FOY0io=";
  };

  v2_1_0 = let
    canonicalVersion = "v2.1.0";
  in {
    inherit canonicalVersion;
    url = mkUrl canonicalVersion;
    sha256 = "sha256-6MzyYWCohJiLNzFYpnCh5GkIQPUh6vw6iSJv/WVnfmE=";
  };
}
