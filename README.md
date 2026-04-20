# clank

## Try

```sh
nix run github:magenta-aps/clank -- claude setup-token
nix run github:magenta-aps/clank -- CLAUDE_CODE_OAUTH_TOKEN=hunter2 claude
```

## Install

### Linux (non-NixOS)

Install the Nix package manager on your distro (Ubuntu, Fedora, Debian, Arch, etc.) — this is just a package manager, not a full OS switch:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Reopen your terminal, then enable flakes if not already enabled:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Then follow the [Try](#try) section above. For a permanent install:

```sh
nix profile install github:magenta-aps/clank
```

### NixOS

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
