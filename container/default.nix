{lib, ...}: {
  imports = [
    ./claude.nix
    ./hardware.nix
    ./meridian.nix
    ./nix.nix
    ./opencode.nix
    ./podman.nix
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
