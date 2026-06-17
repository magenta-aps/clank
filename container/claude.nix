{
  pkgs,
  vars,
  claude-carbon,
  ...
}: {
  # Cringe
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
    ];

  environment.systemPackages = [
    # RTK (Rust Token Killer): a CLI proxy that strips noise from command
    # output before it reaches the model, cutting token use (and carbon).
    # Wired in via the PreToolUse hook below. https://github.com/rtk-ai/rtk
    pkgs.rtk
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
    # Reduce carbon footprint: compact the context earlier than the ~95%
    # default so we don't keep a bloated, token-heavy session around.
    # https://github.com/gwittebolle/claude-carbon
    CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "50";
  };

  # https://code.claude.com/docs/en/settings
  systemd.tmpfiles.rules = let
    claudeJson = pkgs.writeText "claude.json" (builtins.toJSON {
      # Claude Code asks us to log in during onboarding. We may want to use
      # CLAUDE_CODE_OAUTH_TOKEN instead.
      hasCompletedOnboarding = true;
    });
    settingsJson = pkgs.writeText "settings.json" (builtins.toJSON {
      # Disable commercials in git commits
      attribution = {
        commit = "";
        pr = "";
      };
      # Default to Sonnet rather than Opus. Model choice is the biggest lever
      # on Claude's carbon footprint, and Sonnet is plenty for most work.
      # Override per-session with `/model opus` when you need it.
      # https://github.com/gwittebolle/claude-carbon
      model = "sonnet";
      # Cap reasoning effort to avoid burning thinking tokens on routine tasks.
      # This is the lever that works on adaptive-reasoning models (Opus/Sonnet),
      # which ignore MAX_THINKING_TOKENS. Bump to "high" when you need it.
      effortLevel = "medium";
      # yolo
      permissions.defaultMode = "bypassPermissions";
      skipDangerousModePermissionPrompt = true;
      # Transparently rewrite Bash commands through RTK (see systemPackages
      # above) so e.g. `git status` runs as `rtk git status`, trimming output
      # before it costs context tokens. This is what `rtk init` would patch in.
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
      # claude-carbon: show live CO2 estimate in the status line, and persist
      # each session's footprint to the SQLite DB on Stop (read by the
      # /carbon-report command, wired up in carbon.nix). We invoke via `bash`
      # so it doesn't depend on the script's executable bit in the nix store.
      statusLine = {
        type = "command";
        command = "${pkgs.bash}/bin/bash ${claude-carbon}/scripts/statusline.sh";
      };
      hooks.Stop = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "${pkgs.bash}/bin/bash ${claude-carbon}/scripts/persist-session.sh";
            }
          ];
        }
      ];
    });
  in [
    # It's annoying to bind mount a single file, so we symlink
    # /root/.claude.json to the persisted directory.
    "L+ /root/.claude.json - - - - /root/.claude/claude.json"
    "C /root/.claude/claude.json 0600 root root - ${claudeJson}"
    # settings.json is generated config, not runtime state, so symlink it into
    # the store. Using "C" (copy-if-absent) here meant the file persisted in the
    # mounted ~/.claude volume and never picked up rebuilds; "L+" always points
    # at the current build (and unlinks any stale copy first).
    "L+ /root/.claude/settings.json - - - - ${settingsJson}"
    # We must use AGENTS.md, rather than CLAUDE.md, since we patched the binary
    "L+ /root/.claude/AGENTS.md - - - - ${vars.AGENTS_md}"
  ];

  # Automatically trust the mounted directory
  systemd.services.claude-auto-trust = {
    wantedBy = ["multi-user.target"];
    after = ["systemd-tmpfiles-setup.service"];
    before = ["console-getty.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.yq-go}/bin/yq \
        --inplace \
        --input-format=json \
        --output-format=json \
        '.projects[loadstr("/clank/cwd")].hasTrustDialogAccepted = true' \
        /root/.claude.json
    '';
  };

  # https://code.claude.com/docs/en/claude-directory#application-data
  fileSystems."/root/.claude" = {
    device = "/persist/root/.claude";
    fsType = "none";
    options = ["bind"];
  };
}
