{
  pkgs,
  lib,
  meridian,
  ...
}: {
  # Keep Opus on the 200k models the subscription covers; Meridian defaults to
  # the 1M tier (`opus[1m]`), which needs paid extra usage, with no env to opt out.
  nixpkgs.overlays = [
    meridian.overlays.default
    (_final: prev: {
      meridian = prev.meridian.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            for f in "$out"/lib/meridian/dist/*.js; do
              substituteInPlace "$f" \
                --replace-quiet 'function supports1mContext(model) {' \
                                'function supports1mContext(model) { return false;'
            done
          '';
      });
    })
  ];

  # Local Anthropic API backed by the Claude subscription.
  systemd.services.meridian = {
    description = "Meridian - Local Anthropic API proxy";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = pkgs.writeShellScript "meridian-start" ''
        # clank.sh provides CLAUDE_CODE_OAUTH_TOKEN; HOME=/root has the creds.
        [ -s /clank/clank.sh ] && . /clank/clank.sh
        exec ${lib.getExe pkgs.meridian}
      '';
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "HOME=/root"
        "MERIDIAN_HOST=127.0.0.1"
        "MERIDIAN_PORT=3456"
      ];
    };
  };

  # Don't forward OpenCode's prompt; its `<env>` block clashes with the Claude
  # Code SDK, which insists on managing its own environment. Preset + tools stay.
  systemd.tmpfiles.rules = let
    sdkFeatures = pkgs.writeText "meridian-sdk-features.json" (builtins.toJSON {
      opencode.clientSystemPrompt = false;
    });
  in [
    "L+ /root/.config/meridian/sdk-features.json - - - - ${sdkFeatures}"
  ];
}
