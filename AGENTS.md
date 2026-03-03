# Agent Instructions — CipherOwl Password Manager

## Project Overview
CipherOwl is a military-grade password manager graduation project. Flutter/Dart UI + Rust crypto core + Supabase cloud backend. Features: Face-Track continuous biometric, TOTP 2FA, security gamification, zero-knowledge sync.

**Tech Stack**: Flutter 3.x, Rust (FFI via flutter_rust_bridge), Drift+SQLCipher, Supabase, BLoC, Google ML Kit, MobileFaceNet TFLite  
**Languages**: Arabic (primary) + English

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work atomically
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.

Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.

**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file

# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```

**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

<!-- BEGIN BEADS INTEGRATION -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update <id> --claim --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task atomically**: `bd update <id> --claim`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs with git:

- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `git pull`)
- No manual export/import needed!

## Architecture Rules
1. **ALL cryptography in Rust** — never implement crypto in Dart
2. **Zero-knowledge** — encrypt client-side before Supabase upload
3. **BLoC pattern strictly** — no state management in widgets
4. **Arabic-first** — all UI strings need Arabic translations
5. **Secure memory** — use mlock/zeroize for sensitive data in Rust

## File Structure
```
lib/
  main.dart, app.dart
  core/constants/ theme/ router/
  features/auth/ vault/ generator/ settings/ security/ academy/ onboarding/
  shared/widgets/
native/smartvault_core/        # Rust crate (to be created)
```

## Task Structure — 16 EPICs, 80 Tasks
| # | EPIC | Priority | Independent? |
|---|------|----------|-------------|
| 1 | Project Foundation & Build System | P0 | Start here |
| 2 | Rust Cryptography Core | P0 | After EPIC-1 |
| 3 | Local Database (Drift+SQLCipher) | P0 | After EPIC-2 |
| 4 | State Management BLoC Layer | P0 | After EPIC-3 |
| 5 | Supabase Cloud Backend | P1 | After EPIC-1 (parallel with 2) |
| 6 | Face-Track Biometric | P1 | After EPIC-4 |
| 7 | FIDO2/WebAuthn Auth | P2 | After EPIC-4 |
| 8 | TOTP 2FA System | P1 | After EPIC-2 |
| 9 | Animations (Rive/Lottie) | P2 | After EPIC-4 |
| 10 | Security Center & Dark Web | P1 | After EPIC-4 |
| 11 | Autofill Service | P1 | After EPIC-4 |
| 12 | Encrypted Sharing & Enterprise | P2 | After EPIC-2+5 |
| 13 | Firebase & Push Notifications | P2 | After EPIC-1 |
| 14 | Security Academy & Gamification | P2 | Content anytime |
| 15 | Testing & QA | P1 | After EPIC-4 |
| 16 | Deployment & Release | P1 | After EPIC-15 |

## Critical Path
```
EPIC-1 → EPIC-2 → EPIC-3 → EPIC-4 → EPIC-15 → EPIC-16
       → EPIC-5 ↗ (parallel)
```

## Concurrent Work
- EPICs are independent work units — multiple team members can work on different EPICs
- Within an EPIC, follow dependency chain (check `bd ready`)
- EPIC-14 (academy content) has zero code dependencies
- After EPIC-1, teams can split: Rust crypto (EPIC-2) + Supabase (EPIC-5) in parallel

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- END BEADS INTEGRATION -->
