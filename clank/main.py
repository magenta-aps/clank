import argparse
import os
import subprocess
from pathlib import Path

# Passed by buildPythonApplication's makeWrapperArgs
CLANK_INIT_DOCKER = os.environ["CLANK_INIT_DOCKER"]
CLANK_INIT_PODMAN = os.environ["CLANK_INIT_PODMAN"]
CLANK_EMPTY_DIRECTORY = os.environ["CLANK_EMPTY_DIRECTORY"]


def cli() -> None:
    parser = argparse.ArgumentParser(
        prog="clank",
    )
    parser.add_argument("args", nargs="*")
    args = parser.parse_args()
    print(args)  # TODO

    command = [
        "podman",
        "run",
        "--rm",
        "-it",
        # Kinda yolo, but you need at least `--device=/dev/fuse`, and
        # `--cap-add=SYS_ADMIN,NET_ADMIN,NET_RAW,mknod` to make compose work
        # inside the container anyway. Claude tried to break out for like half
        # an hour without success, so it's probably fine.
        # https://www.redhat.com/en/blog/podman-inside-container,
        "--privileged",
        "--security-opt=label=disable",
        "--security-opt=apparmor=unconfined",
        "--volume=/proc/sys:/proc/sys:rw",
        # TODO: only mount if exists
        f"--volume={Path.home()}/.local/share/containers/storage:/var/lib/shared:ro",
        f"--volume={Path.home()}/.config/git:/root/.config/git:ro",
        f"--volume={Path.home()}/.config/clank.sh:/root/.config/clank.sh:ro",
        # Mount current directory to /host/
        "--volume=./:/root/host:rw",
        # TODO: only mount if exists
        # TODO: explain why
        # "--volume=./.git/hooks:/root/host/.git/hooks:ro",
        # https://discourse.nixos.org/t/running-nix-os-containers-directly-from-the-store-with-podman/29220
        # https://github.com/metaspace/container-nixos/tree/main
        "--volume=/nix/store:/nix/store:ro",
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/run",
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/run/wrappers,suid",
        "--systemd=always",
        "--rootfs",
        f"{CLANK_EMPTY_DIRECTORY}:O",
    ]

    # TODO: podman or docker
    command += [
        CLANK_INIT_PODMAN,
    ]
    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        # The systemd init process exits with status code 130 when properly
        # powered off.
        if e.returncode not in (0, 130):
            raise
