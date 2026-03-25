---
name: task-updater
description: Atualiza TASK_BOARD, PROGRESS, HANDOFF e DECISIONS ao concluir, pausar ou bloquear uma tarefa. Use esta skill como último passo obrigatório de qualquer agente do time.
user-invocable: false
---

# Task Updater

Execute as atualizações abaixo em sequência ao iniciar, finalizar ou interromper uma tarefa. Não pule etapas — estes docs são o único estado compartilhado entre agentes.

**REGRA CRÍTICA**: Mover uma tarefa significa SEMPRE duas operações atômicas:
1. **REMOVA** a linha inteira da tarefa da seção de origem
2. **ADICIONE** a linha na seção de destino
Nunca faça apenas uma das duas. Se a tarefa aparecer em duas seções ao mesmo tempo, o board está corrompido.

## 1. Atualizar TASK_BOARD.md

Abra `docs/project-state/TASK_BOARD.md` e:

**Se a tarefa está sendo INICIADA (TODO → IN_PROGRESS):**
- **REMOVA** a linha inteira da tarefa da seção `## 📋 TODO`
- **ADICIONE** na seção `## 🔄 IN_PROGRESS` com formato: `| ID | Descrição | Tipo | {seu agente} | {data atual} |`
- Confirme visualmente que a tarefa NÃO aparece mais na seção TODO

**Se a tarefa foi CONCLUÍDA (IN_PROGRESS → DONE):**
- **REMOVA** a linha inteira da tarefa da seção `## 🔄 IN_PROGRESS`
- **ADICIONE** na seção `## ✅ DONE` com formato: `| ID | Descrição | Tipo | {data atual} |`
- Confirme visualmente que a tarefa NÃO aparece mais na seção IN_PROGRESS

**Se a tarefa foi BLOQUEADA (IN_PROGRESS → BLOCKED):**
- **REMOVA** a linha inteira da tarefa da seção `## 🔄 IN_PROGRESS`
- **ADICIONE** na seção `## 🚫 BLOCKED` com formato: `| ID | Descrição | [motivo específico, não genérico] |`
- O tech-lead-agent vai ler esse motivo para desbloquear

**Se a tarefa foi INTERROMPIDA no meio:**
- Deixe em `IN_PROGRESS` (não mova)
- Vá para o passo 3 (HANDOFF) obrigatoriamente

**Se o QA aprovou (DONE → VERIFIED):**
- **REMOVA** a linha inteira da tarefa da seção `## ✅ DONE`
- **ADICIONE** na seção `## ✔️ VERIFIED` com formato: `| ID | Descrição | Tipo | {data atual} |`
- Confirme visualmente que a tarefa NÃO aparece mais na seção DONE

**Se o QA encontrou bug e criou tarefa FIX-:**
- Se bug CRÍTICO/ALTO:
  - **REMOVA** a linha inteira da tarefa original da seção `## ✅ DONE`
  - **ADICIONE** a tarefa original de volta na seção `## 📋 TODO`
  - Confirme visualmente que a tarefa NÃO aparece mais na seção DONE
- Se bug MÉDIO/BAIXO:
  - **REMOVA** a linha inteira da tarefa original da seção `## ✅ DONE`
  - **ADICIONE** a tarefa original na seção `## ✔️ VERIFIED`
- A tarefa FIX-BACK-XXX ou FIX-FRONT-XXX já foi criada na seção TODO pelo QA

**Se a tarefa foi DESBLOQUEADA (BLOCKED → TODO):**
- **REMOVA** a linha inteira da tarefa da seção `## 🚫 BLOCKED`
- **ADICIONE** de volta na seção `## 📋 TODO`
- Confirme visualmente que a tarefa NÃO aparece mais na seção BLOCKED

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

- ❌ NUNCA adicione uma tarefa em uma seção sem REMOVER da seção anterior — isso causa duplicatas
- ❌ Não pule o PROGRESS.md — é o histórico auditável e o QA usa para saber onde testar
- ❌ HANDOFF vago = próxima instância vai começar do zero em vez de continuar
- ❌ "Próximo passo exato" genérico ("continue implementando") não ajuda — seja preciso
- ✅ Após cada movimentação, releia o TASK_BOARD e confirme que a tarefa aparece em UMA ÚNICA seção
- ✅ Se houver nova API implementada, registre o schema completo em DECISIONS.md
- ✅ Atualizar os docs é tão importante quanto implementar — não pule por "falta de tempo"
