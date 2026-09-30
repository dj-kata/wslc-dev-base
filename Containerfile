FROM ubuntu:24.04

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV EDITOR=vim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bat \
        build-essential \
        bubblewrap \
        ca-certificates \
        curl \
        eza \
        file \
        fzf \
        git \
        jq \
        less \
        locales \
        openssh-client \
        procps \
        ripgrep \
        sudo \
        tmux \
        tree \
        unzip \
        vim-tiny \
        wget \
        zip \
        zsh \
    && sed -i "s/^# *ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/" /etc/locale.gen \
    && locale-gen C.UTF-8 ja_JP.UTF-8 \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && rm -rf /var/lib/apt/lists/*

RUN if getent group "${USER_GID}" >/dev/null; then \
        existing_group="$(getent group "${USER_GID}" | cut -d: -f1)"; \
        if [ "${existing_group}" != "${USERNAME}" ] && ! getent group "${USERNAME}" >/dev/null; then \
            groupmod -n "${USERNAME}" "${existing_group}"; \
        fi; \
    else \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
    && if getent passwd "${USERNAME}" >/dev/null; then \
        usermod --uid "${USER_UID}" --gid "${USER_GID}" -s /usr/bin/zsh "${USERNAME}"; \
        mkdir -p /home/"${USERNAME}"; \
    elif getent passwd "${USER_UID}" >/dev/null; then \
        existing_user="$(getent passwd "${USER_UID}" | cut -d: -f1)"; \
        usermod -l "${USERNAME}" -d /home/"${USERNAME}" -m -s /usr/bin/zsh "${existing_user}"; \
        usermod --gid "${USER_GID}" "${USERNAME}"; \
    else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /usr/bin/zsh "${USERNAME}"; \
    fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-"${USERNAME}" \
    && chmod 0440 /etc/sudoers.d/90-"${USERNAME}"

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
    && chmod 0755 /usr/local/bin/uv /usr/local/bin/uvx

COPY dotfiles/zsh/.zshrc /home/${USERNAME}/.zshrc
COPY dotfiles/tmux/.tmux.conf /home/${USERNAME}/.tmux.conf
COPY scripts/setup-git-identity.sh /usr/local/bin/setup-git-identity
COPY scripts/install-dotfiles.sh /usr/local/bin/install-dotfiles
COPY scripts/devcontainer-entrypoint.sh /usr/local/bin/devcontainer-entrypoint
COPY dotfiles /usr/local/share/wslc-dev-base/dotfiles
COPY config/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts

RUN chown "${USERNAME}:${USERNAME}" /home/"${USERNAME}"/.zshrc /home/"${USERNAME}"/.tmux.conf \
    && chmod 0755 /usr/local/bin/setup-git-identity /usr/local/bin/install-dotfiles /usr/local/bin/devcontainer-entrypoint \
    && chmod 0644 /etc/ssh/ssh_known_hosts

USER root
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/devcontainer-entrypoint"]
CMD ["sleep", "infinity"]
