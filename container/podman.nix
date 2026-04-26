{
  lib,
  pkgs,
  ...
}: {
  # Stolen from https://git.caspervk.net/caspervk/nixos/src/commit/56ad8f33f998129a980e05dcd29ab45bec084301/modules/podman.nix

  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings = {
      # DNS is required for containers under podman-compose to be able to talk
      # to each other.
      dns_enabled = true;
      ipv6_enabled = true;
    };
    # Create an alias mapping `docker` to `podman`. This does *not* enable the
    # docker-compatible socket (`virtualisation.podman.dockerSocket.enable`),
    # which would allow members of the `podman` group to gain root access.
    dockerCompat = true;
  };

  virtualisation.containers = {
    enable = true;
    containersConf.settings = {
      engine = {
        # `podman compose` is a thin wrapper around an external compose provider
        # such as `docker-compose` or `podman-compose.` This means that `podman
        # compose` is executing another tool that implements the compose
        # functionality but sets up the environment in a way to let the compose
        # provider communicate transparently with the local Podman socket.
        # https://docs.podman.io/en/stable/markdown/podman-compose.1.html
        # Redhat focuses more on making `docker-compose` work with Podman than
        # supporting `podman-compose` (and it looks better), so we use that.
        # https://github.com/containers/podman-compose/issues/276#issuecomment-809463088
        compose_providers = ["${pkgs.docker-compose}/bin/docker-compose"];
        # By default, `podman compose` will emit a warning saying that it
        # executes an external command.
        compose_warning_logs = false;
      };
    };
    # https://github.com/containers/storage/blob/main/docs/containers-storage.conf.5.md
    storage.settings = {
      storage = {
        # Root is tmpfs, but building images or running containers may require
        # a lot of space. Use (per-Clank) disk for that. Once an image is
        # built, it is saved to the (persistent and shared) imagestore.
        graphroot = "/disk/graphroot";
        imagestore = "/persist/imagestore";
        options = {
          # We can use the host's images if it also uses Podman. This is
          # mounted (read-only) in main.oy.
          # https://www.redhat.com/en/blog/image-stores-podman
          additionalimagestores = [
            "/var/lib/shared"
          ];
        };
      };
    };
  };

  # /var/lib/shared isn't mounted if the host doesn't use Podman. Ensure an
  # empty directory exists to avoid errors.
  systemd.tmpfiles.rules = [
    "d /var/lib/shared 0700 root root -"
  ];

  # Add default image mirrors. NixOS generates registries.conf in the
  # deprecated version 1 format so we overwrite the entire file.
  # https://github.com/containers/image/blob/main/docs/containers-registries.conf.5.md
  environment.etc."containers/registries.conf".text =
    lib.mkForce
    # toml
    ''
      # Unqualified images suck, but we'll do it for granddad
      unqualified-search-registries = ["docker.io"]

      # Use Google's Docker Hub mirror for everything docker.io
      # https://cloud.google.com/artifact-registry/docs/pull-cached-dockerhub-images
      [[registry]]
      location = "docker.io"
      [[registry.mirror]]
      location = "mirror.gcr.io"
    '';

  # Use the (rootless) Podman user socket for compatibility with Docker-only
  # tools such as `dive`.
  # https://k3d.io/stable/usage/advanced/podman/#using-rootless-podman
  environment.sessionVariables = rec {
    DOCKER_HOST = "unix://${DOCKER_SOCK}";
    DOCKER_SOCK = "\${XDG_RUNTIME_DIR}/podman/podman.sock";
  };
}
