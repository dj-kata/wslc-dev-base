IMAGE ?= localhost/wslc-dev-base:dev
CONTAINER_ENGINE ?= docker
WORKSPACE ?= $(CURDIR)

.PHONY: build run shell check

build:
	$(CONTAINER_ENGINE) build -f Containerfile -t $(IMAGE) .

run:
	$(CONTAINER_ENGINE) run --rm -it \
		--user vscode \
		--workdir /workspace \
		--mount type=bind,source=$(WORKSPACE),target=/workspace \
		$(IMAGE) zsh

shell: run

check:
	$(CONTAINER_ENGINE) run --rm $(IMAGE) zsh --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) tmux -V
	$(CONTAINER_ENGINE) run --rm $(IMAGE) git --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) uv --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) fzf --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) rg --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) jq --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) bat --version
	$(CONTAINER_ENGINE) run --rm $(IMAGE) eza --version
