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
| `/dev-team-start` | Inicia o time com um PRD — cria board/ e arquivos de tarefa |
| `/dev-team-next [TIPO\|ID]` | Executa uma tarefa (modo manual) |
| `/dev-team-run` | Loop autonomo: dev paralelo + QA automatico ate tudo verified |
| `/dev-team-status` | Mostra snapshot visual do board |

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

**Playwright screenshots sao a fonte de verdade.** Se o screenshot nao confirma o criterio de aceite, a tarefa volta para todo/.
