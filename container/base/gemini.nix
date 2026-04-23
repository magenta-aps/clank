{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "gemini";
      paths = [pkgs.gemini-cli];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        # why not
        wrapProgram "$out/bin/gemini" --add-flags "--yolo"
      '';
    })
  ];

  # https://github.com/google-gemini/gemini-cli
  systemd.tmpfiles.rules = let
    geminiSettingsJson = pkgs.writeText "gemini-settings.json" (builtins.toJSON {
      general.enableAutoUpdate = false;
      general.enableAutoUpdateNotification = false;

      privacy.usageStatisticsEnabled = false;
      telemetry.enabled = false;

      # do not prompt for API key every time, just read from env var
      security.auth = {
        selectedType = "gemini-api-key";
        enforcedType = "gemini-api-key";
      };

      model.name = "auto-gemini-3";

      # Load AGENTS.md instead of GEMINI.md
      context.fileName = "AGENTS.md";

      # --yolo flag makes this unnecessary, but might as well
      general.defaultApprovalMode = "auto_edit";
      security.folderTrust.enabled = false;
    });
  in [
    "C /root/.gemini/settings.json 0600 root root - ${geminiSettingsJson}"
  ];
}
