# cheat

`cheat` is a small Bash command-line tool for creating and viewing personal
cheatsheets. It includes bundled sheets and supports custom sheet directories,
nested sheet names, search, editing, and optional syntax highlighting.

## Attribution

This project is based on the original [`cheat/cheat`](https://github.com/cheat/cheat)
project, originally created by **Chris Lane**. The original project was forked
as [`j0nk0/cheat`](https://github.com/j0nk0/cheat), and this pure-Bash
conversion is developed as a branch of that fork. The original project, fork,
and author remain fully credited. This branch preserves the original
command-line concepts while removing the Python runtime dependency and adding
recursive sheet support.

## Requirements

- Bash 3.2 or newer
- Standard Unix utilities: `find`, `mktemp`, `sed`, `sort`, and `cp`
- `pygmentize` is optional and only required for syntax highlighting

The project is designed for macOS and Linux. No Python installation is
required.

This Bash conversion is version `3.0.0`.

## Installation

The installer uses `/usr/local` by default:

```sh
git clone https://github.com/j0nk0/cheat.git cheat
cd cheat
./install.sh
```

Use another prefix when needed:

```sh
PREFIX="$HOME/.local" ./install.sh
```

Make sure the selected `bin` directory is in `PATH`.

The repository can also be used directly. The public command is `bin/cheat`;
it loads the implementation from `lib/` and bundled sheets from
`cheat/cheatsheets/`.

You can also invoke it without installing anything:

```sh
./bin/cheat tar
```

## Usage

```text
cheat <cheatsheet>
cheat -e <cheatsheet>
cheat -s <keyword>
cheat -l
cheat -d
cheat -v
cheat -h
```

Examples:

```sh
cheat tar
cheat -e docker/network
cheat -s ssh
cheat -l
cheat -d
```

Sheet names may contain nested directories, such as `docker/network` or
`kubernetes/pods`. Hidden files and path components beginning with `__` are
ignored. Absolute paths and `.` or `..` path components are rejected.

## Configuration

### Default directory

Personal sheets are stored in `~/.cheat` by default. Set `DEFAULT_CHEAT_DIR`
to use another directory:

```sh
export DEFAULT_CHEAT_DIR="$HOME/Documents/cheats"
```

The directory is created automatically when needed.

### Additional directories

Use `CHEATPATH` for one or more colon-separated sheet directories:

```sh
export CHEATPATH="$HOME/cheats/community:$HOME/cheats/work"
```

The effective precedence, from lowest to highest, is:

1. The default directory
2. Bundled sheets
3. Directories in `CHEATPATH`, from left to right

Therefore, a sheet in the last matching `CHEATPATH` directory wins. Use
`cheat -d` to display the configured directories in their search order.

Set `CHEAT_BUNDLED_DIR` to override the bundled-sheet directory:

```sh
export CHEAT_BUNDLED_DIR="$HOME/cheats/bundled"
```

### Editing

`cheat -e name` uses `CHEAT_EDITOR`, then `VISUAL`, then `EDITOR`:

```sh
export CHEAT_EDITOR="vim"
cheat -e git
```

New sheets are created in the default directory. If an existing sheet comes
from the bundled directory or `CHEATPATH`, it is copied into the default
directory before editing. This keeps personal changes separate from shared or
bundled sheets.

### Syntax highlighting

Set `CHEATCOLORS` to enable highlighting through `pygmentize`:

```sh
export CHEATCOLORS=1
cheat tar
```

Sheets use the Bash lexer by default. A fenced sheet can select another lexer:

````text
```sql
SELECT id, name FROM users;
```
````

If `pygmentize` is unavailable, or a lexer is unknown, the sheet is printed as
plain text or with the Bash fallback.

## Shell completion

Completion scripts for Bash, Fish, and Zsh are in
`cheat/autocompletion/`. Install or source the script appropriate for your
shell according to its completion conventions.

## Tests

The repository includes a focused Bash test script at `tests/test.sh`. It
covers nested sheets, path precedence, reading sheets, and traversal
protection. Run it from the repository root with:

```sh
bash tests/test.sh
```

## Project layout

```text
bin/cheat                  Public command
bin/cheat.sh               CLI implementation
install.sh                 Local installation script
lib/utils.sh               Errors, editors, and highlighting
lib/sheets.sh              Paths, discovery, listing, and search
lib/sheet.sh               Individual sheet operations
cheat/cheatsheets/         Bundled sheets
cheat/autocompletion/      Shell completion scripts
licenses/                  MIT and GPLv3 license texts
tests/test.sh              Focused Bash test suite
```

## License

This project follows the original project's dual MIT/GPLv3 licensing. See
[LICENSE](LICENSE) for the licensing notice and the full terms.
