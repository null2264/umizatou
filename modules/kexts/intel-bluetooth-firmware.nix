{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.intel-bluetooth-firmware;
in

{
  options = {
    kexts.intel-bluetooth-firmware = {
      enable = mkEnableOption "IntelBluetoothFirmware";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.intel-bluetooth-firmware;
        defaultText = literalExpression "pkgs.oc.intel-bluetooth-firmware";
        description = ''
          Package containing the IntelBluetoothFirmware Kext.
        '';
      };

      brcmPatchPackage = mkOption {
        type = types.package;
        default = pkgs.oc.brcmpatchram;
        defaultText = literalExpression "pkgs.oc.brcmpatchram";
        description = ''
          Package containing the BrcmPatchRAM Kext. Mainly to retrieve BlueToolFixup.kext.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting IntelBluetoothFirmware package.
        '';
      };

      includeBlueToolFixup = mkOption {
        type = types.bool;
        default = true;
        description = ''
          BlueToolFixup.kext is required for bluetooth support on macOS Monterey and newer.
        '';
      };
    };
  };

  config = let
    finalPackage = cfg.package.overrideAttrs (old: {
      preInstall =
        (old.preInstall or "") +
        (if (cfg.includeBlueToolFixup == true) then ''
          cp -r ${cfg.brcmPatchPackage}/Kexts/BlueToolFixup.kext ./BlueToolFixup.kext
        '' else "");
    });
  in mkIf cfg.enable {
    kexts.intel-bluetooth-firmware.finalPackage = finalPackage;
    oceanix.opencore.resources.packages = [ finalPackage ];
  };
}
