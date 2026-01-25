{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.kexts.virtualsmc;
in

{
  options = {
    kexts.virtualsmc = {
      enable = mkEnableOption "VirtualSMC";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.virtualsmc;
        defaultText = literalExpression "pkgs.oc.virtualsmc";
        description = ''
          Package containing the VirtualSMC Kexts.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting VirtualSMC package.
        '';
      };

      includedPlugins =
        let
          # REF: https://github.com/acidanthera/VirtualSMC/tree/master/Sensors
          validValues =
            [
              "SMCBatteryManager"
              "SMCDellSensors"
              "SMCLightSensor"
              "SMCProcessor"
              "SMCSuperIO"
            ];
        in mkOption {
          # Unfortunately I can't seems to adjust typecheck error message...
          type = types.listOf (types.addCheck types.str (x: builtins.elem x validValues));
          default = [];
          description = ''
            Which VirtualSMC (bundled) plugin(s) should be included on the EFI installation.
          '';
        };
    };
  };

  config = let
    plugins = builtins.map (plugin: plugin + ".kext") ([ "VirtualSMC" ] ++ cfg.includedPlugins);
    virtualsmcPackage = cfg.package.overrideAttrs (old: {
      preInstall = ''
        ${old.preInstall or ""}

        find Kexts/ -type d -iname "*.kext" \! \( -iname ${builtins.concatStringsSep " -o -iname " plugins} \) -exec rm -r \{\} +
      '';
    });
  in mkIf cfg.enable {
    kexts.virtualsmc.finalPackage = virtualsmcPackage;
    oceanix.opencore.resources.packages = [ virtualsmcPackage ];
  };
}
