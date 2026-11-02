# Clank 🤖

`clank` is an AI sandbox, pre-configured to quickly start using AI.

## ⚡ Quick Start

### Get Nix

Clank is built using the [Nix package
manager](https://nixos.org/download/#nix-install-linux).

```sh
sudo apt install -y nix uidmap
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
sudo usermod -aG nix-users $USER
```

**At this point you need to log out and in again to effectuate the change to
your user's groups.**

### Try Clank

Through the power of Nix, you can run Clank without installing anything else.

```sh
nix run github:magenta-aps/clank
```

This mounts the current directory into a sandbox, which the AI will have full
access to, so maybe don't do it in a directory with sensitive data. Get the
vibes going by running [`opencode`](https://opencode.ai) or
[`claude`](https://code.claude.com). See below for more.

## ⚙️ Customisation and Security

Giving AI access to secrets is certainly one of the ideas ever. Fortunately, we
can keep secrets out of the sandbox container by configuring the harness to use
dummy credentials and a credentials-injecting proxy.

```text
              Sandbox
┌─────────────────────────────────┐
│                                 │
│ ┌─────────────┐                 │    ┌───────────┐                           ┌──────────────┐
│ │  Open Code  │  apiKey: dummy  │    │   Caddy   │   apiKey: aHVudGVyMg==    │  Mistral AI  │
│ │  (harness)  ├─────────────────┼───►│  (proxy)  ├──────────────────────────►│  (provider)  │
│ └─────────────┘                 │    └───────────┘                           └──────────────┘
│                                 │
└─────────────────────────────────┘
```

This requires configuring OpenCode or Claude Code to use the proxy. See the
[OpenCode documentation](https://opencode.ai/v2/docs/providers/) for a list of
supported providers. Base URLs can be found at <https://models.dev/api.json>.
Some providers use a custom SDK, in which case they are documented at
<https://ai-sdk.dev/providers/ai-sdk-providers>.

**See [magenta/](magenta/) for an example setup.**

## 💡 Tips and Tricks

### OpenCode Web

```sh
CLANK_PODMAN_OPTS='--publish=127.0.0.1:4096:4096' clank opencode web --hostname=0.0.0.0 --port=4096
```

### Remove All State

```sh
nix run nixpkgs#podman -- rm --force --filter 'name=^clank'
nix run nixpkgs#podman -- volume rm clank-persist
```

## 🧑‍🔧 Development

```sh
git clone https://github.com/magenta-aps/clank.git
cd clank/
nix run .
```
