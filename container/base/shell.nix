{pkgs, ...}: {
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

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
