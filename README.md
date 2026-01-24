# `oceanix`

This project provides a basic to manage [OpenCore bootloader](https://github.com/acidanthera/OpenCorePkg) configuration using the [Nix](https://nixos.org/explore.html) package manager.

## Features

> [!NOTE]
> This project is not designed to simplify or make setting up OpenCore easier, the main goal is to make **maintaining** the OpenCore's configuration less painful.
> To get started with Hackintosh and OpenCore, I highly recommend reading [Dortania's guide](https://dortania.github.io/OpenCore-Install-Guide/).

- Automatically validate `Config.plist` with `ocvalidate`
- Compile \*.dsl patches to \*.aml
- Dependency resolution
- Modules to configure the kexts

## Usage

> [!WARNING]
> This section is unfinished. Check out [my personal config](https://github.com/null2264/ThinkPad-L460-OpenCore) as an example instead.

### Steps
1. Install [nix](https://nixos.org) and [enable flake support](https://nixos.wiki/wiki/Flakes).
2. Create a new flake with `flake.nix` like
```nix
{
  description = "My OpenCore config managed by oceanix";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.utils.url = "github:numtide/flake-utils";
  inputs.oceanix.url = "github:null2264/oceanix";

  outputs = { self, nixpkgs, utils, oceanix, ... }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      {
        packages = rec {
          x1c7 = (oceanix.lib.OpenCoreConfig {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ oceanix.overlays.default ];
            };

            modules = [
              ./modules/x1c7
            ];
          }).efiPackage;
          default = x1c7;
        };
      });
}
```
3. Write your configuration
4. Run `nix build`

## Development

To test the project you just to run `nix flake check`

### Updating Kexts/OpenCore

Use the provided `nix-update` shell script to fetch new version of certain Kexts or OpenCore itself. For example: `./nix-update --argstr package oc.voodoops2`.

## License

This project is licensed under the terms of the [GPL-3.0 license](./LICENSE).
