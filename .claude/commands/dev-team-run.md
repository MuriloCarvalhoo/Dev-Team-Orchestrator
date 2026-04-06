# /dev-team-run

Executa o projeto inteiro em loop autonomo: desbloqueia tarefas, lanca devs em paralelo em **worktrees isolados**, roda QA com Playwright E2E em `main`, repete ate tudo em `board/verified/`.

## Uso

```
/dev-team-run
```

## Pre-requisitos

- `board/` deve existir com subpastas (rode `/dev-team-start` antes)
- Working directory limpo (sem mudancas uncommitted) no branch `main`
- `.gitattributes` deve conter `merge=union` para `docs/DECISIONS.md` e `docs/PROGRESS.md` (criado pelo `devops-agent` no scaffold)

## Modelo

Todos os agentes usam **model: "opus"** via override no Agent().

## Parametros do loop

- **MAX_PARALLEL** = 3 (default — teto de worktrees simultaneos para evitar explosao de conflitos e exaustao de recursos)
- **MAX_FIX_CYCLES** = 3 por tarefa original (circuit breaker — ver PASSO 4)

---

## Modelo mental: worktrees + main

- **O board e fonte unica e mora SEMPRE no `main`**. `board-scanner` e `/dev-team-status` leem do `main`, nunca agregam worktrees ativos.
- Cada tarefa paralela roda em um `git worktree` isolado, em branch `task/{ID}` criado a partir do `main` atual.
- Dev agent trabalha 100% dentro do worktree: implementa codigo, roda unit/integration, faz `git mv` do arquivo da tarefa.
- Ao finalizar, o agente faz `git fetch && git rebase main`, resolve conflitos, **squash-merge** para `main`, e o worktree e removido.
- **QA opera no `main`, NUNCA em worktree.**

### Arquivos append-only (merge automatico via union driver)
- `docs/DECISIONS.md` e `docs/PROGRESS.md` usam `merge=union` em `.gitattributes` — multiplos agentes anexam linhas em paralelo sem conflito. Cada entrada em `DECISIONS.md` deve ter ID unico `DEC-{AGENT}-{NNN}`.

### Arquivos estruturais (exigem rebase + serializacao)
- `package.json`, `tsconfig.json`, `vite.config.ts` (configs)
- `docs/contracts/*.md` (fonte de verdade)
- Codigo-fonte em paths compartilhados

Conflito que o agente nao consegue resolver no rebase → mover tarefa para `board/blocked/` com `reason: merge_conflict` no Handoff. Tech Lead assume.

### Contratos sao imutaveis durante o run
Apos `/dev-team-start`, os contratos em `docs/contracts/` estao **congelados**. Se um dev descobrir que precisa alterar um contrato, mova a tarefa para `board/blocked/` com `reason: contract_change`. Tech Lead atualiza o contrato, registra `DEC-TL-XXX` e marca tarefas dependentes para re-validacao.

---

## LOOP AUTONOMO

Execute os passos abaixo em loop. Continue ate a condicao de parada.

### PASSO 1 — Escanear board e desbloquear

1. **Sempre no `main`** — confirme `git branch --show-current` retorna `main`.
2. Liste os arquivos em cada subpasta de `board/`:
   - `board/todo/*.md`, `board/in_progress/*.md`, `board/done/*.md`, `board/verified/*.md`, `board/blocked/*.md`
3. Para cada arquivo, leia APENAS o frontmatter e extraia: `id`, `type`, `priority`, `depends_on`, `assigned`, `has_fix`, `needs_user`, `fix_cycles`.
4. Se ha tarefas em `board/blocked/` SEM `needs_user`, invoque o tech-lead-agent para cada uma:

```
Agent(subagent_type="tech-lead-agent", model="opus", prompt="
Desbloqueie a tarefa em board/blocked/{ID}.md.

Leia o arquivo (Handoff tem o motivo: merge_conflict, contract_change, ou outro).
Leia docs/DECISIONS.md.

1. Tome decisao definitiva (atualizar contrato? mudar approach? etc.)
2. Registre em docs/DECISIONS.md (DEC-TL-XXX)
3. Adicione a decisao na secao Context da tarefa
4. Se foi contract_change: atualize docs/contracts/{slug}.md e marque tarefas dependentes para re-validacao
5. Mova: git mv board/blocked/{ID}.md board/todo/{ID}.md
6. Atualize frontmatter: updated: {hoje}
")
```

