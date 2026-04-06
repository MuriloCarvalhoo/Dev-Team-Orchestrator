# Dev Team Orchestrator

Este projeto usa um time de agentes Claude Code para implementar sistemas a partir de PRDs.
O padrao de orquestracao e: Command → Agent → Skill.

## Regras Obrigatorias para TODOS os Agentes

<important if="sempre">
1. **SEMPRE leia o arquivo da sua tarefa antes de comecar:**
   - O path vem no prompt (ex: `board/todo/BACK-001.md`)
   - Ele contem: descricao, criterios de aceite, contexto, handoff
   - Voce NAO precisa ler outros arquivos do board/

2. **SEMPRE atualize o arquivo da tarefa ao concluir ou pausar:**
   - Mova o arquivo para a pasta de status correta (ex: `todo/ → in_progress/ → done/`)
   - Preencha secao Log ao concluir
   - Preencha secao Handoff ao pausar
   - Registre decisoes tecnicas novas em `docs/DECISIONS.md`

3. **NUNCA tome decisoes arquiteturais sem registrar em DECISIONS.md**

4. **NUNCA implemente algo que conflite com decisoes ja em DECISIONS.md**
   — Para mudar uma decisao: registre a mudanca antes de implementar.

5. **SEMPRE use os IDs de tarefa** (ex: BACK-001) ao referenciar trabalho

6. **SEMPRE escreva testes antes de mover para done/:**
   - Unit tests em `tests/unit/`
   - Integration tests em `tests/integration/`
   - O QA escrevera E2E com Playwright — screenshots sao a fonte de verdade
</important>

## Stack do Projeto
(preenchida pelo tech-lead-agent durante /dev-team-start)

- Backend: [a definir]
- Frontend: [a definir]
- Banco de dados: [a definir]
- Unit Tests: [a definir]
- Integration Tests: [a definir]
- E2E Tests: Playwright (obrigatorio)

## Estrutura de Arquivos

```
board/                    ← kanban visual por pastas
  todo/                   ← tarefas aguardando execucao
  in_progress/            ← tarefas sendo executadas
  done/                   ← tarefas implementadas, aguardando QA
  verified/               ← tarefas aprovadas (E2E Playwright passou)
  blocked/                ← tarefas bloqueadas aguardando decisao
docs/
  DECISIONS.md            ← decisoes tecnicas (append-only, compartilhado)
  PROGRESS.md             ← timeline leve (one-liners)
  wireframes/             ← um .html por tela (sem CSS), aprovado pelo usuario
    index.html            ← indice de telas
    {nome}.html           ← uma tela
  contracts/              ← um .md por feature (## API + ## Screen)
    {nome}.md             ← contrato compartilhado por BACK e FRONT
tests/
  unit/                   ← testes unitarios (escritos pelo dev)
  integration/            ← testes de integracao (escritos pelo dev)
  e2e/
    specs/                ← testes E2E Playwright (escritos pelo QA)
    screenshots/          ← screenshots = fonte de verdade
  test-doc-structure.sh   ← testes de integridade do orchestrator
.claude/
  agents/                 ← definicoes dos subagentes
    po-agent.md
    tech-lead-agent.md
    backend-agent.md
    frontend-agent.md
    qa-agent.md
    devops-agent.md
  commands/               ← comandos /dev-team-*
  skills/
    task-reader/SKILL.md  ← le um arquivo de tarefa (pre-carregada nos agentes)
    task-writer/SKILL.md  ← atualiza um arquivo de tarefa (pre-carregada nos agentes)
    board-scanner/SKILL.md ← escaneia frontmatter do board (usado pelos commands)
```

## Formato do Arquivo de Tarefa

Cada `board/{status}/{ID}.md`:
- Frontmatter YAML: id, type, priority, assigned, depends_on, created, updated
- Secoes: Description, Acceptance Criteria, Context, Handoff, Log, Test Results
- Status = pasta onde o arquivo esta (NAO ha campo status no frontmatter)
- Mover arquivo entre pastas = mudar status

## Comandos Disponiveis

| Comando | Descricao |
|---|---|
| `/dev-team-start` | Inicia o time com um PRD — wireframes, contratos, board/, scaffold |
| `/dev-team-run` | Loop autonomo: dev paralelo em worktrees + QA no main ate tudo verified |
| `/dev-team-status` | Snapshot visual do board (read-only, le do main) |

## Invocacao de Subagentes

Use `Agent(subagent_type="nome-do-agente", prompt="...")` para invocar subagentes.
**Subagentes NAO podem invocar outros subagentes via bash** — apenas via Agent().
O campo `subagent_type` deve corresponder exatamente ao campo `name:` no frontmatter do agente.

## Camadas de Teste

| Camada | Quem escreve | Quando roda | Ferramenta |
|--------|-------------|-------------|------------|
| Unit | Dev agent | Antes de mover para done/ | Jest/Vitest/pytest |
| Integration | Dev agent | Antes de mover para done/ | Supertest/Testing Library |
| E2E | QA agent | Ao validar tarefa em done/ | **Playwright** (screenshots) |

**Playwright screenshots sao a fonte de verdade.** Se o screenshot nao confirma o criterio de aceite, o QA cria uma nova tarefa `FIX-{ID}-N` em `board/todo/` e a tarefa original vai para `verified/` com flag `has_fix: true` (NUNCA volta para `todo/`).

## Governanca do /dev-team-run

- **Worktrees por tarefa**: cada tarefa paralela roda em um `git worktree` isolado em branch `task/{ID}` criado a partir de `main`. O dev faz `rebase` + `squash-merge` ao mover para `done/`. **Limite default: 3 worktrees simultaneos.**
- **Board e fonte unica e mora no `main`**. `/dev-team-status` e `board-scanner` sempre leem do `main`, nunca agregam worktrees ativos. QA tambem opera no `main`, nunca em worktrees.
- **`.gitattributes` com `merge=union`** para `docs/DECISIONS.md` e `docs/PROGRESS.md` (configurado pelo `devops-agent` no scaffold) — permite que multiplos agentes anexem linhas em paralelo sem conflito.
- **Contratos sao imutaveis durante o run**. Mudar contrato → tarefa vai para `blocked/` com `reason: contract_change`; Tech Lead atualiza, registra `DEC-TL-XXX` e marca dependentes para re-validacao.
- **Circuit breaker do QA**: cada tarefa original tem orcamento de **3 ciclos de FIX-***. Na 4a falha, vai para `blocked/` com `needs_user: true`.
- **Wireframes (gate do usuario)**: maximo de **3 iteracoes** de feedback. Se rejeitar na 3a, Tech Lead registra `DEC-TL-XXX` e decide entre abortar ou prosseguir com escopo reduzido.
- **Wireframes validam estrutura, NAO estetica**. Estetica vem do frontend-agent na implementacao e e validada via screenshots do QA.
- **Smoke test final**: apos a ultima tarefa entrar em `verified/` (sem `FIX-*` pendente), o QA executa um E2E ponta-a-ponta do sistema inteiro antes do projeto ser considerado entregue.
