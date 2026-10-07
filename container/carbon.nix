{
  pkgs,
  claude-carbon,
  ...
}: let
  # The upstream skill's awk one-liners reference the piped value as `$1`. When
  # run as a slash command, Claude Code expands `$1` as a positional argument
  # placeholder (empty, since /carbon-report takes none) before the script ever
  # reaches awk, so every CO2/cost/equivalence field renders blank. `$0` (the
  # whole record) equals `$1` for these single-value lines and isn't a slash
  # command placeholder, so it survives expansion. Patch it at build time since
  # the upstream file lives read-only in the nix store.
  carbonReportSkill =
    pkgs.runCommand "carbon-report-SKILL.md" {}
    ''
      substitute ${claude-carbon}/skills/carbon-report/SKILL.md "$out" \
        --replace-quiet ", \$1}'" ", \$0}'" \
        --replace-quiet "\$1 / 120" "\$0 / 120" \
        --replace-quiet "\$1 / 0.2" "\$0 / 0.2" \
        --replace-quiet "\$1 / 2.4" "\$0 / 2.4"
    '';
in {
  # sqlite3 is the one extra dependency claude-carbon needs (jq is already in
  # shell.nix; awk/sed/grep/curl/date come with the base NixOS system).
  environment.systemPackages = [
    pkgs.sqlite
  ];

  # Expose the /carbon-report slash command. The skill is self-contained (it
  # queries the SQLite DB directly), so a symlink into the commands directory
  # is all that's needed.
  systemd.tmpfiles.rules = [
    "L+ /root/.claude/commands/carbon-report.md - - - - ${carbonReportSkill}"
  ];

  # The Stop hook (see claude.nix) only writes to the DB if it already exists,
  # so we create and backfill it once at boot. setup.sh is idempotent, but
  # backfill rescans history every run, so we skip it when the DB is present.
  systemd.services.claude-carbon-init = {
    wantedBy = ["multi-user.target"];
    after = ["systemd-tmpfiles-setup.service"];
    before = ["console-getty.service"];
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.jq
      pkgs.sqlite
    ];
    environment.HOME = "/root";
    serviceConfig.Type = "oneshot";
    script = ''
      if [ ! -f /root/.claude/claude-carbon/carbon.db ]; then
        bash ${claude-carbon}/scripts/setup.sh
      fi
    '';
  };
}
