---
name: sdd-docs
description: >-
  Sincroniza a documentação viva do repo-alvo com o que a missão mudou — README, CLAUDE.md,
  .claude/rules/, CONTEXT.md, CHANGELOG, KAIZEN_LOG — com progressive disclosure obrigatório.
  Roda depois do código final e antes do PR. Produz 45-docs.md com o checklist de drift.
---

# sdd-docs

Você roda **depois** do código final (pós-review, pré-PR) e mantém a documentação do repo
**viva**: sincronizada com o que esta missão mudou. Nem mais, nem menos.

Documentação que descreve um mundo que não existe mais é pior do que documentação nenhuma —
ela custa confiança toda vez que alguém a segue e se dá mal.

## 1. Carregue o estado

1. O diff completo da missão — é ele que define o que pode ter dado drift.
2. `docs/handoffs/<missão>/*` — a missão, o plano, os handoffs de EXEC, QA e REVIEW.
3. Os documentos candidatos do repo: `README.md`, `CLAUDE.md`, `.claude/rules/*`, `CONTEXT.md`
   (glossário), `CHANGELOG.md`, `KAIZEN_LOG.md`, `docs/adr/*`, docs específicos das áreas
   tocadas.

## 2. Progressive disclosure — obrigatório

Arquivo-índice **roteia**; profundidade vive em `references/` ou em docs específicos.

- Um `CLAUDE.md` ou `README.md` que cresce a cada missão vira um documento que ninguém lê e que
  estoura a janela de contexto do próximo agente. **Doc que estoura janela é doc quebrado.**
- Ao acrescentar conteúdo, pergunte primeiro: *isto roteia ou isto aprofunda?* Aprofundamento
  vai para o arquivo específico, com um link de uma linha no índice.
- Documento longo já existente que você tocou e que está claramente inchado: registre no
  `TODO_FILE` a proposta de quebra. Não refatore doc alheio no meio desta missão.

## 3. O que atualizar (e o que não)

| Documento | Atualize quando… | NÃO atualize quando… |
|---|---|---|
| `README.md` | mudou como se instala, roda ou usa | mudou implementação interna |
| `CLAUDE.md` / `.claude/rules/` | **uma convenção realmente mudou** | você "acha" que a convenção deveria mudar |
| `CONTEXT.md` (glossário) | entrou/mudou termo do domínio | o termo só apareceu num nome de variável |
| `CHANGELOG.md` | a missão entrega algo visível ao usuário | refactor interno sem efeito externo |
| `KAIZEN_LOG.md` | a missão mede um antes/depois | não há número para mostrar |
| `docs/adr/*` | uma decisão arquitetural foi tomada ou revertida | a decisão já está registrada e continua válida |

Sobre rules e `CLAUDE.md`: **SDCA** — padronizar exige confirmar no arquivo que a mudança está
lá. Mudou a convenção de verdade? Escreva. Não mudou? Não escreva. Regra inventada por agente é
dívida que o próximo agente vai obedecer sem questionar.

## 4. Confira os achados de TODO da missão

Parte do seu trabalho: as entradas que os outros agentes criaram no `TODO_FILE` durante esta
missão estão **bem-formadas**? Cada uma precisa de: o quê + onde (`arquivo:linha`) + por que
importa + descoberto por (agente/missão/data). Complete as que estiverem pela metade.

## 5. Escreva o checklist de drift

`docs/handoffs/<missão>/45-docs.md`. É o **gate** desta fase, e ele é uma tabela — uma linha por
área que o diff tocou:

```md
# Documentação — <missão>

## Checklist de drift

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `packages/x/serializer.ts` | `docs/contratos.md` | ✅ | atualizado no commit `abc1234` |
| `bin/sdd` | `README.md` | ✅ | seção "Uso" reescrita, commit `def5678` |
| `packages/y/utils.ts` | — | n/a | refactor interno, nenhum doc descreve estas funções |
```

Regras do checklist:

- **toda** área tocada pelo diff tem uma linha;
- `✅` exige o hash do commit que atualizou o doc;
- `n/a` exige justificativa concreta (não "não se aplica");
- **nenhum `✗` pode sobrar** — o runner reprova o gate se encontrar item pendente.

Feche com uma seção "Entradas de TODO desta missão" listando as que você conferiu.

Commite tudo.

## Regras que não se negociam

- Progressive disclosure: índice roteia, `references/` aprofunda.
- Rule/`CLAUDE.md` só muda quando a convenção mudou de verdade.
- Toda área do diff tem linha no checklist, com hash ou justificativa.
- Nenhum `✗` sobra no checklist.
- Você não faz push, não abre PR, não faz merge.
