# /dev-team-run

Executa o projeto inteiro em loop autonomo: desbloqueia tarefas, lanca devs em paralelo, roda QA com Playwright E2E, repete ate tudo em `board/verified/`.

## Uso

```
/dev-team-run
```

## Pre-requisitos

- `board/` deve existir com subpastas (rode `/dev-team-start` antes)
- Working directory limpo (sem mudancas uncommitted)

## Modelo

Todos os agentes usam **model: "opus"** via override no Agent().

---

## LOOP AUTONOMO

Execute os passos abaixo em loop. Cada iteracao executa tarefas, roda QA, e verifica completude. Continue ate a condicao de parada.

### PASSO 1 — Escanear board e desbloquear

1. Liste os arquivos em cada subpasta de `board/`:
   - `board/todo/*.md`
   - `board/in_progress/*.md`
   - `board/done/*.md`
   - `board/verified/*.md`
   - `board/blocked/*.md`

2. Para cada arquivo, leia APENAS o frontmatter (linhas entre `---`) e extraia: `id`, `type`, `priority`, `depends_on`, `assigned`.

3. Se ha tarefas em `board/blocked/`, invoque o tech-lead-agent para cada uma:

```
Agent(subagent_type="tech-lead-agent", model="opus", prompt="
Desbloqueie a tarefa em board/blocked/{ID}.md.

Leia o arquivo da tarefa (secao Handoff tem o motivo do bloqueio).
Leia docs/DECISIONS.md para contexto de decisoes existentes.

1. Tome uma decisao clara e definitiva
2. Registre em docs/DECISIONS.md (formato DEC-TL-XXX)
3. Adicione a decisao na secao Context do arquivo da tarefa
4. Mova: git mv board/blocked/{ID}.md board/todo/{ID}.md
5. Atualize frontmatter: updated: {hoje}
")
```

4. Contabilize:
   - `TODO_PRONTAS`: tarefas em `board/todo/` cujas dependencias estao em `done/` ou `verified/`
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

1. **Projeto completo**: TOTAL_VERIFIED == TOTAL_TAREFAS
   → Exiba: `Projeto completo! Todas as {TOTAL} tarefas verificadas.`
   → PARE.

2. **Sem trabalho possivel**: TODO_PRONTAS == 0 E DONE_PENDENTES == 0
   → Se ha blocked/ nao resolvidas: informe quais
   → Se ha todo/ com dependencias pendentes: liste quais faltam
   → PARE.

Se nenhuma condicao de parada: continue para o PASSO 3.

### PASSO 3 — Executar tarefas em paralelo

Se TODO_PRONTAS > 0:

Identifique todas as tarefas TODO prontas (deps satisfeitas). Filtre as mutuamente independentes.

Exiba:
```
Lancando {N} tarefa(s) em paralelo (Opus 4.6):
  - {ID} [{TIPO}] — {titulo do arquivo}
  - {ID} [{TIPO}] — {titulo do arquivo}
```

Lance TODOS os agentes em uma **unica mensagem** (paralelo), cada um com `isolation: "worktree"` e `model: "opus"`:

Para tarefas [BACK]:
```
Agent(
  subagent_type="backend-agent",
  isolation="worktree",
  model="opus",
  prompt="
Execute a tarefa em board/todo/{ID}.md.

Leia o arquivo — ele contem descricao, criterios de aceite, contexto e handoff.

Siga seu protocolo:
1. Mova: git mv board/todo/{ID}.md board/in_progress/{ID}.md
2. Atualize frontmatter: assigned: backend-agent, updated: {hoje}
3. Implemente seguindo os criterios de aceite e o contexto do arquivo
4. Escreva testes unitarios em tests/unit/ e de integracao em tests/integration/
5. Rode os testes e confirme que passam
6. Preencha secao Log no arquivo (arquivos criados, testes escritos)
7. Marque checkboxes dos criterios atendidos
8. Mova: git mv board/in_progress/{ID}.md board/done/{ID}.md
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
Execute a tarefa em board/todo/{ID}.md.

Leia o arquivo — ele contem descricao, criterios de aceite, contexto e handoff.

Siga seu protocolo:
1. Mova: git mv board/todo/{ID}.md board/in_progress/{ID}.md
2. Atualize frontmatter: assigned: frontend-agent, updated: {hoje}
3. Implemente seguindo os criterios de aceite e o contexto do arquivo
4. Escreva testes unitarios em tests/unit/ e de integracao em tests/integration/
5. Rode os testes e confirme que passam
6. Preencha secao Log no arquivo (componentes criados, testes escritos)
7. Marque checkboxes dos criterios atendidos
8. Mova: git mv board/in_progress/{ID}.md board/done/{ID}.md
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
Execute a tarefa em board/todo/{ID}.md.

Leia o arquivo — ele contem descricao, criterios de aceite, contexto e handoff.

Siga seu protocolo:
1. Mova: git mv board/todo/{ID}.md board/in_progress/{ID}.md
2. Atualize frontmatter: assigned: devops-agent, updated: {hoje}
3. Implemente seguindo os criterios de aceite e o contexto do arquivo
4. Preencha secao Log no arquivo
5. Mova: git mv board/in_progress/{ID}.md board/done/{ID}.md
"
)
```

