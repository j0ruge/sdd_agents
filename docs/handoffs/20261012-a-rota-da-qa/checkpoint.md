---
missao: 20261012-a-rota-da-qa
atualizado: 2026-10-12 20:05
---

# Checkpoint — a rota da QA

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas. Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **A célula Commit leva o hash curto NU, sem crase.**
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | alocar a ADR da rota da QA com o humano (`sdd adr new --slug the-qa-route`), que escolhe entre as alternativas do `00-missao.md` | `o=$(ls docs/adr); grep -c -e 'the-qa-route' <<< "$o"` → `1` | pending | — |
| I2 | a rota do `skipped`: o `qa_substep` devolve `close` quando o `00-missao.md` declara `qa: skipped`, com interface | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a plan that declares qa: skipped goes straight to QA:close with an interface' <<< "$o"` → `1` | pending | — |
| I3 | o contrato da chave `qa:` — template da missão, `sdd-qa` § 2 (confere o diff; diff visível vira `blocked`), planner e `docs/pipeline.md` | `o=$(grep -l -e '^qa:' -e 'plan declares .qa: skipped' templates/missao.md agents/sdd-qa.md); grep -c . <<< "$o"` → `2` | pending | — |
| I4 | a rota do reteste: `F<n>` feito depois do relatório fechado devolve a QA ao `exec`; `sdd-qa` § 4 e o comentário das skills dizem a verdade | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a fix increment done after the closed report sends QA back to exec for the retest' <<< "$o"` → `1` | pending | — |
| I5 | o spec do bug `human`/`deferred`: `sdd-qa` § 3 nomeia o `test.fail()` chamado depois das pré-condições | `o=$(grep -l -F 'test.fail()' agents/sdd-qa.md); grep -c . <<< "$o"` → `1` | pending | — |
| I6 | onde vai o `RESOLVED by` num item no teto de 8 linhas: os dois templates do `TODO.md` dizem | `o=$(cat templates/todo.pt-BR.md templates/todo.md); grep -c -e 'fim da linha .Fonte' -e 'end of the .Source' <<< "$o"` → `2` | pending | — |
| I7 | fecho: `docs/pipeline.md`, `CONTEXT.md`, anatomia § 4, `sdd install --force` e a entrada do `KAIZEN_LOG.md` | `grep -c -E '^## .*a rota da QA' KAIZEN_LOG.md` → `1` | pending | — |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo.

## Incrementos de fix (QA e REVIEW)

> Duas fases escrevem na tabela acima depois do EXEC, pelo mesmo motivo e pela mesma rota: quem
> **acha** não conserta, e o `current_phase()` devolve a bola ao EXEC sozinho porque uma linha
> `pending` reprova o `gate_EXEC` antes de o gate da fase que a escreveu ser lido.
>
> **`F<n>` — `sdd-qa`**, quando um bug sanável é reprovado. O Check obrigatoriamente inclui
> **regression test passa** + **re-walk da jornada impactada verde**. Bug que exige julgamento
> humano NÃO vira fix — vai para "Decisions for a Human" no handoff de QA.
>
> **`R<n>` — `sdd-reviewer`**, um por achado CRITICAL/HIGH da rodada; os MEDIUM/LOW baratos entram
> num único `R<n>` de lote por rodada, com um Check por achado dentro da célula. Caro demais vai
> para o `TODO_FILE`; o que exige julgamento humano vai para as pendências do `40-review-r<N>.md`.
