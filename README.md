# shell-utilities

A collection of zsh / iTerm2 shell scripts for developer productivity I've created and have been using for some time now.
Each script is self-contained and ships with a built-in installer that appends the necessary `source` line to your `~/.zshrc`.

## Contents

```
shell-utils/
├── aliases-injected.sh       # Installs aliases inline into ~/.zshrc
├── aliases-mapped.sh         # Installs a source pointer to an external aliases.sh
├── functions.sh              # Developer utility functions
├── claude-keepalive/
│   └── keepalive.sh          # Keeps a Claude.ai usage window active

```

---

## Installation

Every script supports a one-shot installer. Clone or download this repo, then run any combination of the following. All installers are idempotent — running them twice will not create duplicate entries.

```zsh
# Make scripts executable (once)
chmod +x aliases-injected.sh aliases-mapped.sh functions.sh

# Install each script you want
./aliases-injected.sh install
./aliases-mapped.sh   install
./functions.sh        install

# Reload your shell
source ~/.zshrc
```

---

## `claude-keepalive/keepalive.sh`

Pre-warms a Claude.ai usage window so that when you actually sit down to code, a large portion of the ~4–5 hour window has already elapsed — meaning your next window after hitting the limit will be available sooner.

**How it works:** The `claude` CLI (Claude Code) shares the same usage session as the Claude.ai web UI. The script sends a minimal "Hi" ping on a configurable interval using the `haiku` model, which costs the fewest tokens.

### Requirements

