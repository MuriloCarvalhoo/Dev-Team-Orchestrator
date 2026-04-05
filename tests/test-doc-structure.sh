#!/usr/bin/env bash
# Integration tests for Dev Team Orchestrator v2
# Validates structure of board/, agents, commands, skills, and docs
set -euo pipefail

PASS=0
FAIL=0
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pass() { echo "  ✔ $1"; ((PASS++)) || true; }
fail() { echo "  ✘ $1"; ((FAIL++)) || true; }
check() {
  if eval "$2" >/dev/null 2>&1; then
    pass "$1"
  else
    fail "$1"
  fi
}

echo "=== Dev Team Orchestrator v2 — Integration Tests ==="
echo ""

# --- Agent validation ---
echo "--- Agents ---"

for agent in "$PROJECT_ROOT"/.claude/agents/*.md; do
  name=$(basename "$agent" .md)
  echo "  Agent: $name"

  check "$name has 'name:' in frontmatter" "head -15 '$agent' | grep -q '^name:'"
  check "$name has 'tools:' in frontmatter" "head -15 '$agent' | grep -q '^tools:'"
  check "$name has 'skills:' in frontmatter" "head -15 '$agent' | grep -q '^skills:'"

  # Skills referenced exist
  skills=$(sed -n '/^skills:/,/^---/p' "$agent" | grep '^ *- ' | sed 's/^ *- //')
  for skill in $skills; do
    check "$name skill '$skill' exists" "test -f '$PROJECT_ROOT/.claude/skills/$skill/SKILL.md'"
  done

  # Should NOT reference old skills
  check "$name does NOT reference shared-docs-reader" "! grep -q 'shared-docs-reader' '$agent'"
  check "$name does NOT reference task-updater" "! grep -q 'task-updater' '$agent'"
done

echo ""

# --- Command validation ---
echo "--- Commands ---"

for cmd in "$PROJECT_ROOT"/.claude/commands/*.md; do
  name=$(basename "$cmd" .md)
  echo "  Command: $name"

  agents_referenced=$(grep -oP 'subagent_type="([^"]+)"' "$cmd" | sed 's/subagent_type="//;s/"//' | grep -v '{' | sort -u 2>/dev/null || true)
  for ref in $agents_referenced; do
    check "$name references existing agent '$ref'" "test -f '$PROJECT_ROOT/.claude/agents/$ref.md'"
  done

  # Should NOT reference old paths
  check "$name does NOT reference docs/project-state/" "! grep -q 'docs/project-state/' '$cmd'"
  check "$name does NOT reference TASK_BOARD.md" "! grep -q 'TASK_BOARD.md' '$cmd'"
done

echo ""

# --- Skill validation ---
echo "--- Skills ---"

for skill_dir in "$PROJECT_ROOT"/.claude/skills/*/; do
  skill_name=$(basename "$skill_dir")
  check "Skill '$skill_name' has SKILL.md" "test -f '$skill_dir/SKILL.md'"
  check "Skill '$skill_name' has 'name:' field" "head -10 '$skill_dir/SKILL.md' | grep -q '^name:'"
done

# Required skills exist
check "task-reader skill exists" "test -f '$PROJECT_ROOT/.claude/skills/task-reader/SKILL.md'"
check "task-writer skill exists" "test -f '$PROJECT_ROOT/.claude/skills/task-writer/SKILL.md'"
check "board-scanner skill exists" "test -f '$PROJECT_ROOT/.claude/skills/board-scanner/SKILL.md'"

# Old skills removed
check "shared-docs-reader skill removed" "! test -d '$PROJECT_ROOT/.claude/skills/shared-docs-reader'"
check "task-updater skill removed" "! test -d '$PROJECT_ROOT/.claude/skills/task-updater'"

echo ""

# --- Board structure validation (only if board/ exists) ---
if [ -d "$PROJECT_ROOT/board" ]; then
  echo "--- Board Structure ---"

  check "board/todo/ exists" "test -d '$PROJECT_ROOT/board/todo'"
  check "board/in_progress/ exists" "test -d '$PROJECT_ROOT/board/in_progress'"
  check "board/done/ exists" "test -d '$PROJECT_ROOT/board/done'"
  check "board/verified/ exists" "test -d '$PROJECT_ROOT/board/verified'"
  check "board/blocked/ exists" "test -d '$PROJECT_ROOT/board/blocked'"

  # Validate task file format (if any exist)
  for task in "$PROJECT_ROOT"/board/*/*.md; do
    [ -f "$task" ] || continue
    task_name=$(basename "$task" .md)
    check "$task_name has 'id:' in frontmatter" "head -10 '$task' | grep -q '^id:'"
    check "$task_name has 'type:' in frontmatter" "head -10 '$task' | grep -q '^type:'"
    check "$task_name has 'priority:' in frontmatter" "head -10 '$task' | grep -q '^priority:'"
    check "$task_name has 'depends_on:' in frontmatter" "head -10 '$task' | grep -q '^depends_on:'"
    check "$task_name has NO 'status:' in frontmatter" "! head -10 '$task' | grep -q '^status:'"
  done

  echo ""
fi

# --- Docs validation ---
echo "--- Docs ---"

if [ -f "$PROJECT_ROOT/docs/DECISIONS.md" ]; then
  check "DECISIONS has Stack section" "grep -q '## Stack' '$PROJECT_ROOT/docs/DECISIONS.md'"
fi

# Old docs should not exist
check "docs/project-state/ does NOT exist" "! test -d '$PROJECT_ROOT/docs/project-state'"

echo ""

# --- Required commands exist ---
echo "--- Required Commands ---"

check "dev-team-start command exists" "test -f '$PROJECT_ROOT/.claude/commands/dev-team-start.md'"
check "dev-team-next command exists" "test -f '$PROJECT_ROOT/.claude/commands/dev-team-next.md'"
check "dev-team-run command exists" "test -f '$PROJECT_ROOT/.claude/commands/dev-team-run.md'"
check "dev-team-status command exists" "test -f '$PROJECT_ROOT/.claude/commands/dev-team-status.md'"

# Old commands removed
check "dev-team-next-parallel removed" "! test -f '$PROJECT_ROOT/.claude/commands/dev-team-next-parallel.md'"
check "dev-team-review removed" "! test -f '$PROJECT_ROOT/.claude/commands/dev-team-review.md'"

echo ""

# --- Settings validation ---
echo "--- Settings ---"

SETTINGS="$PROJECT_ROOT/.claude/settings.json"
check "settings.json is valid JSON" "python3 -c \"import json; json.load(open('$SETTINGS'))\""
check "settings.json has permissions.allow" "python3 -c \"import json; d=json.load(open('$SETTINGS')); assert 'allow' in d['permissions']\""

echo ""

# --- Summary ---
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi
