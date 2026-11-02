{
  lib,
  vars,
  ...
}: {
  home-manager.users.root = {
    programs.opencode = {
      enable = true;
      context = vars.AGENTS_md;
      # https://opencode.ai/v2/docs/
      settings = {
        # By default, OpenCode isn't allowed to read .env files
        permissions = [
          {
            action = "*";
            resource = "*";
            effect = "allow";
          }
        ];
        # Disable update checks
        update = "disable";
        # Enable web search
        websearch = lib.mkDefault {
          provider = "random";
        };
      };
    };
    # The OpenCode state is shared between Clank containers, so they will try
    # to share one background server by default, which doesn't work.
    # `service.json` isn't part of the home-manager module yet.
    # https://opencode.ai/v2/docs/cli/#background-service
    xdg.configFile."opencode/service.json".text = builtins.toJSON {
      disabled = true;
    };
  };

  fileSystems."/root/.local/share/opencode" = {
    device = "/persist/root/.local/share/opencode";
    fsType = "none";
    options = ["bind"];
  };
  fileSystems."/root/.local/state/opencode" = {
    device = "/persist/root/.local/state/opencode";
    fsType = "none";
    options = ["bind"];
  };
}
