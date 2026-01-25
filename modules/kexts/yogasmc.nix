{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.yogasmc;
in

{
  options = {
    kexts.yogasmc = {
      enable = mkEnableOption "YogaSMC";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.yogasmc;
        defaultText = literalExpression "pkgs.oc.yogasmc";
        description = ''
          Package containing the YogaSMC Kext.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting YogaSMC package.
        '';
      };

      type = mkOption {
        type = types.enum [ "lilu" "alter" ];
        default = "lilu";
        description = ''
          The YogaSMCAlter.kext is a variant without SMC keys support and the dependencies of Lilu and VirtualSMC. It's designed for quick loading / unloading without reboot when debugging.
        '';  # REF: https://github.com/zhen-zen/YogaSMC/blob/2e70a3b96396253f426cf6f5882fa9cf460a6258/README.md#installation
      };
    };
  };

  config = let
    finalPackage = cfg.package.overrideAttrs (old: {
      preInstall = ''
        ${old.preInstall or ""}

        rm -r ./${if cfg.type == "lilu" then "YogaSMCAlter" else "YogaSMC"}.kext
      '';
    });
  in mkIf cfg.enable {
    kexts.yogasmc.finalPackage = finalPackage;
    oceanix.opencore.resources.packages = [ finalPackage ];
  };
}
