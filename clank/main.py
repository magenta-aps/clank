import os
import shlex
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
from uuid import uuid4

# Passed by buildPythonApplication's makeWrapperArgs in flake.nix
CLANK_CACERT = os.environ["CLANK_CACERT"]
CLANK_CADDY_BIN = os.environ["CLANK_CADDY_BIN"]
CLANK_EMPTY_DIRECTORY = os.environ["CLANK_EMPTY_DIRECTORY"]
CLANK_ROOT = os.environ["CLANK_ROOT"]

# Passed by the user
CLANK_PODMAN_OPTS = os.getenv("CLANK_PODMAN_OPTS", default="")


def cli() -> None:
    with TemporaryDirectory() as tmp:
        main(Path(tmp))


def main(tmp: Path) -> None:
    # Prime the podman pause process to avoid AppArmor errors due to user
    # namespace creation. Dumb workaround for
    # https://github.com/containers/podman/issues/24642.
    subprocess.run(["podman", "unshare", "true"])

    identifier = f"clank-{uuid4()}"

    # Each Clank sandbox is networked with its own credentials proxy
    subprocess.run(["podman", "network", "create", identifier], check=True)

    command = [
        "podman",
        "run",
        "--rm",
        "-it",
        f"--name={identifier}",
        f"--network={identifier}",
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
        # Mount the current working directory at the same absolute path inside
        # the container, so absolute paths (e.g. in mounted Python virtual
        # environments) work.
        f"--volume=./:{Path.cwd()}:rw",
        # Root is tmpfs, but some things need to be on disk, or we will quickly
        # run out of ram. Bind mounts are defined in the NixOS configuration.
        "--volume=/disk",
        # Mount a volume shared amongst all Clank instances to /persist. Bind
        # mounts are defined in the NixOS configuration.
        "--volume=clank-persist:/persist",
        # Allow callers to configure Podman
        *shlex.split(CLANK_PODMAN_OPTS),
    ]

    home = Path.home()

    # Mount host's git config to ensure commits are done by the right author
    if (git_config := home.joinpath(".config/git")).exists():
        command += [
            f"--volume={git_config}:/root/.config/git:ro",
        ]

    # We can use the host's images if it also uses Podman
    if (storage := home.joinpath(".local/share/containers/storage")).exists():
        command += [
            f"--volume={storage}/overlay:/var/lib/shared/overlay:ro",
            f"--volume={storage}/overlay-images:/var/lib/shared/overlay-images:ro",
            f"--volume={storage}/overlay-layers:/var/lib/shared/overlay-layers:ro",
        ]

    # Whatever extra arguments were given on the command line are run in the
    # container, e.g. `clank opencode --model=berget/moonshotai/Kimi-K3`. We
    # have to do it in this roundabout way because the command argument to
    # `podman run` has to be systemd (/init).
    tmp.joinpath("command").write_text(shlex.join(sys.argv[1:]))
    tmp.joinpath("cwd").write_text(str(Path.cwd()))
    command += [
        f"--volume={tmp}:/clank:ro",
    ]

    command += [
        # NixOS just needs an /init and /nix/store to start, so we mount an
        # empty tmpfs on / and bind mount the host's store. /init symlinks the
        # required files from /nix/store into / and starts systemd. This
        # mirrors how NixOS containers works, except we are not root on the
        # host, so we must tmpfs-mount root's profile.
        # https://github.com/NixOS/nixpkgs/blob/123e240e07c793377ad22ef9c3381a865df10f7c/nixos/modules/virtualisation/nixos-containers.nix#L203-L207
        "--mount=type=tmpfs,tmpfs-size=512M,notmpcopyup,destination=/",
        "--volume=/nix/store:/nix/store:ro",
        "--volume=/nix/var/nix/db:/nix/var/nix/db:ro",
        "--volume=/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro",
        "--tmpfs=/nix/var/nix/profiles/per-user/root",
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

    # Start the credentials proxy
    if (caddyfile := home.joinpath(".config/clank/Caddyfile")).exists():
        subprocess.run([CLANK_CADDY_BIN, "validate", "--config", caddyfile], check=True)
        subprocess.run(
            [
                "podman",
                "run",
                "--rm",
                "--detach",
                f"--name={identifier}-proxy",
                f"--network={identifier}",
                "--network-alias=clank-proxy",
                "--volume=/nix/store:/nix/store:ro",
                f"--volume={CLANK_CACERT}/etc/ssl:/etc/ssl:ro",
                f"--volume={caddyfile}:/Caddyfile:ro",
                "--rootfs",
                f"{CLANK_EMPTY_DIRECTORY}:O",
                CLANK_CADDY_BIN,
                "run",
            ],
            check=True,
        )

    try:
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        # The systemd init process exits with status code 130 when properly
        # powered off.
        if e.returncode not in (0, 130):
            raise
    finally:
        # Removing a network using --force also removes any containers using it
        subprocess.run(["podman", "network", "rm", "--force", identifier], check=True)
