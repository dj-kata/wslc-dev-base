---
name: wslc-dev-base-maintenance
description: Maintain the wslc-dev-base repository for WSL Containers/Dev Containers setup, Containerfile changes, dotfiles, VS Code settings, and WSLc-specific troubleshooting. Use for this repo; do not use for unrelated Dev Container projects.
metadata:
  short-description: Maintain wslc-dev-base
---

# wslc-dev-base Maintenance

Use this skill when working in the `wslc-dev-base` repository or when the user asks to maintain its WSL Containers / Dev Containers base image, dotfiles, VS Code settings, or troubleshooting docs.

## Repository Shape

This repo is a personal common Linux development base for Windows 11 + WSL2 + WSL Containers (WSLc), not a project-specific runtime image.

Important files:

- `Containerfile`: Ubuntu 24.04 base image, common CLI tools, `vscode` user, uv, fallback dotfiles, persistent `CMD`.
- `.devcontainer/devcontainer.json`: Dev Containers config that uses a prebuilt image.
- `.vscode/settings.json`: VS Code workspace hint for WSLc path.
- `.devcontainer/devcontainer.json` mounts the Linux named volume `wslc-dev-base-codex-home` to `/home/vscode/.codex` and sets `CODEX_HOME` there for persistent Codex user files and runtime state; `scripts/devcontainer-entrypoint.sh` seeds selected config/auth files from `/mnt/host-codex` and chowns this volume before VS Code extensions start.
- `dotfiles/zsh/.zshrc`: common zsh config copied into the container user's home.
- `dotfiles/tmux/.tmux.conf`: common tmux config copied into the container user's home.
- `scripts/install-dotfiles.sh`: copies repo dotfiles into `$HOME` on create/start.
- `scripts/setup-git-identity.sh`: fills missing Git identity from optional env values without overwriting existing config.
- `config/ssh/ssh_known_hosts`: GitHub official SSH host keys copied into `/etc/ssh/ssh_known_hosts`.
- `README.md` and `docs/secrets.md`: user-facing operating notes.

## Design Invariants

Preserve these unless the user explicitly changes the architecture:

- Use Ubuntu 24.04 LTS as the base OS.
- Do daily work as non-root user `vscode`; keep zsh as that user's shell.
- Do not bake secrets, Git author identity, SSH private keys, `.env`, or `secrets/` into the image.
- Keep project-specific dependencies out of this base image: no PySide6, cx_Freeze, pytest, ruff, Node.js, Java, Android SDK, Verilator, or language-specific VS Code extensions unless the user deliberately broadens scope.
- Keep VS Code extensions in Dev Containers metadata, not in `Containerfile`.
- Include `bubblewrap` in the base image for Codex sandbox support.
- Keep the image command persistent, currently `CMD ["sleep", "infinity"]`, so WSLc/Dev Containers containers do not exit immediately when command override behavior differs.
- Keep `.devcontainer/devcontainer.json` on `image: localhost/wslc-dev-base:dev` rather than `build` while WSLc lacks Docker Buildx compatibility.
- Keep Codex user-level files outside the image and repo by mounting the Linux named volume `wslc-dev-base-codex-home` to `/home/vscode/.codex`; repo-local `.codex/` is for checked-in project assets such as skills. Ensure the root entrypoint seeds only safe user-level files from the read-only host mount and chowns the volume to `vscode:vscode`.

## WSLc / Dev Containers Notes

WSLc 3.0.1 does not support the Docker CLI `buildx` subcommand. The Dev Containers extension may try to call `docker buildx build` when `devcontainer.json` contains a `build` section. For this repo, prefer the current prebuilt-image flow:

1. Build the image manually with WSLc from PowerShell:
   `& "C:\Program Files\WSL\wslc.exe" build -f Containerfile -t localhost/wslc-dev-base:dev .`
2. Remove old Dev Containers containers when stale state persists:
   `& "C:\Program Files\WSL\wslc.exe" ps -a --filter label=devcontainer.local_folder=d:\work\wslc-dev-base`
   then `remove -f <container-id>`.
