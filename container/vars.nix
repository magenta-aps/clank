{pkgs, ...}: {
  _module.args.vars = {
    AGENTS_md = pkgs.writeText "AGENTS.md" ''
      - Run unknown commands using `nix shell nixpkgs#<package>`
      - Avoid writing em-dashes (`—`) in comments or commit messages
      - Be concise. No preamble or summaries unless asked.
      - Prefer solving inline. Only spawn subagents or workflows when the task genuinely needs parallelism, since each one multiplies token use (and carbon).
      - Shell commands are auto-rewritten through `rtk` to save tokens; run `rtk gain` to see the savings. Use `rtk proxy <cmd>` if you need raw, unfiltered output.
    '';
  };
}
