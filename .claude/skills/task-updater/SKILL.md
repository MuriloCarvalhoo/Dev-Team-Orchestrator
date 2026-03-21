---
name: task-updater
description: Atualiza TASK_BOARD, PROGRESS, HANDOFF e DECISIONS ao concluir, pausar ou bloquear uma tarefa. Use esta skill como último passo obrigatório de qualquer agente do time.
user-invocable: false
---

# Task Updater

Execute as atualizações abaixo em sequência ao finalizar ou interromper uma tarefa. Não pule etapas — estes docs são o único estado compartilhado entre agentes.

## 1. Atualizar TASK_BOARD.md

Abra `docs/project-state/TASK_BOARD.md` e:

**Se a tarefa foi CONCLUÍDA:**
- Remova a linha da seção `## 🔄 IN_PROGRESS`
- Adicione na seção `## ✅ DONE` com a data atual

**Se a tarefa foi BLOQUEADA:**
- Remova de `IN_PROGRESS`
- Adicione na seção `## 🚫 BLOCKED` com motivo claro e objetivo (o tech-lead-agent vai ler esse motivo)
- Formato: `| ID | Descrição | [motivo específico, não genérico] |`

**Se a tarefa foi INTERROMPIDA no meio:**
- Deixe em `IN_PROGRESS` (não mova)
- Vá para o passo 3 (HANDOFF) obrigatoriamente

**Se o QA aprovou (VERIFIED):**
- Remova de `DONE`
- Adicione em `## ✔️ VERIFIED` com a data

## 2. Atualizar PROGRESS.md

Adicione no topo de `docs/project-state/PROGRESS.md`:

```markdown
## YYYY-MM-DD — {ID_TAREFA}: {descrição curta}

**Implementado por**: {nome do agente}
**O que foi feito**:
- {item concreto 1 — seja específico}
- {item concreto 2}
**Arquivos criados/modificados**:
- `caminho/arquivo.ext` — {o que faz este arquivo}
**Notas**: {decisões tomadas, trade-offs, dívida técnica, limitações conhecidas}
```

## 3. Atualizar HANDOFF.md

**Se a tarefa foi CONCLUÍDA ou VERIFICADA:**
- Remova qualquer entrada desta tarefa de `docs/project-state/HANDOFF.md`

**Se a tarefa foi INTERROMPIDA:**
- Adicione:

```markdown
## Handoff: {ID_TAREFA} — {DATA}

**Agente**: {seu tipo: backend-agent | frontend-agent | qa-agent}
**Estado**: Interrompida no meio

**Progresso**:
- ✅ Já feito: {o que foi concluído — seja específico}
- ⏳ Em andamento: {o que estava sendo feito quando parou — seja específico}
- ❌ Ainda não feito: {o que falta — liste todos os itens}

**Contexto importante para retomada**:
{informações críticas que a próxima instância precisa saber — decisões tomadas, por que certas abordagens foram escolhidas, armadilhas encontradas}

**Próximo passo exato**:
{instrução precisa do que fazer ao retomar — sem ambiguidade. Ex: "Abrir src/api/users.ts e implementar a função validateEmail na linha 45, depois rodar npm test"}

**Arquivos relevantes**:
- `caminho/arquivo.ext` — {relevância}
```

## 4. Atualizar DECISIONS.md (se necessário)

Se você tomou qualquer decisão técnica durante a implementação que ainda não está registrada:

```markdown
### DEC-{PRÓXIMO_ID}: {título da decisão}
- **Data**: {data}
- **Contexto**: {por que precisou decidir}
- **Decisão**: {o que foi escolhido — seja específico, inclua versões e configurações}
- **Justificativa**: {por que essa escolha}
- **Alternativas descartadas**: {o que foi rejeitado e por que}
- **Decidido por**: {seu tipo de agente}
```

Para descobrir o próximo ID: liste as decisões existentes em DECISIONS.md e incremente.

## Gotchas

- ❌ Não pule o PROGRESS.md — é o histórico auditável e o QA usa para saber onde testar
- ❌ HANDOFF vago = próxima instância vai começar do zero em vez de continuar
- ❌ "Próximo passo exato" genérico ("continue implementando") não ajuda — seja preciso
- ✅ Se houver nova API implementada, registre o schema completo em DECISIONS.md
- ✅ Atualizar os docs é tão importante quanto implementar — não pule por "falta de tempo"
