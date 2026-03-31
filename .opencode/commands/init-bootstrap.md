---
description: Interactive setup wizard that helps new users create a personalized AGENTS.md file based on their Obsidian workflow preferences
---

# Initialize Bootstrap Configuration

## How this command works

You are an interactive setup wizard. The steps below describe a conversation
you guide the user through — each numbered step is a phase where you explain
what's happening, ask questions, wait for real user input, and take action
based on their answers.

Do not rush through steps or auto-answer on the user's behalf. Present each
step clearly, explain why you're asking, and confirm before making changes.
The user should feel in control of the process at all times.

## Goal

Read the AGENTS-BOOTSTRAP.md template and interactively gather information about
the user's:

- Existing vault structure (if any)
- Workflow preferences
- Note-taking style
- Organization methods
- Specific requirements

Then generate a customized AGENTS.md file tailored to their needs.

## Process

1. **Initial Environment Setup**
   - Get current date with `date` command for timestamps
   - Check current folder name and ask if they want to rename it
   - If yes, guide them through renaming (handle parent directory move)
   - Check for package.json and install dependencies:
     - Try `pnpm install` first (faster, better)
     - Fall back to `npm install` if pnpm not available
   - Verify core dependencies are installed
   - Check git status:
     - If no .git folder: Initialize git repository
     - If has remote origin: Ask about development work
       - Personal vault: Remove origin and .github folder
       - Contributing: Keep origin and workflows intact
     - If clean local repo: Ready to go
   - Don't create folders yet - wait until after asking about organization
     method

