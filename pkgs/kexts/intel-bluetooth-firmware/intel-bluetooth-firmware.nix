{ lib, stdenv, fetchzip, ver ? "latest" }:
let
  mkKext = import ../../lib/mkKext.nix;
  versionList = (import ./version.nix { inherit lib; });
  version = versionList."${ver}".canonicalVersion;
  tagVersion = if ver == "nightly" then "nightly" else version;
in mkKext rec {
  pname = "intel-bluetooth-firmware";
  inherit version;

  src = fetchzip {
    url =
      "https://github.com/${if ver == "nightly" then "null2264" else "OpenIntelWireless"}/IntelBluetoothFirmware/releases/download/${tagVersion}/IntelBluetooth${if ver == "nightly" then "Firmware" else ""}-${version}${if ver == "nightly" then "-RELEASE" else ""}.zip";
    sha256 = versionList."${ver}".hash;
    stripRoot = false;
  };

  inherit stdenv;
}
