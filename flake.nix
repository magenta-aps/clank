{
  description = "clank";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-25.11";
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

    # `nix build`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      cli = pkgs.python3Packages.buildPythonApplication {
        pname = "clank";
        version = "0.0.1";
        pyproject = true;

        src = ./.;

        build-system = [pkgs.python3Packages.setuptools];

        doCheck = false; # has no tests, of course

        dependencies = [
          pkgs.podman
        ];

        makeWrapperArgs = [
          "--add-flag"
          "--init=${self.packages.${system}.container.config.system.build.toplevel}/init"
          "--add-flag"
          "--empty=${pkgs.emptyDirectory}"
        ];
      };

      container = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [./container];
      };
    });

    # `nix run`
    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.cli}/bin/clank";
      };
    });
  };
}