2. **Claudesidian Migration**

   Check if `.migration/` directory exists in the vault root (created by
   `install.sh` when the user provides a claudesidian vault path). If not
   found, ask the user: "Are you migrating from an existing claudesidian
   installation? If so, provide the path and I'll stage the files for
   migration." If they provide a path, run the staging (copy everything from
   the source into `.migration/` following the same structure as install.sh).

   If `.migration/` is found, explain to the user:

   "I found staged content from your claudesidian vault. I'll walk you
   through migrating everything to opesidian. Your original claudesidian
   directory has not been modified — everything here is a copy.

   I'll go through each category of content and ask how you'd like to
   handle it. Your notes, plugins, and Obsidian settings will be brought
   over. For commands and skills, I'll adapt what I can for opencode and
   flag anything that needs your review."

   **Important principles for this step:**
   - The user's original claudesidian directory is NEVER modified
   - When in doubt about any file or directory, copy it to `.migration/`
     for the user to review rather than discarding or auto-placing it
   - Always explain what you're doing and why before taking action
   - Ask the user before overwriting anything that already exists in
     opesidian
   - The `.migration/` directory persists until the user is satisfied
     everything has been properly placed — do NOT delete it automatically

   **Sub-steps (process each category with the user):**

   a. **Notes and content directories** (`.migration/content/`)
      - List ALL directories found with file counts and sizes
      - Show the user a clear overview: "Here's what was in your vault:"
      - For each directory:
        - If it matches an existing opesidian PARA folder (e.g., 00_Inbox,
          01_Projects), ask: "Merge [name] (N files) into your opesidian
          [name] folder? (yes/skip)"
        - If it's a custom directory the user created, ask: "Found [name]
          with N files. Would you like to: (1) place it at the vault root,
          (2) rename it, (3) keep it in .migration/ for now?"
      - Use `cp -rn` (no-clobber) so existing opesidian files aren't
        overwritten
      - Show summary of what was moved and what remains in `.migration/`

   b. **Obsidian configuration** (`.migration/obsidian/`)
      - Tell user: "Your Obsidian settings, plugins, and themes are ready
        to copy over."
      - If `.obsidian/` already exists in opesidian (stock config), ask:
        "Replace with your claudesidian Obsidian settings? (yes/no)"
      - Copy to `.obsidian/` if confirmed
      - Note: this brings over their plugins, themes, workspace, hotkeys

   c. **MCP configuration** (`.migration/.mcp.json`)
      - If exists, explain what MCP config contains
      - Note that opencode uses `opencode.json` for MCP config instead of
        `.mcp.json` — offer to help translate the config
      - If they also use Claude Code, copy `.mcp.json` as-is for backward
        compat

   d. **Claude configuration** (`.migration/claude/`)

      Walk through each sub-item with the user:

      - **settings.local.json**: Copy to `.claude/settings.local.json`
        (user's local permissions — only relevant if they also use Claude
        Code)

      - **vault-config.json**: Read the user's preferences (name, projects,
        areas, resources, organization method). Copy to
        `.opencode/vault-config.json` to pre-populate later setup questions.
        Show the user what was found: "Your previous config shows you use
        PARA with these projects: [list]. I'll use this as a starting point."

      - **MCP servers**: Check if the user has custom MCP servers beyond
        stock (gemini-vision). For custom ones, copy to
        `.opencode/mcp-servers/` and note they may need config adaptation.
        For stock ones, keep opesidian's version.

      - **Custom commands**: Identify commands NOT in the stock claudesidian
        list. Stock commands: README.md, add-frontmatter.md,
        create-command.md, daily-review.md, de-ai-ify.md,
        download-attachment.md, inbox-processor.md, init-bootstrap.md,
        install-claudesidian-command.md, pragmatic-review.md,
        pull-request.md, release.md, research-assistant.md,
        thinking-partner.md, upgrade.md, weekly-synthesis.md

        For each custom command:
        - Read the file and show the user a summary of what it does
        - Determine if it can be cleanly adapted for opencode:
          - Convert frontmatter from Claude format (`name:`,
            `allowed-tools:`, `argument-hint:`) to opencode format
            (just `description:`)
          - Perform text substitutions where appropriate
        - If cleanly adaptable: show the user the adapted version, ask
          for confirmation, write to `.opencode/commands/[name].md`
        - If there are ambiguities or Claude-specific dependencies:
          consult the user on how to handle it. Options:
          - Adapt with best effort and let user review
          - Keep in `.migration/claude/commands/` for manual adaptation
          - Skip entirely
        - Always tell the user what was done with each command

      - **Custom skills**: Identify skills NOT in the stock list.
        Stock skills: git-worktrees, json-canvas, obsidian-bases,
        obsidian-markdown, skill-creator, systematic-debugging,
        LICENSE-kepano

        For each custom skill:
        - Read SKILL.md and show the user what it does
        - Update `compatibility:` frontmatter to include "opencode"
        - Copy to `.agents/skills/[name]/`
        - If there are concerns about compatibility, keep a copy in
          `.migration/` and tell the user

   e. **CLAUDE.md → AGENTS.md**
      - If `.migration/CLAUDE.md` exists:
        - Read the content and show the user a summary of their
          personalized configuration
        - Explain: "Your CLAUDE.md contains your personalized system
          prompt. I'll adapt it for opencode as AGENTS.md."
        - Create AGENTS.md by adapting the content:
          - "Claude Code" → "opencode"
          - "Claudesidian" → "Opesidian" / "claudesidian" → "opesidian"
          - "CLAUDE.md" → "AGENTS.md"
          - "CLAUDE-BOOTSTRAP.md" → "AGENTS-BOOTSTRAP.md"
          - ".claude/commands/" → ".opencode/commands/"
          - ".claude/skills/" → ".agents/skills/"
          - Do NOT change bare "Claude" (the AI model name)
        - Show the user the full adapted result and ask for confirmation
          before writing
        - Write AGENTS.md only after user approves
        - Also copy original CLAUDE.md to vault root for Claude Code
          backward compatibility

   f. **Other directories and files** (`.migration/other/`)
      - List each directory with a summary of contents
      - For each, ask the user: "Found [name] — would you like to place
        this at the vault root, or keep it in .migration/ for now?"
      - Move as directed

   g. **Other dotfiles** (`.migration/.trash`, `.migration/.smart-connections`,
      etc.)
      - List what was found and explain what each is
      - Copy to vault root with user confirmation

   h. **Migration summary**
      - Show a complete summary of everything that was migrated
      - List anything still remaining in `.migration/` that wasn't placed
      - If `.migration/` still has content, tell the user: "Some items are
        still in .migration/ for your review. You can move them manually
        or ask me to help place them later."
      - If `.migration/` is empty, offer to remove it
      - Remind the user: "Your original claudesidian vault was not modified."

   After migration completes, CONTINUE with the remaining steps. The setup
   wizard should now pre-populate answers from the migrated vault-config.json.

