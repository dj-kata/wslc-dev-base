# Secrets and Personal Configuration

`wslc-dev-base` does not bake personal settings, tokens, SSH keys, or Git identity into the image.

## `.env`

Copy `.env.example` to `.env` when you need local fallback values:

```bash
cp .env.example .env
```

`.env` is ignored by Git and must stay out of image layers. The `Containerfile` copies only explicit dotfiles and scripts, and `.dockerignore` excludes `.env`, `.env.local`, `*.secret`, and `secrets/`.

The zsh setup and `setup-git-identity` script read `.env` from the current workspace when it exists. The file is optional; an empty or missing `.env` is a normal supported state.

## Git Identity

Preferred order:

1. Use an existing global Git config, such as one copied by VS Code Dev Containers from the Windows host.
2. If global Git config is missing, use `GIT_USER_NAME` and `GIT_USER_EMAIL` from `.env` or `~/.config/wslc-dev-base/env`.
3. If neither source exists, leave Git unset and let Git show its normal commit-time error.

Run the fallback manually when needed:

```bash
setup-git-identity
```

## Codex Configuration

Codex user-level state should live outside the image and outside this repository. For this Dev Container, `CODEX_HOME` is `/home/vscode/.codex`, backed by the Linux named volume `wslc-dev-base-codex-home`. The Windows host `%USERPROFILE%\.codex` directory is mounted read-only at `/mnt/host-codex` only as a seed source. The container entrypoint copies selected user-level files into the Linux volume and fixes ownership to `vscode:vscode` before VS Code extensions start.

Use the named volume for:

- `config.toml` personal defaults
- `auth.json` or other local auth state
- MCP server configuration that contains personal paths or credentials
- profiles, history, logs, caches, sessions, SQLite-backed runtime state, and user-level skills

Do not bind-mount Windows `%USERPROFILE%\.codex` directly to `CODEX_HOME`; Codex may fail to initialize SQLite or other runtime state on that filesystem. Keep Windows `.codex` as the source for durable user settings, and keep generated runtime state in the Linux volume. The repository `.codex/` directory is for project-scoped checked-in assets. Do not commit auth files, tokens, provider secrets, personal profiles, or machine-local service paths there.

## SSH Keys

SSH private keys are personal secrets. Do not copy them into `Containerfile`, committed files, or image layers. GitHub host verification is handled by the tracked `/etc/ssh/ssh_known_hosts` seed, but user authentication should use SSH agent forwarding or a runtime bind mount/volume for personal keys.

If a bind-mounted `.ssh` directory comes from Windows and OpenSSH rejects key permissions, prefer SSH agent forwarding or a Linux-side `.ssh` directory/volume with `0600` private key permissions.

## API Keys and Tokens

Do not place secrets in `Containerfile`, build args, or committed files. Use runtime environment variables, an ignored `.env`, VS Code secret storage, or bind mounts for personal config directories.

Examples of useful runtime mounts:

```bash
--mount type=bind,source="$HOME/.ssh",target=/home/vscode/.ssh,readonly
--mount type=bind,source="$HOME/.config/codex",target=/home/vscode/.config/codex
```

Only mount what each workflow actually needs.
