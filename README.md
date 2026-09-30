# wslc-dev-base

Personal Linux development base image for WSL Containers and Dev Containers on Windows 11 + WSL2.

This repository is intentionally not tied to a single project. It provides common command-line tools, shell configuration, tmux configuration, Git fallback setup, and shared VS Code extension declarations. Project-specific runtimes and dependencies belong in each project image.

## Included

- Ubuntu 24.04 LTS
- Non-root `vscode` user with passwordless sudo
- zsh as the default shell
- tmux, git, curl, wget, unzip, zip, build-essential
- fzf, ripgrep, jq, bat, eza, less, tree, procps, file, openssh-client
- bubblewrap for Codex sandbox support
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

The Dev Container configuration uses the prebuilt image `localhost/wslc-dev-base:dev`, starts the container with a root entrypoint that fixes mounted-volume ownership, connects day-to-day sessions as `vscode`, mounts the Linux named volume `wslc-dev-base-codex-home` at `/home/vscode/.codex`, mounts `%USERPROFILE%\.codex` read-only at `/mnt/host-codex` as a seed source, sets `CODEX_HOME=/home/vscode/.codex`, sets zsh as the integrated terminal profile, and runs `install-dotfiles && setup-git-identity` after creation. This avoids Dev Containers calling Docker Buildx, which is not supported by WSLc 3.0.1. The image default command is `sleep infinity` so the container stays alive even if Dev Containers cannot override the command. `.env` is optional; the container works without it.

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

## GitHub SSH Access

The image includes GitHub's official SSH host keys in `/etc/ssh/ssh_known_hosts`, so `github.com` host verification should not prompt inside the Dev Container. Rebuild the image after changing `config/ssh/ssh_known_hosts`.

Authentication is still personal state and is not baked into the image. Use one of these approaches:

- Prefer SSH agent forwarding when available from VS Code or your host environment.
- Or bind mount a personal `.ssh` directory at runtime, keeping private keys out of Git and out of image layers.

For manual runs, a mount can look like this:

```bash
--mount type=bind,source="$HOME/.ssh",target=/home/vscode/.ssh,readonly
```

If using a Windows `.ssh` bind mount, OpenSSH may reject private keys when the filesystem reports broad permissions. In that case, use an SSH agent or keep a Linux-side `.ssh` directory/volume with proper `0600` key permissions.

Check access from inside the Dev Container with:

```bash
ssh -T git@github.com
git ls-remote git@github.com:OWNER/REPO.git
```

## Git Identity

Preferred behavior:

1. Dev Containers uses the host Git configuration when VS Code provides it.
2. Existing `git config --global user.name` and `user.email` are preserved.
3. If Git identity is missing, `setup-git-identity` reads `GIT_USER_NAME` and `GIT_USER_EMAIL` from `.env` or `~/.config/wslc-dev-base/env`.
4. If no identity exists, nothing is configured and Git reports its normal commit-time error.

The image does not contain a real personal name or email address.

## Codex Settings Persistence

Codex user-level config and state are persisted in a Linux named volume:

```text
wslc-dev-base-codex-home volume -> /home/vscode/.codex
%USERPROFILE%\.codex read-only -> /mnt/host-codex
CODEX_HOME=/home/vscode/.codex
```

This keeps Codex logs, sessions, caches, and SQLite-backed runtime state on a Linux filesystem. The image entrypoint creates `/home/vscode/.codex`, seeds `config.toml`, `*.config.toml`, `auth.json`, `hooks.json`, `rules/`, and `skills/` from `/mnt/host-codex` when present, then chowns the volume to `vscode:vscode` before VS Code extensions start. Do not bind-mount Windows `%USERPROFILE%\.codex` directly to `CODEX_HOME`; Codex can fail while initializing SQLite or other runtime state on that filesystem.

The repo-local `.codex/` directory is for project-scoped checked-in assets such as skills or project overrides. Keep secrets, auth files, provider settings, notification hooks, and machine-local paths in the user-level Codex home volume.

To inspect or back up generated state, use a temporary container or `wslc cp`/export workflow appropriate for WSLc. Rebuilding the image does not remove the named volume, but explicitly removing the volume will remove Codex login/runtime state. Host-side `config.toml` remains the preferred source for durable user settings.

## Personal Config Mounts

Bind mount other personal config only when a workflow needs it. Do not bind-mount a Windows `.codex` directory directly to `CODEX_HOME`; use a Linux volume for that. Examples for manual `wslc run` or `docker run` commands:

```bash
--mount type=bind,source="$HOME/.ssh",target=/home/vscode/.ssh,readonly
--mount type=bind,source="$HOME/.config/codex",target=/home/vscode/.config/codex
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

### Codex Extension Warnings

These log lines are not all fatal:

- `Codex could not find bubblewrap on PATH`: install `bubblewrap` in the image. This repository includes it in `Containerfile`; rebuild the image to remove the warning.
- `failed to warm featured plugin ids cache ... 401 Unauthorized`: Codex is running, but the extension is not authenticated for that remote plugin request yet. Sign in from the Codex panel/settings.
- `ignoring interface.defaultPrompt[0]: prompt must be at most 128 characters`: a plugin manifest in the Codex home volume has a too-long default prompt. Fix or remove that plugin from the Codex home volume if it matters.

### Codex Sidebar Stays Blank

If the Codex sidebar opens but stays on a blank loading view, try these in order:

1. Run `Developer: Reload Window` or fully restart VS Code.
2. Confirm `/home/vscode/.codex` is backed by the `wslc-dev-base-codex-home` Linux named volume, and `%USERPROFILE%\.codex` is mounted only at `/mnt/host-codex` read-only.
3. In VS Code, open `Output` and check the Codex/OpenAI ChatGPT extension logs for startup errors.
4. If the extension is installed but unresponsive on Windows, install or repair the Microsoft Visual C++ Redistributable and Visual Studio Build Tools C++ workload, then fully restart VS Code.

This repo sets `chatgpt.openOnStartup=false` so the panel does not auto-open on every reload, and `chatgpt.runCodexInWindowsSubsystemForLinux=true` so Windows VS Code prefers WSL execution when available.

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
