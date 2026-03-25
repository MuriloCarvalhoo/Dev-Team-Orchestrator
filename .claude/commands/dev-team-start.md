# /dev-team-start

Inicia o time de desenvolvimento a partir de um PRD.

## Uso

```
/dev-team-start
/dev-team-start docs/prd.md
```

Se nenhum caminho for passado, solicite que o usuário cole o PRD diretamente no chat.

## Execução — siga esta sequência exatamente

### PASSO 1 — Criar documentos compartilhados

Verifique se `docs/project-state/` existe. Se não existir, crie os 4 arquivos abaixo.
Se já existirem (projeto retomado), leia-os e pule para o PASSO 2.

**`docs/project-state/TASK_BOARD.md`:**
```markdown
# Task Board

> Última atualização: {DATA_ATUAL}
> Sprint: 1

## 📋 TODO

| ID | Descrição | Tipo | Prioridade | Depende de | Critérios de Aceite |
|---|---|---|---|---|---|

## 🔄 IN_PROGRESS

| ID | Descrição | Tipo | Agente | Iniciado em |
|---|---|---|---|---|

## ✅ DONE

| ID | Descrição | Tipo | Concluído em |
|---|---|---|---|

## ✔️ VERIFIED

| ID | Descrição | Tipo | Verificado em |
|---|---|---|---|

## 🚫 BLOCKED

| ID | Descrição | Motivo do Bloqueio |
|---|---|---|

```

**`docs/project-state/DECISIONS.md`:**
```markdown
# Decisões Técnicas

> Todos os agentes devem ler antes de implementar.
> Formato de cada decisão: DEC-XXX com contexto, decisão, justificativa e alternativas descartadas.

## Stack

| Camada | Tecnologia | Versão | Decidido em | Por |
|---|---|---|---|---|
| Backend | [a definir] | - | - | - |
| Frontend | [a definir] | - | - | - |
| Banco de dados | [a definir] | - | - | - |
| Testes | [a definir] | - | - | - |

## Decisões
```

**`docs/project-state/HANDOFF.md`:**
```markdown
# Handoff — Contexto de Retomada

> Preenchido quando uma tarefa é interrompida no meio.
> Limpo quando a tarefa é concluída.

(vazio no início)
```

**`docs/project-state/PROGRESS.md`:**
```markdown
# Progress Log

> Registro cronológico reverso do que foi implementado.
> Usado pelo QA para saber o que testar e onde.

## {DATA_ATUAL} — Projeto iniciado
- PRD recebido, aguardando análise do PO Agent
```

### PASSO 2 — PO Agent analisa o PRD

```
Agent(subagent_type="po-agent", prompt="
Analise o PRD abaixo e crie todas as tarefas no TASK_BOARD.

Siga seu protocolo completo:
1. Leia o TASK_BOARD e DECISIONS existentes para não criar IDs duplicados
2. Quebre o PRD em tarefas atômicas [BACK], [FRONT] e [DEVOPS] de 1-3h cada
3. Defina critérios de aceite verificáveis para cada tarefa
4. Mapeie dependências entre tarefas
5. Registre em DECISIONS.md as decisões que o PRD implica
6. Reporte o backlog criado

PRD:
{CONTEÚDO_COMPLETO_DO_PRD}
")
```

### PASSO 3 — Tech Lead define a stack

```
Agent(subagent_type="tech-lead-agent", prompt="
Setup inicial: o PO criou as tarefas no TASK_BOARD.

Siga seu protocolo completo:
1. Leia o TASK_BOARD com as tarefas criadas
2. Defina a stack técnica completa (linguagem, framework, versões, padrões)
3. Registre TODAS as decisões em DECISIONS.md com justificativa (formato DEC-XXX)
4. Atualize a seção 'Stack do Projeto' no CLAUDE.md com as tecnologias escolhidas
5. Verifique se alguma tarefa precisa de esclarecimento e registre em DECISIONS.md
")
```

### PASSO 3.5 — DevOps Agent faz scaffold do projeto

```
Agent(subagent_type="devops-agent", prompt="
Setup inicial: o Tech Lead definiu a stack em DECISIONS.md.

Siga seu protocolo de scaffold:
1. Leia DECISIONS.md para saber a stack completa (linguagens, frameworks, versões)
2. Crie a estrutura de pastas do projeto
3. Crie arquivos de configuração (package.json, tsconfig, requirements.txt, etc.)
4. Crie scripts de desenvolvimento (dev, build, test, lint)
5. Crie .env.example com variáveis necessárias
6. Instale dependências base
7. Verifique que o projeto compila/roda sem erros
8. Registre decisões de infra em DECISIONS.md (formato DEC-XXX)
9. Adicione entrada em PROGRESS.md
")
```

### PASSO 4 — PO Agent valida cobertura do PRD

```
Agent(subagent_type="po-agent", prompt="
Validação de cobertura: verifique se TODAS as funcionalidades do PRD têm pelo menos uma tarefa correspondente no TASK_BOARD.

1. Releia o PRD completo
2. Para cada requisito/funcionalidade, verifique se existe tarefa que o cobre
3. Se encontrar gap: crie a tarefa faltante no TASK_BOARD
4. Reporte:
   - Total de requisitos do PRD
   - Total cobertos por tarefas
   - Gaps encontrados e tarefas criadas para cobri-los
   - Cobertura final (deve ser 100%)

PRD:
{CONTEÚDO_COMPLETO_DO_PRD}
")
```

### PASSO 5 — Apresente o resultado ao usuário

Leia os docs criados e mostre:

```
✅ Dev Team iniciado com sucesso!

📋 Backlog:
  • X tarefas [BACK] criadas
  • Y tarefas [FRONT] criadas
  • Z tarefas sem dependências (podem começar agora)

🔧 Stack definida:
  [extrair da seção Stack em DECISIONS.md]

📌 Sequência recomendada:
  1. [ID] — [descrição] (sem dependências)
  2. [ID] — [descrição] (depende de: [IDs])
  ...

▶️  Próximo passo: /dev-team-next
```
