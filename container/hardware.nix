{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot.isContainer = true;

  # https://github.com/NixOS/nixpkgs/pull/480686
  console.enable = true;
}
