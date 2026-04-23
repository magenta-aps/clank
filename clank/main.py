import os
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

# Passed by buildPythonApplication's makeWrapperArgs in flake.nix
CLANK_EMPTY_DIRECTORY = os.environ["CLANK_EMPTY_DIRECTORY"]
CLANK_ROOT_DOCKER = os.environ["CLANK_ROOT_DOCKER"]
CLANK_ROOT_PODMAN = os.environ["CLANK_ROOT_PODMAN"]


def cli() -> None:
    with TemporaryDirectory() as tmp:
        main(Path(tmp))


def main(tmp: Path) -> None:
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

    home = Path.home()

    # clank.sh is the way to inject environment variables into the container.
    # You could also use it to run arbitrary commands on startup.
    if home.joinpath(".config/clank.sh").exists():
        command += [
            f"--volume={home}/.config/clank.sh:/root/.config/clank.sh:ro",
        ]

    # Whatever extra arguments were given on the command line are run in the
    # container, e.g. `clank opencode --model=scaleway/qwen3.5-397b-a17b`.
    command_sh = tmp.joinpath("command.sh")
    command_sh.write_text(" ".join(sys.argv[1:]))
    command += [
        f"--volume={command_sh}:/command.sh:ro",
    ]

    # Mount git config to ensure commits are done by the right author
    if home.joinpath(".config/git").exists():
        command += [
            f"--volume={home}/.config/git:/root/.config/git:ro",
        ]

    # Use Podman/Docker in the container depending on which one is installed on
    # the host. Default to Podman in case neither is installed.
    if Path("/var/lib/docker").exists():
        root = CLANK_ROOT_DOCKER
        command += [
            # Root is tmpfs. Mount Docker's data directory to a disk-backed
            # anonymous volume to avoid exploding ram usage.
            "--volume=/var/lib/docker",
            # Mount host's build/image cache to make builds and pulls faster
            # TODO
        ]
    else:
        root = CLANK_ROOT_PODMAN
        command += [
            # Root is tmpfs. Mount Podman's data directory to a disk-backed
            # anonymous volume to avoid exploding ram usage.
            "--volume=/var/lib/containers/storage",
        ]
        if home.joinpath(".local/share/containers/storage").exists():
            command += [
                # Mount host's build/image cache to make builds and pulls faster
                f"--volume={home}/.local/share/containers/storage:/var/lib/shared:ro",
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
        # /var/tmp should be disk-backed
        "--volume=/var/tmp",
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

    # Prime the podman pause process to avoid AppArmor errors due to user
    # namespace creation. Dumb workaround for
    # https://github.com/containers/podman/issues/24642.
    subprocess.run(["podman", "unshare", "true"])

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        # The systemd init process exits with status code 130 when properly
        # powered off.
        if e.returncode not in (0, 130):
            raise


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
#
# All of this is of course mitigated by the fact that we use anonymous volumes
# for podman/docker storage, but in general it seems like a bad time to use
# overlayfs as the root filesystem.
#
# https://github.com/containers/fuse-overlayfs/issues/324
# https://github.com/containers/fuse-overlayfs/issues/425
# https://github.com/containers/fuse-overlayfs/issues/444
# https://github.com/containers/podman/issues/3021