**Apos todos os agentes concluirem**, faca o merge dos worktrees:

1. Para cada worktree com mudancas:
   a. Tente merge automatico
   b. Cada agente editou arquivos diferentes em `board/` — conflito improvavel
   c. Se conflito em `docs/DECISIONS.md`: append-only, concatene entradas
   d. Se conflito em codigo fonte: tente resolver automaticamente; se impossivel, reporte e PARE

2. Faca commit das mudancas mergeadas para manter o working directory limpo.

Se TODO_PRONTAS == 0 (apenas DONE pendentes), pule este passo e va direto ao PASSO 4.

### PASSO 4 — QA nas tarefas concluidas

Reliste `board/done/*.md`.

Se ha tarefas em `done/`:

Exiba:
```
Rodando QA em {N} tarefa(s) (Opus 4.6):
  - {ID} — {titulo}
```

Para cada tarefa DONE, invoque o QA:

```
Agent(subagent_type="qa-agent", model="opus", prompt="
Valide a tarefa em board/done/{ID}.md.

Leia o arquivo — ele contem criterios de aceite e log (arquivos modificados, testes escritos).

Siga seu protocolo:
1. Rode testes unitarios existentes — se falha, mova para board/todo/
2. Rode testes de integracao — se falha, mova para board/todo/
3. Escreva teste E2E com Playwright em tests/e2e/specs/{ID}.spec.ts
   - Um cenario por criterio de aceite
   - Tire screenshot de cada: tests/e2e/screenshots/{ID}/{nome}.png
4. Rode o E2E: npx playwright test tests/e2e/specs/{ID}.spec.ts
5. Analise screenshots — cada criterio atendido?
6. Se APROVADA:
   - Preencha secao Test Results no arquivo
   - Mova: git mv board/done/{ID}.md board/verified/{ID}.md
7. Se BUG ENCONTRADO:
   - Crie board/todo/FIX-{TYPE}-{N}.md com bug report e screenshot
   - Bug CRITICO/ALTO: git mv board/done/{ID}.md board/todo/{ID}.md
   - Bug MEDIO/BAIXO: git mv board/done/{ID}.md board/verified/{ID}.md
")
```

Se nao ha tarefas em `done/`: pule este passo.

### PASSO 5 — Reportar progresso

Reliste `board/*/` e exiba:

```
Resultado da iteracao {N}:
  Tarefas executadas: {IDs do passo 3}
  QA aprovadas:       {IDs verificados}
  Bugs encontrados:   {N} ({IDs de FIX-* criados})
  Progresso:          {VERIFIED}/{TOTAL} ({%}%)
  [====================] {%}%
```

### PASSO 6 — Voltar ao PASSO 1

O loop continua automaticamente.

Notas:
- Tarefas FIX-* criadas pelo QA entram em `board/todo/` e serao executadas na proxima iteracao
- Tarefas cujas dependencias foram satisfeitas ficam disponiveis na proxima iteracao
- O loop so para quando TUDO esta em `verified/` ou nao ha trabalho possivel
- Cada iteracao faz commit para manter working directory limpo

---

## Tratamento de erros

**Conflito de codigo irresolvivel no merge:**
→ Exiba os arquivos em conflito
→ Pergunte ao usuario como resolver
→ Apos resolver, continue o loop

**Agente falhou ou retornou erro:**
→ Preencha Handoff no arquivo da tarefa com o erro
→ Mova o arquivo de volta para `board/todo/`
→ Continue o loop (retentada na proxima iteracao)

**Nenhuma tarefa disponivel mas projeto nao completo:**
→ Liste todas as tarefas pendentes com seus bloqueios/dependencias
→ PARE e informe o usuario
