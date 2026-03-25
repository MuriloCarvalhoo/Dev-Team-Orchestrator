# /dev-team-next

Executa a próxima tarefa disponível no TASK_BOARD.

## Uso

```
/dev-team-next            # próxima tarefa disponível (priorizando BACK)
/dev-team-next BACK       # força tarefa backend
/dev-team-next FRONT      # força tarefa frontend
/dev-team-next DEVOPS     # força tarefa devops
/dev-team-next BACK-003   # executa tarefa específica por ID
```

## Auto-desbloqueio

Antes de selecionar a tarefa, verifique se há tarefas BLOCKED no TASK_BOARD.
Se houver:

1. Para cada tarefa BLOCKED, invoque o tech-lead-agent automaticamente:

```
Agent(subagent_type="tech-lead-agent", prompt="
Desbloqueie a tarefa {ID}.
Motivo do bloqueio no TASK_BOARD: {MOTIVO}

Siga seu protocolo:
1. Tome uma decisão clara e definitiva
2. Registre em DECISIONS.md (formato DEC-XXX)
3. No TASK_BOARD: REMOVA a tarefa da secao BLOCKED, ADICIONE na secao TODO. Confirme que NAO aparece em ambas.
4. Escreva orientações de retomada em HANDOFF.md
")
```

2. Após desbloquear, continue com a seleção normal de tarefa
3. Se o tech-lead não conseguir desbloquear (motivo externo — ex: "precisa de credenciais AWS do cliente"):
   → Informe o usuário: "Tarefa {ID} requer intervenção manual: {motivo}"
   → Continue selecionando entre as tarefas desbloqueadas

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

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
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

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
")
```

## Execução para tarefas [DEVOPS]

```
Agent(subagent_type="devops-agent", prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRIÇÃO COMPLETA DA TAREFA DO TASK_BOARD}

Critérios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITÉRIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISÕES DE STACK, INFRA, CONFIGS QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEÚDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
")
```

## Cenários especiais

**Nenhuma tarefa disponível (todas as TODO têm dependências pendentes):**
→ Exiba: "Nenhuma tarefa disponível no momento."
→ Mostre quais tarefas estão bloqueando (dependências IN_PROGRESS ou TODO)
→ Sugira: `/dev-team-status` para ver o quadro completo

**Tarefa BLOCKED encontrada:**
→ O auto-desbloqueio já foi executado no início (ver seção acima)
→ Se ainda houver BLOCKED após auto-desbloqueio: informe o motivo ao usuário

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
