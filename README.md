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
[OpenCode documentation](https://opencode.ai/docs/providers) for a list of
supported providers. Base URLs can be found at <https://models.dev/api.json>.
Some providers use a custom SDK, in which case they are documented at
<https://ai-sdk.dev/providers/ai-sdk-providers>.

**See [magenta/](magenta/) for an example setup.**

#### 🌱 Carbon Footprint

Clank integrates [claude-carbon](https://github.com/gwittebolle/claude-carbon)
to display a live CO2 estimate in the status line and persist each session's
footprint to a local SQLite database. The `/carbon-report` slash command reads
this database to show your measured history.

Clank also ships with a few greener defaults, configured in
[`container/claude.nix`](container/claude.nix):

- **`model = "sonnet"`** — defaults to Sonnet instead of Opus. Model choice is
  the biggest lever, and Sonnet is plenty for most work. Switch per-session with
  `/model opus` when you need more, or `/model haiku` for trivial tasks (the
  low-carbon floor). Change the default in `claude.nix`.
- **`effortLevel = "medium"`** — caps reasoning effort so routine tasks don't
  burn thinking tokens. (This is the lever that works on Sonnet and Opus, which
  ignore `MAX_THINKING_TOKENS`.) Raise it to `"high"` in `claude.nix` when you
  need deeper reasoning.
- **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "50"`** — compacts the context at 50%
  instead of the ~95% default, keeping sessions leaner. Tune the percentage in
  `claude.nix`.

Use `/carbon-report` rather than assuming the greenest setting: e.g. compacting
earlier keeps each turn leaner, but on long tasks it can force re-reading files
and break prompt-cache reuse, so the best percentage is workload-dependent.

Changing any of these requires rebuilding the container (`nix run ~/clank`
during development). For a one-off session you can instead set them on the host
in `~/.config/clank.sh`, e.g.:

```sh
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE='80'
```

The bundled `AGENTS.md` (in [`container/vars.nix`](container/vars.nix)) also
asks Claude to be concise (output tokens are the most expensive) and to avoid
spawning subagents or workflows unless a task genuinely needs parallelism, since
each one multiplies token use.

Carbon also depends on the grid powering the datacenter, not just token count.
For the OpenCode path you can pick a provider on a low-carbon grid: **Scaleway**
runs on the (largely nuclear) French grid, and **Mistral** is EU-hosted. They're
a greener choice for trivial or throwaway work. You can't pick a region for the
Claude subscription, so this only applies to OpenCode.

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
