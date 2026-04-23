{lib, ...}: {
  imports = [
    ./claude.nix
    ./gemini.nix
    ./hardware.nix
    ./opencode.nix
    ./shell.nix
  ];

  # Disable unneeded services
  networking.dhcpcd.enable = false;
  networking.firewall.enable = false;
  systemd.oomd.enable = false;

  networking.hostName = "clank";

  systemd.mounts = [
    {
      where = "/sys/kernel/debug";
      enable = false;
    }
    {
      where = "/sys/kernel/tracing";
      enable = false;
    }
  ];

  system.stateVersion = lib.trivial.release; # No need to read any comments!
}
