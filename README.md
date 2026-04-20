# clank

## Try

```sh
nix run github:magenta-aps/clank -- claude setup-token
nix run github:magenta-aps/clank -- CLAUDE_CODE_OAUTH_TOKEN=hunter2 claude
```

## Install

```nix
{
  inputs = {
    clank = {
      url = "github:magenta-aps/clank";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

```nix
{clank, pkgs}: {
  environment.systemPackages = [
    clank.packages.${pkgs.system}.app
  ];
}
```

### Run

```sh
clank
```
