---
description: Intelligently upgrade opesidian with new features while preserving user customizations using AI-powered semantic analysis
---

# Smart Upgrade Command

Intelligently upgrades your opesidian installation by fetching the latest
release from GitHub and using AI-powered semantic analysis to merge new features
with your existing customizations. Preserves user intent while adding new
capabilities.

## Task

1. Check GitHub for the latest opesidian release
2. Download and analyze what has changed since your version
3. Use semantic understanding to identify user customizations
4. Intelligently merge new features with existing customizations
5. Safely apply updates while preserving user data and preferences
6. Create backups and provide rollback options

## Process

### 1. **Version Check & Setup**

- Get current version from package.json
- Check if already on latest version:

  ```bash
  # Detect repo URL dynamically from git remote
  REPO_URL=$(git remote get-url origin 2>/dev/null || echo "https://github.com/trevorrecker/opesidian.git")
  REPO=$(echo "$REPO_URL" | sed -E 's|.*github\.com[:/](.+)(\.git)?$|\1|' | sed 's/\.git$//')

  # Use cut instead of sed to avoid zsh parentheses escaping issues
  CURRENT=$(grep '"version"' package.json | head -1 | cut -d'"' -f4)
  LATEST=$(curl -s "https://raw.githubusercontent.com/$REPO/main/package.json" | grep '"version"' | head -1 | cut -d'"' -f4)

  if [ "$CURRENT" = "$LATEST" ]; then
    echo "You're already on the latest version ($CURRENT)"
    exit 0
  fi
  ```

- Create timestamped backup in `.backup/upgrade-YYYY-MM-DD-HHMMSS/`:

  ```bash
  # Create backup directory
  BACKUP_DIR=".backup/upgrade-$(date +%Y-%m-%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"

  # Copy all important files to backup
  cp -r .opencode "$BACKUP_DIR/"
  cp -r .scripts "$BACKUP_DIR/"
  cp package.json "$BACKUP_DIR/"
  cp CHANGELOG.md "$BACKUP_DIR/" 2>/dev/null || true
  cp README.md "$BACKUP_DIR/" 2>/dev/null || true

  echo "Backup created in $BACKUP_DIR"
  ```

- Clone latest opesidian to temp directory (doesn't affect user's repo):
  ```bash
  # Detect repo URL dynamically from git remote
  REPO_URL=$(git remote get-url origin 2>/dev/null || echo "https://github.com/trevorrecker/opesidian.git")
  REPO=$(echo "$REPO_URL" | sed -E 's|.*github\.com[:/](.+)(\.git)?$|\1|' | sed 's/\.git$//')

  # Get fresh copy in .tmp dir (hidden from Obsidian) - user's repo stays disconnected
  git clone --depth=1 --branch=main "https://github.com/$REPO.git" .tmp/opesidian-upgrade
  ```
- Now we have latest version to compare against

### 2. **Create Upgrade Checklist**

- Compare system files between current directory and .tmp/opesidian-upgrade/:

  ```bash
  # Find all system files that differ AND new files in upstream
  # First, find files that exist in both but differ
  diff -qr . .tmp/opesidian-upgrade/ --include="*.md" --include="*.sh" --include="*.json" |
  grep -E '(\.opencode/|\.scripts/|package\.json|CHANGELOG\.md|README\.md)' |
  grep -v '(00_|01_|02_|03_|04_|05_|06_|\.obsidian|AGENTS\.md)'

  # Also find NEW files in upstream (like new commands)
  find .tmp/opesidian-upgrade/.opencode/commands -name "*.md" | while read f; do
    local_file=${f#.tmp/opesidian-upgrade/}
    [ ! -f "$local_file" ] && echo "NEW: $local_file"
  done
  ```