3. **Check Existing Configuration**
   - Look for existing AGENTS.md
   - If exists, ask if they want to update or start fresh
   - Check for AGENTS-BOOTSTRAP.md template

4. **Gather Vault Information**
   - If claudesidian migration was just performed in Step 2, skip the vault
     search and import prompts. The user's content is already in the vault.
     Tell user: "Your claudesidian content has been imported. Let's configure
     your preferences." Then proceed to Step 5.
   - Search common locations for existing Obsidian vaults (.obsidian folder)
   - Check these paths with appropriate depth limits:
     - `~/Documents` (maxdepth 3) - all platforms
     - `~/Desktop` (maxdepth 3) - all platforms
     - `~/Library/Mobile Documents/iCloud~md~obsidian/Documents` (maxdepth 5 -
       **macOS only**, iCloud vaults)
     - Home directory `~/` (maxdepth 2) - all platforms
     - Current directory parent (maxdepth 2) - all platforms
   - If found, ask: "Found Obsidian vault at [path]. Is this the vault you want
     to import?"
   - Count files correctly: `find [path] -type f -name "*.md" | wc -l` (no depth
     limit)
   - Show vault size: `du -sh [path]`
   - If confirmed, analyze vault structure:
     - Run `tree -L 3 -d [path]` to see folder hierarchy
     - Sample 10-15 random notes to understand content types
     - List 30-50 recent file names to detect naming patterns
     - Check for daily notes folder and format
     - Identify most active folders by file count
     - Detect if using PARA, Zettelkasten, Johnny Decimal, or custom
   - If not the right one or none found:
     - **On macOS only:** Ask: "Is your vault stored in iCloud Drive? (yes/no)"
     - If yes (macOS): "Please enter the full path to your vault (e.g.,
       ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/YourVault)"
     - If no, or on Linux/Windows: "Please enter the path to your existing
       vault, or type 'skip' to start fresh"
     - **Validate user-provided paths** (see "User Path Validation" section
       below)
   - If no existing vault or user skips, they're starting fresh

5. **Ask Configuration Questions**
   - "What's your name?" (for personalization)
   - "Would you like me to research your public work to better understand your
     context?"
     - If yes: Search for information
     - ALWAYS show findings and ask "Is this correct?" for confirmation
     - If multiple people found, list them numbered for selection
     - If wrong person, offer to search again or skip
     - Save relevant context about their work, writing style, areas of expertise
   - "Do you follow the PARA method or have a different organization system?"
   - "What are your main use cases? (research, writing, project management,
     knowledge base, daily notes)"

   **If using PARA, ask specific setup questions:**
   [PARA Method by Tiago Forte](https://fortelabs.com/blog/para/)
   - "What active projects are you working on?" (Create folders in 01_Projects)
   - "What areas of responsibility do you maintain?" (e.g., Work, Health,
     Finance, Family)
   - "What topics do you research frequently?" (Set up in 03_Resources)
   - "Any projects you recently completed?" (Can archive with summaries)

   **General preferences:**
   - Check .obsidian/community-plugins.json to see what plugins they use
   - Analyze existing files to detect naming convention automatically
   - Check for attachments folder to see if they work with media files
   - "Do you use git for version control?"
   - "Any specific websites or resources you reference often?"
   - "Do you have any specific writing style preferences?"
   - "Are there any workflows or patterns you want opencode to follow?"
   - "Would you like a weekly review ritual? (e.g., Thursday project review)"
   - "Do you prefer 'thinking mode' (questions/exploration) vs 'writing mode'?"

6. **Optional Tool Setup**

   **Gemini Vision (already included)**
   - Ask: "Gemini Vision is already included for analyzing images, PDFs, and
     videos. Would you like to activate it? (yes/no/later)"
   - Explain: "You just need a free API key from Google. This lets opencode
     analyze any visual content in your vault."
   - If later: "No problem! You can set it up anytime by running
     `/setup-gemini`"
   - If yes:
     - Guide to get API key from https://aistudio.google.com/apikey (free, takes
       30 seconds)
     - Help add to shell profile (.zshrc, .bashrc, etc.)
     - Run
       `claude mcp add --scope project gemini-vision node .claude/mcp-servers/gemini-vision.mjs`
     - Configure .mcp.json with API key
     - Test the connection with a sample command

   **Firecrawl (already included)**
   - Ask: "Firecrawl is included for web research. Would you like to set it up?
     (yes/no/later)"
   - Explain: "This is a game-changer for research! When you find an article or
     website, you can save it directly to your vault as markdown - preserving
     the content forever, making it searchable, and letting opencode analyze it.
     Perfect for building a research library."
   - Example: "Just tell opencode: 'Save this article to my vault: [URL]' and it's
     done!"
   - If later: "You can set it up anytime by running `/setup-firecrawl`"
   - If yes:
     - Guide to get API key from https://firecrawl.dev (free tier available)
     - Help configure the scripts in .scripts/
     - Show example usage: `.scripts/firecrawl-scrape.sh https://example.com`

