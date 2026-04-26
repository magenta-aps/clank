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
      model = "{env:OPENCODE_MODEL}";
      provider = {
        scaleway = {
          options = {
            apiKey = "{env:SCW_SECRET_KEY}";
            baseURL = "https://api.scaleway.ai/{env:SCW_PROJECT_ID}/v1";
          };
        };
      };
    });
  in [
    "C /root/.config/opencode/opencode.json 0600 root root - ${opencodeJson}"
  ];

  # ~/.config/opencode/ and ~/.local/share/opencode/ are persisted to allow
  # `opencode --session` and changes to settings across Clank invocations. This
  # means that the opencode.json settings is only copied the first time.
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
