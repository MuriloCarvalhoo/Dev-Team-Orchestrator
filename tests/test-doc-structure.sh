#!/usr/bin/env bash
# Integration tests for Dev Team Orchestrator
# Validates structure of docs, agents, commands, and skills
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

echo "=== Dev Team Orchestrator — Integration Tests ==="
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
done

echo ""

# --- Skill validation ---
echo "--- Skills ---"

for skill_dir in "$PROJECT_ROOT"/.claude/skills/*/; do
  skill_name=$(basename "$skill_dir")
  check "Skill '$skill_name' has SKILL.md" "test -f '$skill_dir/SKILL.md'"
  check "Skill '$skill_name' has 'name:' field" "head -10 '$skill_dir/SKILL.md' | grep -q '^name:'"
done

echo ""

# --- Doc structure validation (only if docs exist) ---
if [ -d "$PROJECT_ROOT/docs/project-state" ]; then
  echo "--- Doc Structure ---"

  TB="$PROJECT_ROOT/docs/project-state/TASK_BOARD.md"
  if [ -f "$TB" ]; then
    check "TASK_BOARD has TODO section" "grep -q '## 📋 TODO' '$TB'"
    check "TASK_BOARD has IN_PROGRESS section" "grep -q '## 🔄 IN_PROGRESS' '$TB'"
    check "TASK_BOARD has DONE section" "grep -q '## ✅ DONE' '$TB'"
    check "TASK_BOARD has VERIFIED section" "grep -q '## ✔️ VERIFIED' '$TB'"
    check "TASK_BOARD has BLOCKED section" "grep -q '## 🚫 BLOCKED' '$TB'"
  fi

  DEC="$PROJECT_ROOT/docs/project-state/DECISIONS.md"
  if [ -f "$DEC" ]; then
    check "DECISIONS has Stack section" "grep -q '## Stack' '$DEC'"
  fi

  check "HANDOFF.md exists" "test -f '$PROJECT_ROOT/docs/project-state/HANDOFF.md'"
  check "PROGRESS.md exists" "test -f '$PROJECT_ROOT/docs/project-state/PROGRESS.md'"

  echo ""
fi

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
