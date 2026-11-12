# Magenta

## Configuration

### 1. Proxy

`~/.config/clank/Caddyfile`

```Caddy
# Providers
:1689 {
	reverse_proxy https://api.greenpt.ai {
		header_up Authorization "Bearer <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}
:1666 {
	reverse_proxy https://api.anthropic.com {
		header_up Authorization "Bearer <token>"  # `claude setup-token`
	}
}

# MCP Servers
:1394 {
	reverse_proxy https://mcp.kagi.com {
		header_up Authorization "Bearer <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}

# Agent Skills
:1932 {
	reverse_proxy https://logs-prod-us-central1.grafana.net {
		header_up Authorization "Basic <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}
:1942 {
	reverse_proxy https://git.magenta.dk {
		# https://git.magenta.dk/-/user_settings/personal_access_tokens (api, write_repository)
		header_up PRIVATE-TOKEN "<token>"
		header_up Authorization "Basic <base64>"  # `printf 'clank:<token>' | base64 --wrap=0`
	}
}
:1974 {
	reverse_proxy https://redmine.magenta.dk {
        # https://redmine.magenta.dk/my/account (API access key)
		header_up X-Redmine-API-Key "<token>"
	}
}
```

### 2. Clank

#### 2a. NixOS

Add the clank input to your NixOS `flake.nix`:

```nix
{
  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
    };
    clank = {
      url = "github:magenta-aps/clank";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
      # inputs.home-manager.follows = "home-manager-unstable";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: {
    nixosConfigurations = {
      example = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./clank.nix
        ];
      };
    };
  };
}
```

Add the `clank` package to your modules, e.g. `clank.nix`:

```nix
{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    (inputs.clank.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      extraModules = [
        ({...}: {
          imports = [
            "${inputs.clank}/magenta/modules/gitlab.nix"
            "${inputs.clank}/magenta/modules/grafana-logs.nix"
            "${inputs.clank}/magenta/modules/kagi.nix"
            "${inputs.clank}/magenta/modules/redmine.nix"
          ];
          # https://search.nixos.org/options?channel=unstable&query=programs.opencode&source=home_manager
          # https://search.nixos.org/options?channel=unstable&query=programs.claude-code&source=home_manager
          home-manager.users.root = {
            programs.opencode = {
              settings = {
                providers = {
                  greenpt = {
                    settings = {
                      baseURL = "http://clank-proxy:1689/v1";
                    };
                  };
                };
              };
            };
            programs.claude-code = {
              settings = {
                env = {
                  CLAUDE_CODE_OAUTH_TOKEN = "dummy";
                  ANTHROPIC_BASE_URL = "http://clank-proxy:1666";
                };
              };
            };
          };
        })
      ];
    })
  ];
}
```

`nixos-rebuild` and then run it using `clank`!

#### 2b. Elsewhere

Make sure Nix is installed ([README](../)). Create a `flake.nix` in an empty
directory, e.g. `~/clank/flake.nix`.

```nix
{
  inputs = {
    clank = {
      url = "github:magenta-aps/clank";
    };
  };

  outputs = {...} @ inputs: let
    nixpkgs = inputs.clank.inputs.nixpkgs;
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = inputs.clank.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        extraModules = [
          ({...}: {
            imports = [
              "${inputs.clank}/magenta/modules/gitlab.nix"
              "${inputs.clank}/magenta/modules/grafana-logs.nix"
              "${inputs.clank}/magenta/modules/kagi.nix"
              "${inputs.clank}/magenta/modules/redmine.nix"
            ];
            # https://search.nixos.org/options?channel=unstable&query=programs.opencode&source=home_manager
            # https://search.nixos.org/options?channel=unstable&query=programs.claude-code&source=home_manager
            home-manager.users.root = {
              programs.opencode = {
                settings = {
                  providers = {
                    greenpt = {
                      settings = {
                        baseURL = "http://clank-proxy:1689/v1";
                      };
                    };
                  };
                };
              };
              programs.claude-code = {
                settings = {
                  env = {
                    CLAUDE_CODE_OAUTH_TOKEN = "dummy";
                    ANTHROPIC_BASE_URL = "http://clank-proxy:1666";
                  };
                };
              };
            };
          })
        ];
      };
    });
  };
}
```

Run it using

```sh
nix run ~/clank
```
