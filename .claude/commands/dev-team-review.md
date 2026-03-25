# /dev-team-review

Roda o QA Agent nas tarefas concluídas.

## Uso

```
/dev-team-review           # testa todas as tarefas DONE
/dev-team-review BACK-003  # testa tarefa específica por ID
```

## Execução

1. Leia `docs/project-state/TASK_BOARD.md`
2. Identifique tarefas com status `DONE`
3. Se nenhuma encontrada: informe o usuário e sugira `/dev-team-next`

Confirme antes de executar:

```
🔍 Tarefas para revisão de QA:
  • {ID} — {descrição}
  • {ID} — {descrição}

Iniciar revisão? [aguardar confirmação ou proceder]
```

Execute o QA Agent:

```
Agent(subagent_type="qa-agent", prompt="
Rode o QA nas seguintes tarefas com status DONE:

{PARA CADA TAREFA:}
---
ID: {ID}
Descrição: {descrição completa}
Critérios de aceite:
  - {critério 1}
  - {critério 2}
  - {critério 3}
---

Para cada tarefa:
1. Leia PROGRESS.md para saber quais arquivos foram criados/modificados
2. Execute os testes automatizados existentes (npm test / pytest / equivalente da stack)
3. Valide cada critério de aceite — um por um, sem pular nenhum
4. Teste edge cases: input inválido, dados vazios, permissões, limites
5. Reporte bugs com severidade (CRÍTICO/ALTO/MÉDIO/BAIXO) e passos exatos para reproduzir
6. Atualize o TASK_BOARD (DUAS operações obrigatórias por tarefa):
   - Aprovada: REMOVA a linha da seção DONE, ADICIONE na seção VERIFIED
   - Bug crítico/alto: REMOVA a linha da seção DONE, ADICIONE na seção TODO (crie tarefa de fix)
   - Bug médio/baixo: REMOVA a linha da seção DONE, ADICIONE na seção VERIFIED (crie tarefa de fix separada)
   - CONFIRME que cada tarefa aparece em UMA ÚNICA seção após movimentação

Siga seu protocolo completo.
")
```

## Após a execução — mostre o resultado

```
📊 Resultado da rodada de QA:

✔️  VERIFIED: {N} tarefa(s)
  {lista de IDs aprovados}

🐛 Bugs encontrados: {N}
  FIX-{TIPO}-{N} [{severidade}] — {título} (fix para: {ID original})

📋 Tarefas de fix criadas: {N}
  {lista de novos FIX-* IDs no TODO}
```

**Próximo passo sugerido:**
- Há bugs CRÍTICO ou ALTO → `/dev-team-next` para corrigir primeiro
- Apenas bugs MÉDIO/BAIXO → `/dev-team-next` para próxima feature
- Sem bugs pendentes e ainda há tarefas TODO → `/dev-team-next`
- Tudo VERIFIED e sem mais tarefas → "🎉 Sprint completo!"
