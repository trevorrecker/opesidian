---
description: Install opesidian shell command to launch CLI tools from anywhere
---

# Install Opesidian Command

Creates an executable script at `~/.config/opesidian/command.sh` and a symlink
at `~/.local/bin/opesidian` so you can run `opesidian` from any directory.

## Task

Install a command that:

1. Changes to your opesidian vault directory
2. Launches a CLI tool — opencode by default, or any configured tool via prefix shorthand
3. Works from any directory in your terminal

Supports multiple CLI tools (opencode, claude, cursor, codex, etc.) with prefix
matching. The user picks which tools to include and their preference order during
install. First prefix match wins, so tool order determines ambiguous shortcuts
like `c`.

## Process

### 1. Get vault path and select tools

- Use `pwd` as the vault path (or let the user specify one)
- Present the available CLI tools:
  - `opencode` — OpenCode CLI (default, always included)
  - `claude` — Claude Code CLI
  - `cursor` — Cursor CLI
  - `codex` — Codex CLI
- Ask which to include and in what **preference order**. Order matters:
  - First tool is the default (bare `opesidian` with no argument)
  - Ambiguous prefixes (e.g., `c`) resolve to the first match in the list
- Show the prefix table for confirmation:

```
Prefix shortcuts (based on your ordering):
  (none) → opencode (default)
  o      → opencode
  c      → claude
  cu     → cursor
  co     → codex
```

### 2. Write the script

Write `~/.config/opesidian/command.sh`:

```bash
#!/usr/bin/env bash
# opesidian — launch a CLI tool in your vault
# Installed by: /install-opesidian-command

VAULT="/path/to/vault"
TOOLS=("opencode" "claude")

# Resolve which tool to run
cmd=""
if [[ -n "${1:-}" ]]; then
  # Prefix match against tools list (first match wins)
  for t in "${TOOLS[@]}"; do
    [[ "$t" == "$1"* ]] && cmd="$t" && break
  done
  if [[ -z "$cmd" ]]; then
    echo "opesidian: '$1' didn't match any tool (${TOOLS[*]})" >&2
    exit 1
  fi
else
  # No argument — use the first available tool
  for t in "${TOOLS[@]}"; do
    command -v "$t" &>/dev/null && cmd="$t" && break
  done
fi

# Verify the resolved tool is installed
if [[ -z "$cmd" ]]; then
  echo "opesidian: none of your configured tools are installed (${TOOLS[*]})" >&2
  exit 1
elif ! command -v "$cmd" &>/dev/null; then
  echo "opesidian: '$cmd' is not installed" >&2
  # Try falling back to the first available tool
  for t in "${TOOLS[@]}"; do
    command -v "$t" &>/dev/null && echo "  hint: '$t' is available — try: opesidian ${t:0:1}" >&2 && break
  done
  exit 1
fi

cd "$VAULT" && exec "$cmd"
```

Then:
```bash
mkdir -p ~/.config/opesidian
# write the script
chmod +x ~/.config/opesidian/command.sh
```

### 3. Symlink into PATH

```bash
mkdir -p ~/.local/bin
ln -sf ~/.config/opesidian/command.sh ~/.local/bin/opesidian
```

If `~/.local/bin` is not on `PATH`, append it to the user's shell config:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
```

This is the only line that ever touches the shell config, and only if needed.

### 4. Check for legacy installs

If the user's shell config contains an older inline `alias opesidian` or
`opesidian()` function, offer to remove it:

```bash
# Check for legacy inline command
SHELL_CONFIG="$HOME/.zshrc"  # or detect from $SHELL
if grep -q 'opesidian()\|alias opesidian\|function opesidian' "$SHELL_CONFIG" 2>/dev/null; then
  echo "Found legacy inline opesidian command in $SHELL_CONFIG"
  echo "This can be removed — the new command uses ~/.local/bin instead."
  # Ask before removing, create backup first
fi
```

### 5. Verify

```bash
which opesidian        # should show ~/.local/bin/opesidian
opesidian --help       # or just confirm it launches
```

## Prefix Matching

The script stores an ordered array of CLI tools. When called with an argument,
it iterates the array and picks the first tool whose name starts with that
argument. First match wins — so the array order is the user's preference order.

```
opesidian         → default (first tool in array)
opesidian o       → opencode
opesidian c       → first tool starting with "c" (depends on ordering)
opesidian cl      → claude
opesidian cu      → cursor
opesidian co      → codex
opesidian openco  → opencode (any unique prefix works)
opesidian xyz     → error with available tools listed
```

## Updating Tools

To add or reorder tools after install, just edit `~/.config/opesidian/command.sh`
and change the `TOOLS` array. No shell reload needed — it's a script, not a
sourced function.

## Example Output

```
🔧 Installing opesidian command...

📁 Vault path: /home/user/My Obsidian Vault
🛠️  Tools: opencode, claude

Prefix shortcuts:
  (none) → opencode (default)
  o      → opencode
  c      → claude

✅ Wrote ~/.config/opesidian/command.sh
✅ Linked ~/.local/bin/opesidian → ~/.config/opesidian/command.sh
✅ ~/.local/bin is already on PATH

✨ Usage:
   opesidian       → opencode (default)
   opesidian c     → claude
   opesidian o     → opencode
```

## Security Considerations

- **The LLM never reads shell config files** — the script lives in
  `~/.config/opesidian/command.sh`, which contains no secrets
- Shell config is only touched if `~/.local/bin` needs to be added to PATH
  (a single `export PATH` line) or to clean up a legacy inline install
- Vault path is properly quoted in the script
- Asks permission before replacing an existing install or cleaning up legacy
  commands

## Important Notes

- The script uses `exec` so it replaces the script process with the CLI tool
  (no leftover shell process)
- Shell-agnostic — works with bash, zsh, fish, or any shell since it's a
  standalone executable, not a sourced function
- `~/.local/bin` is the standard XDG user binary directory
- Updates only touch `~/.config/opesidian/command.sh` — edit the `TOOLS` array
  directly to add/remove/reorder tools
