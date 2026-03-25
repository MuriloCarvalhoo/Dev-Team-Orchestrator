# Dev Team Orchestrator

Um time de agentes Claude Code que implementa sistemas a partir de PRDs, com estado compartilhado e handoff entre agentes.

## Arquitetura

```
Usuário
  |
  |-- /dev-team-start        -- PO Agent (opus)        -> cria TASK_BOARD
  |                          -- Tech Lead Agent (opus)  -> define stack em DECISIONS.md
  |                          -- DevOps Agent (sonnet)   -> scaffold do projeto
  |                          -- PO Agent (opus)         -> valida cobertura PRD
  |
  |-- /dev-team-next         -- Backend Agent (sonnet)  -> implementa [BACK]
  |                          -- Frontend Agent (sonnet) -> implementa [FRONT]
  |                          -- DevOps Agent (sonnet)   -> implementa [DEVOPS]
  |                          -- Tech Lead Agent (opus)  -> auto-desbloqueio de BLOCKED
  |
  |-- /dev-team-next-parallel -- Mesmo que /dev-team-next, mas lanca agentes
  |                             independentes em paralelo via worktrees
  |
  |-- /dev-team-review       -- QA Agent (sonnet)       -> valida DONE -> VERIFIED
  |
  +-- /dev-team-status       (sem agente -- le docs direto)
```

### Padrao: Command -> Agent -> Skill

Cada **command** (`/dev-team-*`) orquestra a execucao, selecionando qual **agent** invocar.
Cada **agent** tem duas **skills** pre-carregadas em seu contexto:
- `shared-docs-reader` -- le o estado antes de agir
- `task-updater` -- atualiza o estado ao concluir

### Docs compartilhados

```
docs/project-state/
  TASK_BOARD.md   <- kanban: TODO -> IN_PROGRESS -> DONE -> VERIFIED
  DECISIONS.md    <- stack, padroes, contratos de API, decisoes arquiteturais
  HANDOFF.md      <- contexto de tarefas interrompidas para retomada
  PROGRESS.md     <- log cronologico do que foi implementado
```

Estes 4 arquivos sao o **unico estado compartilhado** entre agentes. Cada agente le ao comecar e atualiza ao terminar.

## Instalacao

1. Copie a pasta `.claude/` para a raiz do seu projeto
2. Copie o `CLAUDE.md` para a raiz do seu projeto
3. O Claude Code carrega automaticamente `.claude/agents/`, `.claude/commands/` e `.claude/skills/`

```
seu-projeto/
  .claude/
    agents/
      po-agent.md
      tech-lead-agent.md
      backend-agent.md
      frontend-agent.md
      qa-agent.md
      devops-agent.md
    commands/
      dev-team-start.md
      dev-team-next.md
      dev-team-next-parallel.md
      dev-team-review.md
      dev-team-status.md
    skills/
      shared-docs-reader/SKILL.md
      task-updater/SKILL.md
    settings.json
  CLAUDE.md
  docs/              <- criado automaticamente pelo /dev-team-start
    project-state/
      TASK_BOARD.md
      DECISIONS.md
      HANDOFF.md
      PROGRESS.md
  tests/             <- testes de integridade do orchestrator
    test-doc-structure.sh
```

## Uso

### Fluxo completo

```bash
# 1. Iniciar com um PRD
/dev-team-start docs/prd.md
# -- PO Agent cria o backlog
# -- Tech Lead define a stack
# -- DevOps Agent faz scaffold do projeto
# -- PO Agent valida cobertura do PRD

# 2. Executar tarefas (repita ate o board estar cheio de DONE)
/dev-team-next              # escolhe automaticamente (BACK antes de FRONT)
/dev-team-next BACK         # forca backend
/dev-team-next FRONT        # forca frontend
/dev-team-next DEVOPS       # forca devops
/dev-team-next BACK-003     # tarefa especifica

# 2b. Executar tarefas independentes em paralelo
/dev-team-next-parallel     # detecta e executa tarefas independentes simultaneamente

# 3. Revisar qualidade
/dev-team-review            # QA valida todas as tarefas DONE

# 4. Ver estado atual a qualquer momento
/dev-team-status
```

### Fluxo de estado de uma tarefa

```
TODO -> IN_PROGRESS -> DONE -> VERIFIED
         |                    ^
         +-- BLOCKED --+------+
                       |
                       v (auto-desbloqueio via tech-lead-agent)
                     TODO

Bugs: QA cria tarefa FIX-XXX [BACK|FRONT] diretamente no TODO
```

