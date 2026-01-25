{
  description = "OpenCore bootloader manager with Nix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils, ... }: with utils.lib;
    rec {
      lib = {
        oc = (import ./lib/stdlib-extended.nix nixpkgs.lib).oc;
        OpenCoreConfig =
          { modules ? [ ]
          , pkgs
          , lib ? pkgs.lib
          , extraSpecialArgs ? { }
          , check ? true
          }@args:
          (import ./modules {
            inherit pkgs lib check extraSpecialArgs;
            configuration = { ... }: { imports = modules; };
          });
      };

      overlays.default = final: prev: {
        oc = (import ./pkgs {
          inherit (prev) lib;
          pkgs = prev;
        });
      };
    } // eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };

        ocConfig = self.lib.OpenCoreConfig {
          inherit pkgs;

          modules = [
            ({ lib, pkgs, ... }: {
              kexts.applealc = {
                enable = true;
                type = "alcu";
              };

              kexts.virtualsmc = {
                enable = true;
                includedPlugins = [ "SMCBatteryManager" "SMCDellSensors" ];
              };

              kexts.usbtoolbox = {
                enable = true;
                mapping = "";
              };

              kexts.cpufriend = {
                enable = true;
                dataProvider = "";
              };

              kexts.intel-bluetooth-firmware = {
                enable = true;
                includeBlueToolFixup = false;
                package = pkgs.oc.intel-bluetooth-firmware;
              };

              kexts.itlwm = {
                enable = true;
                wifiProfiles = [
                  {
                    ssid = "ssdt_5G";
                    password = "zxyssdt112233";
                  }
                ];
              };

              oceanix.opencore = {
                validate = false;  # Ignore validation for sample
                resources.packages = [
                  pkgs.oc.applemcereporterdisabler
                  pkgs.oc.airportitlwm.latest-ventura
                  # pkgs.oc.itlwm.latest
                  pkgs.oc.brcmpatchram
                  pkgs.oc.brightnesskeys
                  pkgs.oc.cputscsync
                  pkgs.oc.ctlnaahciport
                  pkgs.oc.debugenhancer
                  pkgs.oc.ecenabler
                  pkgs.oc.hibernationfixup
                  pkgs.oc.intel-bluetooth-firmware
                  pkgs.oc.intel-mausi
                  pkgs.oc.lilu
                  pkgs.oc.nvmefix
                  pkgs.oc.restrictevents
                  pkgs.oc.voltageshift
                  pkgs.oc.voodooi2c
                  pkgs.oc.voodoormi
                  pkgs.oc.voodoops2
                  pkgs.oc.yogasmc
                  pkgs.oc.whatevergreen
                ];
              };
            })
          ];
        };

        # REF: https://github.com/NixOS/nixpkgs/pull/221608
        collect' =
        pred:
        f:
        attrs:
          let
            recurse = prefix: attrs:
              builtins.concatMap
                (name: visit (prefix ++ [ name ]) attrs.${name})
                (builtins.attrNames attrs);
            visit = path': value:
              if pred path' value then
                [ (f path' value) ]
              else if builtins.isAttrs value then
                recurse path' value
              else
                [ ];
          in
          visit [ ] attrs;

        # REF: https://github.com/NixOS/nixpkgs/pull/221608
        flattenAttrs = # pkgs.lib.flattenAttrs  # FIXME: Uncomment once GH-221608 is merged
        pred:
        f:
        attrs:
          if pred attrs then attrs
          else
            builtins.listToAttrs (map (x: pkgs.lib.nameValuePair (f x.path) x.value) (collect'
              (_: v: pred v || !builtins.isAttrs v)
              (path: value: { inherit path value; })
              attrs));
      in {
        checks.buildExampleEfi = ocConfig.efiPackage;

        packages = flattenAttrs pkgs.lib.isDerivation (builtins.concatStringsSep "-") pkgs.oc;

        apps = rec {
          fmt = utils.lib.mkApp {
            drv = with import nixpkgs { inherit system; };
              pkgs.writeShellScriptBin "oceanix-fmt" ''
                export PATH=${
                  pkgs.lib.strings.makeBinPath [
                    findutils
                    nixpkgs-fmt
                    shfmt
                    shellcheck
                  ]
                }
                find . -type f -name '*.sh' -exec shellcheck {} +
                find . -type f -name '*.sh' -exec shfmt -w {} +
                find . -type f -name '*.nix' -exec nixpkgs-fmt {} +
              '';
          };
          default = fmt;
        };
      }
    );
}
