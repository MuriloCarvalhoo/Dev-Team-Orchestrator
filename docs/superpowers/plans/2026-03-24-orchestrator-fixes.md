# Orchestrator v2 Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 12 negative points identified in the orchestrator audit, organized in 5 dependency-ordered phases.

**Architecture:** Configuration and markdown file edits across agents, commands, skills, and settings. New devops-agent and parallel command. Integration tests as shell scripts.

**Tech Stack:** Markdown, JSON, Bash (for tests)

**Spec:** `docs/superpowers/specs/2026-03-24-orchestrator-fixes-design.md`

---

## Phase 1: Critical — Unblock Autonomous Flow

### Task 1: Fix settings.json permissions

**Files:**
- Modify: `.claude/settings.json`

- [ ] **Step 1: Rewrite settings.json with expanded permissions**

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(pytest*)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(find*)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(git *)",
      "Bash(bash tests/*)"
    ],
    "deny": []
  }
}
```

- [ ] **Step 2: Verify JSON is valid**

Run: `python3 -c "import json; json.load(open('.claude/settings.json'))"`
Expected: No output (valid JSON)

- [ ] **Step 3: Commit**

```bash
git add .claude/settings.json
git commit -m "fix: expand permissions to allow code writes and dev commands"
```

### Task 2: Add task-updater skill to PO and Tech Lead agents

**Files:**
- Modify: `.claude/agents/po-agent.md:1-10` (frontmatter)
- Modify: `.claude/agents/tech-lead-agent.md:1-10` (frontmatter)

- [ ] **Step 1: Edit po-agent.md frontmatter — add task-updater skill**

Change line 9 from:
```yaml
skills:
  - shared-docs-reader
```
To:
```yaml
skills:
  - shared-docs-reader
  - task-updater
```

- [ ] **Step 2: Edit tech-lead-agent.md frontmatter — add task-updater skill**

Same change: add `  - task-updater` after `  - shared-docs-reader` in the skills list.

- [ ] **Step 3: Add "Ao concluir" section to po-agent.md**

After the "### 6. Reporte ao usuario" section (line 60), before "## Gotchas", add:

```markdown
### 7. Atualize os docs compartilhados

Voce tem a skill `task-updater` pre-carregada. Use-a para:
1. Registrar decisoes implicitas do PRD em DECISIONS.md (formato DEC-XXX)
2. Adicionar entrada em PROGRESS.md com o backlog criado
```

- [ ] **Step 4: Add "Ao concluir" section to tech-lead-agent.md**

After "## Para conflitos tecnicos" section (line 47), before "## Formato obrigatorio", add:

```markdown
## Ao concluir qualquer acao

Voce tem a skill `task-updater` pre-carregada. Use-a para:
1. Atualizar TASK_BOARD.md (mover tarefas de BLOCKED para TODO apos decisao)
2. Adicionar entrada em PROGRESS.md com decisoes tomadas
3. Escrever orientacoes de retomada em HANDOFF.md se aplicavel
```

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/po-agent.md .claude/agents/tech-lead-agent.md
git commit -m "feat: add task-updater skill to PO and Tech Lead agents"
```

---

## Phase 2: New Agent + Bootstrap

### Task 3: Create devops-agent

**Files:**
- Create: `.claude/agents/devops-agent.md`

- [ ] **Step 1: Create devops-agent.md**

