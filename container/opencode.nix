{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.fzf
    pkgs.opencode
    pkgs.ripgrep
  ];

  # https://opencode.ai/docs/config
  systemd.tmpfiles.rules = let
    opencodeJson = pkgs.writeText "opencode.json" (builtins.toJSON {
      autoupdate = false;
      provider = {
        scaleway = {
          options = {
            # Magenta's "AI" Scaleway project
            baseURL = "https://api.scaleway.ai/594a268d-8577-4b86-a983-be375e13e197/v1";
          };
        };
      };
    });
  in [
    "C /root/.config/opencode/opencode.json 0600 root root - ${opencodeJson}"
  ];

  fileSystems."/root/.config/opencode" = {
    device = "/persist/root/.config/opencode";
    fsType = "none";
    options = ["bind"];
  };
  fileSystems."/root/.local/share/opencode" = {
    device = "/persist/root/.local/share/opencode";
    fsType = "none";
    options = ["bind"];
  };
}
