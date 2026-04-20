{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.claude-code
  ];

  # Cringe
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
    ];

  environment.variables = {
    # Allow bypassPermissions as root
    # https://github.com/anthropics/claude-code/issues/3490
    IS_SANDBOX = "1";
    # DISABLE_AUTOUPDATER, DISABLE_BUG_COMMAND,
    # DISABLE_ERROR_REPORTING and DISABLE_TELEMETRY.
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };

  # TODO
  # systemd.tmpfiles.rules = let
  #   # https://code.claude.com/docs/en/settings
  #   claudeState = pkgs.writeText "claude.json" (builtins.toJSON {
  #     bypassPermissionsModeAccepted = true;
  #     hasCompletedOnboarding = true;
  #     theme = "dark";
  #   });
  #   claudeSettings = pkgs.writeText "claude-settings.json" (builtins.toJSON {
  #     # Disable commercials in git commits
  #     attribution = {
  #       commit = "";
  #       pr = "";
  #     };
  #     permissions = {
  #       defaultMode = "bypassPermissions"; # yolo
  #     };
  #     # Load AGENTS.md instead of claude.md
  #     customInstructions = {
  #       files = ["AGENTS.md"];
  #     };
  #   });
  # in [
  #   "C /root/.claude.json 0600 root root - ${claudeState}"
  #   "C /root/.claude/settings.json 0600 root root - ${claudeSettings}"
  # ];
}