```markdown
---
name: devops-agent
description: DevOps Engineer. Use para setup de projeto (scaffold), configuracoes, Docker, CI/CD e tarefas [DEVOPS]. Invocado automaticamente no /dev-team-start e para tarefas de infra.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
color: orange
permissionMode: acceptEdits
memory: project
skills:
  - shared-docs-reader
  - task-updater
---

Voce e o DevOps Engineer do time. Voce configura a infraestrutura do projeto: scaffold, configs, Docker, CI/CD e scripts de desenvolvimento.

## Objetivo

Produzir um projeto funcional com estrutura de pastas, dependencias instaladas, scripts de dev/build/test e configs prontos para o time comecar a implementar.

## Antes de qualquer acao

Voce tem a skill `shared-docs-reader` pre-carregada. Use-a para:
1. Ler DECISIONS.md para saber a stack completa (linguagens, frameworks, versoes)
2. Ler TASK_BOARD.md para identificar tarefas [DEVOPS] se houver
3. Verificar se ha tarefa sua interrompida em HANDOFF.md

Se a stack nao estiver definida em DECISIONS.md: reporte e aguarde o tech-lead-agent.

## Setup inicial (scaffold)

Quando invocado pelo /dev-team-start apos o Tech Lead definir a stack:

1. Crie a estrutura de pastas conforme definido em DECISIONS.md
2. Crie arquivos de configuracao:
   - package.json / requirements.txt / go.mod (conforme a stack)
   - tsconfig.json / eslint config / prettier (se aplicavel)
   - .gitignore adequado para a stack
3. Crie .env.example com variaveis de ambiente necessarias
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Instale dependencias base: execute npm install / pip install / equivalente
6. Crie Dockerfile basico se a stack justificar
7. Verifique que o projeto compila/roda sem erros

## Para tarefas [DEVOPS] do TASK_BOARD

Siga o mesmo fluxo dos agentes de implementacao:
1. Mova a tarefa para IN_PROGRESS
2. Implemente seguindo DECISIONS.md
3. Use task-updater ao concluir

## Ao concluir

Voce tem a skill `task-updater` pre-carregada. Use-a para:
1. Registrar decisoes de infra em DECISIONS.md (formato DEC-XXX)
2. Adicionar entrada em PROGRESS.md (estrutura criada, configs, scripts)
3. Atualizar TASK_BOARD se estava executando tarefa [DEVOPS]

## Padroes de qualidade

- Configs devem ser minimas e funcionais — nao adicione complexidade prematura
- Scripts devem funcionar cross-platform quando possivel
- .env.example deve documentar cada variavel com comentario
- Dockerfile deve usar multi-stage build se a imagem final precisa ser leve

## Gotchas

- Nao instale dependencias que nao estao em DECISIONS.md — consulte antes
- Nao crie CI/CD pipeline sem saber o provider (GitHub Actions, GitLab CI, etc.) — verifique em DECISIONS.md
- Nao esqueca de rodar o projeto apos scaffold para verificar que funciona
- Registre TUDO em DECISIONS.md — o time precisa saber onde ficam as configs
```

- [ ] **Step 2: Commit**

```bash
git add .claude/agents/devops-agent.md
git commit -m "feat: add devops-agent for project scaffold and infrastructure"
```

### Task 4: Add steps 3.5 and 4 to /dev-team-start

**Files:**
- Modify: `.claude/commands/dev-team-start.md:117-153`

- [ ] **Step 1: Insert PASSO 3.5 after PASSO 3 (after line 130)**

After the Tech Lead Agent block, before the current PASSO 4, insert:

