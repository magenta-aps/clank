# clank

## Try

```sh
nix run github:magenta-aps/clank -- claude setup-token
nix run github:magenta-aps/clank -- CLAUDE_CODE_OAUTH_TOKEN=hunter2 claude
```

## Install

### Linux (non-NixOS)

Install the [Nix package manager](https://nixos.org/download/) on your distro. This is just a package manager, not a full OS switch:

> **Multi-user (requires sudo)**
> 
> ```sh
> sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
> ```

> **Fedora**
> 
> Allegedly, the multi-user install above does not work on SELinux distros, in that case you can install Nix as a Fedora package instead:
>
> ```sh
> sudo dnf install nix nix-daemon
> sudo systemctl enable --now nix-daemon
> ```

Reopen your terminal, then enable flakes if not already enabled:

```sh
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Then follow the [Try](#try) section above. For a permanent install:

```sh
nix profile add github:magenta-aps/clank
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
