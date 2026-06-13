{
  pkgs,
  vars,
  ...
}: {
  environment.systemPackages = [
    pkgs.opencode
  ];

  environment.variables = {
    # Enable Exa web search tools
    # https://opencode.ai/docs/tools/#websearch
    OPENCODE_ENABLE_EXA = "1";
  };

  # https://opencode.ai/docs/config
  systemd.tmpfiles.rules = let
    opencodeJson = pkgs.writeText "opencode.json" (builtins.toJSON {
      autoupdate = false;
      # Use the Claude subscription via the local Meridian proxy (meridian.nix).
      # apiKey is an unused placeholder OpenCode requires.
      plugin = ["${pkgs.meridian}/lib/meridian/plugin/meridian.ts"];
      provider = {
        anthropic = {
          options = {
            baseURL = "http://127.0.0.1:3456";
            apiKey = "meridian";
          };
        };
        scaleway = {
          options = {
            # Magenta's "AI" Scaleway project
            baseURL = "https://api.scaleway.ai/594a268d-8577-4b86-a983-be375e13e197/v1";
          };
        };
      };
      # By default, OpenCode isn't allowed to read .env files, and has to ask
      # permission to do anything outside the working directory.
      permission = "allow";
    });
  in [
    "L+ /root/.config/opencode/AGENTS.md - - - - ${vars.AGENTS_md}"
    "L+ /root/.config/opencode/opencode.json - - - - ${opencodeJson}"
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
