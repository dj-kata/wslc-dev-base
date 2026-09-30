# wslc-dev-base

Personal Linux development base image for WSL Containers and Dev Containers on Windows 11 + WSL2.

This repository is intentionally not tied to a single project. It provides common command-line tools, shell configuration, tmux configuration, Git fallback setup, and shared VS Code extension declarations. Project-specific runtimes and dependencies belong in each project image.

## Included

- Ubuntu 24.04 LTS
- Non-root `vscode` user with passwordless sudo
- zsh as the default shell
- tmux, git, curl, wget, unzip, zip, build-essential
- fzf, ripgrep, jq, bat, eza, less, tree, procps, file, openssh-client
- Linux uv installed with Astral's official installer
- Git-managed zsh and tmux dotfiles
- Optional Git identity fallback from ignored personal env files

## Not Included

Keep project-specific dependencies out of this image:

- PySide6, cx_Freeze, pytest, ruff, or project Python packages
- Node.js, Java, Android SDK, Verilator, or app-specific system libraries
- Language-specific VS Code extensions
- Personal names, emails, tokens, SSH keys, or other secrets

## Prerequisites

On Windows:

- VS Code
- Dev Containers extension
- WSL2
- WSL Containers or another OCI-compatible container engine available from WSL

Docker Desktop is not required by design. The sample commands use `docker` only as a default command name; set `CONTAINER_ENGINE` to the WSLc-compatible command you use.

## Build

```bash
make build CONTAINER_ENGINE="C:\\Program Files\\WSL\\wslc.exe"
```

Equivalent explicit command:

```bash
docker build -f Containerfile -t localhost/wslc-dev-base:dev .
```

For WSLc or another engine:

```bash
make build CONTAINER_ENGINE=wslc IMAGE=localhost/wslc-dev-base:dev
```

## Run

```bash
make run
```

Equivalent explicit command:

```bash
docker run --rm -it \
  --user vscode \
  --workdir /workspace \
  --mount type=bind,source="$PWD",target=/workspace \
  localhost/wslc-dev-base:dev zsh
```

Pass ignored personal values at runtime when needed:

```bash
docker run --rm -it --env-file .env localhost/wslc-dev-base:dev zsh
```

## Dev Containers

Build the image with WSLc first:

```powershell
cd D:\work\wslc-dev-base
& "C:\Program Files\WSL\wslc.exe" ps -a --filter label=devcontainer.local_folder=d:\work\wslc-dev-base
# Remove any old stopped container IDs shown above before rebuilding.
& "C:\Program Files\WSL\wslc.exe" remove -f <container-id>
& "C:\Program Files\WSL\wslc.exe" build -f Containerfile -t localhost/wslc-dev-base:dev .
```

Then open this repository in VS Code and run "Dev Containers: Reopen in Container". This workspace includes `dev.containers.dockerPath = C:\\Program Files\\WSL\\wslc.exe`, but also set the same value in VS Code User Settings for the host window you use.

The Dev Container configuration uses the prebuilt image `localhost/wslc-dev-base:dev`, connects as `vscode`, lets Dev Containers override the startup command so the container stays alive, sets zsh as the integrated terminal profile, and runs `setup-git-identity` after creation. This avoids Dev Containers calling Docker Buildx, which is not supported by WSLc 3.0.1. The image default command is `sleep infinity` so the container stays alive even if Dev Containers cannot override the command. `.env` is optional; the container works without it.

## VS Code Extensions

Common, language-independent extensions are managed in `.devcontainer/devcontainer.json` under `customizations.vscode.extensions`.

Keep project-specific extensions in each project repository. Examples:

- Python, Ruff, Pyright
- C/C++
- SystemVerilog
- Any framework- or app-specific extension

Do not install VS Code extensions in `Containerfile`.

## Using This Image From Projects

After publishing a versioned image, project containers can inherit from it:

```Dockerfile
FROM ghcr.io/dj-kata/wslc-dev-base:0.1.0
```

Prefer version tags for projects. Avoid relying only on `latest`.

