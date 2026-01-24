{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.applealc;
in

{
  options = {
    kexts.applealc = {
      enable = mkEnableOption "AppleALC";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.applealc;
        defaultText = literalExpression "pkgs.oc.applealc";
        description = ''
          Package containing the AppleALC Kext.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting AppleALC package.
        '';
      };

      type = mkOption {
        type = types.enum [ "alc" "alcu" ];
        default = "alc";
        description = ''
          AppleALCU.kext is a pared down version of AppleALC that only supports digital audio - but you can still use AppleALC.kext on digital audio-only systems.
        '';  # REF: https://dortania.github.io/OpenCore-Install-Guide/ktext.html#audio
      };
    };
  };

  config = let
    applealcPackage = cfg.package.overrideAttrs (old: {
      preInstall = ''
        ${old.preInstall or ""}

        rm -r ./${if cfg.type == "alc" then "AppleALCU" else "AppleALC"}.kext
      '';
    });
  in mkIf cfg.enable {
    kexts.applealc.finalPackage = applealcPackage;
    oceanix.opencore.resources.packages = [ applealcPackage ];
  };
}
