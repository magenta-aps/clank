# clank

`clank` is an AI sandbox, pre-configured to quickly start using AI.

## Quick Start

### Linux Install (non-NixOS)

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

Run the following for a persistent install:

```sh
nix profile add github:magenta-aps/clank
```

Alternatively, you can run the latest version directly from GitHub, without installing it:

```sh
nix run github:magenta-aps/clank
```

If everything succeeded, you should be able to boot into your sandbox like so:

```sh
clank
```

This boots into a NixOS container. To set up your favorite AI coding assistant, use one of the following links:
- [Set up Claude Code](#set-up-claude-code)
- [Set up Open Code with Scaleway](#set-up-open-code-with-scaleway)
- Set up Gemini (TODO)

### NixOS Install

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

### Set up Claude Code

Prerequisites:
- [Install `clank`](#quick-start)
- Have a [Claude account](https://claude.ai)

Boot into `clank`:

```sh
clank
```

Inside `clank`, run the following and follow the on-screen instructions to create an access token, linked with your Claude account:

```sh
claude setup-token
```

You should now have a Claude access token. Copy it.

Create a file in `~/.config/clank.sh` (on the host machine, not inside clank) containing the following:

```sh
export CLAUDE_CODE_OAUTH_TOKEN=<your-access-token-here>
```

Re-open `clank`. You should now be able to start Claude Code with your account, without having to log in every time.

### Set up Open Code with Scaleway

Prerequisites:
- [Install `clank`](#quick-start)
- Have a [Scaleway account](https://www.scaleway.com/) with access to [Scaleway Generative APIs](https://www.scaleway.com/en/generative-apis/)

Create or retrieve your Scaleway secret key from the [Scaleway console](https://console.scaleway.com/iam/api-keys).

Add the following to `~/.config/clank.sh` (on the host machine, not inside clank):

```sh
export SCW_SECRET_KEY=<your-scaleway-secret-key>
```

Boot (or re-open) `clank`:

```sh
clank
```

You should now be able to start Open Code, which will automatically discover available Scaleway models:

```sh
opencode
```

## Usage

Prerequisites:
- [Complete the quick start section](#quick-start)

Run clank:

```sh
clank
```

This starts a podman container running NixOS, with some essential packages pre-installed, as well as AI coding assistants (Claude Code and Open Code).

From here, you can launch your coding assistant, for instance:

```sh
claude
```

## Updating Clank (non-NixOs)

```sh
nix profile upgrade clank
```
