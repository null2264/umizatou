{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.kexts.cpufriend;
in

{
  options = {
    kexts.cpufriend = {
      enable = mkEnableOption "CPUFriend";

      package = mkOption {
        type = types.package;
        default = pkgs.oc.cpufriend;
        defaultText = literalExpression "pkgs.oc.cpufriend";
        description = ''
          Package containing the CPUFriend Kext.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting USBToolBox package.
        '';
      };

      dataProvider = mkOption {
        type = with types; nullOr (either types.path types.str);
        default = null;
        description = ''
          Path to your CPUFriendDataProvider.kext. Set to empty string ("") if it's already handled by `resources.KextsFolders`.

          Refer to https://github.com/acidanthera/CPUFriend/blob/master/Instructions.md for instruction on how to generate it.
        '';
      };
    };
  };

  config = let
    finalPackage = cfg.package.overrideAttrs (old: {
      preInstall =
        (old.preInstall or "") +
        (if (cfg.dataProvider != null && (builtins.typeOf cfg.dataProvider) != "string") then ''
          mkdir ./CPUFriend.kext/Contents/PlugIns
          cp -r ${cfg.dataProvider} ./CPUFriend.kext/Contents/PlugIns/CPUFriendDataProvider.kext
        '' else "");
    });
  in mkIf cfg.enable {
    kexts.usbtoolbox.finalPackage = finalPackage;
    oceanix.opencore.resources.packages = [ finalPackage ];
  };
}
