{...}: {
  home-manager.users.root = {
    programs.opencode = {
      settings = {
        mcp = {
          servers = {
            kagi = {
              type = "remote";
              url = "http://clank-proxy:1394/mcp";
            };
          };
        };
        # Disable built-in websearch
        websearch = false;
      };
    };
  };
}
