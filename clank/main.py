import argparse
import os
import subprocess
from pathlib import Path

# Passed by buildPythonApplication's makeWrapperArgs in flake.nix
CLANK_EMPTY_DIRECTORY = os.environ["CLANK_EMPTY_DIRECTORY"]
CLANK_ROOT_DOCKER = os.environ["CLANK_ROOT_DOCKER"]
CLANK_ROOT_PODMAN = os.environ["CLANK_ROOT_PODMAN"]


def cli() -> None:
    parser = argparse.ArgumentParser(
        prog="clank",
    )
    # TODO: join string and send into container
    parser.add_argument("args", nargs="*")
    args = parser.parse_args()
    print(args)  # TODO

    command = [
        "podman",
        "run",
        "--rm",
        "-it",
        # Kinda yolo, but you need at least `--device=/dev/fuse`, and
        # `--cap-add=SYS_ADMIN,NET_ADMIN,NET_RAW,mknod` to make podman/docker
        # compose work inside the container anyway. Claude tried to break out
        # for like half an hour without success, so it's probably fine.
        # https://www.redhat.com/en/blog/podman-inside-container,
        "--privileged",
        "--security-opt=label=disable",
        "--security-opt=apparmor=unconfined",
        "--volume=/proc/sys:/proc/sys:rw",
        # Do not create the /etc/hostname file in the container
        "--no-hostname",
        # Do not modify the /etc/hosts file in the container
        "--no-hosts",
        # Mount current working directory into the container
        "--volume=./:/root/host:rw",
    ]

    # TODO
    if (path := Path.home() / ".config/clank.sh").exists():
        command += [
            f"--volume={path}:/root/.config/clank.sh:ro",
        ]

    # TODO
    if (path := Path.home() / ".local/share/containers/storage").exists():
        command += [
            f"--volume={path}/:/var/lib/shared:ro",
            # Root is tmpfs. Mount Docker's data directory to a disk-backed
            # anonymous volume to avoid exploding ram usage.
            # "--volume=/var/lib/docker/",
            "--volume=/var/lib/containers/storage",
        ]
    root = CLANK_ROOT_PODMAN

    # TODO
    if (path := Path.home() / ".config/git").exists():
        command += [
            f"--volume={path}/:/root/.config/git:ro",
        ]

    command += [
        # NixOS just needs an /init and /nix/store to start, but podman needs
        # *something*. Instead of a container image, `--rootfs` tells podman to
        # use the empty directory as container file system. We mount an
        # empty tmpfs root and bind mount the host's /nix/store. The command is
        # /init from the built NixOS system, which symlinks the required files
        # from /nix/store into / and starts systemd. `nosuid` is the default
        # for tmpfs mounts, so we have to remount /run/wrappers with `suid`.
        # https://discourse.nixos.org/t/running-nix-os-containers-directly-from-the-store-with-podman/29220
        # https://github.com/metaspace/container-nixos/tree/main
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/",
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/run",
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/run/wrappers,suid",
        "--volume=/nix/store:/nix/store:ro",
        "--systemd=always",
        "--rootfs",
        # Even though we mount / as tmpfs, podman apparently *has* to create a
        # symlink `/etc/mtab -> /proc/mounts`, and apparently before the tmpfs
        # root is mounted. This fails because CLANK_EMPTY_DIRECTORY is in
        # /nix/store and thus read-only. :O mounts it as an overlay on tmpfs,
        # which makes it writable [1].
        f"{CLANK_EMPTY_DIRECTORY}:O",
        f"{root}/init",
    ]

    subprocess.run(command, check=True)


# [1]
# You may wonder why we need to make / tmpfs if we are using an overlayfs
# backed by tmpfs anyway. The reason is that podman/docker also uses overlayfs
# to run containers, and the Linux kernal doesn't support using an overlayfs as
# an upperdir for an overlayfs. Docker daemon syscall:
#
#
#   mount(
#       "overlay",
#       "/tmp/containerd-mount915074888",
#       "overlay",
#       0,
#       "workdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/6/work,
#        upperdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/6/fs,
#        lowerdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/2/fs,userxattr,
#        index=off",
#   ) = -1 EINVAL (Invalid argument)
#
#
# Associated dmesg:
#
#
#   overlay: filesystem on /var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/6/work not supported as upperdir
#
#
# Podman uses the userspace fuse-overlayfs to avoid the Linux kernel
# limitation, but it is buggy (content of deleted directory still visible).
# https://github.com/containers/fuse-overlayfs/issues/324
# https://github.com/containers/fuse-overlayfs/issues/425
# https://github.com/containers/fuse-overlayfs/issues/444
# https://github.com/containers/podman/issues/3021
