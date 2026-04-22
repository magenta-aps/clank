{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./claude.nix
    ./hardware.nix
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

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.bash = {
    # Load mounted environment variables and enter the mounted host/ directory.
    loginShellInit =
      # bash
      ''
        source ~/.config/clank.sh
        cd host/
        bash /command.sh
      '';
    # Exit systemd and stop the container automatically when the login shell
    # exits -- otherwise you will be stuck in an auto-login loop on CTRL-D.
    logout =
      # bash
      ''
        systemctl exit 0
      '';
  };

  # Don't wait for containers to stop gracefully during exit
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "1s";
  };

  system.stateVersion = lib.trivial.release; # No need to read any comments!
}