Project images should add only their own runtime, libraries, tools, and VS Code extensions.

## Updating

Change `Containerfile`, dotfiles, or scripts, then rebuild:

```bash
make build IMAGE=localhost/wslc-dev-base:dev
```

When publishing to an OCI registry such as GitHub Container Registry, tag releases explicitly:

```bash
docker tag localhost/wslc-dev-base:dev ghcr.io/dj-kata/wslc-dev-base:0.1.0
docker push ghcr.io/dj-kata/wslc-dev-base:0.1.0
```

GitHub Actions publishing can be added later.

## Dotfiles

Tracked files:

```text
dotfiles/
├─ zsh/
│  └─ .zshrc
└─ tmux/
   └─ .tmux.conf
```

`postCreateCommand` and `postStartCommand` run `install-dotfiles`, so these files are copied into `$HOME` when the Dev Container is created or started. Restart the Dev Container after editing dotfiles. Rebuild the image when you also want the fallback copies inside the image to change.

## Personal Env and Secrets

Copy `.env.example` to `.env` only when you need local fallback values. `.env` is ignored by Git.

The image never copies `.env`, `.env.local`, `*.secret`, or `secrets/`. Do not place secrets in build args or committed files.

See `docs/secrets.md` for details.

## Git Identity

Preferred behavior:

1. Dev Containers uses the host Git configuration when VS Code provides it.
2. Existing `git config --global user.name` and `user.email` are preserved.
3. If Git identity is missing, `setup-git-identity` reads `GIT_USER_NAME` and `GIT_USER_EMAIL` from `.env` or `~/.config/wslc-dev-base/env`.
4. If no identity exists, nothing is configured and Git reports its normal commit-time error.

The image does not contain a real personal name or email address.

## Personal Config Mounts

Bind mount personal config only when a workflow needs it:

```bash
--mount type=bind,source="$HOME/.config/codex",target=/home/vscode/.config/codex
--mount type=bind,source="$HOME/.codex",target=/home/vscode/.codex
```

Keep these paths out of the image and out of Git.

## Troubleshooting

### Dev Containers says Docker is not found

If the Dev Containers log contains a message like this:

```text
Docker returned an error code ENOENT, message: Exectuable docker not found on PATH
```

VS Code is trying to run `docker` from the Windows host. This means the host/User setting `dev.containers.dockerPath = C:\\Program Files\\WSL\\wslc.exe` was not applied, or VS Code cannot find `wslc.exe` from that window. Workspace settings alone may be too late for this initial check. A full path also avoids `spawn wslc ENOENT` when the host server PATH is missing or stale.

For the intended WSLc setup, first make sure WSL Containers is installed and `wslc` is available, then open the folder through WSL:

1. In VS Code, run `WSL: Connect to WSL` or `WSL: Open Folder in WSL`.
2. Open `/mnt/d/work/wslc-dev-base` from the WSL window.
3. Then run `Dev Containers: Reopen in Container`.

Check that the WSL environment can see a container engine:

```bash
command -v docker || command -v wslc || command -v podman
```

If you intentionally want to launch Dev Containers from a Windows-local VS Code window, install Docker Desktop or provide a Windows `docker.exe` shim that forwards to the container engine inside WSL.

### userEnvProbe waits on ssh-add

If the log says `userEnvProbe is taking longer than 10 seconds` and shows `keychain` or `ssh-add`, the host shell startup is waiting for SSH input. Guard that keychain setup so it only runs for an interactive terminal with a TTY.

## Verification

After building, run:

```bash
make check
```

The check target verifies:

- `zsh --version`
- `tmux -V`
- `git --version`
- `uv --version`
- `fzf --version`
- `rg --version`
- `jq --version`
- `bat --version`
- `eza --version`

Additional manual checks:

- Container starts as `vscode`
- Default shell is zsh
- `.zshrc` and `.tmux.conf` load
- tmux starts
- uv works as the non-root user
- `.env` is ignored by Git
- `.env.example` has placeholders only
- common VS Code extensions are declared in Dev Container metadata
