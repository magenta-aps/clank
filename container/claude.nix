{pkgs, ...}: {
  # Cringe
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
    ];

  environment.systemPackages = [
    (pkgs.claude-code.overrideAttrs (previousAttrs: {
      # The most upvoted issue on Claude Code: "Feature Request: Support
      # AGENTS.md", i.e. "stop requiring me to put ads for Anthropic in my
      # repo". Don't let them win.
      # https://github.com/anthropics/claude-code/issues/6235
      postInstall = ''
        ${previousAttrs.postInstall or ""}
        # Claude Code is a binary file, but luckily the strings `CLAUDE.md` and
        # `AGENTS.md` are of the same length 😎
        sed -i -e 's/CLAUDE\.md/AGENTS\.md/g' $out/bin/.claude-wrapped
      '';
    }))
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

  systemd.tmpfiles.rules = let
    # https://code.claude.com/docs/en/settings#global-config-settings
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
    # https://code.claude.com/docs/en/settings
    claudeSettingsJson = pkgs.writeText "claude-settings.json" (builtins.toJSON {
      # Disable commercials in git commits
      attribution = {
        commit = "";
        pr = "";
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

  # The .claude directory is persisted to allow `claude --resume` and changes
  # to settings across Clank invocations. This means that the settings.json is
  # only copied the first time.
  # https://code.claude.com/docs/en/claude-directory#application-data
  fileSystems."/root/.claude" = {
    device = "/persist/root/.claude";
    fsType = "none";
    options = ["bind"];
  };
}
