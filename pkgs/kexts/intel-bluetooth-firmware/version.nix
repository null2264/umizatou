# Upstream: https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases/

{ lib }: rec {
  latest = v2_2_0;

  nightly = {
    canonicalVersion = "2.5.0";
    hash = "sha256-yNug8u3aWJqLx3FIn4U7fxHrBjx3qHasBzLDluf7mpA=";
    stripped = true;
  };

  v2_2_0 = {
    canonicalVersion = "v2.2.0";
    hash = "sha256-mymbfJAVJTBbB7q4m2MUSUkaEeiRYbrubpS+cKTgCso=";
    stripped = false;
  };
}