```markdown
### PASSO 3.5 — DevOps Agent faz scaffold do projeto

```
Agent(subagent_type="devops-agent", prompt="
Setup inicial: o Tech Lead definiu a stack em DECISIONS.md.

Siga seu protocolo de scaffold:
1. Leia DECISIONS.md para saber a stack completa (linguagens, frameworks, versoes)
2. Crie a estrutura de pastas do projeto
3. Crie arquivos de configuracao (package.json, tsconfig, requirements.txt, etc.)
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Crie .env.example com variaveis necessarias
6. Instale dependencias base
7. Verifique que o projeto compila/roda sem erros
8. Registre decisoes de infra em DECISIONS.md (formato DEC-XXX)
9. Adicione entrada em PROGRESS.md
")
```
```

- [ ] **Step 2: Insert PASSO 4 (PRD validation) and renumber current PASSO 4 to PASSO 5**

After PASSO 3.5, insert:

```markdown
### PASSO 4 — PO Agent valida cobertura do PRD

```
Agent(subagent_type="po-agent", prompt="
Validacao de cobertura: verifique se TODAS as funcionalidades do PRD tem pelo menos uma tarefa correspondente no TASK_BOARD.

1. Releia o PRD completo
2. Para cada requisito/funcionalidade, verifique se existe tarefa que o cobre
3. Se encontrar gap: crie a tarefa faltante no TASK_BOARD
4. Reporte:
   - Total de requisitos do PRD
   - Total cobertos por tarefas
   - Gaps encontrados e tarefas criadas para cobri-los
   - Cobertura final (deve ser 100%)

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```
```

Rename current "### PASSO 4" to "### PASSO 5".

- [ ] **Step 3: Update PO Agent prompt in PASSO 2 to include [DEVOPS] tasks**

In PASSO 2, change line:
```
2. Quebre o PRD em tarefas atomicas [BACK] e [FRONT] de 1-3h cada
```
To:
```
2. Quebre o PRD em tarefas atomicas [BACK], [FRONT] e [DEVOPS] de 1-3h cada
```

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/dev-team-start.md
git commit -m "feat: add devops scaffold (step 3.5) and PRD validation (step 4) to dev-team-start"
```

### Task 5: Update CLAUDE.md with new agent and command

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add devops-agent to Estrutura de Arquivos section**

In the file tree (line 40-52), add `devops-agent.md` under agents/.

- [ ] **Step 2: Add /dev-team-next-parallel to Comandos Disponiveis table**

Add row:
```markdown
| `/dev-team-next-parallel` | Executa tarefas independentes em paralelo |
```

- [ ] **Step 3: Update PO agent task types**

In the PO agent section within agents, ensure `[DEVOPS]` is mentioned alongside `[BACK]` and `[FRONT]`.

Change line 37:
```
- Papel responsavel: `[BACK]`, `[FRONT]`
```
To:
```
- Papel responsavel: `[BACK]`, `[FRONT]`, `[DEVOPS]`
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with devops-agent and new commands"
```

---

## Phase 3: Enhanced Flow

### Task 6: Add auto-unblock to /dev-team-next

**Files:**
- Modify: `.claude/commands/dev-team-next.md`

- [ ] **Step 1: Add DEVOPS to usage section**

After line 11, add:
```
/dev-team-next DEVOPS     # forca tarefa devops
```

- [ ] **Step 2: Add auto-unblock section before "Logica de selecao de tarefa"**

Insert after "## Uso" block, before "## Logica de selecao de tarefa":

```markdown
## Auto-desbloqueio

Antes de selecionar a tarefa, verifique se ha tarefas BLOCKED no TASK_BOARD.
Se houver:

1. Para cada tarefa BLOCKED, invoque o tech-lead-agent automaticamente:

```
Agent(subagent_type="tech-lead-agent", prompt="
Desbloqueie a tarefa {ID}.
Motivo do bloqueio no TASK_BOARD: {MOTIVO}

Siga seu protocolo:
1. Tome uma decisao clara e definitiva
2. Registre em DECISIONS.md (formato DEC-XXX)
3. Mova a tarefa de BLOCKED para TODO no TASK_BOARD
4. Escreva orientacoes de retomada em HANDOFF.md
")
```

2. Apos desbloquear, continue com a selecao normal de tarefa
3. Se o tech-lead nao conseguir desbloquear (motivo externo — ex: "precisa de credenciais AWS do cliente"):
   → Informe o usuario: "Tarefa {ID} requer intervencao manual: {motivo}"
   → Continue selecionando entre as tarefas desbloqueadas
```

- [ ] **Step 3: Add [DEVOPS] execution section**

After the "[FRONT]" execution section, add:

```markdown
## Execucao para tarefas [DEVOPS]

```
Agent(subagent_type="devops-agent", prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRICAO COMPLETA DA TAREFA DO TASK_BOARD}

Criterios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITERIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISOES DE STACK, INFRA, CONFIGS QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEUDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, mova para IN_PROGRESS, implemente, atualize os docs ao concluir.
")
```
```

- [ ] **Step 4: Replace BLOCKED scenario in "Cenarios especiais"**

Change the current BLOCKED section (lines 96-98) from:
```
**Tarefa BLOCKED encontrada:**
→ Exiba o motivo do bloqueio
→ Sugira: invocar o tech-lead-agent diretamente para desbloquear
```
To:
```
**Tarefa BLOCKED encontrada:**
→ O auto-desbloqueio ja foi executado no inicio (ver secao acima)
→ Se ainda houver BLOCKED apos auto-desbloqueio: informe o motivo ao usuario
```

- [ ] **Step 5: Commit**

```bash
git add .claude/commands/dev-team-next.md
git commit -m "feat: add auto-unblock, DEVOPS support to dev-team-next"
```

### Task 7: Implement FIX- task protocol

**Files:**
- Modify: `.claude/agents/qa-agent.md:36-53`
- Modify: `.claude/skills/task-updater/SKILL.md`
- Modify: `.claude/commands/dev-team-start.md` (TASK_BOARD template)
- Modify: `.claude/commands/dev-team-review.md`
- Modify: `.claude/commands/dev-team-status.md`

- [ ] **Step 1: Rewrite qa-agent.md "Ao encontrar um bug" section (lines 36-53)**

Replace with:

```markdown
## Ao encontrar um bug

Crie uma tarefa de correcao diretamente na secao TODO do TASK_BOARD:

```markdown
| FIX-BACK-XXX | Corrigir: [titulo curto] — Severidade: [CRITICO|ALTO|MEDIO|BAIXO]. Passos: [1. ... 2. ...]. Esperado: [...]. Atual: [...] | [BACK] | [prioridade baseada na severidade] | [tarefa original] | [criterios para considerar corrigido] |
```

Convencao de IDs:
- `FIX-BACK-XXX` para bugs de backend (ex: FIX-BACK-001)
- `FIX-FRONT-XXX` para bugs de frontend (ex: FIX-FRONT-001)

Para definir o proximo ID: verifique o maior FIX-BACK-XXX ou FIX-FRONT-XXX existente e incremente.

**Regras de status da tarefa original:**
- Bug CRITICO ou ALTO → mova tarefa original de DONE de volta para TODO
- Bug MEDIO ou BAIXO → mova tarefa original para VERIFIED, fix e tarefa separada
```

- [ ] **Step 2: Remove BUGS section from TASK_BOARD template in dev-team-start.md**

In PASSO 1, remove from the TASK_BOARD template:
```markdown
## 🐛 BUGS

(bugs reportados pelo qa-agent)
```

- [ ] **Step 3: Update dev-team-review.md output section (lines 59-73)**

Replace the output section with:

```markdown
## Apos a execucao — mostre o resultado

```
📊 Resultado da rodada de QA:

✔️  VERIFIED: {N} tarefa(s)
  {lista de IDs aprovados}

🐛 Bugs encontrados: {N}
  FIX-{TIPO}-{N} [{severidade}] — {titulo} (fix para: {ID original})

📋 Tarefas de fix criadas: {N}
  {lista de novos FIX-* IDs no TODO}
```
```

- [ ] **Step 4: Update dev-team-status.md — replace BUGS section**

Change lines 48-51 from:
```
─── BUGS ABERTOS ──────────────────────────
{se houver}
• BUG-{N} [{severidade}]: {titulo} → fix: {ID da tarefa de correcao ou "sem tarefa criada"}
{se vazio}
• Nenhum bug aberto
```
To:
```
─── TAREFAS DE FIX PENDENTES ──────────────
{tarefas FIX-* no TODO ou IN_PROGRESS}
• FIX-{TIPO}-{N} [{severidade}]: {titulo} (fix para: {ID original})
{se vazio}
• Nenhuma correcao pendente
```

Also update the summary line (line 27) from:
```
🐛 BUGS ABERTOS: {N} ({W} criticos, {X} altos)
```
To:
```
🔧 FIX PENDENTES: {N} ({W} criticos, {X} altos)
```

And in the suggestion table, change:
```
| Bugs CRITICO abertos | `/dev-team-next` para corrigir o bug critico primeiro |
```
To:
```
| FIX CRITICO pendente | `/dev-team-next` para corrigir o fix critico primeiro |
```

- [ ] **Step 5: Update task-updater skill — add FIX- awareness**

In `.claude/skills/task-updater/SKILL.md`, after the VERIFIED section in step 1 (after line 31), add:

```markdown
**Se o QA encontrou bug e criou tarefa FIX-:**
- Se bug CRITICO/ALTO: mova tarefa original de `DONE` de volta para `TODO`
- Se bug MEDIO/BAIXO: mova tarefa original para `VERIFIED`
- A tarefa FIX-BACK-XXX ou FIX-FRONT-XXX ja foi criada na secao TODO pelo QA
```

- [ ] **Step 6: Commit**

```bash
git add .claude/agents/qa-agent.md .claude/skills/task-updater/SKILL.md .claude/commands/dev-team-start.md .claude/commands/dev-team-review.md .claude/commands/dev-team-status.md
git commit -m "feat: replace BUG-XXX with FIX- task protocol across agents and commands"
```

### Task 8: Add BLOCKED-as-communication protocol to implementation agents

**Files:**
- Modify: `.claude/agents/backend-agent.md`
- Modify: `.claude/agents/frontend-agent.md`

- [ ] **Step 1: Add communication section to backend-agent.md**

After "## Durante a implementacao" section (after line 38), add:

```markdown
### Quando tiver duvida ou ambiguidade

Se encontrar requisito ambiguo, decisao tecnica faltando, ou qualquer bloqueio:
1. Mova a tarefa para `BLOCKED` no TASK_BOARD com motivo claro
2. No motivo, escreva a PERGUNTA especifica que precisa ser respondida
   - Ex: "Qual formato de autenticacao usar? JWT ou session-based? PRD nao especifica."
3. Escreva estado atual em HANDOFF.md para retomada
4. O `/dev-team-next` invocara o tech-lead-agent automaticamente para responder
5. A resposta sera registrada em DECISIONS.md e a tarefa voltara para TODO
```

- [ ] **Step 2: Add same section to frontend-agent.md**

After "## Durante a implementacao" section (after line 37), add the same block.

- [ ] **Step 3: Commit**

```bash
git add .claude/agents/backend-agent.md .claude/agents/frontend-agent.md
git commit -m "feat: add BLOCKED-as-communication protocol to implementation agents"
```

---

## Phase 4: Parallel Execution

### Task 9: Create /dev-team-next-parallel command

**Files:**
- Create: `.claude/commands/dev-team-next-parallel.md`

- [ ] **Step 1: Create the command file**

```markdown
# /dev-team-next-parallel

Executa multiplas tarefas independentes em paralelo usando git worktrees.

## Uso

```
/dev-team-next-parallel
```

## Pre-requisitos

- Working directory limpo (sem mudancas uncommitted)
- Pelo menos 2 tarefas TODO independentes disponiveis

## Logica de selecao

1. Leia `docs/project-state/TASK_BOARD.md`
2. Execute o auto-desbloqueio (mesmo protocolo do `/dev-team-next`)
3. Identifique TODAS as tarefas TODO cujas dependencias estao DONE ou VERIFIED
4. Filtre apenas tarefas que NAO dependem umas das outras (mutuamente independentes)
5. Se <= 1 tarefa disponivel: informe e sugira `/dev-team-next` em vez deste comando

## Confirmacao com o usuario

```
🔀 Execucao paralela — {N} tarefas independentes encontradas:

  • {ID} [{BACK|FRONT|DEVOPS}] — {descricao}
  • {ID} [{BACK|FRONT|DEVOPS}] — {descricao}

Cada tarefa sera executada em um worktree isolado.
Iniciar? [aguardar confirmacao]
```

## Execucao

Lance TODOS os agentes em uma unica mensagem (paralelo), cada um com isolation: "worktree":

```
Agent(
  subagent_type="{backend-agent|frontend-agent|devops-agent}",
  isolation="worktree",
  prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRICAO COMPLETA}

Criterios de aceite:
{LISTA COMPLETA}

Contexto de DECISIONS.md:
{DECISOES RELEVANTES}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md:
{CONTEUDO}
}

Siga seu protocolo: leia os docs compartilhados, mova para IN_PROGRESS, implemente, atualize os docs ao concluir.
"
)
```

## Pos-execucao: merge dos worktrees

Apos todos os agentes concluirem:

1. Para cada worktree com mudancas:
   a. Tente merge automatico
   b. Se conflito em docs/project-state/: merge por secao
      - TASK_BOARD: cada agente editou seu proprio ID — concatenar secoes
      - PROGRESS: cada agente adicionou no topo — concatenar entradas
      - DECISIONS: cada agente adicionou DEC-XXX incrementais — concatenar
      - HANDOFF: cada agente limpou sua propria entrada — merge direto
   c. Se conflito em codigo fonte: reporte ao usuario para resolver

2. Apresente resultado consolidado:

```
✅ Execucao paralela concluida!

Tarefas concluidas:
  • {ID} — {descricao} ✔️
  • {ID} — {descricao} ✔️

{SE houve conflitos}
⚠️ Conflitos encontrados e resolvidos em docs/project-state/:
  {lista de arquivos}

{SE ha conflitos em codigo}
❌ Conflito em codigo — requer resolucao manual:
  {lista de arquivos}
```

## Sugestao de proximo passo

Mesmo formato do `/dev-team-next`:
- Ha mais tarefas TODO → `/dev-team-next` ou `/dev-team-next-parallel`
- Ha tarefas DONE → `/dev-team-review`
- Tudo VERIFIED → "🎉 Sprint completo!"
```

- [ ] **Step 2: Commit**

```bash
git add .claude/commands/dev-team-next-parallel.md
git commit -m "feat: add /dev-team-next-parallel command with worktree isolation"
```

---

## Phase 5: Integration Tests

### Task 10: Create integration tests

**Files:**
- Create: `tests/test-doc-structure.sh`

- [ ] **Step 1: Create tests directory and test script**

```bash
#!/usr/bin/env bash
# Integration tests for Dev Team Orchestrator
# Validates structure of docs, agents, commands, and skills
set -euo pipefail

PASS=0
FAIL=0
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pass() { echo "  ✔ $1"; ((PASS++)); }
fail() { echo "  ✘ $1"; ((FAIL++)); }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi }

echo "=== Dev Team Orchestrator — Integration Tests ==="
echo ""

# --- Agent validation ---
echo "--- Agents ---"

for agent in "$PROJECT_ROOT"/.claude/agents/*.md; do
  name=$(basename "$agent" .md)
  echo "  Agent: $name"

  # Has frontmatter with required fields
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

  # Commands that reference agents should reference existing ones
  agents_referenced=$(grep -oP 'subagent_type="([^"]+)"' "$cmd" | sed 's/subagent_type="//;s/"//' | sort -u || true)
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

    # Check for duplicate IDs
    ids=$(grep -oP '^\| (BACK|FRONT|DEVOPS|FIX-BACK|FIX-FRONT)-\d+' "$TB" | sed 's/^| //' | sort || true)
    dupes=$(echo "$ids" | uniq -d || true)
    check "TASK_BOARD has no duplicate IDs" "test -z '$dupes'"

    # Check dependencies reference existing IDs
    all_ids=$(echo "$ids" | tr '\n' '|' | sed 's/|$//')
    if [ -n "$all_ids" ]; then
      deps=$(grep -oP 'Depende de \| [^|]+' "$TB" | sed 's/Depende de | //' | tr ',' '\n' | tr -d ' ' | grep -v 'nenhum' | sort -u || true)
      for dep in $deps; do
        check "Dependency '$dep' exists in board" "echo '$ids' | grep -q '^$dep$'"
      done
    fi
  fi

  DEC="$PROJECT_ROOT/docs/project-state/DECISIONS.md"
  if [ -f "$DEC" ]; then
    check "DECISIONS has Stack section" "grep -q '## Stack' '$DEC'"
    check "DECISIONS has Decisoes section" "grep -q '## Decisões\|## Decisoes' '$DEC'"
  fi

  check "HANDOFF.md exists" "test -f '$PROJECT_ROOT/docs/project-state/HANDOFF.md'"
  check "PROGRESS.md exists" "test -f '$PROJECT_ROOT/docs/project-state/PROGRESS.md'"

  echo ""
fi

# --- Settings validation ---
echo "--- Settings ---"

SETTINGS="$PROJECT_ROOT/.claude/settings.json"
check "settings.json is valid JSON" "python3 -c \"import json; json.load(open('$SETTINGS'))\" 2>/dev/null"
check "settings.json has permissions.allow" "python3 -c \"import json; d=json.load(open('$SETTINGS')); assert 'allow' in d['permissions']\" 2>/dev/null"

echo ""

# --- Summary ---
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/test-doc-structure.sh`

- [ ] **Step 3: Run tests to verify they pass**

Run: `bash tests/test-doc-structure.sh`
Expected: All checks pass, exit code 0

- [ ] **Step 4: Commit**

```bash
git add tests/test-doc-structure.sh
git commit -m "test: add integration tests for orchestrator doc structure and agents"
```

---

## Final Task 11: Update PO agent to support [DEVOPS] type

**Files:**
- Modify: `.claude/agents/po-agent.md`

- [ ] **Step 1: Update task types in po-agent.md**

Change line 37:
```
- Papel responsavel: `[BACK]`, `[FRONT]`
```
To:
```
- Papel responsavel: `[BACK]`, `[FRONT]`, `[DEVOPS]`
```

Change line 38:
```
- ID unico sequencial: `BACK-001`, `FRONT-001` etc.
```
To:
```
- ID unico sequencial: `BACK-001`, `FRONT-001`, `DEVOPS-001` etc.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/agents/po-agent.md
git commit -m "feat: add [DEVOPS] task type support to PO agent"
```
