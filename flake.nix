{
  description = "clank";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    # CO2 footprint tracker for Claude Code (status line + /carbon-report).
    # Not a flake, so we consume its scripts directly. https://github.com/gwittebolle/claude-carbon
    claude-carbon = {
      url = "github:gwittebolle/claude-carbon";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    claude-carbon,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # `nix build` / `nix run` / `nix shell`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      container = nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {inherit claude-carbon;};
        modules = [./container];
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
          ["--set" "CLANK_ROOT" self.packages.${system}.container.config.system.build.toplevel]
        ];
      };
      default = self.packages.${system}.clank;
    });
  };
}
