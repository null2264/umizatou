{}:

import <nixpkgs> {
  system = builtins.currentSystem;
  overlays = [
    (final: prev: {
      lib = (import ./lib/stdlib-extended.nix prev.lib);

      oc = (import ./pkgs {
        lib = final.lib;
        pkgs = prev;
      });
    })
  ];
}
