{
  description = "clank";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # `nix build` / `nix run` / `nix shell`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      containerDocker = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./container/base
          ./container/docker.nix
        ];
      };
      containerPodman = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./container/base
          ./container/podman.nix
        ];
      };

      clank = pkgs.python3Packages.buildPythonApplication {
        pname = "clank";
        version = "0.0.1";
        pyproject = true;

        src = ./.;

        build-system = [pkgs.python3Packages.setuptools];

        doCheck = false; # has no tests, of course

        dependencies = [
          pkgs.podman
        ];

        makeWrapperArgs = builtins.concatLists [
          ["--set" "CLANK_EMPTY_DIRECTORY" "${pkgs.emptyDirectory}"]
          ["--set" "CLANK_ROOT_DOCKER" self.packages.${system}.containerDocker.config.system.build.toplevel]
          ["--set" "CLANK_ROOT_PODMAN" self.packages.${system}.containerPodman.config.system.build.toplevel]
        ];
      };
      default = self.packages.${system}.clank;
    });
  };
}
