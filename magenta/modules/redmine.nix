{pkgs, ...}: {
  environment.variables = {
    REDMINE_URL = "http://clank-proxy:1974";
  };

  environment.systemPackages = [
    pkgs.curl
    pkgs.jq
  ];

  home-manager.users.root = {
    programs.opencode = {
      skills = {
        magenta-redmine = ''
          ---
          name: magenta-redmine
          description: Read and update issues, projects and time entries in Magenta's Redmine.
          ---

          Redmine is reachable through a credentials-injecting proxy at `$REDMINE_URL`.
          Use its REST API with `curl` and `jq`.
          Never send an API key yourself; the proxy adds it.

          When the user links to `https://redmine.magenta.dk/<path>`, request `$REDMINE_URL/<path>` instead.

          See https://www.redmine.org/projects/redmine/wiki/Rest_api for endpoints.
        '';
      };
    };
  };
}
