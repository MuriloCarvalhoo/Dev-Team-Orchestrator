# Dev Team Orchestrator

Um time de agentes Claude Code que implementa sistemas a partir de PRDs, com estado compartilhado e handoff entre agentes.

## Arquitetura

```
Usuário
  │
  ├─ /dev-team-start   ── PO Agent (opus)        → cria TASK_BOARD
  │                    ── Tech Lead Agent (opus)  → define stack em DECISIONS.md
  │
  ├─ /dev-team-next    ── Backend Agent (sonnet)  → implementa [BACK]
  │                    ── Frontend Agent (sonnet) → implementa [FRONT]
  │
  ├─ /dev-team-review  ── QA Agent (sonnet)       → valida DONE → VERIFIED
  │
  └─ /dev-team-status  (sem agente — lê docs direto)
```

### Padrão: Command → Agent → Skill

Cada **command** (`/dev-team-*`) orquestra a execução, selecionando qual **agent** invocar.
Cada **agent** tem duas **skills** pré-carregadas em seu contexto:
- `shared-docs-reader` — lê o estado antes de agir
- `task-updater` — atualiza o estado ao concluir

### Docs compartilhados

```
docs/project-state/
  TASK_BOARD.md   ← kanban: TODO → IN_PROGRESS → DONE → VERIFIED
  DECISIONS.md    ← stack, padrões, contratos de API, decisões arquiteturais
  HANDOFF.md      ← contexto de tarefas interrompidas para retomada
  PROGRESS.md     ← log cronológico do que foi implementado
```

Estes 4 arquivos são o **único estado compartilhado** entre agentes. Cada agente lê ao começar e atualiza ao terminar.

## Instalação

1. Copie a pasta `.claude/` para a raiz do seu projeto
2. Copie o `CLAUDE.md` para a raiz do seu projeto
3. O Claude Code carrega automaticamente `.claude/agents/`, `.claude/commands/` e `.claude/skills/`

```
seu-projeto/
  .claude/
    agents/
      po-agent.md
      tech-lead-agent.md
      backend-agent.md
      frontend-agent.md
      qa-agent.md
    commands/
      dev-team-start.md
      dev-team-next.md
      dev-team-review.md
      dev-team-status.md
    skills/
      shared-docs-reader/SKILL.md
      task-updater/SKILL.md
    settings.json
  CLAUDE.md
  docs/              ← criado automaticamente pelo /dev-team-start
    project-state/
      TASK_BOARD.md
      DECISIONS.md
      HANDOFF.md
      PROGRESS.md
```

## Uso

### Fluxo completo

```bash
# 1. Iniciar com um PRD
/dev-team-start docs/prd.md
# — PO Agent cria o backlog
# — Tech Lead define a stack

# 2. Executar tarefas (repita até o board estar cheio de DONE)
/dev-team-next          # escolhe automaticamente (BACK antes de FRONT)
/dev-team-next BACK     # força backend
/dev-team-next FRONT    # força frontend
/dev-team-next BACK-003 # tarefa específica

# 3. Revisar qualidade
/dev-team-review        # QA valida todas as tarefas DONE

# 4. Ver estado atual a qualquer momento
/dev-team-status
```

### Fluxo de estado de uma tarefa

```
TODO → IN_PROGRESS → DONE → VERIFIED
         │                    ↑
         └── BLOCKED ─ (tech-lead-agent) ─┘
                              ↓
                           BUG → novo TODO (fix)
```

## Agentes

| Agente | Modelo | Quando invocar |
|---|---|---|
| `po-agent` | opus | PRD fornecido, backlog vazio ou precisa de novas tarefas |
| `tech-lead-agent` | opus | Stack indefinida, tarefa BLOCKED, conflito técnico |
| `backend-agent` | sonnet | Tarefa [BACK] disponível no TASK_BOARD |
| `frontend-agent` | sonnet | Tarefa [FRONT] disponível no TASK_BOARD |
| `qa-agent` | sonnet | Tarefas com status DONE no TASK_BOARD |

## Boas práticas

**Para o usuário:**
- Execute `/dev-team-status` antes de qualquer `/dev-team-next` para ter contexto
- Se um agente ficou travado, use `/dev-team-next {ID}` para forçar retomada via HANDOFF
- Quando o Tech Lead bloquear uma tarefa, invoque-o diretamente antes de continuar

**Para tarefas bloqueadas:**
```
# Desbloquear manualmente
Agent(subagent_type="tech-lead-agent", prompt="
Desbloqueie a tarefa {ID}. Motivo do bloqueio: {motivo do TASK_BOARD}.
Tome uma decisão definitiva, registre em DECISIONS.md e mova para TODO.
")
```

**Para retomar projeto existente:**
```
/dev-team-start
# Vai detectar que docs/project-state/ já existe e pular a criação
/dev-team-status
# Ver onde parou
/dev-team-next
# Continuar de onde estava
```

## Limitações conhecidas

- Subagentes não podem invocar outros subagentes via bash — apenas via `Agent()`
- Cada agente tem seu próprio contexto window — não compartilham memória de conversa
- O estado compartilhado via arquivos é a única forma de persistência entre agentes
- Para projetos muito grandes (>50 tarefas), considere dividir em múltiplos sprints