3. Reopen in container from VS Code.

The VS Code setting `dev.containers.dockerPath` may need the full Windows path `C:\Program Files\WSL\wslc.exe`; plain `wslc` can fail with `spawn wslc ENOENT` when the Dev Containers host server has a stale or missing PATH. Do not bind-mount Windows `%USERPROFILE%\.codex` directly to `CODEX_HOME`; keep `CODEX_HOME` on a Linux named volume because Codex runtime state can fail on Windows bind mounts. Mount Windows `.codex` read-only at `/mnt/host-codex` only as a seed source.

If logs show `WSLC_E_CONTAINER_NOT_RUNNING`, first check for an old stopped container and verify the image has a persistent command. Do not assume a Containerfile build failure.

Codex warning `failed to warm featured plugin ids cache` with 401 indicates an auth/plugin cache request issue, not necessarily app-server failure. A plugin manifest warning about `interface.defaultPrompt` over 128 characters comes from a plugin under the Codex home volume and should be fixed there if needed.

If the Codex sidebar stays on a blank loading view, first avoid assuming auth failure. Check the Codex/OpenAI ChatGPT extension Output log, confirm `/home/vscode/.codex` is backed by the Linux named volume `wslc-dev-base-codex-home`, reload/restart VS Code, and consider Windows native dependency issues such as Microsoft Visual C++ Redistributable or Visual Studio Build Tools C++ workload. This repo should keep `chatgpt.openOnStartup=false` and may set `chatgpt.runCodexInWindowsSubsystemForLinux=true` for Windows-hosted VS Code.

## Dotfiles

The repo dotfiles are the source of truth. `install-dotfiles` copies them into the container user's `$HOME` on `postCreateCommand` and `postStartCommand`.

When changing `dotfiles/zsh/.zshrc` or `dotfiles/tmux/.tmux.conf`:

- Prefer common, container-safe settings in tracked dotfiles.
- Put machine-specific Windows paths, SDK managers, project aliases, SSH agent/keychain setup, and secrets in ignored personal files such as `~/.zshrc.local` or `~/.config/wslc-dev-base/zshrc.local`.
- After edits, tell the user to run `install-dotfiles && exec zsh` or restart the Dev Container.
- Rebuild the image only when fallback copies inside the image also need updating.

For zsh + fzf:

- Installing `fzf` is not enough; zsh key bindings must be sourced or a widget must be bound.
- Ctrl-r should be bound to an fzf history widget.
- Do not use `status` as a local zsh variable; it is read-only. Use names like `fzf_status`.
- On fzf cancel/Esc, call `zle reset-prompt` and `zle -R` so the terminal display does not shift or leave stale lines.

For GitHub SSH host verification, keep GitHub official host keys in `config/ssh/ssh_known_hosts` and copy them to `/etc/ssh/ssh_known_hosts`; do not rely on interactive host-key prompts in Dev Containers. Keep private keys out of the image; use SSH agent forwarding or personal runtime mounts/volumes.

For ssh-agent/keychain:

- Do not auto-start keychain in the tracked base `.zshrc`; it can block Dev Containers `userEnvProbe` via `ssh-add` prompts.
- Prefer VS Code/host SSH agent forwarding or a personal local zsh file when the user wants keychain.

## Validation

Use lightweight checks after edits:

- `zsh -n dotfiles/zsh/.zshrc`
- `bash -n scripts/install-dotfiles.sh scripts/setup-git-identity.sh`
- `python3 -m json.tool .devcontainer/devcontainer.json`
- `python3 -m json.tool .vscode/extensions.json` when present
- `git check-ignore -v .env .env.local secrets/token.secret`

If a full container check is requested, explain whether it was run with Docker-compatible local tooling or WSLc. WSLc build/run from Windows usually must be performed by the user in PowerShell unless the environment exposes a usable Windows `wslc.exe` path.
