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

## API Keys and Tokens

Do not place secrets in `Containerfile`, build args, or committed files. Use runtime environment variables, an ignored `.env`, VS Code secret storage, or bind mounts for personal config directories.

Examples of useful runtime mounts:

```bash
--mount type=bind,source="$HOME/.ssh",target=/home/vscode/.ssh,readonly
--mount type=bind,source="$HOME/.config/codex",target=/home/vscode/.config/codex
```

Only mount what each workflow actually needs.
