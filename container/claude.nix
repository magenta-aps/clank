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
    # Don't use memory since we're in an ephemeral container.
    # https://code.claude.com/docs/en/memory
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
  };

  # https://code.claude.com/docs/en/settings
  systemd.tmpfiles.rules = let
    claudeJson = pkgs.writeText "claude.json" (builtins.toJSON {
      bypassPermissionsModeAccepted = true; # yolo
      # Claude Code asks us to log in during onboarding. We want to use
      # CLAUDE_CODE_OAUTH_TOKEN instead.
      hasCompletedOnboarding = true;
      # Always trust the mounted host volume
      projects = {
        "/root/host" = {
          hasTrustDialogAccepted = true;
        };
      };
      theme = "dark";
    });
    claudeSettingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON {
      # Disable commercials in git commits
      attribution = {
        commit = "";
        pr = "";
      };
      # Load AGENTS.md instead of CLAUDE.md
      customInstructions = {
        files = ["AGENTS.md"];
      };
      # Default to the best model
      model = "claude-opus-4-7";
      # yolo
      permissions = {
        defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
      };
    });
  in [
    "C /root/.claude.json 0600 root root - ${claudeJson}"
    "C /root/.claude/settings.json 0600 root root - ${claudeSettingsJson}"
  ];
}
