#!/bin/bash

# Opesidian Setup Script
# Usage:
#   ./install.sh                          # Fresh install (or prompted migration)
#   ./install.sh /path/to/claudesidian    # Migrate from claudesidian vault

CLAUDESIDIAN_PATH="${1:-}"

# ─── Helpers ─────────────────────────────────────────────────────────────────

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "  $1 is not installed"
        return 1
    else
        echo "  $1 is installed"
        return 0
    fi
}

validate_claudesidian_dir() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        echo "Error: '$dir' is not a directory"
        echo ""
        echo "Suggestions:"
        echo "  - Check for typos in the path"
        echo "  - Use the full path (e.g., /Users/name/claudesidian-vault)"
        echo "  - You can use ~ for your home directory"
        return 1
    fi

    local indicators=0

    if [ -f "$dir/package.json" ] && grep -q '"claudesidian"' "$dir/package.json" 2>/dev/null; then
        indicators=$((indicators + 1))
    fi
    if [ -f "$dir/CLAUDE-BOOTSTRAP.md" ]; then
        indicators=$((indicators + 1))
    fi
    if [ -d "$dir/.claude" ]; then
        indicators=$((indicators + 1))
    fi
    if [ -d "$dir/.claude/commands" ]; then
        indicators=$((indicators + 1))
    fi

    if [ $indicators -lt 2 ]; then
        echo "Error: '$dir' does not appear to be a claudesidian installation"
        echo ""
        echo "Expected to find at least two of:"
        echo "  - package.json referencing 'claudesidian'"
        echo "  - CLAUDE-BOOTSTRAP.md"
        echo "  - .claude/ directory"
        echo "  - .claude/commands/ directory"
        return 1
    fi

    return 0
}

# ─── Migration Staging ───────────────────────────────────────────────────────

