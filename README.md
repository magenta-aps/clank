# 🤖 Clank

`clank` is an AI sandbox, pre-configured to quickly start using AI.

> [!NOTE]
> This tool is designed for internal use at
> [Magenta](https://github.com/magenta-aps/). It is open source, so you're
> allowed to use it and fork it, but we may not be able to help you if you
> don't work at Magenta.

## ⚡ Quick Start

### ❄️ Get Nix

Clank is build using the Nix package manager.

#### Debian / Ubuntu

```sh
sudo apt install -y nix uidmap
sudo usermod -aG nix-users $USER
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
```

**At this point you need to log out and in again to effectuate the change to
your user's groups.** Yeah, it's cringe.

#### Fedora

```sh
sudo dnf install nix nix-daemon
sudo systemctl enable --now nix-daemon
# TODO: do you need to log in and out?
```

### 🚀 Try Clank

Through the power of Nix, you can run Clank without installing anything else.
But note that you will have to manually log in every time. See the next section
for how to avoid that.

```sh
nix run github:magenta-aps/clank
```

### ⚙️ Configure Providers

### Claude Code

Create an access token:

```sh
clank claude setup-token
```

Add it to `~/.config/clank.sh` (on the host):

```sh
export CLAUDE_CODE_OAUTH_TOKEN=<your-access-token-here>
```

You can now `claude` without having to log in every time:

```sh
clank claude
```

### Open Code (Scaleway)

Add the following to `~/.config/clank.sh` (on the host):

```sh
export SCW_PROJECT_ID='594a268d-8577-4b86-a983-be375e13e197'  # Magenta's 'AI' Project ID
export SCW_SECRET_KEY='<your-scaleway-secret-key>'  # See 'TODO' in Bitwarden
export OPENCODE_MODEL='scaleway/qwen3.5-397b-a17b'  # https://models.dev/?search=scaleway/
```

You can now `opencode`, which will automatically use the Scaleway model you
specified:

```sh
clank opencode
```

You can also switch to a different model temporarily by pressing `Ctrl-p` while
inside the opencode interface.

### Gemini

Add the following to `~/.config/clank.sh` (on the host):

```sh
# TODO
```

### 📦 Install Clank

#### NixOS

```nix

```

#### Everything Else

```sh

```
