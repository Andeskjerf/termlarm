{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    # https://flake.parts/module-arguments.html
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        withSystem,
        moduleWithSystem,
        ...
      }:
      {
        imports = [
        ];
        flake = {
        };
        systems = [
          "x86_64-linux"
        ];
        perSystem = { config, pkgs, ... }: {
          devshells.default = {
            env = [
              {
                name = "HELLO_DEVSHELL";
                value = "HI!";
              }
            ];
            commands = [
              {
                build = "zig build";
              }
            ];
            packages = [
              pkgs.zig
            ];
          };
        };
      }
    );
}
