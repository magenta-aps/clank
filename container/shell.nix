{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.git
    pkgs.jq
  ];

  # Unlike SSH, these variables aren't passed from the host terminal, so
  # everything is ugly by default.
  environment.variables = {
    COLORTERM = "truecolor";
    TERM = "xterm-256color";
  };

  programs.fish = {
    enable = true;
    generateCompletions = false; # *really* slow
    shellInit =
      # fish
      ''
        # Don't greet the user
        set fish_greeting
      '';
    loginShellInit =
      # fish
      ''
        # Load environment variables mounted from the host's ~/.config/clank.sh
        if test -s ~/.config/clank.sh
          source ~/.config/clank.sh
        end
        # Enter the mounted host/ directory
        cd host/
        # Run extra arguments if given on the command line, otherwise just
        # spawn an interactive fish shell.
        if test -s /command.sh
          source /command.sh
        else
          fish
        end
        # "Power off" and stop the container when the shell exits -- otherwise
        # you will be stuck in an auto-login loop on CTRL-D. We double --force,
        # so we don't have to wait for anything to cleanly shut down, since
        # this is an ephemeral container anyway.
        exec systemctl poweroff --force --force
      '';
  };

  # Automatically log in as root
  users = {
    mutableUsers = false;
    users.root = {
      password = "";
      shell = pkgs.fish;
    };
  };
  services.getty.autologinUser = "root";

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  # Persist fish history for a nicer experience
  fileSystems."/root/.local/share/fish" = {
    device = "/persist/root/.local/share/fish";
    fsType = "none";
    options = ["bind"];
  };
}
