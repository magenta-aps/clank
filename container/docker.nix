{pkgs, ...}: {
  # https://wiki.nixos.org/wiki/Docker

  virtualisation.docker = {
    enable = true;
  };

  # TODO: google pull-through cache

  # TODO
  # virtualisation.containers = {
  #   enable = true;
  #   storage.settings = {
  #     storage.options = {
  #       # Use images from the host
  #       # https://www.redhat.com/en/blog/image-stores-podman
  #       additionalimagestores = [
  #         "/var/lib/shared"
  #       ];
  #     };
  #   };
  # };
}
