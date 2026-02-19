#!/usr/bin/env bash
# Run this script to install aliases into your shell rc file
# Usage for Bash: bash aliases-mapped.sh install
# Usage for executable: chmod +x aliases-mapped.sh && ./aliases-mapped.sh install

# For safety, we use strict mode to prevent unintended consequences
set -euo pipefail

if [ "$1" = "install" ]; then
    # Detect shell rc file
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "$(which zsh)" ]; then
        RC_FILE="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "$(which bash)" ]; then
        RC_FILE="$HOME/.bashrc"
    else
        echo "Unsupported shell. Please add aliases manually."
        exit 1
    fi

    ALIAS_FILE="$(cd "$(dirname "$0")" && pwd)/aliases.sh"
    SOURCE_LINE="[ -f \"$ALIAS_FILE\" ] && source \"$ALIAS_FILE\""

    if grep -qF "$ALIAS_FILE" "$RC_FILE" 2>/dev/null; then
        echo "Aliases already sourced in $RC_FILE"
    else
        printf "\n# Custom aliases\n%s\n" "$SOURCE_LINE" >> "$RC_FILE"
        echo "Aliases added to $RC_FILE. Run: source $RC_FILE to apply."
    fi

    exit 0
fi

# ── Node / npm ───────────────────────────────────────────────────────────────
alias dev='[ -f .nvmrc ] && nvm use; npm run dev'
alias build='[ -f .nvmrc ] && nvm use; npm run build'
alias start='[ -f .nvmrc ] && nvm use; npm start'
alias test='[ -f .nvmrc ] && nvm use; npm run test'
alias run='[ -f .nvmrc ] && nvm use; npm run'
alias ni='[ -f .nvmrc ] && nvm use; npm i'
alias nci='[ -f .nvmrc ] && nvm use; npm ci'
alias nil='[ -f .nvmrc ] && nvm use; npm i --legacy-peer-deps'
alias use='nvm use'
alias nv='node -v && npm -v'
alias serve='npx serve .'

# ── System ───────────────────────────────────────────────────────────────────
alias cls='clear'
alias reload='source $HOME/.zshrc 2>/dev/null || source $HOME/.bashrc'
alias path='echo $PATH | tr ":" "\n"'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias ip='ipconfig getifaddr en0'
alias myip='curl -s https://ifconfig.me && echo'
alias weather='curl -s wttr.in'
alias brewup='brew update && brew upgrade && brew cleanup'