5. Tarefas em `blocked/` com `needs_user: true` ficam paradas — sao escalacao para o usuario (ver PASSO 4).

6. Contabilize:
   - `TODO_PRONTAS`: tarefas em `board/todo/` cujas dependencias estao em `done/` ou `verified/`. Ordene por `priority DESC, created ASC`.
   - `DONE_PENDENTES`: tarefas em `board/done/` aguardando QA
   - `TOTAL_VERIFIED`: tarefas em `board/verified/`
   - `TOTAL_TAREFAS`: soma de todos os arquivos em `board/*/`

### PASSO 2 — Verificar condicao de parada

Exiba resumo:
```
--- Iteracao {N} ---
TODO prontas: {X} | DONE pendentes QA: {Y} | VERIFIED: {Z}/{TOTAL}
```

**PARE o loop** se qualquer condicao for verdadeira:

1. **Projeto completo**: `TOTAL_VERIFIED == TOTAL_TAREFAS` E nao ha `FIX-*` pendente.
   → Execute o **smoke test final** (PASSO 6).
   → Exiba: `Projeto completo! Todas as {TOTAL} tarefas verificadas.`
   → PARE.

2. **Sem trabalho possivel**: `TODO_PRONTAS == 0` E `DONE_PENDENTES == 0`
   → Se ha `blocked/` com `needs_user`: liste e escale ao usuario
   → Se ha `todo/` com dependencias pendentes: liste o que falta
   → PARE.

Se nenhuma condicao de parada: continue para o PASSO 3.

### PASSO 3 — Executar tarefas em paralelo (worktrees)

Se `TODO_PRONTAS > 0`:

Selecione ate `MAX_PARALLEL` (3) tarefas mutuamente independentes da fila ordenada.

Exiba:
```
Lancando {N} tarefa(s) em paralelo (Opus 4.6, worktrees isolados):
  - {ID} [{TIPO}] — {titulo}
```

Lance TODOS os agentes em uma **unica mensagem** (paralelo). Cada Agent() usa `isolation: "worktree"` (a harness cria o worktree no branch `task/{ID}` a partir de `main`).

#### Para tarefas [BACK]:
```
Agent(
  subagent_type="backend-agent",
  isolation="worktree",
  model="opus",
  prompt="
Execute a tarefa em board/todo/{ID}.md.

Voce esta em um git worktree isolado no branch task/{ID} criado a partir de main.
TODAS as suas operacoes git acontecem dentro deste worktree. Nao saia dele.

Leia o arquivo da tarefa — descricao, criterios de aceite, contexto, handoff.
Se Context apontar docs/contracts/{slug}.md, leia o contrato — ele e fonte de verdade.
Contratos sao IMUTAVEIS durante o run. Se precisar mudar, mova para blocked/ com reason: contract_change.

Siga seu protocolo:
1. git mv board/todo/{ID}.md board/in_progress/{ID}.md
2. Atualize frontmatter: assigned: backend-agent, updated: {hoje}
3. Implemente seguindo criterios de aceite e o contrato
4. Escreva tests/unit/ + tests/integration/ e rode-os ate passar
5. Se conflito de rebase com main que voce nao consegue resolver: mova para blocked/ com reason: merge_conflict
6. Preencha Log no arquivo
7. git mv board/in_progress/{ID}.md board/done/{ID}.md
8. Commit no worktree
9. git fetch origin && git rebase main
10. Squash-merge para main: checkout main, git merge --squash task/{ID}, commit, push (ou apenas commit se local)
11. Worktree sera removido pela harness apos sucesso
"
)
```

#### Para tarefas [FRONT]:
Mesmo prompt acima, trocando `backend-agent` por `frontend-agent` e referindo `## Screen` no contrato + `docs/wireframes/{slug}.html`.

#### Para tarefas [DEVOPS]:
Mesmo prompt acima, trocando para `devops-agent`. Tarefas DEVOPS frequentemente tocam arquivos estruturais (package.json, configs) — esperam-se mais conflitos de rebase; serializar com paralelismo 1 quando possivel.

#### Apos os agentes paralelos retornarem:

1. Cada agente ja fez squash-merge no `main`. A harness removeu o worktree.
2. Append-only files (`DECISIONS.md`, `PROGRESS.md`) merged automaticamente via `merge=union` driver.
3. Estruturais: o ultimo a mergear faz rebase; se algum agente falhou no rebase, sua tarefa esta em `blocked/` (sera vista no proximo PASSO 1).
4. Confirme que o working directory de `main` esta limpo. Faca commit consolidador se necessario.

