---
missao: 20260816-kit-como-alvo
atualizado: 2026-08-16 00:00
---

# Checkpoint — quando o kit é o próprio alvo, quatro instrumentos param de afirmar o que nunca mediram

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | entry point com guarda + sensor diferencial | `bash tests/check-entrypoint.sh >/dev/null 2>&1; echo $?` → `0` | pending | — |
| I2 | os três leitores do ledger filtram por repo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c 'a row from another repo never enters the series' <<< "$o"` → `1` | pending | — |
| I3 | preflight compara conteúdo do agente, não presença | `o=$(bash tests/check-preflight.sh 2>&1); grep -c 'a drifted agent copy fails the preflight' <<< "$o"` → `1` | pending | — |
| I4 | aviso de branch base alcança run e kaizen | `o=$(bash tests/check-gates.sh 2>&1); grep -c 'the base branch warning reaches sdd run' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 00:00 · `plano` · Os 4 Checks foram rodados contra o HEAD `df18c88` na sessão que
  escreveu este plano e deram **`127`, `0`, `0`, `0`** — todos vermelhos pelo motivo certo
  (sensor ausente / asserção ausente), nenhum verde por construção. Se algum já estiver verde
  quando você começar, **pare e descubra por quê** antes de implementar.
- 2026-08-16 15:08 · `humano` · **Os Checks de I2/I3/I4 não usam pipe, e isso é obrigatório — não
  "simplifique" de volta.** Dois motivos independentes, os dois medidos hoje. (1) `checkpoint_rows`
  (`bin/sdd:174`) faz `awk -F'|'` cru e não conhece `\|`, o escape de pipe do GFM: com pipe na
  célula as três linhas davam `NF=8` contra `NF=7` da limpa, o `gate_EXEC` reprovava com "invalid
  status" e o `sdd status` imprimia `pending` na coluna Commit. Está no `TODO.md` (`2897a94`).
  (2) A primeira reescrita tentada — process substitution `grep -c '…' <(cmd)` — foi descartada,
  mas o motivo **não vale para você**: no shell interativo daquela sessão o `grep` era uma função
  do snapshot apontando para ugrep 7.5.0, que não imprime o `0` com `<(...)`. Dentro de `bash -c`,
  como o sensor roda, o `grep` é GNU 3.11 e imprime. Herestring ficou porque não depende de qual
  `grep` atende e é a forma que o `CLAUDE.md` já prescreve (SIGPIPE sob `pipefail`). ⚠️ O runner
  usa `grep` 40× e a suíte em 11 arquivos: se algum dia um Check parecer mentir, confira **em que
  shell** você o rodou antes de acusar o sensor.
  Re-medido em herestring contra o HEAD: `127`, `0`, `0`, `0` — os mesmos
  quatro números que o plano declara, então a evidência do critério (d) segue válida.
- 2026-08-16 00:00 · `plano` · O `bin/sdd` tem **2365** linhas neste HEAD. Âncoras do `TODO.md`
  citam offsets da época em que tinha 2324. `grep` pelo texto antes de editar por número.
- 2026-08-16 00:00 · `plano` · `run_mutant` devolve **rc 90** quando a sabotagem não altera o
  arquivo (`tests/check-mutation.sh:492`). Esse rc é "âncora apodreceu", não "mutação fraca".
- 2026-08-16 00:00 · `plano` · I1 tem Jidoka declarado: se a repro de reexecução não for
  determinística com ≥128 KB, **não commite repro flaky** — degrade para a asserção de forma,
  registre a degradação aqui e no handoff, e mantenha a mutação.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
