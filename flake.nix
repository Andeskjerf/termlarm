{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
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
          inputs.devshell.flakeModule
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
                help = "Build project";
                name = "build";
                command = "zig build";
              }
              {
                help = "Run project";
                name = "run";
                command = "zig build run";
              }
            ];
            packages = [
              pkgs.zig
              pkgs.ncurses
            ];
          };
        };
      }
    );
}
