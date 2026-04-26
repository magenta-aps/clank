{modulesPath, ...}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot.isContainer = true;

  # https://github.com/NixOS/nixpkgs/pull/480686
  console.enable = true;

  # Root is tmpfs, but /var/tmp should be backed by disk or ram might quickly
  # run out. This is unlike /tmp, which should actually be on a ramfs.
  fileSystems."/var/tmp" = {
    device = "/disk/var/tmp";
    fsType = "none";
    options = ["bind"];
  };
}
