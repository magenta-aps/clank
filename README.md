# f

## Try

```sh
nix run git+https://git.caspervk.net/caspervk/f.git -- claude setup-token
nix run git+https://git.caspervk.net/caspervk/f.git -- CLAUDE_CODE_OAUTH_TOKEN=hunter2 claude
```

## Install

```nix
{
  inputs = {
    f = {
      url = "git+https://git.caspervk.net/caspervk/f.git";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

```nix
{f, pkgs}: {
  environment.systemPackages = [
    f.packages.${pkgs.system}.app
  ];
}
```

### Run

```sh
f
```
