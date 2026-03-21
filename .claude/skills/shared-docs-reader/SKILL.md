---
name: shared-docs-reader
description: Carrega o contexto completo do projeto lendo TASK_BOARD, DECISIONS, HANDOFF e PROGRESS antes de iniciar qualquer tarefa. Use esta skill como primeiro passo obrigatório de qualquer agente do time.
user-invocable: false
---

# Shared Docs Reader

Leia os documentos na ordem abaixo antes de qualquer ação. O objetivo é saber exatamente: qual tarefa executar, quais padrões seguir e onde retomar se houver trabalho pela metade.

## 1. TASK_BOARD.md

Leia `docs/project-state/TASK_BOARD.md` e identifique:
- Tarefas do seu tipo com status `TODO` onde **todas** as dependências estão `DONE` ou `VERIFIED`
- Tarefas do seu tipo em `IN_PROGRESS` (verifique HANDOFF.md para retomar)
- Tarefas do seu tipo em `BLOCKED` (informe ao usuário, não tente resolver sozinho)

**Regra de seleção**: Escolha a tarefa TODO de maior prioridade cujas dependências estão todas concluídas. Se duas têm mesma prioridade, prefira a que não depende de nada.

## 2. DECISIONS.md

Leia `docs/project-state/DECISIONS.md` e extraia:
- Stack tecnológica definida (linguagem, framework, versões)
- Padrões de código, arquitetura e convenções de nomenclatura
- Contratos de API (endpoints, request/response schemas) se existirem
- Decisões específicas para sua área (backend: DB schema, migrations; frontend: design system, libs)

## 3. HANDOFF.md

Leia `docs/project-state/HANDOFF.md` e verifique:
- Há contexto de tarefa interrompida para o seu tipo de agente?
- Se sim: retome de onde parou, não recomece do zero
- O campo "Próximo passo exato" diz exatamente o que fazer

## 4. PROGRESS.md

Leia `docs/project-state/PROGRESS.md` para entender:
- O que foi implementado recentemente e por quem
- Arquivos criados/modificados (útil para QA saber onde testar)
- Trade-offs e dívida técnica registrada

## Output esperado após ler todos os docs

Você deve saber claramente:
1. **Qual tarefa executar** — ID + descrição completa + critérios de aceite
2. **Quais padrões seguir** — stack, libs, convenções de DECISIONS.md
3. **Onde continuar** — se há HANDOFF, comece a partir do "Próximo passo exato" listado lá

## Gotchas

- Se `docs/project-state/` não existir: reporte que `/dev-team-start` precisa ser executado primeiro
- Se não houver tarefa disponível do seu tipo: reporte claramente (ex: "Todas as tarefas [BACK] dependem de BACK-001 que ainda está TODO")
- Não interprete critérios de aceite — leia literalmente, o QA vai usar exatamente eles para testar
- Se DECISIONS.md não tiver a stack definida: reporte e aguarde o tech-lead-agent definir antes de implementar
