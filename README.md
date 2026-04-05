# Dev Team Orchestrator

Um time de agentes Claude Code que implementa sistemas completos a partir de PRDs — do backlog ao deploy, com testes E2E automaticos.

## O que e isso?

Um framework de orquestracao que coordena 6 agentes especializados (PO, Tech Lead, Backend, Frontend, QA, DevOps) para transformar um PRD em codigo implementado e verificado. O estado e mantido em arquivos no filesystem — sem banco de dados, sem servicos externos.

## Arquitetura

O padrao de orquestracao segue tres camadas:

```
Command (/dev-team-*)  →  Agent (6 especializados)  →  Skill (task-reader, task-writer, board-scanner)
```

Cada **command** orquestra a execucao, selecionando quais **agents** invocar. Cada **agent** usa **skills** pre-carregadas para ler e atualizar o estado do board.

## Fluxo de Trabalho

> **Diagrama visual interativo:** abra [`docs/workflow.html`](docs/workflow.html) no navegador para ver o fluxo completo com todos os agentes e etapas.

```
  PRD
   │
   ▼
┌─────────────────────────────────────────────────────┐
│  /dev-team-start                                    │
│  PO analisa PRD → cria board/todo/*.md              │
│  Tech Lead define stack → DECISIONS.md              │
│  DevOps faz scaffold → configs, deps, testes        │
│  PO injeta contexto tecnico em cada tarefa          │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  /dev-team-next (manual) ou /dev-team-run (auto)    │
│                                                     │
│  Para cada tarefa:                                  │
│    Dev le board/todo/{ID}.md                        │
│    Move todo/ → in_progress/ → done/                │
│    Escreve unit + integration tests                 │
│                                                     │
│  /dev-team-run lanca tarefas em paralelo            │
│  (worktrees isolados, merge automatico)             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  QA Agent                                           │
│  Roda unit + integration tests                      │
│  Escreve E2E Playwright specs + screenshots         │
│  Screenshots = fonte de verdade                     │
│  Aprovado → verified/  |  Bug → cria FIX-* → todo/ │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
              ✓ Projeto Concluido
         (todas tarefas em verified/)
```

## Comandos

| Comando | Descricao |
|---|---|
| `/dev-team-start` | Inicializa projeto a partir de PRD: cria board, tarefas, define stack, scaffold |
| `/dev-team-next` | Seleciona e executa uma tarefa por vez, com auto-desbloqueio de BLOCKED |
| `/dev-team-run` | Loop autonomo: tarefas em paralelo + QA automatico ate tudo verified |
| `/dev-team-status` | Snapshot visual do board (read-only, sem agentes) |

## Agentes

| Agente | Papel | Responsabilidade |
|---|---|---|
| `po-agent` | Product Owner | Analisa PRD, cria tarefas atomicas (1-3h), define criterios de aceite, mapeia dependencias |
| `tech-lead-agent` | Arquiteto | Define stack com versoes, resolve conflitos, desbloqueia BLOCKED, registra em DECISIONS.md |
| `backend-agent` | Dev Backend | Implementa [BACK]: APIs, logica, DB. Escreve unit + integration tests |
| `frontend-agent` | Dev Frontend | Implementa [FRONT]: componentes, telas. Trata loading/error/empty |
| `qa-agent` | QA Engineer | Valida DONE: roda testes, escreve E2E Playwright, screenshots como prova |
| `devops-agent` | Infraestrutura | Scaffold, configs, dependencias, Playwright setup, Docker |

## Ciclo de Vida da Tarefa

O status e determinado pela pasta onde o arquivo `.md` da tarefa esta:

```
board/todo/       →  board/in_progress/  →  board/done/      →  board/verified/
                          │                       │
                          ▼                       ▼
                    board/blocked/          (bug critico)
                    Tech Lead decide        QA cria FIX-*
                    volta p/ todo/          volta p/ todo/
```

Cada tarefa e um arquivo `board/{status}/{ID}.md` com:
- **Frontmatter YAML**: id, type, priority, depends_on, assigned, created, updated
- **Secoes**: Description, Acceptance Criteria, Context, Handoff, Log, Test Results

## Estrutura do Projeto

```
seu-projeto/
├── .claude/
│   ├── agents/                     ← 6 agentes especializados
│   │   ├── po-agent.md
│   │   ├── tech-lead-agent.md
│   │   ├── backend-agent.md
│   │   ├── frontend-agent.md
│   │   ├── qa-agent.md
│   │   └── devops-agent.md
│   ├── commands/                   ← 4 comandos /dev-team-*
│   │   ├── dev-team-start.md
│   │   ├── dev-team-next.md
│   │   ├── dev-team-run.md
│   │   └── dev-team-status.md
│   ├── skills/                     ← 3 skills compartilhadas
│   │   ├── task-reader/SKILL.md
│   │   ├── task-writer/SKILL.md
│   │   └── board-scanner/SKILL.md
│   └── settings.json
├── CLAUDE.md                       ← regras obrigatorias para agentes
├── board/                          ← kanban por pastas (criado pelo /dev-team-start)
│   ├── todo/
│   ├── in_progress/
│   ├── done/
│   ├── verified/
│   └── blocked/
├── docs/
│   ├── DECISIONS.md                ← decisoes tecnicas (append-only)
│   ├── PROGRESS.md                 ← timeline de eventos
│   └── workflow.html               ← diagrama visual do fluxo
└── tests/
    ├── unit/                       ← testes unitarios (dev)
    ├── integration/                ← testes de integracao (dev)
    ├── e2e/
    │   ├── specs/                  ← specs Playwright (QA)
    │   └── screenshots/            ← screenshots = fonte de verdade
    └── test-doc-structure.sh       ← testes de integridade do orchestrator
```

## Piramide de Testes

| Camada | Quem escreve | Quando roda | Ferramenta |
|---|---|---|---|
| Unit | Dev agent | Antes de mover para `done/` | Jest / Vitest / pytest |
| Integration | Dev agent | Antes de mover para `done/` | Supertest / Testing Library |
| E2E | QA agent | Ao validar tarefa em `done/` | **Playwright** (screenshots) |

**Playwright screenshots sao a fonte de verdade.** Se o screenshot nao confirma o criterio de aceite, a tarefa volta para `todo/`.

## Instalacao

1. Copie `.claude/` e `CLAUDE.md` para a raiz do seu projeto
2. Claude Code carrega automaticamente agents, commands e skills

## Uso

```bash
# 1. Iniciar com um PRD
/dev-team-start docs/prd.md

# 2a. Executar tarefas manualmente
/dev-team-next              # escolhe automaticamente
/dev-team-next BACK         # forca backend
/dev-team-next BACK-003     # tarefa especifica

# 2b. Modo autonomo (recomendado)
/dev-team-run               # loop paralelo ate concluir

# 3. Ver status a qualquer momento
/dev-team-status
```

### Retomar projeto existente

```bash
/dev-team-start    # detecta board/ existente e pula criacao
/dev-team-status   # ver onde parou
/dev-team-next     # continuar
```

## Estado Compartilhado

Os agentes se comunicam exclusivamente por arquivos:

- **`board/{status}/{ID}.md`** — cada tarefa e um arquivo individual
- **`docs/DECISIONS.md`** — decisoes tecnicas (append-only, compartilhado)
- **`docs/PROGRESS.md`** — timeline de transicoes de status

Agentes **nao** leem tarefas de outros agentes. O contexto necessario e injetado pelo PO na secao Context de cada tarefa.
