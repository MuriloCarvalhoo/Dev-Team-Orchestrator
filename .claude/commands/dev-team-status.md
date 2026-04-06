# /dev-team-status

Exibe um snapshot completo do estado atual do projeto baseado na estrutura `board/`.

## Uso

```
/dev-team-status
```

## Execucao

**Sempre leia do `main`** — `/dev-team-status` NUNCA agrega worktrees ativos. Worktrees em andamento sao invisiveis ao status; o board so e atualizado quando o agente faz squash-merge para `main`.

Liste os arquivos em cada subpasta de `board/` e leia frontmatter de cada um.
Leia `docs/DECISIONS.md` para a stack.
Leia as ultimas 5 linhas de `docs/PROGRESS.md` para atividade recente.
Nao invoque nenhum agente — apenas leia e formate.

## Formato do relatorio

```
STATUS DO PROJETO — {DATA E HORA}
=======================================

board/todo/         {N} tarefas ({X} disponiveis agora, {Y} aguardando deps)
board/in_progress/  {N} tarefas
board/done/         {N} tarefas (aguardando QA)
board/verified/     {N} tarefas
board/blocked/      {N} tarefas
FIX pendentes:      {N} ({W} criticos, {X} altos)

--- EM ANDAMENTO --------------------------
{listar arquivos em board/in_progress/ com ID e titulo}
- {ID}: {titulo} (assigned: {agent})
{se vazio}
- Nenhuma tarefa em andamento

--- PRONTAS PARA EXECUTAR -----------------
{tarefas em board/todo/ cujas deps estao em done/ ou verified/}
1. {ID} [{BACK|FRONT}] [{prioridade}]: {titulo}
2. {ID} [{BACK|FRONT}] [{prioridade}]: {titulo}
{se vazio}
- Nenhuma tarefa disponivel — todas aguardam dependencias

--- AGUARDANDO QA -------------------------
{listar arquivos em board/done/}
- {ID}: {titulo}
{se vazio}
- Nenhuma tarefa aguardando QA

--- BLOQUEADAS ----------------------------
{listar arquivos em board/blocked/ com motivo do Handoff}
- {ID}: {motivo}
{se vazio}
- Nenhuma tarefa bloqueada

--- FIX PENDENTES -------------------------
{tarefas FIX-* em board/todo/ ou board/in_progress/}
- {ID} [{severidade}]: {titulo}
{se vazio}
- Nenhuma correcao pendente

--- STACK ---------------------------------
{extrair da tabela Stack em docs/DECISIONS.md}
Backend:    {tecnologia} {versao}
Frontend:   {tecnologia} {versao}
Banco:      {tecnologia} {versao}
Unit Tests: {tecnologia}
Integration:{tecnologia}
E2E:        Playwright

--- PROGRESSO GERAL -----------------------
VERIFIED: {N} de {TOTAL} tarefas ({%}%)
[====================] {%}%

--- ULTIMA ATIVIDADE ----------------------
{ultimas 5 linhas de docs/PROGRESS.md}
```

## Sugestao de proximo passo

| Situacao | Sugestao |
|---|---|
| Tarefas em board/todo/ disponiveis | `/dev-team-run` |
| Tarefas em board/done/ | `/dev-team-run` (inclui QA automatico) |
| Apenas blocked/ com `needs_user` | Resolver manualmente e remover a flag |
| Tudo em board/verified/ sem FIX-* | "Projeto completo!" |
| FIX-* pendentes em board/todo/ | `/dev-team-run` (loop os trata como tarefas normais) |