- Create checklist of files that need review
- Explicitly EXCLUDE:
  - User content folders (00_Inbox, 01_Projects, etc.)
  - User's AGENTS.md (their personalized version)
  - vault-config.json (user's vault configuration)
  - .obsidian/ (user's Obsidian settings)
  - Any .md files in the root except README and CHANGELOG
- Create `.upgrade-checklist.md` with only system files that differ
- Mark each file with status: `[ ] pending`, `[x] updated`, `[-] skipped`
- Group files by type for easier review:

  ```markdown
  ## Commands (12 files)

  [ ] .opencode/commands/init-bootstrap.md [ ] .opencode/commands/release.md [ ]
  .opencode/commands/thinking-partner.md ...

  ## Settings (2 files)

  [ ] .claude/settings.json (Claude Code specific)
  [ ] .claude/settings.local.json (Claude Code specific)

  ## Core Files (3 files)

  [ ] package.json [ ] CHANGELOG.md [ ] README.md
  ```

### 3. **File-by-File Review**

**CRITICAL IMPLEMENTATION REQUIREMENT:**

- **NEVER blindly overwrite files without showing diffs first**
- **ALWAYS show diffs to the user first**
- **ALWAYS ask for confirmation before replacing files**
- **Skipping these steps can lose user customizations!**
- **NEVER use `cp` or `cp -f` (both can cause prompts on protected files)**
- **ALWAYS USE `cat source > dest` for guaranteed non-interactive replacement**
- **WAIT for actual user input - don't automatically choose option 1**

For EACH file in the checklist:

1.  Read current checklist status from `.upgrade-checklist.md`
2.  **MANDATORY: Show the diff between local and upstream**:
    ```bash
    # ALWAYS show this to the user!
    diff -u current/file .tmp/opesidian-upgrade/file
    ```
3.  Determine update strategy:
    - **No local changes**: Direct replace from upstream
    - **Never update**: User's AGENTS.md, vault-config.json, .mcp.json
    - **Local changes detected**: Ask user:

      ```
      File: .opencode/commands/thinking-partner.md has local modifications

      Options:
      1. Keep your version (skip update)
      2. Take upstream version (lose your changes)
      3. View diff and decide
      4. Try to merge both (AI-assisted)

      Choice (1/2/3/4): [WAIT FOR USER TO TYPE NUMBER AND PRESS ENTER]
      ```

      **IMPORTANT**: Actually WAIT for the user to type their choice! Do NOT
      automatically select any option. The user must manually type 1, 2, 3, or 4
      and press Enter.

4.  Apply the chosen strategy:
    - **For option 1 (Apply update/Take upstream)**:
      ```bash
      # IMPORTANT: Check if file exists first, then use cat with redirection
      if [ -f ".tmp/opesidian-upgrade/path/to/file" ]; then
        cat .tmp/opesidian-upgrade/path/to/file > path/to/file && echo "Updated"
      else
        echo "File not found in upstream - keeping local version"
      fi
      ```
    - **For option 2 (Keep your version)**:
      ```bash
      echo "Kept your version"
      ```
    - **For option 4 (AI merge)**: Read both files and create merged version
5.  **CRITICAL: Update the checklist file immediately**:
    ```markdown
    [ ] .opencode/commands/init-bootstrap.md -> becomes -> [x]
    .opencode/commands/init-bootstrap.md
    ```
6.  Save `.upgrade-checklist.md` after EVERY file update
7.  Move to next file

### 4. **Update Types**

- **Safe to replace**: `.opencode/commands/*.md`, `.agents/*.md`,
  `.scripts/*`
- **Needs review**: `package.json` (preserve user's custom scripts)
- **Never touch**: User content folders, AGENTS.md, API configs

#### Batch Updates for Similar Files

For commands that have only formatting changes, you can batch update:

```bash
# Batch update multiple command files with same type of changes
for file in thinking-partner.md daily-review.md inbox-processor.md; do
  if [ -f ".tmp/opesidian-upgrade/.opencode/commands/$file" ]; then
    cat ".tmp/opesidian-upgrade/.opencode/commands/$file" > ".opencode/commands/$file"
    echo "Updated $file"
  fi
done
```

#### Handling Missing Upstream Files

Some files may exist locally but not in upstream (like deprecated agents):

```bash
# Check if file exists in upstream before trying to update
if [ ! -f ".tmp/opesidian-upgrade/$filepath" ]; then
  echo "$filepath not in upstream - keeping local version"
  # Mark as skipped in checklist: [-]
fi
```

### 5. **Progress Tracking**

- Track progress alongside the checklist
- Save progress after each file in `.upgrade-checklist.md`
- **MUST mark items in checklist**:
  - `[x]` = completed
  - `[-]` = skipped (user customization)
  - `[ ]` = still pending
- If interrupted, can resume from where you left off
- Show progress: "Updating file 5 of 23..."
- Clear indication of what's been done and what's remaining

### 6. **Verification Check**

- Re-check all system files against the checklist
- Compare with checklist to identify:
  - Files marked `[ ]` pending = likely missed (problem)
  - Files marked `[-]` skipped = intentionally kept different (fine)
  - Files marked `[x]` updated but still in diff = merge issues or user edits
    (review)
- Show verification results:
  ```
  All required files updated successfully
  2 files intentionally kept with user customizations:
  - .opencode/commands/thinking-partner.md (user's concise style)
  - package.json (user's custom scripts preserved)
  - or -
  Warning: 2 files appear to be missed (still marked pending):
  - .opencode/commands/release.md
  - .scripts/vault-stats.sh
  ```
- Only flag as problem if files are still marked `[ ]` pending in checklist

### 7. **Final Steps**

- Update version in package.json
- Verify all commands work
- Clean up temp directory: `rm -rf .tmp/opesidian-upgrade`
- Save final checklist for reference (shows what was updated vs skipped)
- Show summary of what was updated

## Update Categories

### AI-Powered Intelligent Merge

**Commands** (`.opencode/commands/*.md`):

- Analyze user's prompt style, output preferences, workflow modifications
- Merge new features with existing customizations
- Preserve user's tone, structure, and specific requirements

**Agents** (`.agents/*.md`):

- Understand user's interaction preferences
- Combine new capabilities with existing personality
- Maintain user's established workflows

**Templates** (`06_Metadata/Templates/*.md`):

- Preserve custom fields and structure
- Add new template features
- Maintain user's formatting preferences

### Automatic Safe Updates

- **New commands/agents**: Purely additive, no conflicts
- **Scripts** (`.scripts/*`): Utility functions, safe to replace
- **Dependencies** (`package.json`): Security and feature updates
- **Documentation**: README, CONTRIBUTING updates

### Never Modified

- **User content**: All `00_*` through `06_*` folders (except templates)
- **Personal config**: User's `AGENTS.md`
- **API keys**: `.mcp.json`, environment variables
- **Git history**: User's commits and branches

## Smart Conflict Resolution

When conflicts are detected:

### Example Scenarios:

**Scenario 1: Command Enhancement**

```
thinking-partner command has updates:

YOUR VERSION: Custom concise output format, specific industry focus
NEW VERSION: Added video analysis capability, improved questioning flow

SMART MERGE PROPOSAL:
- Keep your concise output style
- Keep your industry-specific prompts
- Add new video analysis features
- Integrate improved questioning (adapted to your style)

Options:
1. Apply smart merge (recommended)
2. Show detailed diff first
3. Skip this update
4. Replace with new version (backup yours)
```

**Scenario 2: Template Updates**

```
Project Template has changes:

YOUR VERSION: Added custom fields for client info, budget tracking
NEW VERSION: Enhanced metadata structure, new automation hooks

SMART MERGE PROPOSAL:
- Preserve your custom client/budget fields
- Add new metadata enhancements
- Integrate automation hooks
- Maintain your field ordering

Apply merge? (y/n/preview)
```

## Command Usage

### Preview Mode (Recommended First Run)

```
/upgrade check
```

- Shows what would be updated
- Displays intelligent merge previews
- No changes made to files
- Safe to run anytime

### Interactive Upgrade

```
/upgrade
```

- Step-by-step confirmation for each change
- Shows before/after for modified files
- Allows selective application of updates
- Creates automatic backups

### Batch Upgrade (Advanced)

```
/upgrade force
```

- Applies all safe updates automatically
- Still prompts for complex merges
- Faster for users comfortable with the process
- Full backup created before starting

## Safety Features

### Automatic Backups

- Complete backup before any changes: `.backup/upgrade-[timestamp]/`
- Individual file backups for each modification
- Backup includes current git state and uncommitted changes

### Rollback Support

```
# If upgrade causes issues:
/rollback-upgrade [timestamp]
# Restores from specific backup
```

### Verification Steps

- Post-upgrade functionality testing
- Command validation (runs test commands)
- MCP server connectivity check
- Git repository integrity verification

### Incremental Application

- Updates applied one file at a time
- Validation after each critical change
- Stops on first error with clear diagnostics
- Easy to identify which change caused issues

## Common Pitfalls to Avoid

### Selective Updates Problem

**Never cherry-pick files based only on release notes!** This leads to:

- Missing critical command updates
- Incomplete feature implementations
- Broken dependencies between files
- Users not getting all improvements

**Always use `git diff HEAD upstream/main --name-only`** to get the complete
list of changed files, then update ALL relevant files systematically.

## Error Handling

### Common Scenarios

- **No internet connection**: Graceful failure with offline options
- **GitHub API rate limits**: Intelligent retry with backoff
- **Merge conflicts**: Clear explanation and manual resolution options
- **Permission issues**: Helpful guidance on fixing file permissions

### Recovery Options

- **Partial failure**: Continue from last successful step
- **Complete failure**: Full rollback to pre-upgrade state
- **Git conflicts**: Merge upstream changes with local commits
- **Dependency issues**: Fallback to previous working versions

## Advanced Features

### Custom Merge Rules

Users can create `.upgrade-rules.json` to specify:

- Files to always skip
- Custom merge preferences
- Automatic approval for specific change types
- Backup retention policies

### Integration with Git

- Commits each major change separately
- Meaningful commit messages describing updates
- Preserves user's branch structure
- Handles git conflicts intelligently

### Selective Updates

```
/upgrade commands-only    # Update just commands
/upgrade agents-only      # Update just agents
/upgrade scripts-only     # Update just scripts
/upgrade deps-only        # Update just dependencies
```

## CORRECT Implementation Example

**THIS is how the upgrade should work:**

```bash
File 1/3: .opencode/commands/release.md

# Step 1: ALWAYS show the diff first
Checking for differences...

--- .opencode/commands/release.md
+++ .tmp/opesidian-upgrade/.opencode/commands/release.md
@@ -58,6 +58,11 @@

 ### Semantic Versioning (MAJOR.MINOR.PATCH)

+**Quick Decision Guide:**
+- Can users do something they couldn't do before? -> **MINOR**
+- Did something that worked break? -> **MAJOR** (if breaking) or **PATCH** (if fixing)
+- Did something that worked get better? -> **PATCH**
+
 **MAJOR** (1.0.0 -> 2.0.0):

# Step 2: Ask user what to do
This file has updates available. What would you like to do?

1. Apply update (take upstream version)
2. Keep your version (skip this update)
3. View full diff again
4. Try to merge changes (AI-assisted)

Your choice (1-4): 1

Applying update...
[x] Updated .opencode/commands/release.md
```

**WRONG Implementation (what happened in the test):**

```bash
File 1/3: .opencode/commands/release.md

# NO DIFF SHOWN - WRONG!
# Just blindly overwrites:
Bash(cat .tmp/opesidian-upgrade/.opencode/commands/release.md > .opencode/commands/release.md)

# No user confirmation - WRONG!
# Could lose customizations!
```

## Example Session

```
> /upgrade

Checking for updates...
Current version: 0.8.2
Latest version: 0.8.3

Creating backup to .backup/upgrade-2025-09-13-142030/

Creating upgrade checklist...
Checking system files only (not your personal notes)...
Found 15 system files with updates available

Created .upgrade-checklist.md to track updates:

## Commands (8 files)
[ ] .opencode/commands/init-bootstrap.md
[ ] .opencode/commands/release.md
[ ] .opencode/commands/thinking-partner.md
[ ] .opencode/commands/upgrade.md
[ ] .opencode/commands/daily-review.md
[ ] .opencode/commands/inbox-processor.md
[ ] .opencode/commands/research-assistant.md
[ ] .opencode/commands/weekly-synthesis.md

## Settings (1 file)
[ ] .claude/settings.json (Claude Code specific)

## Core Files (3 files)
[ ] package.json
[ ] CHANGELOG.md
[ ] README.md

## Scripts (3 files)
[ ] .scripts/vault-stats.sh
[ ] .scripts/firecrawl-scrape.sh
[ ] .scripts/setup-mcp.sh

Starting file-by-file review...

File 1/15: .opencode/commands/init-bootstrap.md
   Status: No local changes detected
   Action: Direct update from upstream
   [x] Updated

File 2/15: .opencode/commands/release.md
   Status: No local changes detected
   Action: Direct update from upstream
   [x] Updated

File 3/15: .claude/settings.json (Claude Code specific)
   Status: Has local changes (your custom hooks)
   Showing diff...
   Action: Merge needed - preserving your hooks, adding new features
   [x] Merged

[... continues through all files ...]

**Verification Check**
Re-checking for any missed system files...

All system files successfully updated!
No opesidian system files remain out of sync with upstream.

Upgrade complete!
opesidian 0.8.2 -> 0.8.3

Updated: 14 files
Skipped: 1 file (AGENTS.md - user customization)
Verified: All system files match upstream

Summary of changes:
- Fixed init-bootstrap vault selection
- Improved SessionStart hooks
- Enhanced user identification prompts
- Updated all commands to latest versions
```

### Example: Verification Catches Missed Files

```
**Verification Check**
Re-checking for any missed system files...

Warning: 2 files appear to be missed (still marked pending in checklist):
- .opencode/commands/thinking-partner.md [ ]
- .scripts/vault-stats.sh [ ]

These files haven't been processed yet.

Would you like to complete the upgrade for these files? (y/n) > y

Completing upgrade for missed files...

File: .opencode/commands/thinking-partner.md
   Status: Reviewing diff...
   Action: Direct update from upstream
   [x] Updated

File: .scripts/vault-stats.sh
   Status: Reviewing diff...
   Action: Direct update from upstream
   [x] Updated

Verification complete - all system files now match upstream!
```

### Example: Verification with User Customizations

```
**Verification Check**
Re-checking for any missed system files...

Files still differing from upstream:
- .opencode/commands/thinking-partner.md [x] <- Updated but user customized
- package.json [x] <- Merged, kept user's custom scripts
- .opencode/commands/daily-review.md [ ] <- Not processed yet!

2 files intentionally preserve user customizations
1 file appears to be missed (still pending)

Would you like to:
1. Review the missed file (.opencode/commands/daily-review.md)
2. Skip verification (keep current state)
3. See details about customized files

Choice (1/2/3) > 1

File: .opencode/commands/daily-review.md
   Status: Reviewing diff...
   Action: Direct update from upstream
   [x] Updated

Verification complete!
- All required updates applied
- User customizations preserved where intended
```

This intelligent upgrade system leverages semantic understanding to
provide the smoothest possible upgrade experience while ensuring no user
customizations are lost.
