# /dev-team-next-parallel

Executa o projeto inteiro em loop autonomo: lanca tarefas em paralelo, roda QA, devs corrigem bugs ou continuam com proximas tarefas, repete ate tudo VERIFIED.

## Uso

```
/dev-team-next-parallel
```

## Pre-requisitos

- `docs/project-state/` deve existir (rode `/dev-team-start` antes)
- Working directory limpo (sem mudancas uncommitted)

## Modelo

Todos os agentes de desenvolvimento (backend, frontend, devops) e QA usam **model: "opus"** (Opus 4.6 com pensamento estendido) via override no Agent().

---

## LOOP AUTONOMO

Execute os passos abaixo em loop. Cada iteracao do loop executa tarefas disponiveis, roda QA, e verifica se o projeto esta completo. Continue ate a condicao de parada ser atingida.

### PASSO 1 — Ler estado e desbloquear

1. Leia `docs/project-state/TASK_BOARD.md`
2. Se ha tarefas BLOCKED, invoque o tech-lead-agent para cada uma:

```
Agent(subagent_type="tech-lead-agent", model="opus", prompt="
Desbloqueie a tarefa {ID}.
Motivo do bloqueio no TASK_BOARD: {MOTIVO}

Siga seu protocolo:
1. Tome uma decisao clara e definitiva
2. Registre em DECISIONS.md (formato DEC-XXX)
3. No TASK_BOARD: REMOVA a tarefa da secao BLOCKED, ADICIONE na secao TODO. Confirme que NAO aparece em ambas.
4. Escreva orientacoes de retomada em HANDOFF.md
")
```

3. Contabilize:
   - `TODO_PRONTAS`: tarefas TODO cujas dependencias estao DONE ou VERIFIED
   - `DONE_PENDENTES`: tarefas DONE aguardando QA
   - `TOTAL_VERIFIED`: tarefas VERIFIED
   - `TOTAL_TAREFAS`: todas as tarefas no board (TODO + IN_PROGRESS + DONE + VERIFIED + BLOCKED)

### PASSO 2 — Verificar condicao de parada

Exiba um resumo rapido da iteracao:
```
--- Iteracao {N} ---
TODO prontas: {X} | DONE pendentes QA: {Y} | VERIFIED: {Z}/{TOTAL}
```

**PARE o loop** se qualquer condicao for verdadeira:

1. **Projeto completo**: TOTAL_VERIFIED == TOTAL_TAREFAS
   → Exiba:
   ```
   🎉 Projeto completo! Todas as {TOTAL} tarefas verificadas.
   ```
   → PARE.

2. **Sem trabalho possivel**: TODO_PRONTAS == 0 E DONE_PENDENTES == 0
   → Se ha BLOCKED nao resolvidas: informe quais e por que
   → Se ha TODO com dependencias pendentes: liste quais dependencias faltam
   → PARE.

Se nenhuma condicao de parada: continue para o PASSO 3.

### PASSO 3 — Executar tarefas disponiveis em paralelo

Se TODO_PRONTAS > 0:

Identifique todas as tarefas TODO prontas. Filtre as mutuamente independentes (nao dependem umas das outras).

Exiba:
```
⚡ Lancando {N} tarefa(s) em paralelo (Opus 4.6):
  • {ID} [{TIPO}] — {descricao}
  • {ID} [{TIPO}] — {descricao}
```

Lance TODOS os agentes em uma **unica mensagem** (paralelo), cada um com `isolation: "worktree"` e `model: "opus"`:

Para tarefas [BACK]:
```
Agent(
  subagent_type="backend-agent",
  isolation="worktree",
  model="opus",
  prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRICAO COMPLETA DA TAREFA DO TASK_BOARD}

Criterios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITERIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISOES DE STACK, PADROES E API QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEUDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
"
)
```

Para tarefas [FRONT]:
```
Agent(
  subagent_type="frontend-agent",
  isolation="worktree",
  model="opus",
  prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRICAO COMPLETA DA TAREFA DO TASK_BOARD}

Criterios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITERIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISOES DE STACK, DESIGN SYSTEM, CONTRATOS DE API QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEUDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
"
)
```

Para tarefas [DEVOPS]:
```
Agent(
  subagent_type="devops-agent",
  isolation="worktree",
  model="opus",
  prompt="
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

Siga seu protocolo: leia os docs compartilhados, REMOVA a tarefa da secao TODO e ADICIONE na secao IN_PROGRESS, implemente, atualize os docs ao concluir. Confirme que a tarefa aparece em UMA UNICA secao apos cada movimentacao.
"
)
```

