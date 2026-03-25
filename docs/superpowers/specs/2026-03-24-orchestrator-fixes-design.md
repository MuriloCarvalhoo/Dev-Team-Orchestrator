# Design: Correcao dos 12 pontos negativos do Dev Team Orchestrator

**Data**: 2026-03-24
**Status**: Aprovado pelo usuario
**Referencia completa**: README.md (secao "Plano de Evolucao v2")

## Contexto

Auditoria do repositorio identificou 12 pontos negativos que impedem ou degradam o fluxo autonomo do orchestrator. Este documento registra as decisoes tomadas em sessao colaborativa com o usuario.

## Decisoes

### D1: Permissoes (settings.json)
- **Problema**: Write restrito a `docs/project-state/**`, Bash restrito a poucos comandos
- **Decisao**: Expandir Write(*), Edit(*), adicionar npm/node/python/git/mkdir ao Bash
- **Fase**: 1

### D2: Skills faltantes (PO + Tech Lead)
- **Problema**: PO e Tech Lead escrevem docs sem skill task-updater padronizada
- **Decisao**: Adicionar task-updater a ambos
- **Fase**: 1

### D3: Execucao paralela
- **Problema**: /dev-team-next executa 1 tarefa por vez
- **Decisao**: Novo comando `/dev-team-next-parallel` (separado do existente)
- **Alternativas descartadas**: Flag --parallel no mesmo comando (mistura responsabilidades); sempre paralelo automatico (menos controle)
- **Fase**: 4

### D4: Validacao PRD
- **Problema**: Backlog pode nao cobrir 100% do PRD
- **Decisao**: Novo PASSO 4 no /dev-team-start onde PO re-valida cobertura
- **Alternativas descartadas**: Tech Lead valida (sobrecarga); agente reviewer dedicado (complexidade)
- **Fase**: 2

### D5: Agente DevOps
- **Problema**: Sem agente para setup/scaffold/infra
- **Decisao**: Novo devops-agent (sonnet) + passo 3.5 no /dev-team-start
- **Alternativas descartadas**: Expandir tech-lead (mistura decisao com execucao); passo generico sem agente dedicado
- **Fase**: 2

### D6: Race condition
- **Problema**: Docs compartilhados sem protecao para acesso paralelo
- **Decisao**: Worktree isolation via `isolation: "worktree"` do Claude Code + merge pos-execucao
- **Alternativas descartadas**: Lock files (locks orfaos); escrita por secao (dificil de enforcar)
- **Fase**: 4

### D7: Ciclo de bugs
- **Problema**: BUG-XXX sem status RESOLVIDO, re-teste nao explicito
- **Decisao**: Eliminar secao BUGS. QA cria tarefa FIX-BACK-XXX ou FIX-FRONT-XXX diretamente no TODO
- **Alternativas descartadas**: Campo fix_task bidirecional (overhead); manter bugs como esta (incompleto)
- **Fase**: 3

### D8: Comunicacao inter-agente
- **Problema**: Agente nao pode perguntar a outro agente
- **Decisao**: Reutilizar BLOCKED + auto-desbloqueio. Agente escreve pergunta como motivo do BLOCKED, tech-lead responde via DECISIONS.md
- **Alternativas descartadas**: Secao PERGUNTAS no HANDOFF (infra nova); QUESTIONS.md dedicado (mais um arquivo)
- **Fase**: 3

### D9: Auto-desbloqueio
- **Problema**: /dev-team-next apenas sugere invocar tech-lead manualmente
- **Decisao**: Invocar tech-lead-agent automaticamente ao detectar BLOCKED
- **Alternativas descartadas**: Com confirmacao (adiciona friccao); comando separado /dev-team-unblock (mais um comando)
- **Fase**: 3

### D10: Bootstrap de projeto
- **Problema**: Primeiro agente cria estrutura ad-hoc
- **Decisao**: devops-agent roda como passo 3.5 no /dev-team-start (apos stack definida)
- **Alternativas descartadas**: Tarefa DEVOPS-001 automatica (atrasa inicio); ambos (complexidade)
- **Fase**: 2

### D11: Testes do orchestrator
- **Problema**: Nenhum teste valida integridade dos artefatos
- **Decisao**: Testes de integracao (shell script) validando estrutura de docs, IDs, dependencias, formato
- **Alternativas descartadas**: Linting com schema JSON (nao suporta markdown); checklist no QA (nao e teste automatizado)
- **Fase**: 5

## Fases

1. **Critico** -- permissoes + skills (desbloqueia fluxo autonomo)
2. **Bootstrap** -- devops-agent + validacao PRD (garante inicio solido)
3. **Fluxo** -- auto-desbloqueio + FIX- + comunicacao (melhora autonomia)
4. **Paralelo** -- /dev-team-next-parallel + worktrees (acelera execucao)
5. **Testes** -- integracao + dry-run (garante integridade)
