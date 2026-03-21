---
name: skill-creator
description: Guide for creating effective skills and commands. Use when users want to create a new skill or command, when updating an existing one, or when asking "how do I make a skill" or "create a command for X".
compatibility: opencode
---

# Creating Skills and Commands

This skill provides guidance for creating effective skills and commands in
opencode projects.

## Skills vs Commands

| Aspect | Skills (`.agents/skills/`) | Commands (`.opencode/commands/`) |
|--------|---------------------------|-------------------------------|
| Trigger | Auto-triggered by context | Explicit `/command` invocation |
| Purpose | Background knowledge, domain expertise | Interactive workflows, multi-step tasks |
| Example | Obsidian markdown syntax reference | `/daily-review` workflow |
| Format | `SKILL.md` in named folder | `command-name.md` file |

## Core Principles

### Concise is Key

The context window is a public good. Skills share it with system prompts,
conversation history, and the user's actual request.

**Default assumption: The agent is already very smart.** Only add context it
doesn't already have. Challenge each piece: "Does the agent really need this?"

Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

Match specificity to the task's fragility:

**High freedom (text instructions)**: Multiple approaches valid, context-dependent

**Medium freedom (pseudocode/templates)**: Preferred pattern exists, some variation OK

**Low freedom (specific scripts)**: Operations fragile, consistency critical

## Skill Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description - required)
│   └── Markdown instructions
└── Optional resources
    ├── references/    # Documentation loaded as needed
    ├── scripts/       # Executable code
    └── assets/        # Templates, images, etc.
```

### SKILL.md Frontmatter

```yaml
---
name: skill-name
description:
  What this skill does and when to use it. This is the PRIMARY trigger -
  the agent reads this to decide when to load the skill. Include specific
  scenarios and keywords that should activate it.
compatibility: opencode
---
```

**Important**: The description is loaded into context ALWAYS. The body is only
loaded AFTER the skill triggers. Put "when to use" in the description, not the
body.

## Command Structure

Commands are simpler - single markdown files:

```
.opencode/commands/
├── daily-review.md
├── release.md
└── new-command.md
```

### Command Frontmatter

```yaml
---
description: 'Brief description shown in command list'
---
```

## Progressive Disclosure

Use layered loading to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<500 lines ideal)
3. **References** - As needed by the agent (unlimited)

### Pattern: Reference Files

Keep SKILL.md lean, link to detailed references:

```markdown
# Skill Name

## Quick Reference

Basic usage here.

## Detailed Guides

- **Complex Topic A**: See `references/topic-a.md`
- **Complex Topic B**: See `references/topic-b.md`
```

The agent reads reference files only when needed.

## Creating a New Skill

### Step 1: Understand the Use Case

Ask:
- "What functionality should this skill support?"
- "What would trigger someone to need this?"
- "What does the agent NOT already know that this should teach?"

### Step 2: Plan the Contents

Analyze concrete examples:
- What code/scripts get rewritten each time?
- What documentation would help?
- What assets (templates, examples) are needed?

### Step 3: Create the Skill

```bash
mkdir -p .agents/skills/my-skill
```

Write `SKILL.md`:

```yaml
---
name: my-skill
description:
  What it does. When to use it. Keywords that trigger it.
compatibility: opencode
---

# My Skill

## Overview

Brief explanation.

## Quick Reference

Essential information here.

## Advanced Topics

Link to references if complex.
```

### Step 4: Test and Iterate

1. Start a new session
2. Ask questions that should trigger the skill
3. Verify the agent uses the skill appropriately
4. Refine based on gaps

## Creating a New Command

### Step 1: Define the Workflow

Commands are for explicit multi-step workflows:
- What steps does this workflow include?
- What tools are needed?
- What output should the user see?

### Step 2: Create the Command

```bash
touch .opencode/commands/my-command.md
```

Write the command:

```yaml
---
description: 'Brief description of what this command does'
---

# My Command

## Instructions

1. First step
2. Second step
3. Verify result

## Handling Edge Cases

What to do when X happens.
```

### Step 3: Test

Run `/my-command` and verify the workflow executes correctly.

## Common Patterns

### Workflow with Verification

```markdown
## Workflow

1. Gather context
2. Perform action
3. **Verify result before claiming success**
4. Report outcome

## Verification

Always run `<command>` and check output before claiming complete.
```

### Reference Hub

```markdown
# API Reference Hub

| API | Purpose | Reference |
|-----|---------|-----------|
| API A | Feature X | `references/api-a.md` |
| API B | Feature Y | `references/api-b.md` |

## When to Use Each

Brief guidance on which reference to consult.
```

### Decision Matrix

```markdown
## Approach Selection

| Condition | Approach |
|-----------|----------|
| Simple case | Do X |
| Complex case | Do Y |
| Edge case | Ask user |
```

## What NOT to Include

- README.md, CHANGELOG.md (just clutter)
- Obvious information the agent already knows
- Overly detailed explanations (use examples instead)
- User-facing documentation (skills are for the agent)

## Skill vs Command Decision

**Use a Skill when:**
- Providing background knowledge
- Teaching domain expertise
- Reference material that applies across tasks

**Use a Command when:**
- Interactive workflow with user
- Multi-step process needing explicit invocation
- Specific task with defined start/end
