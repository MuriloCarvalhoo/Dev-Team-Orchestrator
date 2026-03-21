# Dev Team Orchestrator

Este projeto usa um time de agentes Claude Code para implementar sistemas a partir de PRDs.
O padrão de orquestração é: Command → Agent → Skill.

## Regras Obrigatórias para TODOS os Agentes

<important if="sempre">
1. **SEMPRE leia os docs compartilhados antes de começar qualquer tarefa:**
   - `docs/project-state/TASK_BOARD.md` — kanban de tarefas
   - `docs/project-state/DECISIONS.md` — decisões técnicas já tomadas
   - `docs/project-state/HANDOFF.md` — contexto de tarefa interrompida
   - `docs/project-state/PROGRESS.md` — histórico do que já foi feito

2. **SEMPRE atualize os docs ao concluir ou pausar:**
   - Mova a tarefa no TASK_BOARD para o status correto
   - Registre decisões técnicas novas em DECISIONS.md
   - Se pausar no meio, escreva o estado atual em HANDOFF.md
   - Adicione entrada em PROGRESS.md ao concluir

3. **NUNCA tome decisões arquiteturais sem registrar em DECISIONS.md**

4. **NUNCA implemente algo que conflite com decisões já em DECISIONS.md**
   — Para mudar uma decisão: registre a mudança antes de implementar.

5. **SEMPRE use os IDs de tarefa** (ex: BACK-001) ao referenciar trabalho
</important>

## Stack do Projeto
(preenchida pelo tech-lead-agent durante /dev-team-start)

- Backend: [a definir]
- Frontend: [a definir]
- Banco de dados: [a definir]
- Testes: [a definir]

## Estrutura de Arquivos

```
.claude/
  agents/          ← definições dos subagentes
  commands/        ← comandos /dev-team-*
  skills/
    shared-docs-reader/SKILL.md   ← leitura de contexto (pré-carregada nos agentes)
    task-updater/SKILL.md         ← atualização de docs (pré-carregada nos agentes)
docs/
  project-state/
    TASK_BOARD.md
    DECISIONS.md
    HANDOFF.md
    PROGRESS.md
```

## Comandos Disponíveis

| Comando | Descrição |
|---|---|
| `/dev-team-start` | Inicia o time com um PRD |
| `/dev-team-next [TIPO\|ID]` | Executa a próxima tarefa disponível |
| `/dev-team-review` | Roda o QA Agent nas tarefas concluídas |
| `/dev-team-status` | Mostra snapshot atual do projeto |

## Invocação de Subagentes

Use `Agent(subagent_type="nome-do-agente", prompt="...")` para invocar subagentes.
`Task()` funciona como alias mas `Agent()` é o padrão atual (v2.1.63+).
**Subagentes NÃO podem invocar outros subagentes via bash** — apenas via Agent().
O campo `subagent_type` deve corresponder exatamente ao campo `name:` no frontmatter do agente.
