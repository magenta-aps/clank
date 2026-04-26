import os
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
from uuid import uuid4

# Passed by buildPythonApplication's makeWrapperArgs in flake.nix
CLANK_EMPTY_DIRECTORY = os.environ["CLANK_EMPTY_DIRECTORY"]
CLANK_ROOT = os.environ["CLANK_ROOT"]


def cli() -> None:
    with TemporaryDirectory() as tmp:
        main(Path(tmp))


def main(tmp: Path) -> None:
    command = [
        "podman",
        "run",
        "--rm",
        "-it",
        f"--name=clank-{uuid4()}",
        # Kinda yolo, but you need at least `--device=/dev/fuse`, and
        # `--cap-add=SYS_ADMIN,NET_ADMIN,NET_RAW,mknod` to make podman compose
        # work inside the container anyway. Claude tried to break out for like
        # half an hour without success, so it's probably fine.
        # https://www.redhat.com/en/blog/podman-inside-container,
        "--privileged",
        "--security-opt=label=disable",
        "--security-opt=apparmor=unconfined",
        "--volume=/proc/sys:/proc/sys:rw",
        # Do not create /etc/hostname in the container
        "--no-hostname",
        # Mount current working directory into the container
        "--volume=./:/root/host:rw",
        # Root is tmpfs, but some things need to be on disk, or we will quickly
        # run out of ram. Bind mounts are defined in the NixOS configuration.
        "--volume=/disk",
        # Mount a volume shared amongst all Clank instances to /persist. Bind
        # mounts are defined in the NixOS configuration.
        "--volume=clank-persist:/persist",
    ]

    home = Path.home()

    # Mount host's git config to ensure commits are done by the right author
    if home.joinpath(".config/git").exists():
        command += [
            f"--volume={home}/.config/git:/root/.config/git:ro",
        ]

    # We can use the host's images if it also uses Podman
    if home.joinpath(".local/share/containers/storage").exists():
        command += [
            f"--volume={home}/.local/share/containers/storage:/var/lib/shared:ro",
        ]

    # ~/.config/clank.sh is how we inject environment variables into the
    # container since all --env are gobbled by systemd (/init). You could also
    # use it to run arbitrary commands on startup.
    if home.joinpath(".config/clank.sh").exists():
        command += [
            f"--volume={home}/.config/clank.sh:/root/.config/clank.sh:ro",
        ]

    # Whatever extra arguments were given on the command line are run in the
    # container, e.g. `clank opencode --model=scaleway/qwen3.5-397b-a17b`. We
    # have to do it in this roundabout way because the command argument to
    # `podman run` has to be systemd (/init).
    command_sh = tmp.joinpath("command.sh")
    command_sh.write_text(" ".join(sys.argv[1:]))
    command += [
        f"--volume={command_sh}:/command.sh:ro",
    ]

    command += [
        # NixOS just needs an /init and /nix/store to start, so we mount an
        # empty tmpfs on / and bind mount the host's /nix. /init symlinks the
        # required files from /nix/store into / and starts systemd.
        "--mount=type=tmpfs,tmpfs-size=512M,destination=/",
        "--volume=/nix:/nix:ro",
        "--systemd=always",
        # Podman won't run without a container image, but `--rootfs` tells it
        # to use the empty directory as container file system instead. Podman
        # apparently creates a symlink `/etc/mtab -> /proc/mounts` *before* the
        # tmpfs root is mounted. This fails because CLANK_EMPTY_DIRECTORY is in
        # /nix/store and thus read-only. :O mounts it as an overlay on tmpfs,
        # which makes it writable.
        "--rootfs",
        f"{CLANK_EMPTY_DIRECTORY}:O",
        f"{CLANK_ROOT}/init",
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
