{pkgs, ...}: {
  # Make git use the credentials-injecting proxy
  programs.git = {
    config = {
      url."http://clank-proxy:1942/" = {
        insteadOf = [
          "git@git.magenta.dk:"
          "https://git.magenta.dk/"
        ];
      };
    };
  };

  environment.systemPackages = [
    pkgs.glab
  ];

  environment.variables = {
    # The glab cli defaults to gitlab.com
    GITLAB_HOST = "http://clank-proxy:1942";
  };

  systemd.tmpfiles.rules = let
    glabConfig = pkgs.writers.writeYAML "glab-config.yml" {
      check_update = false;
      hosts = {
        # The glab cli defaults to https even though we explicitly set http in
        # the git config and environment variable above.
        "clank-proxy:1942" = {
          api_protocol = "http";
        };
        # Use the proxy, rather than git.magenta.dk, when inferring the host
        # from MR URLs
        "git.magenta.dk" = {
          api_protocol = "http";
          api_host = "clank-proxy:1942";
        };
      };
      show_whats_new = false;
      telemetry = false;
    };
  in [
    # The config must be writable for some dumb reason
    "C /root/.config/glab-cli/config.yml 0600 root root - ${glabConfig}"
  ];

  home-manager.users.root = {
    programs.opencode = {
      commands = {
        glab-watch = ''
          ---
          description: Answer this merge request's review comments as they arrive.
          ---

          Merge request under review:

          !`glab mr view $ARGUMENTS --output json --jq '{iid, title, source_branch, web_url}'`

          Branch you are on:

          !`git branch --show-current`

          Everything below resolves the merge request from that branch, so if it is not
          the `source_branch` above, run `glab mr checkout $ARGUMENTS` first. If the two
          do not match and I gave you no argument to check out, stop and ask me which
          merge request I mean.

          Then repeat these steps until I stop you:

          1.  Run the command below, giving the shell tool a `timeout` of `600000`. It
              blocks until a comment addressed to clank is waiting, then prints the merge
              request's threads as text. Timing out before that happens is normal, so
              just run it again.

              ```sh
              while [ "$(glab mr note list --state=unresolved --output=json \
                --jq='any(.[]; .notes[-1].body | ascii_downcase | startswith("clank"))')" = "false" ]
              do
                sleep 5
              done
              glab mr note list --state=unresolved
              ```

          2.  Act on the threads whose newest comment starts with clank's name, as in
              `clank, please rename this`. The rest are conversations between human
              developers, so leave them alone. If a comment asks a question, just answer
              it. If it asks for a change, amend or rebase it into the commit it belongs
              to rather than stacking a fixup on top, then `git push --force-with-lease`.

          3.  Reply in the thread with `glab mr note create --reply`, the body piped on
              stdin and starting with `🤖:`. The eight characters before the ellipsis are
              the whole discussion id you need. Never resolve a thread.

          4.  Go back to step 1.
        '';
      };
      skills = {
        glab =
          pkgs.runCommand "glab"
          {
            nativeBuildInputs = [
              pkgs.glab
              pkgs.writableTmpDirAsHomeHook
            ];
          }
          ''
            glab skills install glab --path=.
            mv glab $out
          '';
        glab-stack =
          pkgs.runCommand "glab"
          {
            nativeBuildInputs = [
              pkgs.glab
              pkgs.writableTmpDirAsHomeHook
            ];
          }
          ''
            glab skills install glab-stack --path=.
            mv glab-stack $out
          '';
      };
    };
  };
}