**Apos todos os agentes concluirem**, faca o merge dos worktrees:

1. Para cada worktree com mudancas:
   a. Tente merge automatico
   b. Se conflito em docs/project-state/: merge por secao
      - TASK_BOARD: cada agente editou seu proprio ID — concatenar secoes
      - PROGRESS: cada agente adicionou no topo — concatenar entradas
      - DECISIONS: cada agente adicionou DEC-XXX incrementais — concatenar
      - HANDOFF: cada agente limpou sua propria entrada — merge direto
   c. Se conflito em codigo fonte: tente resolver automaticamente; se impossivel, reporte e PARE

2. Faca commit das mudancas mergeadas para manter o working directory limpo para a proxima iteracao.

Se TODO_PRONTAS == 0 (apenas DONE pendentes), pule este passo e va direto ao PASSO 4.

### PASSO 4 — QA nas tarefas concluidas

Releia `docs/project-state/TASK_BOARD.md` (foi modificado pelo PASSO 3).

Se ha tarefas DONE:

Exiba:
```
🔍 Rodando QA em {N} tarefa(s) concluida(s) (Opus 4.6):
  • {ID} — {descricao}
  • {ID} — {descricao}
```

```
Agent(subagent_type="qa-agent", model="opus", prompt="
Rode o QA nas seguintes tarefas com status DONE:

{PARA CADA TAREFA:}
---
ID: {ID}
Descricao: {descricao completa}
Criterios de aceite:
  - {criterio 1}
  - {criterio 2}
  - {criterio 3}
---

Para cada tarefa:
1. Leia PROGRESS.md para saber quais arquivos foram criados/modificados
2. Execute os testes automatizados existentes (npm test / pytest / equivalente da stack)
3. Valide cada criterio de aceite — um por um, sem pular nenhum
4. Teste edge cases: input invalido, dados vazios, permissoes, limites
5. Se aprovada: REMOVA a linha da tarefa da secao DONE, ADICIONE na secao VERIFIED
6. Se encontrar bug:
   - Crie tarefa FIX-BACK-XXX ou FIX-FRONT-XXX na secao TODO do TASK_BOARD
   - Bug CRITICO/ALTO: REMOVA a linha da tarefa original da secao DONE, ADICIONE na secao TODO
   - Bug MEDIO/BAIXO: REMOVA a linha da tarefa original da secao DONE, ADICIONE na secao VERIFIED (fix e tarefa separada)
   - CONFIRME que cada tarefa aparece em UMA UNICA secao apos movimentacao
7. Registre resultados em PROGRESS.md

Siga seu protocolo completo.
")
```

Se nao ha tarefas DONE: pule este passo.

### PASSO 5 — Reportar progresso da iteracao

Releia o TASK_BOARD atualizado e exiba:

```
📊 Resultado da iteracao {N}:
  Tarefas executadas: {lista de IDs do passo 3}
  QA aprovadas:       {lista de IDs verificados}
  Bugs encontrados:   {N} ({lista de FIX-* criados, se houver})
  Progresso:          {VERIFIED}/{TOTAL} ({%}%)
  [████████░░░░░░░░░░░░] {%}%
```

### PASSO 6 — Voltar ao PASSO 1

O loop continua automaticamente. Volte ao PASSO 1 para a proxima iteracao.

Notas sobre o loop:
- Tarefas FIX-* criadas pelo QA entram no TODO e serao executadas na proxima iteracao
- Tarefas que tinham dependencias pendentes podem ficar disponiveis apos esta iteracao
- O loop so para quando TUDO esta VERIFIED ou nao ha mais trabalho possivel
- Cada iteracao faz commit para manter working directory limpo

---

## Tratamento de erros

**Conflito de codigo irresolvivel no merge:**
→ Exiba os arquivos em conflito
→ Pergunte ao usuario como resolver
→ Apos resolver, continue o loop

**Agente falhou ou retornou erro:**
→ Registre o erro em HANDOFF.md para a tarefa
→ Mova a tarefa de IN_PROGRESS de volta para TODO
→ Continue o loop (a tarefa sera retentada na proxima iteracao)

**Nenhuma tarefa disponivel mas projeto nao esta completo:**
→ Liste todas as tarefas pendentes com seus bloqueios
→ PARE e informe o usuario
