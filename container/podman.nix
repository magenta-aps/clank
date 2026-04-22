{pkgs, ...}: {
  # Podman can run rootless containers and be a drop-in replacement for Docker.
  # It is used for systemd services containers defined using
  # `virtualisation.oci-containers`.
  # https://wiki.nixos.org/wiki/Podman

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

  # TODO: set docker.io as default
  # TODO: google pull-through cache

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
    storage.settings = {
      storage.options = {
        # Use host's build/image cache to make builds and pulls faster
        # https://www.redhat.com/en/blog/image-stores-podman
        additionalimagestores = [
          "/var/lib/shared"
        ];
      };
    };
  };
}
