{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./claude.nix
    ./hardware.nix
    ./podman.nix
  ];

  environment.systemPackages = [
    pkgs.bash
    pkgs.coreutils
    pkgs.git
  ];

  # Automatically log in as root
  users = {
    mutableUsers = false;
    users.root.password = "";
  };
  services.getty.autologinUser = "root";

  # Unlike SSH, these variables aren't passed from the host terminal, so
  # everything is ugly by default.
  environment.variables = {
    COLORTERM = "truecolor";
    TERM = "xterm-256color";
  };

  # Disable unneeded services
  networking.dhcpcd.enable = false;
  networking.firewall.enable = false;
  systemd.oomd.enable = false;

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

  # Execute command(s) passed as program arguments (see flake.nix), then
  # poweroff automatically when the program exits -- otherwise you will be
  # stuck in an auto-login loop.
  programs.bash.loginShellInit =
    # bash
    ''
      cd host/
      /run/shell-init
      poweroff
    '';

  system.stateVersion = lib.trivial.release; # No need to read any comments!
}
