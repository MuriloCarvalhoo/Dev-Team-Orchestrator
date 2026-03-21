# /dev-team-next

Executa a próxima tarefa disponível no TASK_BOARD.

## Uso

```
/dev-team-next            # próxima tarefa disponível (priorizando BACK)
/dev-team-next BACK       # força tarefa backend
/dev-team-next FRONT      # força tarefa frontend
/dev-team-next BACK-003   # executa tarefa específica por ID
```

## Lógica de seleção de tarefa

1. Leia `docs/project-state/TASK_BOARD.md`
2. Encontre tarefas com status `TODO` onde **todas** as dependências estão `DONE` ou `VERIFIED`
3. Leia `docs/project-state/HANDOFF.md` — há tarefa interrompida para retomar?

**Prioridade de seleção:**
- Tarefas com HANDOFF pendente (retomar trabalho pela metade)
- Tarefas `[BACK]` antes de `[FRONT]` (backend libera dependências do frontend)
- Tarefas de maior prioridade (ALTA > MÉDIA > BAIXA)
- Tarefas sem dependências (mais independentes)

## Antes de executar — confirme com o usuário

```
📌 Tarefa selecionada: {ID} — {descrição}
Tipo: {Backend|Frontend} | Prioridade: {Alta|Média|Baixa}
Depende de: {IDs ou "nenhum"}

Critérios de aceite:
  ✓ {critério 1}
  ✓ {critério 2}
  ✓ {critério 3}

{se HANDOFF existir: "⚠️ Esta tarefa foi interrompida antes — será retomada de onde parou."}

Iniciar? [aguardar confirmação ou proceder se o usuário já disse "execute"]
```

## Execução para tarefas [BACK]

```
Agent(subagent_type="backend-agent", prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRIÇÃO COMPLETA DA TAREFA DO TASK_BOARD}

Critérios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITÉRIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISÕES DE STACK, PADRÕES E API QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEÚDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, mova para IN_PROGRESS, implemente, atualize os docs ao concluir.
")
```

## Execução para tarefas [FRONT]

```
Agent(subagent_type="frontend-agent", prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRIÇÃO COMPLETA DA TAREFA DO TASK_BOARD}

Critérios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITÉRIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISÕES DE STACK, DESIGN SYSTEM, CONTRATOS DE API QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEÚDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, mova para IN_PROGRESS, implemente, atualize os docs ao concluir.
")
```

## Cenários especiais

**Nenhuma tarefa disponível (todas as TODO têm dependências pendentes):**
→ Exiba: "Nenhuma tarefa disponível no momento."
→ Mostre quais tarefas estão bloqueando (dependências IN_PROGRESS ou TODO)
→ Sugira: `/dev-team-status` para ver o quadro completo

**Tarefa BLOCKED encontrada:**
→ Exiba o motivo do bloqueio
→ Sugira: invocar o tech-lead-agent diretamente para desbloquear

**HANDOFF.md tem contexto desta tarefa:**
→ Inclua o conteúdo completo do HANDOFF no prompt do agente (já coberto acima)
→ Informe ao usuário: "Retomando tarefa interrompida — contexto carregado"

## Após a execução — sugira o próximo passo

```
✅ Tarefa {ID} concluída.

{SE há mais tarefas TODO disponíveis}
▶️  Próximo: /dev-team-next

{SE há tarefas DONE sem QA}
🔍 Há {N} tarefa(s) aguardando revisão de qualidade
▶️  Próximo: /dev-team-review

{SE há tarefas BLOCKED}
🚫 {N} tarefa(s) bloqueada(s) — considere invocar o tech-lead-agent

{SE tudo está VERIFIED}
🎉 Sprint completo! Todas as tarefas verificadas.
```
