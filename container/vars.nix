{...}: {
  _module.args.vars = {
    AGENTS_md = ''
      - You are running in a sandboxed environment, separate from the user's environment
      - Run unknown commands using `nix shell nixpkgs#<package>`
      - Avoid writing em-dashes (`—`) in comments or commit messages
    '';
  };
}
