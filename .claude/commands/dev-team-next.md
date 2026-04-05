# /dev-team-next

Executa a proxima tarefa disponivel no board. Modo manual — uma tarefa por vez.

## Uso

```
/dev-team-next            # proxima tarefa disponivel (priorizando BACK)
/dev-team-next BACK       # forca tarefa backend
/dev-team-next FRONT      # forca tarefa frontend
/dev-team-next DEVOPS     # forca tarefa devops
/dev-team-next BACK-003   # executa tarefa especifica por ID
```

## Auto-desbloqueio

Antes de selecionar a tarefa, liste `board/blocked/*.md`.
Se houver tarefas bloqueadas:

```
Agent(subagent_type="tech-lead-agent", prompt="
Desbloqueie a tarefa em board/blocked/{ID}.md.

Leia o arquivo — a secao Handoff contem o motivo do bloqueio.
Leia docs/DECISIONS.md para contexto existente.

1. Tome uma decisao clara e definitiva
2. Registre em docs/DECISIONS.md (formato DEC-TL-XXX)
3. Adicione a decisao na secao Context do arquivo
4. Mova: git mv board/blocked/{ID}.md board/todo/{ID}.md
5. Atualize frontmatter: updated: {hoje}
")
```

Se o tech-lead nao conseguir desbloquear (motivo externo):
→ Informe o usuario: "Tarefa {ID} requer intervencao manual: {motivo}"

## Logica de selecao

1. Liste `board/todo/*.md` e leia frontmatter de cada um
2. Filtre tarefas cujas dependencias (`depends_on`) estao em `board/done/` ou `board/verified/`
3. Verifique se alguma tarefa em `board/in_progress/` tem secao Handoff preenchida (retomar)

**Prioridade de selecao:**
- Tarefas em `in_progress/` com Handoff (retomar trabalho interrompido)
- Tarefas `BACK` antes de `FRONT` (backend libera frontend)
- Tarefas de maior prioridade (HIGH > MEDIUM > LOW)
- Tarefas sem dependencias

## Antes de executar — confirme com o usuario

```
Tarefa selecionada: {ID} — {titulo}
Tipo: {Backend|Frontend|DevOps} | Prioridade: {High|Medium|Low}
Depende de: {IDs ou "nenhum"}

Criterios de aceite:
  - {criterio 1}
  - {criterio 2}

{se Handoff preenchido: "Esta tarefa foi interrompida — sera retomada de onde parou."}

Iniciar? [aguardar confirmacao]
```

## Execucao

Lance o agente apropriado baseado no tipo da tarefa:

```
Agent(subagent_type="{backend|frontend|devops}-agent", model="opus", prompt="
Execute a tarefa em board/todo/{ID}.md.

Leia o arquivo — ele contem descricao, criterios de aceite, contexto e handoff.

Siga seu protocolo:
1. Mova: git mv board/todo/{ID}.md board/in_progress/{ID}.md
2. Atualize frontmatter: assigned: {agent}, updated: {hoje}
3. Implemente seguindo criterios e contexto do arquivo
4. Escreva testes unitarios e de integracao
5. Rode testes e confirme que passam
6. Preencha secao Log (arquivos criados, testes escritos)
7. Marque checkboxes dos criterios atendidos
8. Mova: git mv board/in_progress/{ID}.md board/done/{ID}.md
")
```

## Apos a execucao — sugira o proximo passo

```
Tarefa {ID} concluida e movida para board/done/.

{SE ha tarefas em board/done/}
Ha {N} tarefa(s) em done/ aguardando QA.
Proximo: /dev-team-next (mais tarefas) ou /dev-team-run (loop com QA automatico)

{SE tudo em verified/}
Projeto completo! Todas as tarefas verificadas.
```
