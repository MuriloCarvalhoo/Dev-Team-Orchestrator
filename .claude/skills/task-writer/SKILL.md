---
name: task-writer
description: Updates a single board/{status}/{ID}.md task file and moves it between status folders. Last step for all agents.
user-invocable: false
---

# Task Writer

Update ONLY your task file and move it to the correct status folder. These are the only write operations you perform on shared state.

## State transitions = move file between folders

Use `git mv` to move the file. This is how status changes work:

**Starting a task (todo → in_progress):**
```bash
git mv board/todo/{ID}.md board/in_progress/{ID}.md
```
- Update frontmatter: `assigned: {your-agent}`, `updated: {today}`

**Completing a task (in_progress → done):**
```bash
git mv board/in_progress/{ID}.md board/done/{ID}.md
```
- Update frontmatter: `assigned: ""`, `updated: {today}`
- Clear `## Handoff` section
- Fill `## Log` section (see format below)
- Check off completed acceptance criteria checkboxes

**Blocking a task (in_progress → blocked):**
```bash
git mv board/in_progress/{ID}.md board/blocked/{ID}.md
```
- Update frontmatter: `updated: {today}`
- Fill `## Handoff` with specific blocking reason and context

**Interrupting a task (stays in in_progress):**
- Do NOT move the file
- Fill `## Handoff` with detailed state (see format below)

**QA approving (done → verified):**
```bash
git mv board/done/{ID}.md board/verified/{ID}.md
```
- Update frontmatter: `updated: {today}`
- Fill `## Test Results` with test outcomes and screenshot references

**QA rejecting — critical bug (done → todo):**
```bash
git mv board/done/{ID}.md board/todo/{ID}.md
```
- Update frontmatter: `updated: {today}`
- Create NEW file `board/todo/FIX-{TYPE}-{N}.md` with bug report

**QA rejecting — minor bug (done → verified, FIX created):**
```bash
git mv board/done/{ID}.md board/verified/{ID}.md
```
- Create NEW file `board/todo/FIX-{TYPE}-{N}.md` with bug report

**Unblocking (blocked → todo):**
```bash
git mv board/blocked/{ID}.md board/todo/{ID}.md
```
- Update frontmatter: `updated: {today}`
- Add tech-lead decision to `## Context`

## Log section format (on completion)

```markdown
## Log

**Completed by**: {agent-type}
**Date**: {today}
**What was done**:
- {concrete item 1}
- {concrete item 2}
**Files created/modified**:
- `path/file.ext` — {what it does}
**Tests written**:
- `tests/unit/file.test.ts` — {what it tests}
- `tests/integration/file.test.ts` — {what it tests}
**Notes**: {decisions, trade-offs, tech debt}
```

## Handoff section format (on interruption)

```markdown
## Handoff

**Agent**: {agent-type}
**State**: Interrupted

**Progress**:
- Done: {specific completed items}
- In progress: {what was being worked on}
- Not done: {remaining items}

**Important context**:
{decisions made, pitfalls found, approaches tried}

**Next exact step**:
{precise instruction — file path, line number, exact action}

**Relevant files**:
- `path/file.ext` — {relevance}
```

## Append to docs/PROGRESS.md

After any state transition, append ONE line to the top of `docs/PROGRESS.md`:

```
- {today} | {ID} | {old_folder} → {new_folder} | {agent-type} | {short description}
```

## Updating DECISIONS.md (if needed)

If you made a new technical decision during implementation:

```markdown
### DEC-{AGENT}-{N}: {title}
- **Date**: {today}
- **Context**: {why}
- **Decision**: {what — be specific, include versions}
- **Rationale**: {why this choice}
- **Rejected alternatives**: {what was rejected}
- **Decided by**: {agent-type}
```

## Gotchas

- NEVER edit another task's file (exception: QA creating FIX-* files)
- ALWAYS use `git mv` for moves — preserves git history
- After moving, confirm the file exists in the new folder and NOT in the old one
- Dev agents: you MUST have written unit + integration tests before moving to `done/`
- QA agents: you MUST have Playwright E2E results before moving to `verified/`
- If unsure about the next FIX-* ID, list `board/todo/FIX-*.md` files to find the next number
