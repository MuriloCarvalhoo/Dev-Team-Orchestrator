---
name: task-reader
description: Reads a single board/{status}/{ID}.md task file and extracts all context the agent needs. First step for dev, QA, and tech-lead agents.
user-invocable: false
---

# Task Reader

Read the task file passed in your prompt (e.g., `board/todo/BACK-001.md`). This is your ONLY source of context.

## What to extract

1. **Frontmatter**: id, type, priority, assigned, depends_on
2. **Description**: what to implement
3. **Acceptance Criteria**: your checklist — validate each one before marking done
4. **Context**: stack, patterns, API contracts relevant to THIS task (injected by PO)
5. **Handoff**: if filled, resume from where the previous agent stopped — do NOT restart
6. **Log**: what was already done (useful for QA)

## What you do NOT read

- Other `board/` files — you only know about YOUR task
- `docs/DECISIONS.md` — relevant decisions are already in your Context section
- `docs/PROGRESS.md` — not needed for execution

## Exception

If you need to ADD a new technical decision (new API schema, new pattern), read `docs/DECISIONS.md` to find the last DEC-* ID and append your new decision at the end.

## Status from folder

The task's current status is determined by which folder it's in:
- `board/todo/` = TODO
- `board/in_progress/` = IN_PROGRESS
- `board/done/` = DONE
- `board/verified/` = VERIFIED
- `board/blocked/` = BLOCKED

## Gotchas

- If the task file doesn't exist at the given path: report the error, do not guess
- If Handoff section is filled: you MUST continue from the "next exact step", not restart
- Read acceptance criteria literally — QA will test exactly these
- If Context section is empty or missing stack info: report and do not implement
