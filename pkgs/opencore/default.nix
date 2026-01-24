{ lib, pkgs }:

lib.mapAttrs (name: value: pkgs.callPackage ./generic.nix value) (lib.importJSON ./versions.json)
