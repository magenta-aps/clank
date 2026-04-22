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
}
