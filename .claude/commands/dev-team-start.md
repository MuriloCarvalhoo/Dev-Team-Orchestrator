# /dev-team-start

Inicia o time de desenvolvimento a partir de um PRD.

## Uso

```
/dev-team-start
/dev-team-start docs/prd.md
```

Se nenhum caminho for passado, solicite que o usuario cole o PRD diretamente no chat.

## Execucao — siga esta sequencia exatamente

### PASSO 1 — Criar estrutura do board

Verifique se `board/` existe. Se nao existir, crie a estrutura:

```bash
mkdir -p board/{todo,in_progress,done,verified,blocked}
mkdir -p docs
mkdir -p tests/{unit,integration,e2e/{specs,screenshots}}
```

Crie `docs/DECISIONS.md` se nao existir:
```markdown
# Decisoes Tecnicas

> Todos os agentes devem ler antes de implementar.
> Formato de cada decisao: DEC-{AGENT}-{N} com contexto, decisao, justificativa e alternativas descartadas.

## Stack

| Camada | Tecnologia | Versao | Decidido em | Por |
|---|---|---|---|---|
| Backend | [a definir] | - | - | - |
| Frontend | [a definir] | - | - | - |
| Banco de dados | [a definir] | - | - | - |
| Testes unitarios | [a definir] | - | - | - |
| Testes integracao | [a definir] | - | - | - |
| Testes E2E | Playwright | latest | {DATA_ATUAL} | tech-lead-agent |

## Decisoes
```

Crie `docs/PROGRESS.md` se nao existir:
```markdown
# Progress Log

> Timeline do projeto. Uma linha por evento.

- {DATA_ATUAL} | PROJETO | inicio | orchestrator | Projeto iniciado, aguardando analise do PO
```

Se `board/` ja existir (projeto retomado), leia o estado atual e pule para o PASSO 2.

### PASSO 2 — PO Agent analisa o PRD

```
Agent(subagent_type="po-agent", prompt="
Analise o PRD abaixo e crie arquivos de tarefa individuais em board/todo/.

Siga seu protocolo completo:
1. Liste board/todo/*.md para ver IDs existentes (evitar duplicatas)
2. Leia docs/DECISIONS.md para decisoes ja tomadas
3. Quebre o PRD em tarefas atomicas [BACK], [FRONT] e [DEVOPS] de 1-3h cada
4. Para cada tarefa, crie um arquivo board/todo/{ID}.md com o formato padrao:
   - Frontmatter: id, type, priority, depends_on, created, updated
   - Description, Acceptance Criteria, Context (vazio por agora), Handoff, Log, Test Results
5. Defina criterios de aceite verificaveis (incluindo visuais para FRONT)
6. Mapeie dependencias entre tarefas (campo depends_on no frontmatter)
7. Registre em docs/DECISIONS.md decisoes implicitas do PRD
8. Reporte o backlog criado

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

### PASSO 3 — Tech Lead define a stack

```
Agent(subagent_type="tech-lead-agent", prompt="
Setup inicial: o PO criou tarefas em board/todo/.

Siga seu protocolo completo:
1. Liste e leia os arquivos em board/todo/ para entender as necessidades tecnicas
2. Defina a stack tecnica completa (linguagem, framework, versoes, padroes)
3. OBRIGATORIO: inclua Playwright como ferramenta de E2E (fonte de verdade do QA)
4. Registre TODAS as decisoes em docs/DECISIONS.md com justificativa (formato DEC-TL-XXX)
5. Atualize a tabela Stack em docs/DECISIONS.md
6. Atualize a secao 'Stack do Projeto' no CLAUDE.md
")
```

### PASSO 3.5 — DevOps Agent faz scaffold do projeto

```
Agent(subagent_type="devops-agent", prompt="
Setup inicial: o Tech Lead definiu a stack em docs/DECISIONS.md.

Siga seu protocolo de scaffold:
1. Leia docs/DECISIONS.md para a stack completa
2. Crie a estrutura de pastas do projeto
3. Crie arquivos de configuracao (package.json, tsconfig, etc.)
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Crie .env.example
6. Instale dependencias base
7. Configure infraestrutura de testes:
   - Unit: Jest/Vitest ou equivalente
   - Integration: Supertest/Testing Library
   - E2E: Playwright (instalar, criar playwright.config.ts)
   - Criar diretorios: tests/unit/, tests/integration/, tests/e2e/specs/, tests/e2e/screenshots/
8. Verifique que o projeto compila/roda sem erros
9. Registre decisoes de infra em docs/DECISIONS.md
10. Adicione entrada em docs/PROGRESS.md
")
```

### PASSO 4 — PO Agent injeta contexto e valida cobertura

```
Agent(subagent_type="po-agent", prompt="
Validacao e injecao de contexto:

1. Releia docs/DECISIONS.md (agora tem a stack definida pelo Tech Lead)
2. Para CADA arquivo de tarefa em board/todo/:
   - Leia o arquivo
   - Injete na secao '## Context' as decisoes de DECISIONS.md relevantes para ESTA tarefa:
     - Tarefa BACK: stack backend, DB, ORM, padroes de API
     - Tarefa FRONT: stack frontend, design system, endpoints disponíveis
     - Tarefa DEVOPS: stack completa, infra
   - Salve o arquivo atualizado
3. Verifique se TODAS as funcionalidades do PRD tem tarefa correspondente
4. Se encontrar gap: crie a tarefa faltante em board/todo/
5. Reporte cobertura final (deve ser 100%)

PRD:
{CONTEUDO_COMPLETO_DO_PRD}
")
```

### PASSO 5 — Apresente o resultado ao usuario

Liste `board/todo/` e leia `docs/DECISIONS.md` para mostrar:

```
Dev Team iniciado com sucesso!

Backlog:
  - X tarefas [BACK] criadas
  - Y tarefas [FRONT] criadas
  - Z tarefas [DEVOPS] criadas
  - W tarefas sem dependencias (podem comecar agora)

Stack definida:
  [extrair da tabela Stack em DECISIONS.md]

Testes configurados:
  Unit: {framework}
  Integration: {framework}
  E2E: Playwright (fonte de verdade)

Estrutura do board:
  board/todo/      — {N} tarefas aguardando
  board/done/      — (vazio)
  board/verified/  — (vazio)

Proximo passo: /dev-team-next (uma tarefa) ou /dev-team-run (loop autonomo)
```
