{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.itlwm;
in

{
  options = {
    kexts.itlwm = {
      enable = mkEnableOption "itlwm";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.itlwm.latest;
        defaultText = literalExpression "pkgs.oc.itlwm.latest";
        description = ''
          Package containing the itlwm Kext.
        '';
      };

      wifiProfiles = mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            ssid = lib.mkOption {
              type = lib.types.str;
              description = "The WiFi's SSID";
              example = "dingus";
            };
            password = lib.mkOption {
              type = lib.types.str;
              description = "The WiFi's Password";
              example = "dingus12345678";
            };
          };
        });
        description = "List of WiFi";
        default = [];
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting itlwm package.
        '';
      };
    };
  };

  config = let
    registerWifi = {}:
      let
        infoPlist = cfg.package + "/Kexts/itlwm.kext/Contents/Info.plist";
        profiles = lib.listToAttrs (lib.imap0 (i: v: {
          name = "WiFi_${toString (i + 1)}";
          value = v;
        }) cfg.wifiProfiles);
        info = mkMerge [
          oc.resolver.parsePlist pkgs infoPlist
          {
            IOKitPersonalities.itlwm.WiFiConfig = profiles;
          }
        ];
      in oc.plist.toPlist { } info;

    itlwmPackage = cfg.package.overrideAttrs (old: {
      preInstall = ''
        ${old.preInstall or ""}
        echo "${registerWifi {}}" > "itlwm.kext/Contents/Info.plist"
      '';
    });
  in mkIf cfg.enable {
    kexts.itlwm.finalPackage = itlwmPackage;
    oceanix.opencore.resources.packages = [ itlwmPackage ];
  };
}