- [`claude` CLI](https://claude.ai/code) installed and authenticated (`claude auth login`)
- macOS (`caffeinate` is used to prevent the machine from sleeping between intervals)

### Usage

```zsh
cd claude-keepalive

# Foreground (Ctrl+C to stop)
./keepalive.sh

# Background with log
nohup ./keepalive.sh >> keepalive.log 2>&1 &

# Background, fully detached
./keepalive.sh & disown

# Stop a backgrounded instance
pkill -f keepalive.sh
```

---

## `aliases-injected.sh`

Appends all alias definitions **directly into `~/.zshrc`** as a heredoc block. Best if you want the aliases to be visible when you open your rc file without needing a second file on disk.

```zsh
./aliases-injected.sh install
```

### Aliases

#### Node / npm

| Alias   | Expands to                                      |
| ------- | ----------------------------------------------- |
| `dev`   | `nvm use` (if `.nvmrc` present) + `npm run dev` |
| `build` | `nvm use` + `npm run build`                     |
| `start` | `nvm use` + `npm start`                         |
| `test`  | `nvm use` + `npm run test`                      |
| `run`   | `nvm use` + `npm run`                           |
| `ni`    | `nvm use` + `npm i`                             |
| `nci`   | `nvm use` + `npm ci`                            |
| `nil`   | `nvm use` + `npm i --legacy-peer-deps`          |
| `use`   | `nvm use`                                       |
| `nv`    | `node -v && npm -v`                             |
| `serve` | `npx serve .`                                   |

#### System

| Alias     | Expands to                                    |
| --------- | --------------------------------------------- |
| `cls`     | `clear`                                       |
| `reload`  | `source ~/.zshrc` (or `~/.bashrc`)            |
| `path`    | Print each `$PATH` entry on its own line      |
| `ports`   | `lsof` — list all listening TCP ports         |
| `ip`      | Local IP via `ipconfig getifaddr en0`         |
| `myip`    | Public IP via `ifconfig.me`                   |
| `weather` | Current weather via `wttr.in`                 |
| `brewup`  | `brew update && brew upgrade && brew cleanup` |

---

## `aliases-mapped.sh`

Adds a **`source` pointer** in `~/.zshrc` pointing to a separate `aliases.sh` file in the same directory. Useful when you want to keep your rc file clean and manage aliases in a dedicated, version-controlled file.

> **Note:** You need to create `aliases.sh` alongside this script — it is the file that will be sourced. The aliases listed above (same set as `aliases-injected.sh`) can be placed there.

```zsh
./aliases-mapped.sh install
```

---

## `functions.sh`

Utility shell functions that extend what aliases can do. Sourced into your shell — no subshell spawned.

```zsh
./functions.sh install
```

### Navigation

| Function     | Description                                           |
| ------------ | ----------------------------------------------------- |
| `mkcd <dir>` | `mkdir -p` the directory and immediately `cd` into it |
| `up [n]`     | Go up `n` directory levels (default: `1`)             |

### File & Archive

| Function         | Description                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `extract <file>` | Auto-detect format and extract any archive: `.tar.gz`, `.zip`, `.7z`, `.rar`, `.zst`, and more |
| `backup <file>`  | Create a timestamped copy — e.g. `config.json.bak.2026-02-20T09:15:00`                         |
| `sized [dir]`    | Disk usage of a directory's contents, sorted largest-first (top 30)                            |

### Text & Data

| Function                                | Description                                      |
| --------------------------------------- | ------------------------------------------------ |
| `json [file]`                           | Pretty-print JSON from a file, a pipe, or stdin  |
| `b64encode <str>`                       | Base64-encode a string                           |
| `b64decode <str>`                       | Base64-decode a string or piped input            |
| `find-replace <old> <new> [dir] [glob]` | Recursive in-place `sed` across a directory tree |

```zsh
# Examples
echo '{"name":"ada"}' | json
b64encode "hello world"
find-replace "localhost:3000" "localhost:8080" ./src "*.ts"
```

### Networking

| Function           | Description                                                    |
| ------------------ | -------------------------------------------------------------- |
| `kill-port <port>` | Find and `kill -9` whatever process is listening on a TCP port |
| `headers <url>`    | Show HTTP response headers for a URL (via `curl -sI`)          |

### Process & Performance

| Function        | Description                                                      |
| --------------- | ---------------------------------------------------------------- |
| `timeit <cmd…>` | Run any command and report its wall-clock time in ms and seconds |

```zsh
timeit npm run build
# ⏱  Finished in 4821ms (4s)
```

### Notes

A lightweight plain-text note system backed by `~/notes.md`. Override the path with `export NOTE_FILE=~/path/to/notes.md`.

| Function        | Description                                 |
| --------------- | ------------------------------------------- |
| `note <text>`   | Append a timestamped bullet to `~/notes.md` |
| `note`          | Open `~/notes.md` in `$EDITOR`              |
| `notes`         | Show the last 20 entries                    |
| `notes <query>` | Case-insensitive grep through all notes     |

```zsh
note "Bump Node to 22 before deploying"
notes "deploy"
```

### Math

| Function      | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `calc <expr>` | Evaluate an expression via Python — supports decimals, `sqrt`, `pi`, etc. |

```zsh
calc "sqrt(144) / 2"   # 6.0
calc "2 ** 10"         # 1024
```

---

### Configuration

Edit the variables at the top of `keepalive.sh`:

| Variable           | Default   | Description            |
| ------------------ | --------- | ---------------------- |
| `INTERVAL_MINUTES` | `30`      | Minutes between pings  |
| `PING_MESSAGE`     | `"Hi"`    | Message sent each ping |
| `PING_MODEL`       | `"haiku"` | Claude model to use    |

---

## Requirements

| Tool         | Required by                  | Install                                     |
| ------------ | ---------------------------- | ------------------------------------------- |
| `zsh`        | All scripts                  | macOS built-in                              |
| `nvm`        | npm aliases                  | [nvm-sh/nvm](https://github.com/nvm-sh/nvm) |
| `python3`    | `json`, `calc`               | macOS built-in                              |
| `curl`       | `headers`, `myip`, `weather` | macOS built-in                              |
| `brew`       | `brewup`                     | [brew.sh](https://brew.sh)                  |
| `claude` CLI | `keepalive.sh`               | [claude.ai/code](https://claude.ai/code)    |
