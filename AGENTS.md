# clank

## Context
- This project is an AI sandbox built into a podman or docker container.
- By reducing the attack surface, the AI can be run with less supervision.
- This is a proof of concept, so it's okay if it isn't super robust, and we accept that there is some risk involved in running it.

## Stack
- Build tool: nix with nix flakes
  - Nix also builds the container image (no Dockerfile)
- Host-side CLI: Python
- Base container OS: NixOS

## Boundaries
- Do not execute git commands if not explicitly asked to do so
- You are not allowed to push or pull from the git remote

## Conventions
- Commit messages: conventional commits
  - e.g.: `feat: added support for XYZ` or `fix: crash when XYZ is not set`
