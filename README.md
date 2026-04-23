# clank

`clank` is an AI sandbox, pre-configured to quickly start using AI.

> [!NOTE]
> This tool is designed for internal use at
> [Magenta](https://github.com/magenta-aps/). It is open source, so you're
> allowed to use it and fork it, but we may not be able to help you if you
> don't work at Magenta.

## Quick Start

### Linux Install (non-NixOS)

Install the [Nix package manager](https://nixos.org/download/) on your distro.
This is just a package manager, not a full OS switch:

> **Multi-user (requires sudo)**
>
> ```sh
> sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
> ```

> **Fedora**
>
> Allegedly, the multi-user install above does not work on SELinux distros, in
> that case you can install Nix as a Fedora package instead:
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

Alternatively, you can run the latest version directly from GitHub, without
installing it:

```sh
nix run github:magenta-aps/clank
```

If everything succeeded, you should be able to boot into your sandbox like so:

```sh
clank
```

This boots into a NixOS container. To set up your favorite AI coding assistant,
use one (or more) of the following links:

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

Inside `clank`, run the following and follow the on-screen instructions to
create an access token, linked with your Claude account:

```sh
claude setup-token
```

You should now have a Claude access token. Copy it.

Create a file in `~/.config/clank.sh` (on the host machine, not inside clank)
containing the following:

```sh
export CLAUDE_CODE_OAUTH_TOKEN=<your-access-token-here>
```

Re-open `clank`. You should now be able to start Claude Code with your account,
without having to log in every time.

### Set up Open Code with Scaleway

Prerequisites:

- [Install `clank`](#quick-start)
- Have a [Scaleway account](https://www.scaleway.com/) with access to [Scaleway Generative APIs](https://www.scaleway.com/en/generative-apis/)

Create or retrieve your Scaleway secret key from the [Scaleway
console](https://console.scaleway.com/iam/api-keys).

Add the following to `~/.config/clank.sh` (on the host machine, not inside
clank):

```sh
# Scaleway Project ID for Magenta (if you're not a Magenta employee you need to set up a project first)
export SCW_PROJECT_ID='594a268d-8577-4b86-a983-be375e13e197'
export SCW_SECRET_KEY='<your-scaleway-secret-key>'
export OPENCODE_MODEL='scaleway/<your-model-id>'
```

`OPENCODE_MODEL` is an identifier for the specific model to use, it has the
format `provider/model_id`. You can [browse supported Scaleway
models](https://models.dev/?search=scaleway/). For instance, any of the
following work:

- `scaleway/qwen3.5-397b-a17b`
- `scaleway/llama-3.3-70b-instruct`

Boot (or re-open) `clank`:

```sh
clank
```

You should now be able to start Open Code, which will automatically use the
Scaleway model you specified:

```sh
opencode
```

You can also switch to a different model temporarily by pressing `Ctrl-p` while
inside the opencode interface.

## Usage

Prerequisites:

- [Complete the quick start section](#quick-start)

Run clank:

```sh
clank
```

This starts a podman container running NixOS, with some essential packages
pre-installed, as well as AI coding assistants (Claude Code and Open Code).

From here, you can launch your coding assistant, for instance:

```sh
claude
```

## Updating Clank (non-NixOs)

```sh
nix profile upgrade clank
```
