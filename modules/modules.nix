# All modules that need to be evaluated
{ pkgs

  # Note, this should be "the standard library" + HM extensions.
, lib

  # Whether to enable module type checking.
, check ? true
}:

with lib;

let
  modules = [
    ./base.nix
    ./kexts/applealc.nix
    ./kexts/cpufriend.nix
    ./kexts/intel-bluetooth-firmware.nix
    ./kexts/intel-mausi.nix
    ./kexts/itlwm.nix
    ./kexts/usbtoolbox.nix
    ./kexts/virtualsmc.nix
    ./kexts/yogasmc.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")

    {
      _module.args.pkgs = lib.mkDefault pkgs;
      _module.check = check;
    }
  ];

in
modules