run_migration_staging() {
    local source_path="$1"
    local content_count=0
    local dotfile_count=0
    local other_count=0
    local file_count=0

    echo ""
    echo "Staging claudesidian vault for migration..."
    echo "Source: $source_path"
    echo ""
    echo "Your original claudesidian directory will NOT be modified."
    echo "Everything is copied into .migration/ for the setup wizard to process."
    echo ""

    mkdir -p .migration/content .migration/dotfiles .migration/other .migration/files

    # ── Stage ALL content directories (NN_* pattern) ──
    for dir in "$source_path"/[0-9][0-9]_*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        echo "  Staging content: $name"
        cp -r "$dir" ".migration/content/$name"
        content_count=$((content_count + 1))
    done

    # ── Stage ALL dot-directories and dot-files ──
    # Skip: .git (their repo history), node_modules-like dirs
    for item in "$source_path"/.*; do
        [ -e "$item" ] || continue
        local name
        name=$(basename "$item")
        case "$name" in
            .|..|.git|.DS_Store) continue ;;
        esac
        echo "  Staging dotfile: $name"
        cp -r "$item" ".migration/dotfiles/$name"
        dotfile_count=$((dotfile_count + 1))
    done

    # ── Stage ALL other top-level directories ──
    # Skip: NN_* dirs (already staged above), node_modules
    for dir in "$source_path"/*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        case "$name" in
            [0-9][0-9]_*|node_modules) continue ;;
        esac
        echo "  Staging directory: $name"
        cp -r "$dir" ".migration/other/$name"
        other_count=$((other_count + 1))
    done

    # ── Stage ALL top-level files ──
    # Skip: package-lock.json, pnpm-lock.yaml (deps are reinstalled)
    for item in "$source_path"/*; do
        [ -f "$item" ] || continue
        local name
        name=$(basename "$item")
        case "$name" in
            package-lock.json|pnpm-lock.yaml) continue ;;
        esac
        echo "  Staging file: $name"
        cp "$item" ".migration/files/$name"
        file_count=$((file_count + 1))
    done

    # ── Create migration manifest ──
    cat > .migration/MANIFEST.md <<'MEOF'
# Claudesidian Migration Staging

Everything from your claudesidian vault has been copied here for migration.
The `/init-bootstrap` wizard will walk you through placing and adapting each
item for opesidian/opencode.

Your original claudesidian directory was not modified.

## Directory structure

- `content/` — Your vault content directories (00_Inbox, 01_Projects, etc.)
- `dotfiles/` — All dot-directories and dot-files (.obsidian, .claude, .mcp.json, etc.)
- `other/` — Other top-level directories (OLD_VAULT, custom folders, etc.)
- `files/` — Top-level files (CLAUDE.md, package.json, etc.)

## What happens next

Run `opencode` then `/init-bootstrap`. The wizard will:

1. Walk through your content directories and place them in the vault
2. Copy your .obsidian settings, plugins, and themes
3. Migrate your .claude configuration (commands, skills, settings)
4. Adapt custom commands for opencode where possible
5. Migrate custom skills to .agents/skills/
6. Help create your AGENTS.md from your CLAUDE.md
7. Handle MCP server configuration
8. Pre-populate setup questions from your existing vault-config.json
9. Ask about any remaining items

Items that can't be cleanly migrated stay in .migration/ for your review.
MEOF

    # ── Print summary ──
    echo ""
    echo "================================================"
    echo "  Claudesidian vault staged for migration"
    echo "================================================"
    echo ""
    echo "  Source:    $source_path"
    echo "  Staged to: .migration/"
    echo ""
    echo "  Content directories:  $content_count"
    echo "  Dot-files/dirs:       $dotfile_count"
    echo "  Other directories:    $other_count"
    echo "  Top-level files:      $file_count"
    echo ""
    echo "  Your claudesidian directory was not modified."
    echo ""
}

# ─── Common Setup ────────────────────────────────────────────────────────────

run_common_setup() {
    echo "Checking required tools..."
    echo ""

    check_command "git"
    local git_ok=$?

    check_command "node"

    check_command "pnpm"
    local pnpm_ok=$?

    echo ""
    echo "Checking optional tools..."
    check_command "yt-dlp" || echo "   -> Install with: brew install yt-dlp (for YouTube transcripts)"
    check_command "jq" || echo "   -> Install with: brew install jq (for JSON processing)"
    check_command "rg" || echo "   -> Install with: brew install ripgrep (for better search)"

    echo ""

    # Install pnpm if needed
    if [ $pnpm_ok -ne 0 ]; then
        echo "Installing pnpm..."
        npm install -g pnpm
        echo "  pnpm installed"
    fi

    # Install dependencies
    echo "Installing dependencies..."
    pnpm install

    # Create PARA folders if missing
    echo ""
    echo "Ensuring folder structure..."
    mkdir -p 00_Inbox 01_Projects 02_Areas 03_Resources 04_Archive 05_Attachments/Organized 06_Metadata/{Reference,Templates}
    echo "  Folders ready"

    # Git setup (only for fresh installs without existing git)
    if [ $git_ok -eq 0 ] && [ ! -d ".git" ]; then
        echo ""
        echo "Initializing git repository..."
        git init
        git add .
        git commit -m "Initial vault setup"
        echo "  Git repository initialized"
    fi

    # Gemini API setup
    echo ""
    echo "Gemini Vision Setup (Optional)"
    echo "================================="
    echo ""
    echo "To enable image and document analysis:"
    echo "1. Get your free API key from: https://aistudio.google.com/apikey"
    echo "2. Add to your shell profile (~/.zshrc or ~/.bashrc):"
    echo ""
    echo "   export GEMINI_API_KEY='your-key-here'"
    echo ""
    echo "3. Reload your shell: source ~/.zshrc"
    echo "4. Test with: pnpm test-gemini"
    echo ""

    # Obsidian check
    echo "Obsidian Setup"
    echo "================"
    if [ -d "/Applications/Obsidian.app" ] || [ -d "$HOME/.local/share/applications/obsidian.desktop" ]; then
        echo "  Obsidian detected"
        echo "  Open this folder as a vault in Obsidian"
    else
        echo "  Download Obsidian from: https://obsidian.md"
        echo "  Then open this folder as a vault"
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo "Opesidian Setup Script"
echo "=========================="
echo ""

# Verify we're in an opesidian directory
if [ ! -f "AGENTS-BOOTSTRAP.md" ] && [ ! -f "FIRST_RUN" ]; then
    if [ -f "package.json" ] && grep -q '"opesidian"' package.json 2>/dev/null; then
        : # looks like opesidian, continue
    else
        echo "Warning: This doesn't appear to be an opesidian directory."
        echo "Make sure you're running this from the opesidian vault root."
        echo ""
        read -p "Continue anyway? (y/n): " confirm
        [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || exit 0
    fi
fi

MIGRATION_DONE=false

if [ -n "$CLAUDESIDIAN_PATH" ]; then
    # Path provided as argument
    # Expand tilde
    CLAUDESIDIAN_PATH="${CLAUDESIDIAN_PATH/#\~/$HOME}"

    if validate_claudesidian_dir "$CLAUDESIDIAN_PATH"; then
        run_migration_staging "$CLAUDESIDIAN_PATH"
        MIGRATION_DONE=true
    else
        exit 1
    fi
else
    # No path — ask about migration
    echo "Do you have an existing claudesidian vault you'd like to migrate?"
    echo ""
    echo "  This will copy ALL of your notes, Obsidian plugins, commands,"
    echo "  skills, and configuration into a staging area. The /init-bootstrap"
    echo "  wizard will then walk you through placing everything in opesidian."
    echo ""
    echo "  Your original claudesidian directory will NOT be modified."
    echo ""
    echo "  1) Yes, migrate from claudesidian"
    echo "  2) No, fresh install"
    echo ""
    read -p "Choice (1/2): " choice

    case $choice in
        1)
            echo ""
            read -p "Enter the path to your claudesidian vault: " cs_path
            cs_path="${cs_path/#\~/$HOME}"

            if validate_claudesidian_dir "$cs_path"; then
                run_migration_staging "$cs_path"
                MIGRATION_DONE=true
            else
                exit 1
            fi
            ;;
        *)
            echo ""
            echo "Starting fresh install..."
            ;;
    esac
fi

echo ""
run_common_setup

echo ""
echo "================================================"
echo "  Setup Complete"
echo "================================================"
echo ""

if [ "$MIGRATION_DONE" = true ]; then
    echo "Your claudesidian content is staged in .migration/"
    echo "The setup wizard will walk you through the final migration."
    echo ""
    echo "Next steps:"
    echo "  1. Start opencode: opencode"
    echo "  2. Run the setup wizard: /init-bootstrap"
    echo "     The wizard will adapt your commands, skills, and config for opencode."
else
    echo "Next steps:"
    echo "  1. Start opencode in this directory: opencode"
    echo "  2. Run the setup wizard: /init-bootstrap"
    echo "  3. Try: /thinking-partner (in opencode)"
fi

echo ""
