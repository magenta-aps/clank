# 🤖 Clank

`clank` is an AI sandbox, pre-configured to quickly start using AI.

> [!NOTE]
> This tool is designed for internal use at
> [Magenta](https://github.com/magenta-aps/). It is open source, so you're
> allowed to use it and fork it, but we may not be able to help you if you
> don't work at Magenta.

We would like feedback from your experience with using clank, please write your complaints in [this hedgedoc](https://hedgedoc.magenta.dk/-BdNEa-KQ0C2hfocolAA4g?both).

## ⚡ Quick Start

### ❄️ Get Nix

Clank is built using the [Nix package
manager](https://nixos.org/download/#nix-install-linux).

#### Debian / Ubuntu

```sh
sudo apt install -y nix uidmap
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
sudo usermod -aG nix-users $USER
```

**At this point you need to log out and in again to effectuate the change to
your user's groups.**

### 🚀 Try Clank

Through the power of Nix, you can run Clank without installing anything else.

```sh
nix run github:magenta-aps/clank
```

This mounts the current directory into a sandbox, which the AI will have full
access to, so maybe don't do it in a directory with sensitive data. Get the
vibes going by running `opencode` or `claude`. See below for more.

## 📦 Install Clank

#### NixOS

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
{clank, pkgs, ...}: {
  environment.systemPackages = [
    clank.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

#### Everything Else

```sh
alias clank='nix run github:magenta-aps/clank --'
```

## ⚙️ Configure Providers

### 👼 Open Code

See the [OpenCode documentation](https://opencode.ai/docs/providers) for a list of providers.

- Scaleway: run `opencode` and then `/connect` to `Scaleway`. The API key [is
  here](https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310).
  We recommend the `Qwen3.5 397B A17B` model.
- Gemini: run `opencode` and then `/connect` to `Google`. The API key [is
  here](https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310).
  We recommend the `Gemini 3.1 Pro Preview` model.

### 😈 Claude Code

Anthropic doesn't allow using OpenCode with a Claude subscription, so we have
to use Claude Code. Open `claude` and then `/login` using `Claude account with
subscription` - make sure to `Continue with email`, _not_ Google.

Due to a [bug](https://github.com/anthropics/claude-code/issues/24317), you
can't use regular `/login` if you want to use multiple concurrent Claude Code
sessions. In this case, run `claude setup-token` and add the resulting token to
`~/.config/clank.sh` (on the host):

```sh
export CLAUDE_CODE_OAUTH_TOKEN='<your-access-token-here>'
```

## 🧑‍🔧 Development

```sh
git clone https://github.com/magenta-aps/clank.git
nix run ~/clank
```

## 🗑️ Remove All State

```sh
rm ~/.config/clank.sh
nix run nixpkgs#podman -- rm --force --filter 'name=^clank'
nix run nixpkgs#podman -- volume rm clank-persist
```