## Agentes

| Agente | Modelo | Quando invocar |
|---|---|---|
| `po-agent` | opus | PRD fornecido, backlog vazio ou precisa de novas tarefas |
| `tech-lead-agent` | opus | Stack indefinida, tarefa BLOCKED, conflito tecnico |
| `backend-agent` | sonnet | Tarefa [BACK] disponivel no TASK_BOARD |
| `frontend-agent` | sonnet | Tarefa [FRONT] disponivel no TASK_BOARD |
| `devops-agent` | sonnet | Setup de projeto, CI/CD, Docker, infra |
| `qa-agent` | sonnet | Tarefas com status DONE no TASK_BOARD |

## Boas praticas

**Para o usuario:**
- Execute `/dev-team-status` antes de qualquer `/dev-team-next` para ter contexto
- Use `/dev-team-next-parallel` quando quiser acelerar tarefas independentes
- Se um agente ficou travado, use `/dev-team-next {ID}` para forcar retomada via HANDOFF

**Para tarefas bloqueadas:**
- O `/dev-team-next` agora invoca o tech-lead-agent automaticamente para tentar desbloquear
- Se o auto-desbloqueio falhar, o usuario e notificado com o motivo

**Para retomar projeto existente:**
```
/dev-team-start
# Vai detectar que docs/project-state/ ja existe e pular a criacao
/dev-team-status
# Ver onde parou
/dev-team-next
# Continuar de onde estava
```

## Limitacoes conhecidas

- Subagentes nao podem invocar outros subagentes via bash -- apenas via `Agent()`
- Cada agente tem seu proprio contexto window -- nao compartilham memoria de conversa
- O estado compartilhado via arquivos e a unica forma de persistencia entre agentes
- Para projetos muito grandes (>50 tarefas), considere dividir em multiplos sprints
- Execucao paralela (`/dev-team-next-parallel`) usa worktrees -- requer git limpo

---

## Plano de Evolucao v2 (sessao 2026-03-24)

> Este plano documenta as decisoes e tarefas para corrigir os 12 pontos negativos
> identificados na auditoria do repositorio. Persiste aqui para manter contexto entre sessoes.

### Decisoes tomadas

| # | Problema | Decisao | Fase |
|---|---|---|---|
| 1 | Permissoes Write em settings.json bloqueiam escrita de codigo | Expandir para permitir escrita em todo o projeto | F1 |
| 2 | Permissoes Bash muito restritivas (faltam npm install, node, mkdir) | Adicionar comandos essenciais de desenvolvimento | F1 |
| 3 | task-updater skill faltando no PO e Tech Lead | Adicionar skill a ambos os agentes | F1 |
| 4 | Sem execucao paralela de tarefas independentes | Novo comando `/dev-team-next-parallel` | F4 |
| 5 | Sem validacao de cobertura PRD apos PO criar tarefas | Novo PASSO 4 no `/dev-team-start` (PO re-valida) | F2 |
| 6 | Sem agente DevOps/Infra para setup de projeto | Novo `devops-agent` | F2 |
| 7 | Race condition nos docs compartilhados com execucao paralela | Worktree isolation + merge ao final | F4 |
| 8 | Ciclo de bugs incompleto (BUG-XXX sem status RESOLVIDO) | Bugs viram tarefas FIX-XXX diretamente, eliminar secao BUGS separada | F3 |
| 9 | Sem comunicacao inter-agente (agente nao pode perguntar ao PO) | Reutilizar mecanismo BLOCKED + auto-desbloqueio pelo tech-lead | F3 |
| 10 | Sem auto-desbloqueio (usuario precisa intermediar manualmente) | Tech Lead invocado automaticamente no `/dev-team-next` | F3 |
| 11 | Sem bootstrap/scaffold de projeto no inicio | devops-agent roda como passo 3.5 no `/dev-team-start` | F2 |
| 12 | Sem testes do proprio orchestrator | Testes de integracao com dry-run validando docs e fluxo | F5 |

### Fase 1 -- Critico (desbloqueia fluxo autonomo)

**Objetivo**: Permitir que os agentes de implementacao funcionem sem pedir aprovacao a cada arquivo.

#### Tarefa 1.1: Corrigir settings.json

**Arquivo**: `.claude/settings.json`

