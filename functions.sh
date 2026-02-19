#!/usr/bin/env zsh
# functions.sh — Developer utility functions for zsh / iTerm2
#
# Usage (source once in your shell rc):
#   echo '[ -f ~/path/to/functions.sh ] && source ~/path/to/functions.sh' >> ~/.zshrc
#
# Or use the installer:
#   chmod +x functions.sh && ./functions.sh install

set -euo pipefail

# ── Installer ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "install" ]]; then
    FUNCTIONS_FILE="$(cd "$(dirname "$0")" && pwd)/functions.sh"
    RC_FILE="${ZDOTDIR:-$HOME}/.zshrc"
    SOURCE_LINE="[ -f \"$FUNCTIONS_FILE\" ] && source \"$FUNCTIONS_FILE\""

    if grep -qF "$FUNCTIONS_FILE" "$RC_FILE" 2>/dev/null; then
        echo "functions.sh already sourced in $RC_FILE"
    else
        printf "\n# Developer utility functions\n%s\n" "$SOURCE_LINE" >> "$RC_FILE"
        echo "Installed → $RC_FILE. Run: source $RC_FILE to apply."
    fi
    exit 0
fi

# ── Navigation ───────────────────────────────────────────────────────────────

# mkcd — Create a directory and immediately cd into it
#   Usage: mkcd my-new-project
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# up — Go up N directory levels (default: 1)
#   Usage: up        → cd ../
#          up 3      → cd ../../../
up() {
    local levels="${1:-1}"
    local path=""
    for (( i = 0; i < levels; i++ )); do
        path+="../"
    done
    cd "$path"
}

# ── File & Archive ───────────────────────────────────────────────────────────

# extract — Intelligently extract any common archive format
#   Usage: extract archive.tar.gz
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <file>"
        return 1
    fi
    if [[ ! -f "$1" ]]; then
        echo "extract: '$1' is not a valid file"
        return 1
    fi
    case "$1" in
        *.tar.bz2)  tar xjf "$1"     ;;
        *.tar.gz)   tar xzf "$1"     ;;
        *.tar.xz)   tar xJf "$1"     ;;
        *.tar.zst)  tar --zstd -xf "$1" ;;
        *.tar)      tar xf "$1"      ;;
        *.bz2)      bunzip2 "$1"     ;;
        *.gz)       gunzip "$1"      ;;
        *.zip)      unzip "$1"       ;;
        *.7z)       7z x "$1"        ;;
        *.rar)      unrar x "$1"     ;;
        *.xz)       xz --decompress "$1" ;;
        *.zst)      zstd --decompress "$1" ;;
        *)          echo "extract: unsupported format '$1'" ; return 1 ;;
    esac
}

# backup — Copy a file with a timestamped suffix
#   Usage: backup config.json   → config.json.bak.2026-02-19T14:30:00
backup() {
    if [[ -z "$1" ]]; then
        echo "Usage: backup <file>"
        return 1
    fi
    local stamp
    stamp=$(date +"%Y-%m-%dT%H:%M:%S")
    cp -a "$1" "${1}.bak.${stamp}" && echo "Backed up → ${1}.bak.${stamp}"
}

# sized — Show disk usage for files/dirs, sorted largest-first
#   Usage: sized           → current directory
#          sized ~/Downloads
sized() {
    du -sh "${1:-.}"/* 2>/dev/null | sort -rh | head -30
}

# ── Text & Data ──────────────────────────────────────────────────────────────

# json — Pretty-print JSON from a file, pipe, or clipboard
#   Usage: cat data.json | json
#          json data.json
#          echo '{"a":1}' | json
json() {
    if [[ -n "${1:-}" && -f "$1" ]]; then
        python3 -m json.tool "$1"
    else
        python3 -m json.tool
    fi
}

# b64encode / b64decode — Base64 helpers that strip newlines
#   Usage: b64encode "hello world"
#          echo "aGVsbG8gd29ybGQ=" | b64decode
b64encode() { printf '%s' "$*" | base64; }
b64decode() {
    if [[ -n "${1:-}" ]]; then
        printf '%s' "$1" | base64 --decode && echo
    else
        base64 --decode && echo
    fi
}

# find-replace — Recursive in-place find & replace across files
#   Usage: find-replace "old_string" "new_string" [dir] [glob]
#   Example: find-replace "localhost:3000" "localhost:8080" ./src "*.ts"
find-replace() {
    local old="${1:?Usage: find-replace <old> <new> [dir] [glob]}"
    local new="${2:?}"
    local dir="${3:-.}"
    local glob="${4:-*}"
    local count
    count=$(grep -rl --include="$glob" "$old" "$dir" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -eq 0 ]]; then
        echo "No matches found for '$old'"
        return 0
    fi
    echo "Replacing '$old' → '$new' in $count file(s)..."
    grep -rl --include="$glob" "$old" "$dir" | xargs sed -i '' "s|${old}|${new}|g"
    echo "Done."
}

# ── Networking ───────────────────────────────────────────────────────────────

# kill-port — Kill the process listening on a given TCP port
#   Usage: kill-port 3000
kill-port() {
    local port="${1:?Usage: kill-port <port>}"
    local pid
    pid=$(lsof -ti tcp:"$port")
    if [[ -z "$pid" ]]; then
        echo "No process found on port $port"
        return 0
    fi
    echo "Killing PID $pid on port $port..."
    kill -9 $pid && echo "Done."
}

# headers — Show HTTP response headers for a URL
#   Usage: headers https://example.com
headers() {
    curl -sI "${1:?Usage: headers <url>}" | less
}

# ── Process & Performance ────────────────────────────────────────────────────

# timeit — Run a command and report its wall-clock duration
#   Usage: timeit npm run build
timeit() {
    local start end elapsed
    start=$(date +%s%3N)
    "$@"
    local exit_code=$?
    end=$(date +%s%3N)
    elapsed=$(( (end - start) ))
    printf "\n⏱  Finished in %dms (%ds)\n" "$elapsed" "$(( elapsed / 1000 ))"
    return $exit_code
}

# ── Notes ────────────────────────────────────────────────────────────────────

# note — Append a timestamped note to ~/notes.md
#   Usage: note "Remembered to update deps before release"
#          note           → opens ~/notes.md in $EDITOR
NOTE_FILE="${NOTE_FILE:-$HOME/notes.md}"
note() {
    if [[ -z "${1:-}" ]]; then
        ${EDITOR:-nano} "$NOTE_FILE"
        return
    fi
    local stamp
    stamp=$(date "+%Y-%m-%d %H:%M")
    printf "\n- [%s] %s\n" "$stamp" "$*" >> "$NOTE_FILE"
    echo "Saved to $NOTE_FILE"
}

# notes — Search notes, or show last N entries
#   Usage: notes              → last 20 entries
#          notes "search term"
notes() {
    if [[ -z "${1:-}" ]]; then
        tail -20 "$NOTE_FILE" 2>/dev/null || echo "(no notes yet — use: note \"text\")"
    else
        grep -i "$*" "$NOTE_FILE" 2>/dev/null || echo "No matches found."
    fi
}

# ── Math ─────────────────────────────────────────────────────────────────────

# calc — Quick arithmetic in the terminal (supports decimals)
#   Usage: calc "3 * (4 + 2) / 1.5"
calc() {
    python3 -c "from math import *; print(${*:?Usage: calc \"expression\"})"
}
