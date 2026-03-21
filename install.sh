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
    local command_count=0
    local skill_count=0
    local other_count=0
    local has_obsidian="no"
    local has_claude="no"
    local has_mcp="no"
    local has_claude_md="no"

    echo ""
    echo "Staging claudesidian content for migration..."
    echo "Source: $source_path"
    echo ""

    mkdir -p .migration

    # 1. Content directories — discover dynamically (NN_* pattern)
    for dir in "$source_path"/[0-9][0-9]_*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        echo "  Staging content: $name"
        mkdir -p ".migration/content/$name"
        cp -r "$dir"/* ".migration/content/$name/" 2>/dev/null
        content_count=$((content_count + 1))
    done

    # 2. Obsidian configuration
    if [ -d "$source_path/.obsidian" ]; then
        echo "  Staging .obsidian/"
        cp -r "$source_path/.obsidian" .migration/obsidian
        has_obsidian="yes"
    fi

    # 3. Claude configuration (entire .claude/ directory)
    if [ -d "$source_path/.claude" ]; then
        echo "  Staging .claude/"
        cp -r "$source_path/.claude" .migration/claude
        has_claude="yes"

        # Count custom commands
        if [ -d "$source_path/.claude/commands" ]; then
            local stock_commands="README.md add-frontmatter.md create-command.md daily-review.md de-ai-ify.md download-attachment.md inbox-processor.md init-bootstrap.md install-claudesidian-command.md pragmatic-review.md pull-request.md release.md research-assistant.md thinking-partner.md upgrade.md weekly-synthesis.md"
            for cmd in "$source_path"/.claude/commands/*.md; do
                [ -f "$cmd" ] || continue
                local cmd_name
                cmd_name=$(basename "$cmd")
                if ! echo "$stock_commands" | grep -qw "$cmd_name"; then
                    command_count=$((command_count + 1))
                fi
            done
        fi

        # Count custom skills
        if [ -d "$source_path/.claude/skills" ]; then
            local stock_skills="git-worktrees json-canvas obsidian-bases obsidian-markdown skill-creator systematic-debugging LICENSE-kepano"
            for skill_dir in "$source_path"/.claude/skills/*/; do
                [ -d "$skill_dir" ] || continue
                local skill_name
                skill_name=$(basename "$skill_dir")
                if ! echo "$stock_skills" | grep -qw "$skill_name"; then
                    skill_count=$((skill_count + 1))
                fi
            done
        fi
    fi

    # 4. MCP configuration
    if [ -f "$source_path/.mcp.json" ]; then
        echo "  Staging .mcp.json"
        cp "$source_path/.mcp.json" .migration/
        has_mcp="yes"
    fi

    # 5. CLAUDE.md (user's personalized prompt)
    if [ -f "$source_path/CLAUDE.md" ]; then
        echo "  Staging CLAUDE.md"
        cp "$source_path/CLAUDE.md" .migration/
        has_claude_md="yes"
    fi

    # 6. Other Obsidian-related dotfiles
    for f in .trash .smart-connections .obsidian.vimrc; do
        if [ -e "$source_path/$f" ]; then
            echo "  Staging $f"
            cp -r "$source_path/$f" ".migration/$f"
        fi
    done

    # 7. Other non-core top-level directories
    for dir in "$source_path"/*/; do
        [ -d "$dir" ] || continue
        local name
        name=$(basename "$dir")
        case "$name" in
            [0-9][0-9]_*|node_modules|ref|.backup) continue ;;
        esac
        echo "  Staging other directory: $name"
        mkdir -p ".migration/other/$name"
        cp -r "$dir"/* ".migration/other/$name/" 2>/dev/null
        other_count=$((other_count + 1))
    done

    # 8. Create migration manifest
    cat > .migration/MANIFEST.md <<'MEOF'
# Claudesidian Migration Staging

Files copied from your claudesidian installation for migration.
The `/init-bootstrap` wizard will process these and adapt them for opesidian/opencode.

## Contents

- `content/` — Your vault content (PARA folders and any custom content directories)
- `obsidian/` — Your .obsidian configuration (settings, plugins, themes)
- `claude/` — Your .claude directory (commands, settings, MCP servers, vault-config)
- `other/` — Other top-level directories from your vault
- `CLAUDE.md` — Your personalized system prompt
- `.mcp.json` — Your MCP server configuration

## What happens next

Run `opencode` then `/init-bootstrap`. The wizard will:

1. Move your content into the vault's PARA folders
2. Copy your .obsidian settings and plugins
3. Detect and adapt custom commands for opencode
4. Detect and migrate custom skills to .agents/skills/
5. Help create your AGENTS.md from your CLAUDE.md
6. Copy your MCP and other configurations
7. Pre-populate setup questions from your existing vault-config.json
MEOF

    # Print summary
    echo ""
    echo "================================================"
    echo "  Claudesidian vault staged for migration"
    echo "================================================"
    echo ""
    echo "  Source:    $source_path"
    echo "  Staged to: .migration/"
    echo ""
    echo "  Content directories:  $content_count"
    echo "  .obsidian config:     $has_obsidian"
    echo "  .claude config:       $has_claude"
    echo "  Custom commands:      $command_count found"
    echo "  Custom skills:        $skill_count found"
    echo "  CLAUDE.md:            $has_claude_md"
    echo "  .mcp.json:            $has_mcp"
    echo "  Other directories:    $other_count"
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
    echo "Are you migrating from an existing claudesidian vault?"
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
