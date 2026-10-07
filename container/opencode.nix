{lib, pkgs, vars, ...}: {
  home-manager.users.root = {
    programs.opencode = {
      enable = true;
      context = vars.AGENTS_md;
      # https://opencode.ai/docs/config
      settings = {
        autoupdate = false;
        # By default, OpenCode isn't allowed to read .env files, and has to ask
        # permission to do anything outside the working directory.
        permission = "allow";
      };
    };
  };

  environment.variables = {
    # Enable Exa web search tools
    # https://opencode.ai/docs/tools/#websearch
    OPENCODE_ENABLE_EXA = lib.mkDefault "1";
  };

# https://opencode.ai/docs/config
  systemd.tmpfiles.rules = let
    # RTK ships an OpenCode plugin that rewrites shell commands to their
    # token-saving `rtk` equivalents (the analogue of the Claude Code hook in
    # claude.nix). `rtk init` normally drops this file in place; we generate it
    # at build time instead so it stays declarative. https://github.com/rtk-ai/rtk
    rtkOpencodePlugin = pkgs.runCommand "rtk-opencode-plugin" {} ''
      export HOME=$(mktemp -d)
      mkdir -p $HOME/.config/opencode
      ${pkgs.rtk}/bin/rtk init --opencode -g --auto-patch >/dev/null 2>&1 || true
      install -Dm644 $HOME/.config/opencode/plugins/rtk.ts $out/rtk.ts
    '';
    opencodeJson = pkgs.writeText "opencode.json" (builtins.toJSON {
      autoupdate = false;
      # By default, OpenCode isn't allowed to read .env files, and has to ask
      # permission to do anything outside the working directory.
      permission = "allow";
    });
  in [
    "L+ /root/.config/opencode/AGENTS.md - - - - ${vars.AGENTS_md}"
    "L+ /root/.config/opencode/opencode.json - - - - ${opencodeJson}"
    "L+ /root/.config/opencode/plugins/rtk.ts - - - - ${rtkOpencodePlugin}/rtk.ts"
  ];

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
