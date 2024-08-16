# CONFIG

vault_path := "$HOME/phd-data-analysis"

#───────────────────────────────────────────────────────────────────────────────

set quiet := true

alias i := init

vault_name := `basename "{{ vault_path }}"`

_build:
    node .esbuild.mjs

#───────────────────────────────────────────────────────────────────────────────

# if on macOS, open dev-vault & create symlink to it if needed
build-and-reload: _build
    cp -f "main.js" "{{ vault_path }}/.obsidian/plugins/quadro/main.js"
    open "obsidian://open?vault={{ vault_name }}"
    open "obsidian://advanced-uri?vault={{ vault_name }}&commandid=app%253Areload"

format:
    npx biome format --write "$(git rev-parse --show-toplevel)"
    npx markdownlint-cli --fix --ignore="node_modules" "$(git rev-parse --show-toplevel)"

check-all:
    zsh ./.githooks/pre-commit

check-tsc:
    npx tsc --noEmit --skipLibCheck --strict && echo "Typescript OK"

release:
    node .release.mjs

# install dependencies, build, enable git hooks
init: && _build
    git config core.hooksPath .githooks
    npm install

update-deps: && _build
    npm update
