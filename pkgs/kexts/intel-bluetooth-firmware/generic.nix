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
  # TODO: Add stripped down version
  inherit version;
  pname = "intel-bluetooth-firmware";

  src = fetchzip {
    inherit url version sha256;
    stripRoot = false;
  };

  passthru.updateScript = [
    ../../standard_updater.py
    "OpenIntelWireless"
    "IntelBluetoothFirmware"
    "--filename=IntelBluetooth"
    "--pname=intel-bluetooth-firmware"
  ];

  inherit stdenv;
}