7. **Generate Custom Configuration**
   - If `.opencode/vault-config.json` exists from a claudesidian migration, read
     it and pre-populate all setup questions with the user's existing preferences.
     Ask user to confirm or modify each value rather than asking from scratch.
   - Get current date: `date +"%B %d, %Y"` for the AGENTS.md header
   - Save preferences to `.opencode/vault-config.json`:
     ```json
     {
       "user": {
         "name": "Jane Smith",
         "background": {
           "companies": ["Variance", "Percolate"],
           "roles": ["Co-founder", "Writer"],
           "publications": ["Why Is This Interesting?", "every.to"],
           "expertise": [
             "Developer tools",
             "Marketing tech",
             "Systems thinking"
           ],
           "interests": ["AI for thinking", "Note-taking systems", "Creativity"]
         },
         "profileSources": [
           "https://whyisthisinteresting.com/about",
           "https://every.to/@username"
         ],
         "customContext": "Focuses on AI as thinking augmentation, not just writing",
         "publicProfile": true
       },
       "vaultPath": "/path/to/existing/vault",
       "fileNamingPattern": "detected-pattern",
       "organizationMethod": "PARA",
       "primaryUses": ["research", "writing", "projects"],
       "tools": {
         "geminiVision": true,
         "firecrawl": false
       },
       "projects": ["Book - Productivity", "SaaS App"],
       "areas": ["Newsletter", "Health"],
       "importedAt": "2025-01-13",
       "lastUpdated": "2025-01-13"
     }
     ```
   - Start with AGENTS-BOOTSTRAP.md as base
   - Add user-specific sections:
     - Custom folder structure with their actual projects/areas
     - Personal workflows
     - Preferred tools and scripts
     - Specific guidelines
     - MCP configuration if set up
   - Include their websites/resources if provided
   - Add any custom naming conventions
   - Pre-populate with their projects and areas:
     - Create project folders in 01_Projects/
     - Create area folders in 02_Areas/
     - Create resource topics in 03_Resources/
     - Add README files explaining each project/area

