{
  description = "clank";

  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # use the same nixpkgs
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # `nix build` / `nix run` / `nix shell`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mkClank = {extraModules ? []}: let
        container = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [./container] ++ extraModules;
        };
      in
        pkgs.python3Packages.buildPythonApplication {
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
            ["--set" "CLANK_CACERT" pkgs.cacert]
            ["--set" "CLANK_CADDY_BIN" "${pkgs.caddy}/bin/caddy"]
            ["--set" "CLANK_EMPTY_DIRECTORY" "${pkgs.emptyDirectory}"]
            ["--set" "CLANK_ROOT" container.config.system.build.toplevel]
            # Don't clash with potentially system-installed Podman
            ["--set" "CONTAINERS_CONF" "/dev/null"]
            ["--set" "CONTAINERS_REGISTRIES_CONF" "/dev/null"]
            ["--set" "CONTAINERS_STORAGE_CONF" "/dev/null"]
          ];
        };
    in {
      default = nixpkgs.lib.makeOverridable mkClank {};
    });
  };
}