Se `TODO_PRONTAS == 0`, pule este passo e va direto ao PASSO 4.

### PASSO 4 — QA nas tarefas DONE (no main)

QA opera EXCLUSIVAMENTE no `main`, nunca em worktrees.

Reliste `board/done/*.md`.

Para cada tarefa DONE, invoque o QA (sem `isolation: worktree`):

```
Agent(subagent_type="qa-agent", model="opus", prompt="
Voce esta em main. Valide a tarefa em board/done/{ID}.md.

Leia o arquivo — criterios de aceite e Log (arquivos modificados, testes escritos).
Se Context aponta para docs/contracts/{slug}.md, leia tambem.

Siga seu protocolo:
1. Re-rode unit + integration tests do Dev. Se quebraram = bug critico.
2. Escreva tests/e2e/specs/{ID}.spec.ts (1 spec por criterio de aceite, getByRole/getByLabel, sem waitForTimeout)
3. Rode E2E com isolamento: porta aleatoria + DB schema isolado por worker
4. Capture screenshots em tests/e2e/screenshots/{ID}/{nome}.png — UM por criterio
5. Analise: cada screenshot confirma o criterio?

DECISAO:
- APROVADA (todos os criterios confirmados por screenshot, todas as camadas verdes):
  - Preencha Test Results
  - git mv board/done/{ID}.md board/verified/{ID}.md

- BUG CRITICO (qualquer um destes):
  (a) AC sem screenshot correspondente
  (b) E2E vermelho
  (c) screenshot nao confirma o AC
  (d) unit/integration quebrando em re-run
  → NAO mova a tarefa original para todo/. Faca:
    1. Crie board/todo/FIX-{ID}-{N}.md com bug report e screenshot. N = proximo numero de FIX para esta tarefa (liste board/*/FIX-{ID}-*.md)
    2. Atualize a tarefa original: frontmatter has_fix: true, fix_cycles: {atual+1}
    3. Se fix_cycles >= 3 (ja teve 3 ciclos de FIX, esta entrando no 4o): NAO crie FIX-*. Em vez disso, mova a tarefa para board/blocked/ com needs_user: true e reason: max_fix_cycles_exceeded.
    4. git mv board/done/{ID}.md board/verified/{ID}.md (com flag has_fix)
")
```

Notas sobre o **circuit breaker**:
- Cada tarefa ORIGINAL tem orcamento de **3 ciclos de FIX-***.
- O `fix_cycles` do frontmatter incrementa a cada FIX criado pelo QA.
- Na 4a falha, em vez de criar FIX-4, a tarefa vai para `blocked/` com `needs_user: true`.
- Tech Lead pode tentar desbloquear no PASSO 1 da proxima iteracao (mas tarefas com `needs_user` sao puladas — sao para escalacao ao usuario).

### PASSO 5 — Reportar progresso e voltar ao PASSO 1

Reliste `board/*/` e exiba:

```
Resultado da iteracao {N}:
  Tarefas executadas: {IDs}
  QA aprovadas:       {IDs verified}
  FIX-* criados:      {IDs}
  Escaladas usuario:  {IDs com needs_user}
  Progresso:          {VERIFIED}/{TOTAL} ({%}%)
  [====================] {%}%
```

Volte ao PASSO 1.

### PASSO 6 — Smoke test final (so quando o loop para por completude)

Apos o ultimo merge, execute UM smoke test do sistema inteiro:

1. Suba o stack completo (db + backend + frontend) em ambiente de teste isolado
2. Rode UM E2E minimo que cobre o fluxo principal ponta a ponta (login → acao critica → resultado)
3. Capture screenshot do fluxo
4. Se passar: `Projeto entregue.`
5. Se falhar: crie tarefa `FIX-SMOKE-1` em `board/todo/`, marque `needs_user: true`, escale ao usuario.

---

## Tratamento de erros

**Conflito de rebase irresolvivel pelo agente:**
→ Tarefa vai para `blocked/` com `reason: merge_conflict`. Tech Lead resolve no PASSO 1.

**Agente falhou ou retornou erro generico:**
→ Tarefa fica em `in_progress/` com Handoff preenchido. Na proxima iteracao, Tech Lead avalia.

**Tarefa com `needs_user: true`:**
→ Pulada pelo loop. Listada no PASSO 5 e na parada do PASSO 2.
