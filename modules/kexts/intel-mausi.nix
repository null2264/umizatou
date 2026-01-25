{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.intel-mausi;
in

{
  options = {
    kexts.intel-mausi = {
      enable = mkEnableOption "IntelMausi";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.intel-mausi;
        defaultText = literalExpression "pkgs.oc.intel-mausi";
        description = ''
          Package containing the IntelMausi Kext.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting IntelMausi package.
        '';
      };

      type = mkOption {
        type = types.enum [ "temperate" "snow" ];
        default = "temperate";
        description = ''
          IntelSnowMausi.kext is a variant of IntelMausi for OSX 10.6-10.8 introduced in IntelMausi v1.0.4
        '';
      };
    };
  };

  config = let
    intelmausiPackage = cfg.package.overrideAttrs (old: {
      preInstall = ''
        ${old.preInstall or ""}

        rm -r ./${if cfg.type == "snow" then "IntelMausi" else "IntelSnowMausi"}.kext || true  # In case pre-1.0.4 is used
      '';
    });
  in mkIf cfg.enable {
    kexts.intel-mausi.finalPackage = intelmausiPackage;
    oceanix.opencore.resources.packages = [ intelmausiPackage ];
  };
}
