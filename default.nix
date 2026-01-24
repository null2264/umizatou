{}:

import <nixpkgs> {
  system = builtins.currentSystem;
  overlays = [
    (final: prev: {
      oc = (import ./pkgs {
        inherit (prev) lib;
        pkgs = prev;
      });
    })
  ];
}
