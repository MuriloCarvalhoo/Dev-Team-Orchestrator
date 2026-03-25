# /dev-team-next-parallel

Executa múltiplas tarefas independentes em paralelo usando git worktrees.

## Uso

```
/dev-team-next-parallel
```

## Pré-requisitos

- Working directory limpo (sem mudanças uncommitted)
- Pelo menos 2 tarefas TODO independentes disponíveis

## Lógica de seleção

1. Leia `docs/project-state/TASK_BOARD.md`
2. Execute o auto-desbloqueio (mesmo protocolo do `/dev-team-next`):
   - Se há tarefas BLOCKED, invoque o tech-lead-agent para cada uma
   - Continue após desbloqueio
3. Identifique TODAS as tarefas TODO cujas dependências estão DONE ou VERIFIED
4. Filtre apenas tarefas que NÃO dependem umas das outras (mutuamente independentes)
5. Se <= 1 tarefa disponível: informe e sugira `/dev-team-next` em vez deste comando

## Confirmação com o usuário

```
🔀 Execução paralela — {N} tarefas independentes encontradas:

  • {ID} [{BACK|FRONT|DEVOPS}] — {descrição}
  • {ID} [{BACK|FRONT|DEVOPS}] — {descrição}

Cada tarefa será executada em um worktree isolado.
Iniciar? [aguardar confirmação]
```

## Execução

Lance TODOS os agentes em uma única mensagem (paralelo), cada um com isolation: "worktree":

```
Agent(
  subagent_type="{backend-agent|frontend-agent|devops-agent}",
  isolation="worktree",
  prompt="
Execute a tarefa {ID}.

Tarefa: {DESCRIÇÃO COMPLETA DA TAREFA DO TASK_BOARD}

Critérios de aceite (valide cada um antes de marcar como DONE):
{LISTA COMPLETA DE CRITÉRIOS}

Contexto de DECISIONS.md relevante para esta tarefa:
{DECISÕES DE STACK, PADRÕES E API QUE SE APLICAM}

{SE HANDOFF EXISTIR:
Contexto de HANDOFF.md — esta tarefa foi interrompida:
{CONTEÚDO DO HANDOFF PARA ESTA TAREFA}
}

Siga seu protocolo: leia os docs compartilhados, mova para IN_PROGRESS, implemente, atualize os docs ao concluir.
"
)
```

## Pós-execução: merge dos worktrees

Após todos os agentes concluírem:

1. Para cada worktree com mudanças:
   a. Tente merge automático
   b. Se conflito em docs/project-state/: merge por seção
      - TASK_BOARD: cada agente editou seu próprio ID — concatenar seções
      - PROGRESS: cada agente adicionou no topo — concatenar entradas
      - DECISIONS: cada agente adicionou DEC-XXX incrementais — concatenar
      - HANDOFF: cada agente limpou sua própria entrada — merge direto
   c. Se conflito em código fonte: reporte ao usuário para resolver

2. Apresente resultado consolidado:

```
✅ Execução paralela concluída!

Tarefas concluídas:
  • {ID} — {descrição} ✔️
  • {ID} — {descrição} ✔️

{SE houve conflitos em docs}
⚠️ Conflitos encontrados e resolvidos em docs/project-state/:
  {lista de arquivos}

{SE há conflitos em código}
❌ Conflito em código — requer resolução manual:
  {lista de arquivos}
```

## Sugestão de próximo passo

Mesmo formato do `/dev-team-next`:
- Há mais tarefas TODO → `/dev-team-next` ou `/dev-team-next-parallel`
- Há tarefas DONE → `/dev-team-review`
- Tudo VERIFIED → "🎉 Sprint completo!"