8. **Import Existing Vault (if applicable)**
   - If claudesidian migration was performed in Step 2, skip this step entirely —
     content is already in place.
   - If user has existing vault:
     - Create OLD_VAULT folder: `mkdir OLD_VAULT`
     - Copy entire vault preserving structure:
       `cp -r [vault-path]/* ./OLD_VAULT/`
     - Copy Obsidian configuration: `cp -r [vault-path]/.obsidian ./`
     - Check for and copy other important files:
       - `.trash/` (Obsidian's trash folder)
       - `.smart-connections/` (if using that plugin)
       - Any workspace files: `.obsidian.vimrc`, etc.
     - Skip copying: `.git/` (they'll have their own), `.opencode/` (using ours)
     - Show summary: "Imported your vault to OLD_VAULT/ (X files, Y folders)"
     - Explain: "Your original structure is preserved in OLD_VAULT. You can
       gradually migrate files to the PARA folders as needed."

9. **Create Supporting Files**
   - Generate initial folder structure if new vault
   - Create README files for main folders
   - For each project folder, create subfolders:
     - Research/ (source materials)
     - Chats/ (AI conversations)
     - Daily Progress/ (running log)
   - Create 05_Attachments/Organized/ directory
   - Set up .gitignore if using git (include .mcp.json, node_modules)
   - Create initial templates if requested
   - Create WEEKLY_REVIEW.md if user wants review ritual
   - Remove FIRST_RUN marker file if it exists
   - Make initial git commit if repository was initialized

10. **Run Test Commands**
   - Execute `pnpm vault:stats` to verify scripts work
   - Test attachment commands if folders exist
   - Test MCP tools if configured
   - Verify git is tracking files correctly

11. **Provide Next Steps**

    - Summary of what was created and configured
    - Quick start guide specific to their setup
    - List of available commands they can use
    - Test commands to verify everything works
    - Suggestions for first tasks based on their use cases
    - How to modify configuration later

## Example Output

```markdown
# Your Obsidian Vault Configuration

Generated on: [Run `date +"%B %d, %Y"` to get current date] Last updated: [Same
date] Based on your preferences for: [main use cases] Setup completed with: ✅
Dependencies ✅ Folder structure ✅ Git initialized

## Your Custom Folder Structure

[Their specific structure with explanations]

## Your Workflows

### Daily Routine

[Based on their answers]

### Project Management

[Their specific approach]

### Research Method (Noah Brier Style)

- Capture everything you read
- Let important ideas naturally resurface
- Start with writing to test understanding
- Use search, not tags, to find things
- [Learn more from Noah's system](https://every.to/superorganizers/ceo-by-day-internet-sleuth-by-night-267452)

### Weekly Review Ritual

[If enabled: Every Thursday at 4pm, review all projects]

## Your Preferences

### File Naming

- Pattern: [their convention]
- Examples: [specific examples]

### Tools & Scripts

[Relevant scripts for their workflow]

## MCP Servers (if configured)

### Gemini Vision

- Status: ✅ Configured and tested
- API Key: Set in .mcp.json
- Test with: `Use gemini-vision to analyze [image path]`

## Available Commands

### Vault Management

- `pnpm vault:stats` - Show vault statistics
- `pnpm attachments:list` - List unprocessed attachments
- `pnpm attachments:organized` - Count organized files

### Opencode Commands

- `/thinking-partner` - Collaborative thinking mode
- `/daily-review` - Review your day
- `/init-bootstrap` - Re-run this setup

## Quick Start

1. [Personalized first step]
2. [Next action based on their goals]
3. [Specific to their workflow]

## Pro Tips from Research Masters

- **Be a token maximalist**: Provide lots of context to opencode
- **Writing scales**: Document everything for future reference
  ([Noah Brier](https://every.to/superorganizers/ceo-by-day-internet-sleuth-by-night-267452))
- **Trust emergence**: Important ideas will keep surfacing
- **Start with writing**: Always begin projects in text form
- **Review regularly**: Set aside time weekly to prune and update
- **PARA Method**: Projects, Areas, Resources, Archive
  ([Tiago Forte](https://fortelabs.com/blog/para/))

## Setup Summary

✅ Dependencies installed (pnpm/npm) ✅ Folder structure created ✅ Git
repository initialized and disconnected from original ✅ AGENTS.md personalized
✅ First-run setup completed [✅ MCP Gemini Vision configured - if set up] [✅
First commit made - if git was initialized]
```

## Important Implementation Notes

### Handling Multiple Vaults

When multiple vaults are detected:

1. **Always list all vaults found** with clear numbering and details
2. **Require explicit selection** - don't assume which vault to use
3. **Confirm the selection** before proceeding with import
4. **Handle ambiguous responses** - if user provides unclear input (like pasting
   a screenshot), ask for clarification:
   - "I see you've shared a screenshot. Could you please type the number (1-3)
     of the vault you'd like to import?"
   - "I need a clear selection. Please type '1', '2', or '3' to choose a vault,
     or 'skip' to start fresh."

### Never Proceed Without Clear Confirmation

If the user's response is unclear:

- Don't guess or assume
- Ask for explicit confirmation
- Provide clear options again
- Example: "I want to make sure I import the right vault. Please type the number
  of your choice (1, 2, or 3)."

### Platform Compatibility

This command is designed to work across Linux, macOS, and Windows (WSL/Git
Bash), with platform-specific features:

**All Platforms:**

- Search ~/Documents, ~/Desktop, home directory
- Standard Obsidian vault detection
- Full vault import and setup

**macOS Only:**

- iCloud Drive vault detection and import
- Obsidian's iCloud sync is macOS-only, so iCloud features are disabled on other
  platforms

**Platform Detection:**

```bash
# Check platform
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS - enable iCloud features
  PLATFORM="macOS"
  ICLOUD_SUPPORTED=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux
  PLATFORM="Linux"
  ICLOUD_SUPPORTED=false
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  # Windows (Git Bash or WSL)
  PLATFORM="Windows"
  ICLOUD_SUPPORTED=false
fi
```

### iCloud Vault Search Implementation

When searching for vaults, use this find command pattern:

```bash
# Standard locations (shallow search)
# Note: 2>/dev/null suppresses expected permission errors from system directories
# If no vaults are found, we'll ask the user for their vault path
find ~/Documents ~/Desktop -maxdepth 3 -type d -name ".obsidian" 2>/dev/null

# iCloud location (deeper search needed due to nested structure)
# Only search on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  find ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents -maxdepth 5 -type d -name ".obsidian" 2>/dev/null
fi

# Home directory (shallow to avoid deep recursion)
find ~ -maxdepth 2 -type d -name ".obsidian" 2>/dev/null
```

The iCloud path requires:

- Higher maxdepth (5) due to nested folder structure
- Escaped spaces in path name
- Silent error handling (2>/dev/null) as many users won't have iCloud
- Platform check (macOS only)

**Error Handling Note:** Permission errors are suppressed (2>/dev/null) because
they're expected when searching system directories. If no vaults are found, the
script gracefully prompts the user for their vault path.

### User Path Validation

When users manually provide a vault path, validate it thoroughly with helpful
error messages:

```bash
# User provided path
USER_PATH="$1"

# Expand tilde and resolve to absolute path
USER_PATH="${USER_PATH/#\~/$HOME}"
REAL_PATH=$(realpath "$USER_PATH" 2>/dev/null)

# Validation 1: Path exists
if [ -z "$REAL_PATH" ]; then
  echo "❌ Error: Path does not exist: $USER_PATH"
  echo ""
  echo "💡 Suggestions:"
  echo "   • Check for typos in the path"
  echo "   • Make sure you're using the full path (e.g., /Users/name/vault)"
  echo "   • You can use ~ for your home directory (e.g., ~/Documents/vault)"
  exit 1
fi

# Validation 2: Is a directory
if [ ! -d "$REAL_PATH" ]; then
  echo "❌ Error: Not a directory: $REAL_PATH"
  echo ""
  echo "💡 The path exists but points to a file, not a folder."
  exit 1
fi

# Validation 3: Contains .obsidian folder
if [ ! -d "$REAL_PATH/.obsidian" ]; then
  echo "❌ Error: Not a valid Obsidian vault (no .obsidian folder)"
  echo "   Looking in: $REAL_PATH"
  echo ""
  echo "💡 Suggestions:"
  echo "   • Make sure the path points to your vault root (not a subfolder)"
  echo "   • Check that you've opened this vault in Obsidian at least once"
  echo "   • Try the path without trailing slash"
  echo "   • For iCloud: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/YourVault"
  exit 1
fi

# Validation 4: Readable permissions
if [ ! -r "$REAL_PATH/.obsidian" ]; then
  echo "❌ Error: Cannot read vault directory (permission denied)"
  echo "   Path: $REAL_PATH"
  echo ""
  echo "💡 You may need to:"
  echo "   • Check file permissions with: ls -la \"$REAL_PATH\""
  echo "   • Make sure you own this directory"
  exit 1
fi

# Show resolved path if different from input
if [ "$USER_PATH" != "$REAL_PATH" ]; then
  echo "✓ Resolved path: $REAL_PATH"
fi

# Valid vault path
VAULT_PATH="$REAL_PATH"
echo "✓ Valid Obsidian vault found"
```

This validation:

- Expands `~` to home directory properly
- Resolves symlinks and relative paths to absolute paths
- Checks all essential requirements (exists, is directory, has .obsidian,
  readable)
- Provides helpful, actionable error messages with suggestions
- Shows the resolved path so users understand what's being checked
- Trusts users (allows symlinks, paths outside home directory)
- Cross-platform compatible (works on Linux, macOS, Windows/WSL)

### iCloud Sync State Checking

When a user selects an iCloud vault, check sync state and warn if needed:

```bash
# After user confirms vault selection
if [[ "$OSTYPE" == "darwin"* ]] && [[ "$vault_path" == *"iCloud"* ]]; then
  # Check for common iCloud sync indicators
  if [ -f "$vault_path/.icloud" ] || [ -f "$vault_path/.obsidian/.icloud" ]; then
    echo ""
    echo "📱 iCloud Sync Notice:"
    echo "   This vault appears to be still downloading from iCloud."
    echo "   For best results, open it in Obsidian first to ensure files are synced."
    echo ""
    read -p "Continue anyway? (yes/no): " sync_answer
    if [[ ! "$sync_answer" =~ ^[Yy] ]]; then
      echo "No problem! Open the vault in Obsidian, then re-run /init-bootstrap"
      exit 0
    fi
  else
    echo ""
    echo "📱 iCloud vault detected. If import seems incomplete, make sure sync is complete."
    echo ""
  fi
fi
```

This provides a soft warning that:

- Only runs on macOS for iCloud paths
- Checks for placeholder files that indicate incomplete download
- Asks for confirmation if sync issues detected
- Gives gentle reminder even when no issues found
- Lets users proceed if they choose

## Interactive Example

````
User: /init-bootstrap
Assistant: Welcome! I'll help you set up your personalized Obsidian + opencode configuration.

📅 Today's date: [Gets from `date +"%B %d, %Y"`]

First, let me check your setup...

📁 **Folder Name Check**
Current folder: opesidian
Would you like to rename this folder to something more personal? (e.g., my-vault, knowledge-base, obsidian-notes)
*Why: Your vault should have a name that makes sense to you - you'll see it every day!*

[If yes: Handles the rename by moving to parent directory and back]

Now setting up your environment...

📦 **Installing Dependencies**
[Checks for pnpm, uses npm if not available]
[Installs dependencies with pnpm/npm]
*Why: These tools enable opencode to work with your vault effectively*

🔓 **Repository Setup**

**Will you be contributing to opesidian development?**
- **No** (Personal vault only) → I'll remove GitHub workflows and disconnect from the repo
- **Yes** (I want to contribute) → I'll keep the development setup intact

[Implementation:]
```bash
# If user says "No" (personal vault):
rm -rf .github  # Remove GitHub workflows
git remote remove origin  # Disconnect from opesidian repo

# If user says "Yes" (contributing):
# Keep .github folder and origin remote
echo "Development setup preserved for contributing"
````

_Why: Personal vaults don't need GitHub Actions, but contributors benefit from
the automation_

📂 **Creating Folder Structure** [Creates folders based on your chosen
organization method] _Why: A good structure helps you organize and find your
knowledge effectively_

🎯 **Finalizing Setup** [Checks git status and removes first-run marker] _Why:
Git gives you version control, and removing the marker ensures you won't see the
welcome message again_

✅ Folder renamed (if requested) ✅ Dependencies installed ✅ Core folders
created ✅ Git repository ready (disconnected from original opesidian) ✅
First-run marker removed

Now let me ask you a few questions to customize your setup:

🔍 **Searching for existing Obsidian vaults...** [Searches ~/Documents,
~/Desktop, home directory, and parent directories. On macOS, also searches
iCloud Drive]

### Case 1: Single Vault Found

Found Obsidian vault at: ~/Documents/MyNotes 📊 Vault stats: 2,517 markdown
files, 1.1GB total size Would you like to import this vault?

- **yes** - Import this vault
- **no** - Search for a different vault
- **skip** - Start fresh without importing
- **path** - Specify a different path manually

User: yes

### Case 2: Multiple Vaults Found

🔍 **Found multiple Obsidian vaults:**

1. **~/Documents/MyNotes** (2,517 files, 1.1GB)
   - Last modified: 2 hours ago
   - Contains: Daily notes, projects, resources

2. **~/Desktop/WorkVault** (892 files, 450MB)
   - Last modified: 3 days ago
   - Contains: Client projects, meeting notes

3. **~/Documents/ObsidianVault** (156 files, 23MB)
   - Last modified: 2 weeks ago
   - Contains: Personal notes, drafts

**Which vault would you like to import?**

- Enter **1-3** to select a vault
- **all** - Import all vaults (each to a separate folder)
- **skip** - Start fresh without importing
- **path** - Specify a different path manually

User: 1

**Confirming your selection:** You selected: ~/Documents/MyNotes (2,517 files,
1.1GB)

Is this correct? (yes/no)

User: yes

Great! I'll import your vault to OLD_VAULT/ where it will be safely preserved.
You can migrate files to the PARA folders at your own pace.

### Case 3: No Vaults Found (Platform-Aware)

🔍 **No Obsidian vaults found in common locations.**

**On macOS:** Is your vault stored in iCloud Drive? (yes/no)

User: yes

Please enter the full path to your vault: (Example: ~/Library/Mobile
Documents/iCloud~md~obsidian/Documents/YourVault)

User: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MyVault

[Validates path and shows vault stats]

Found vault at: ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MyVault
📊 Vault stats: 1,248 markdown files, 523MB total size

Would you like to import this vault? (yes/skip)

**On Linux/Windows:** Please enter the path to your existing Obsidian vault, or
type 'skip' to start fresh: (Example: ~/Documents/MyVault or
/home/user/obsidian-vault)

User: ~/Documents/MyVault

[Validates path and shows vault stats]

Found vault at: ~/Documents/MyVault 📊 Vault stats: 1,248 markdown files, 523MB
total size

Would you like to import this vault? (yes/skip)

📦 **Analyzing your vault structure...** [Running tree to see folder hierarchy]
[Sampling notes to understand content] [Detecting naming patterns from recent
files]

I can see you're using:

- A modified PARA structure with custom folders
- Date-prefixed files for daily notes (YYYY-MM-DD)
- Project folders with nested research
- Heavy use of the Resources folder for reference material

📦 **Importing your vault...** [Copying files to OLD_VAULT/] [Preserving
.obsidian settings] [Checking for plugin folders]

✅ Imported 2,517 files (1.1GB) to OLD_VAULT/ Your original structure is
completely preserved!

Now let's personalize your setup:

1. **What's your name?**

   _Why I'm asking:_ I'll use this to personalize your AGENTS.md file and help
   me understand your context better. This creates a more tailored experience
   where I can reference your work and interests naturally.

User: Noah Brier

2. **Would you like me to research your public work?**

   _Why this helps:_ By understanding your background, expertise, and interests,
   I can:
   - Tailor suggestions to your specific field and workflow
   - Reference relevant examples from your domain
   - Better understand the context of your questions
   - Build a profile that helps me be a more effective thinking partner

User: Yes

Great! To make sure I find information about the real you, could you provide any
of these details?

- Your company or organization
- Your location (city/country)
- A unique project you've worked on
- Your website or social media handle
- Any other distinguishing information

This helps me avoid confusion with others who share your name.

User: I co-founded Variance and Percolate, I write at every.to

Perfect! Let me search for you with those details...

[Searches for information using the provided identifying information]

Based on your details, I found you - Noah Brier, co-founder of Variance and
Percolate, writer at every.to.

Let me confirm this is correct:

- Co-founded Variance (developer tools) and Percolate (marketing software)
- Write at every.to and Why Is This Interesting? newsletter
- Focus on systems thinking, creativity, and technology

Is this you? (yes/no)

User: yes

Excellent! I've identified the right profile.

**Building Your Profile** Would you like me to read any specific pages to better
understand your work?

- Your personal website or blog
- Recent articles or papers you've written
- Company/project pages
- LinkedIn or other profiles

Enter URLs (comma-separated) or 'skip' to continue:

User: https://whyisthisinteresting.com/about, https://every.to/@noahbrier

[Fetches and analyzes the provided URLs]

I've built a comprehensive profile:

- You co-founded Variance (developer tools) and Percolate (marketing software)
- You write Why Is This Interesting? newsletter with Colin Nagy
- You explore creativity, technology, and systems thinking
- You've written about writing as thinking, note-taking systems, and AI

Is there anything else I should know about your work or interests?

User: I'm really interested in how AI can augment thinking, not just writing

Got it! I'll remember that you focus on AI as a thinking tool, not just a
writing assistant.

3. **What will you primarily use this vault for?** (research, writing, project
   management, daily notes, knowledge base, or combination?)

User: I'll use it for research and writing, plus managing client projects