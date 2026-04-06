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
│  /dev-team-run (loop autonomo)                      │
│                                                     │
│  Para cada tarefa:                                  │
│    Dev le board/todo/{ID}.md                        │
│    Em git worktree isolado (branch task/{ID})       │
│    Move todo/ → in_progress/ → done/                │
│    Escreve unit + integration tests                 │
│    Rebase + squash-merge para main                  │
│                                                     │
│  Ate 3 worktrees em paralelo (configuravel)         │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│  QA Agent (sempre no main)                          │
│  Roda unit + integration tests                      │
│  Escreve E2E Playwright specs + screenshots         │
│  Screenshots = fonte de verdade                     │
│  Aprovado → verified/                               │
│  Bug critico → cria FIX-{ID}-N → todo/              │
│                e marca original verified+has_fix    │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
              ✓ Projeto Concluido
         (todas tarefas em verified/)
```

## Comandos

| Comando | Descricao |
|---|---|
| `/dev-team-start` | Inicializa projeto a partir de PRD: wireframes, gate do usuario, contratos, board, scaffold |
| `/dev-team-run` | Loop autonomo: dev paralelo em worktrees + QA no main ate tudo verified |
| `/dev-team-status` | Snapshot visual do board (read-only, le do main) |

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
                    Tech Lead decide        QA cria FIX-{ID}-N em todo/
                    volta p/ todo/          original vai p/ verified/ has_fix
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
│   ├── commands/                   ← 3 comandos /dev-team-*
│   │   ├── dev-team-start.md
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

**Playwright screenshots sao a fonte de verdade.** Se o screenshot nao confirma o criterio de aceite, o QA cria uma tarefa `FIX-{ID}-N` em `board/todo/` e a tarefa original vai para `verified/` com flag `has_fix`. Cada tarefa tem orcamento de 3 ciclos de FIX antes de ser escalada ao usuario.

## Instalacao

1. Copie `.claude/` e `CLAUDE.md` para a raiz do seu projeto
2. Claude Code carrega automaticamente agents, commands e skills

## Uso

```bash
# 1. Iniciar com um PRD (cria wireframes, gate de aprovacao, contratos, board, scaffold)
/dev-team-start docs/prd.md

# 2. Modo autonomo (loop paralelo ate concluir)
/dev-team-run

# 3. Ver status a qualquer momento (read-only)
/dev-team-status
```

### Retomar projeto existente

```bash
/dev-team-start    # detecta board/ existente e pula criacao
/dev-team-status   # ver onde parou
/dev-team-run      # continuar o loop
```

## Estado Compartilhado

Os agentes se comunicam exclusivamente por arquivos:

- **`board/{status}/{ID}.md`** — cada tarefa e um arquivo individual
- **`docs/DECISIONS.md`** — decisoes tecnicas (append-only, compartilhado)
- **`docs/PROGRESS.md`** — timeline de transicoes de status

Agentes **nao** leem tarefas de outros agentes. O contexto necessario e injetado pelo PO na secao Context de cada tarefa.
