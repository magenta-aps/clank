{lib, ...}: {
  imports = [
    ./carbon.nix
    ./claude.nix
    ./hardware.nix
    ./home-manager.nix
    ./nix.nix
    ./opencode.nix
    ./podman.nix
    ./programs.nix
    ./shell.nix
    ./vars.nix
  ];

  # Disable unneeded services
  networking.dhcpcd.enable = false;
  networking.firewall.enable = false;
  systemd.oomd.enable = false;

  networking.hostName = "clank";

  system.stateVersion = lib.trivial.release; # No need to read any comments!
}
