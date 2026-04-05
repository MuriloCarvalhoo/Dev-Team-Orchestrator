---
name: board-scanner
description: Scans frontmatter of all board/{status}/*.md files and returns a structured status index. Used by /dev-team-run and /dev-team-status.
user-invocable: false
---

# Board Scanner

Scan the `board/` directory to build a complete status index. Read ONLY frontmatter — do NOT read task body (description, criteria, log).

## How to scan

1. List all `.md` files in each subfolder:
   - `board/todo/`
   - `board/in_progress/`
   - `board/done/`
   - `board/verified/`
   - `board/blocked/`

2. For each file, read the YAML frontmatter (lines between `---` and `---`) and extract:
   - `id`
   - `type` (BACK, FRONT, DEVOPS)
   - `priority` (HIGH, MEDIUM, LOW)
   - `depends_on` (array of task IDs)
   - `assigned` (agent name or empty)

3. The file's parent folder IS the status. Do not look for a status field in frontmatter.

## Dependency resolution

A task in `todo/` is **ready** when ALL IDs in its `depends_on` array exist as files in `done/` or `verified/`.

To check: for each ID in `depends_on`, look for `board/done/{ID}.md` or `board/verified/{ID}.md`.

## Output format

Report a structured summary:

```
BOARD STATUS:
  todo:        {N} tasks ({M} ready)
  in_progress: {N} tasks
  done:        {N} tasks (awaiting QA)
  verified:    {N} tasks
  blocked:     {N} tasks
  TOTAL:       {N} tasks

READY TASKS (todo, deps satisfied):
  {ID} [{TYPE}] priority={PRIORITY} — depends: {deps or "none"}
  {ID} [{TYPE}] priority={PRIORITY} — depends: {deps or "none"}

IN PROGRESS:
  {ID} [{TYPE}] assigned={AGENT}

DONE (awaiting QA):
  {ID} [{TYPE}]

BLOCKED:
  {ID} [{TYPE}]
```

## Priority ordering for ready tasks

When listing ready tasks, order by:
1. BACK before FRONT (backend unblocks frontend)
2. Higher priority first (HIGH > MEDIUM > LOW)
3. Tasks with no dependencies first

## Gotchas

- If `board/` directory doesn't exist: report that `/dev-team-start` needs to run first
- If a subfolder is empty: that's normal, just report 0 tasks
- Do NOT read task body — the PO/command only needs the index to decide what to do next
- A task with `depends_on: [BACK-001]` is NOT ready if BACK-001 is in `todo/` or `in_progress/`
