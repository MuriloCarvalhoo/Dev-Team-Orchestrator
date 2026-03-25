# /dev-team-status

Exibe um snapshot completo do estado atual do projeto.

## Uso

```
/dev-team-status
```

## Execução

Leia os 4 docs compartilhados em `docs/project-state/` e exiba o relatório abaixo.
Não invoque nenhum agente — apenas leia e formate as informações.

## Formato do relatório

```
📊 STATUS DO PROJETO — {DATA E HORA}
═══════════════════════════════════════════

📋 TODO:         {N} tarefas ({X} disponíveis agora, {Y} aguardando dependências)
🔄 IN_PROGRESS:  {N} tarefas
✅ DONE:         {N} tarefas (aguardando QA)
✔️  VERIFIED:     {N} tarefas
🚫 BLOCKED:      {N} tarefas
🔧 FIX PENDENTES: {N} ({W} críticos, {X} altos)

─── EM ANDAMENTO ──────────────────────────
{se houver}
• {ID}: {descrição} (iniciado em {data})
{se vazio}
• Nenhuma tarefa em andamento

─── PRÓXIMAS DISPONÍVEIS ──────────────────
{tarefas TODO cujas dependências estão DONE/VERIFIED, em ordem de prioridade}
1. {ID} [{BACK|FRONT}] [{prioridade}]: {descrição}
2. {ID} [{BACK|FRONT}] [{prioridade}]: {descrição}
{se vazio}
• Nenhuma tarefa disponível — todas aguardam dependências

─── BLOQUEADAS ────────────────────────────
{se houver}
• {ID}: {motivo do bloqueio}
{se vazio}
• Nenhuma tarefa bloqueada

─── TAREFAS DE FIX PENDENTES ──────────────
{tarefas FIX-* no TODO ou IN_PROGRESS}
• FIX-{TIPO}-{N} [{severidade}]: {título} (fix para: {ID original})
{se vazio}
• Nenhuma correção pendente

─── STACK ─────────────────────────────────
{extrair da tabela Stack em DECISIONS.md}
Backend:  {tecnologia} {versão}
Frontend: {tecnologia} {versão}
Banco:    {tecnologia} {versão}
Testes:   {tecnologia} {versão}

─── PROGRESSO GERAL ───────────────────────
VERIFIED: {N} de {TOTAL} tarefas ({%}%)
[████████░░░░░░░░░░░░] {%}%

─── ÚLTIMA ATIVIDADE ──────────────────────
{primeiras 3 entradas de PROGRESS.md — data e descrição curta}
```

## Sugestão de próximo passo

Baseado no estado atual, sugira o comando mais útil — apenas um:

| Situação | Sugestão |
|---|---|
| Tarefas TODO disponíveis | `/dev-team-next` |
| Tarefas DONE sem QA | `/dev-team-review` (mencione quantas) |
| Apenas BLOCKED e sem TODO disponível | Invocar `tech-lead-agent` diretamente |
| IN_PROGRESS iniciada há muito tempo (>1 dia) | `/dev-team-next {ID}` para retomar via HANDOFF |
| Tudo VERIFIED | "🎉 Sprint completo! Todos os critérios de aceite verificados." |
| FIX CRÍTICO pendente | `/dev-team-next` para corrigir o fix crítico primeiro |