Permissoes atuais (quebradas):
```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Write(docs/project-state/**)",
      "Edit(docs/project-state/**)",
      "Bash(npm test)",
      "Bash(npm run test*)",
      "Bash(pytest*)",
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(find*)"
    ]
  }
}
```

Permissoes corrigidas:
```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(pytest*)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(ls*)",
      "Bash(cat*)",
      "Bash(grep*)",
      "Bash(find*)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(git *)"
    ],
    "deny": []
  }
}
```

**Racional**: Write(*) e Edit(*) sao necessarios porque agentes criam codigo em qualquer lugar do projeto. Bash expandido para cobrir o ciclo completo de desenvolvimento.

#### Tarefa 1.2: Adicionar task-updater ao PO e Tech Lead

**Arquivos**: `.claude/agents/po-agent.md`, `.claude/agents/tech-lead-agent.md`

Mudanca no frontmatter de ambos:
```yaml
skills:
  - shared-docs-reader
  - task-updater          # ADICIONAR
```

**Racional**: Ambos escrevem em docs compartilhados (TASK_BOARD, DECISIONS). Sem o task-updater, usam formato ad-hoc que pode divergir do padrao esperado pelos outros agentes.

### Fase 2 -- Novo agente + Bootstrap

**Objetivo**: Garantir que o projeto tenha scaffold tecnico e cobertura funcional completa desde o inicio.

#### Tarefa 2.1: Criar devops-agent

**Arquivo**: `.claude/agents/devops-agent.md` (NOVO)

Frontmatter:
```yaml
name: devops-agent
description: DevOps Engineer. Use para setup de projeto, scaffold de estrutura, configs, Docker, CI/CD. Invocado automaticamente no /dev-team-start e para tarefas [DEVOPS].
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
color: orange
permissionMode: acceptEdits
memory: project
skills:
  - shared-docs-reader
  - task-updater
```

Responsabilidades:
- Scaffold do projeto (pastas, package.json/requirements.txt, configs)
- Dockerfile, docker-compose
- CI/CD (GitHub Actions, etc.)
- Variaiveis de ambiente (.env.example)
- Scripts de setup (dev, build, test)

#### Tarefa 2.2: Adicionar PASSO 3.5 ao /dev-team-start

**Arquivo**: `.claude/commands/dev-team-start.md`

Apos Tech Lead definir stack (PASSO 3), inserir:

```
### PASSO 3.5 -- DevOps Agent faz scaffold do projeto

Agent(subagent_type="devops-agent", prompt="
Setup inicial: o Tech Lead definiu a stack em DECISIONS.md.

Siga seu protocolo:
1. Leia DECISIONS.md para saber a stack completa (linguagens, frameworks, versoes)
2. Crie a estrutura de pastas do projeto
3. Crie arquivos de configuracao (package.json, tsconfig, requirements.txt, etc.)
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Crie .env.example com variaveis necessarias
6. Crie Dockerfile basico se aplicavel
7. Registre em DECISIONS.md as decisoes de infra tomadas (formato DEC-XXX)
8. Adicione entrada em PROGRESS.md
")
```

#### Tarefa 2.3: Adicionar PASSO 4 ao /dev-team-start (validacao PRD)

**Arquivo**: `.claude/commands/dev-team-start.md`

Apos scaffold, inserir:

```
### PASSO 4 -- PO Agent valida cobertura do PRD

Agent(subagent_type="po-agent", prompt="
Validacao de cobertura: verifique se TODAS as funcionalidades do PRD
tem pelo menos uma tarefa correspondente no TASK_BOARD.

1. Releia o PRD completo
2. Para cada requisito/funcionalidade, verifique se existe tarefa que o cobre
3. Se encontrar gap: crie a tarefa faltante no TASK_BOARD
4. Reporte:
   - Total de requisitos do PRD
   - Total cobertos por tarefas
   - Gaps encontrados e tarefas criadas para cobri-los
   - Cobertura final (deve ser 100%)

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

Renumerar PASSO 4 atual (apresentacao) para PASSO 5.

### Fase 3 -- Fluxo aprimorado

**Objetivo**: Melhorar autonomia e reducir intervencao manual do usuario.

#### Tarefa 3.1: Auto-desbloqueio no /dev-team-next

**Arquivo**: `.claude/commands/dev-team-next.md`

Adicionar logica antes da selecao de tarefa:

```markdown
## Auto-desbloqueio

Antes de selecionar a tarefa, verifique se ha tarefas BLOCKED no TASK_BOARD.
Se houver:

1. Para cada tarefa BLOCKED, invoque o tech-lead-agent:

Agent(subagent_type="tech-lead-agent", prompt="
Desbloqueie a tarefa {ID}.
Motivo do bloqueio: {MOTIVO_DO_TASK_BOARD}

Tome uma decisao definitiva:
1. Registre a decisao em DECISIONS.md (formato DEC-XXX)
2. Mova a tarefa de BLOCKED para TODO no TASK_BOARD
3. Escreva orientacoes de retomada em HANDOFF.md
")

2. Apos desbloquear, continue com a selecao normal de tarefa
3. Se o tech-lead nao conseguir desbloquear (motivo externo ao projeto),
   informe o usuario: "Tarefa {ID} requer intervencao manual: {motivo}"
```

#### Tarefa 3.2: Simplificar ciclo de bugs (FIX- tasks)

**Arquivos afetados**:
- `.claude/agents/qa-agent.md` -- remover protocolo de BUG-XXX, usar FIX-XXX
- `.claude/skills/task-updater/SKILL.md` -- atualizar formato
- `.claude/commands/dev-team-start.md` -- remover secao BUGS do template TASK_BOARD
- `.claude/commands/dev-team-review.md` -- atualizar output
- `.claude/commands/dev-team-status.md` -- atualizar output

Novo protocolo do QA ao encontrar bug:
```markdown
## Ao encontrar um bug

Crie uma tarefa de correcao diretamente na secao TODO do TASK_BOARD:

| FIX-BACK-XXX | Corrigir: {descricao do bug} | [BACK] | ALTA | {tarefa original} | {criterios para considerar corrigido} |

Convencao de IDs:
- FIX-BACK-XXX para bugs de backend
- FIX-FRONT-XXX para bugs de frontend

Inclua na descricao:
- Passos para reproduzir
- Comportamento esperado vs atual
- Severidade (CRITICO/ALTO/MEDIO/BAIXO)

Regras de status da tarefa original:
- Bug CRITICO ou ALTO: mova tarefa de DONE de volta para TODO
- Bug MEDIO ou BAIXO: mova tarefa para VERIFIED, fix e tarefa separada
```

#### Tarefa 3.3: Atualizar protocolos de comunicacao inter-agente

**Arquivos**: `.claude/agents/backend-agent.md`, `.claude/agents/frontend-agent.md`

Adicionar secao em ambos os agentes:

```markdown
## Quando tiver duvida ou ambiguidade

Se encontrar requisito ambiguo, decisao tecnica faltando, ou qualquer bloqueio:
1. Mova a tarefa para BLOCKED no TASK_BOARD
2. No motivo do bloqueio, escreva a PERGUNTA clara que precisa ser respondida
   Ex: "Qual formato de autenticacao usar? JWT ou session-based? PRD nao especifica."
3. O /dev-team-next invocara o tech-lead-agent automaticamente para responder
4. A resposta sera registrada em DECISIONS.md e a tarefa voltara para TODO
```

### Fase 4 -- Execucao paralela

**Objetivo**: Permitir execucao simultanea de tarefas independentes com isolamento seguro.

#### Tarefa 4.1: Criar /dev-team-next-parallel

**Arquivo**: `.claude/commands/dev-team-next-parallel.md` (NOVO)

```markdown
# /dev-team-next-parallel

Executa multiplas tarefas independentes em paralelo usando git worktrees.

## Uso

/dev-team-next-parallel

## Logica de selecao

1. Leia TASK_BOARD.md
2. Identifique TODAS as tarefas TODO cujas dependencias estao DONE/VERIFIED
3. Filtre apenas tarefas que NAO dependem umas das outras (independentes)
4. Se <= 1 tarefa disponivel: sugira /dev-team-next em vez deste comando

## Execucao

Para cada tarefa independente, lance um agente com isolation: "worktree":

Agent(
  subagent_type="{backend-agent|frontend-agent|devops-agent}",
  isolation="worktree",
  prompt="Execute a tarefa {ID}. {PROMPT_COMPLETO}"
)

Lance TODOS os agentes em uma unica mensagem (paralelo).

## Pos-execucao: merge dos worktrees

Apos todos os agentes concluirem:
1. Verifique se houve conflitos nos docs compartilhados
2. Para cada worktree com mudancas:
   a. Se nao ha conflito: merge automatico
   b. Se ha conflito em docs/project-state/: merge manual das secoes
      (cada agente editou secoes diferentes -- concatenar entradas)
   c. Se ha conflito em codigo: reportar ao usuario
3. Apresente resultado consolidado
```

#### Tarefa 4.2: Worktree isolation e merge de docs

A logica de merge de docs compartilhados:
- TASK_BOARD: cada agente edita linhas diferentes (seu proprio ID) -- merge por secao
- PROGRESS: cada agente adiciona no topo -- concatenar entradas com datas
- DECISIONS: cada agente adiciona DEC-XXX incrementais -- concatenar
- HANDOFF: cada agente limpa sua propria entrada -- merge direto

### Fase 5 -- Testes

**Objetivo**: Garantir integridade dos artefatos do orchestrator.

#### Tarefa 5.1: Criar testes de integracao

**Arquivo**: `tests/test-doc-structure.sh` (NOVO)

Testes a implementar:
1. **Estrutura de TASK_BOARD**: todas as secoes obrigatorias existem (TODO, IN_PROGRESS, DONE, VERIFIED, BLOCKED)
2. **IDs unicos**: nenhum ID duplicado no TASK_BOARD
3. **Dependencias validas**: todo ID referenciado em "Depende de" existe no board
4. **DECISIONS formato**: toda decisao segue formato DEC-XXX com campos obrigatorios
5. **Agentes validos**: todo arquivo em .claude/agents/ tem frontmatter com name, tools, skills
6. **Commands validos**: todo comando referencia agentes que existem
7. **Skills referenciadas existem**: skills listadas no frontmatter de agentes existem em .claude/skills/
8. **Dry-run do fluxo**: cria docs de estado, valida formato, limpa

#### Tarefa 5.2: Adicionar ao settings.json

Garantir que `Bash(bash tests/*)` esteja nas permissoes para rodar os testes.

### Impacto nos arquivos -- resumo

| Arquivo | Acao | Fase |
|---|---|---|
| `.claude/settings.json` | REESCREVER permissoes | F1 |
| `.claude/agents/po-agent.md` | EDITAR frontmatter (add task-updater) | F1 |
| `.claude/agents/tech-lead-agent.md` | EDITAR frontmatter (add task-updater) | F1 |
| `.claude/agents/devops-agent.md` | CRIAR | F2 |
| `.claude/commands/dev-team-start.md` | EDITAR (add passos 3.5 e 4) | F2 |
| `.claude/agents/qa-agent.md` | EDITAR (FIX- protocol) | F3 |
| `.claude/agents/backend-agent.md` | EDITAR (add comunicacao via BLOCKED) | F3 |
| `.claude/agents/frontend-agent.md` | EDITAR (add comunicacao via BLOCKED) | F3 |
| `.claude/commands/dev-team-next.md` | EDITAR (add auto-desbloqueio) | F3 |
| `.claude/commands/dev-team-review.md` | EDITAR (FIX- output) | F3 |
| `.claude/commands/dev-team-status.md` | EDITAR (FIX- output) | F3 |
| `.claude/skills/task-updater/SKILL.md` | EDITAR (FIX- format) | F3 |
| `.claude/commands/dev-team-next-parallel.md` | CRIAR | F4 |
| `tests/test-doc-structure.sh` | CRIAR | F5 |
| `CLAUDE.md` | EDITAR (add devops-agent, novo comando) | F2 |
| `README.md` | ESTE DOCUMENTO | -- |

### Sequencia de execucao recomendada

```
Fase 1 (sem dependencias -- comecar por aqui)
  |
  v
Fase 2 (depende de F1 para permissoes funcionarem)
  |
  v
Fase 3 (depende de F2 para devops-agent existir no ecosystem)
  |
  v
Fase 4 (depende de F3 para auto-desbloqueio + FIX- funcionar no paralelo)
  |
  v
Fase 5 (depende de tudo acima estar implementado para testar)
```

### Checklist de conclusao

- [ ] F1: settings.json corrigido
- [ ] F1: task-updater adicionado ao PO e Tech Lead
- [ ] F2: devops-agent criado
- [ ] F2: /dev-team-start com passos 3.5 e 4
- [ ] F3: auto-desbloqueio implementado no /dev-team-next
- [ ] F3: protocolo FIX- implementado (QA, task-updater, commands)
- [ ] F3: comunicacao inter-agente via BLOCKED documentada
- [ ] F4: /dev-team-next-parallel criado
- [ ] F4: worktree isolation + merge funcionando
- [ ] F5: testes de integracao criados e passando
- [ ] CLAUDE.md atualizado com novos agentes e comandos
