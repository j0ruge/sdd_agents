---
missao: 20261121-l4-preflight-health-e-sensores
fase: REVIEW
rodada: 5
status: done
sessao: worker-r5-chore
data: 2026-11-22 10:22
gate: "tests/run-all.sh em 867ecdb → rc 0 (10:03 → 10:19), 'suite green', 0 linhas '^  FAIL', 2336 linhas '^  ok    ', 'anchors: all 986 mutants still apply and leave valid code'; sdd review-base → full (o merge cef90b1 entrou depois da r4), rodada inteira sobre o chore; árvore limpa (git status --short vazio) antes do commit da rodada"
reviewed_head: 867ecdb5948018aa2a87449f51eb1239cba356fd
---

# Review — rodada r5 — L4: preflight, health e sensores (o pós-merge, chore/l4-pos-merge)

## TL;DR

Rodada inteira sobre `cef90b1..867ecdb` (4 commits do chore de pós-merge). Cada número e cada frase nova foram
medidos de novo e conferem: os 15 itens saídos do `TODO.md` são os 15 do `00-missao.md` pelo título, os 12 hashes
`RESOLVED by` são ancestrais de `cef90b1`, a catraca 86 → 71 bate com `check-todo.sh`, o ledger dá 20 sessões,
US$ 46,51 e 34 518 s, e o diário só acrescenta. Dois LOW de prosa e um de registro, nenhum `R<n>`. Nota A em todo critério.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A única mudança em `bin/sdd` é "four" → "three" num comentário (`bin/sdd:1032`), e `grep -cE '^\s+(if )?test_cmd_red_why' bin/sdd` dá 3, como a frase diz. |
| Type Safety | A | Nenhuma expansão nem captura nova; `bash -n bin/sdd` e `shellcheck -S warning bin/sdd tests/check-gates.sh` saem rc 0 no head. |
| Error Handling | A | Nenhum ramo mudou: o diff executável é zero, e o limiar do failure-modes (`printed -gt 1`) bate com `test_cmd_red_why`, medido com `printf x; no_such_cmd` (rc 127, uma linha não vazia). |
| Security | A | O diff só tem prosa, comentário e linhas do `TODO.md`; nenhuma superfície nova, nenhum segredo nas linhas acrescentadas. |
| Performance | A | Não há chamada nova a `git`, a sessão nem a suíte; o diff só tem texto. |
| Test Coverage | A | Sem comportamento novo a cobrir; `check-todo.sh` dá 71 achados, todos no alvo, e `check-lang.sh` dá 0 de 73 na lista, no head. |
| Documentation | A | Os números do `KAIZEN_LOG.md`, do handoff e da F6 conferem no ledger, no `git diff` e no `gh pr view 464`; sobram dois LOW de prosa e um de registro, que não baixam a nota. |
| **Overall** | **A** | O chore cumpre o ciclo de vida: 15 itens saem com hashes ancestrais, os dois itens ganham os vizinhos, a catraca desce no mesmo diff, e o diário é só acréscimo. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW (prosa) | A frase nova do limiar ficou com o antecedente trocado: "a log of exactly one … reads as a command that did not run; that suite ran against the tree, so over a dirty tree `gate_EXEC` answers with its dirty-tree stop instead". O "that suite" agora lê como a de uma linha, mas o que ela diz vale para a que começou (mais de uma linha), e a linha 1138 saiu com 117 colunas sem o reflow → chore: "…; the suite that started ran against the tree, so…", quebrada em ≤ 100. | `docs/failure-modes.md:1136-1139` |
| 2 | LOW (registro) | A célula "Próximo passo" da F6 termina o L4 com "o chore dele vem a seguir", que fica vencida no merge deste chore (o PR e o `sha` dele não estão lá, como o #460 está para o L3) → no próximo chore: "o chore dele entrou pelo #<n> (`<sha>`)". | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21` |
| 3 | LOW (registro) | O diário (10:02) e o `handoff-L4.md` dizem que a `RECURRED` do item do `sdd adr new` foi "reunida à mão" depois do wrap. O diff do `TODO.md` não toca essa linha (`TODO.md:470` igual a `cef90b1`), então o passo é verdadeiro mas não deixa rastro: quem ler só o diff não acha o que foi reunido → opcional: dizer "conferida intacta" em vez de "reunida". | `docs/superpowers/campaigns/20261117-zerar-as-issues/handoff-L4.md`, `journal.md` (linha de 10:02) |

## Conferências feitas (sem achado)

- **`4eaaa04`:** o limiar (`printed -gt 1` em `test_cmd_red_why`), "three sites" (3 hoje), o exemplo `echo x; no_such_cmd`
  e o `TMPDIR` do `DECLARED LIMIT` fecham os achados 1, 2, 3 da r5 do #460, e o Minor do CodeRabbit.
- **`c6020ed`:** 15 itens `- [ ]` removidos, e os títulos batem um a um com a tabela do `00-missao.md`; 12 hashes
  distintos (07fc265, 21a9af7, 261acc8, 3612cb9, 46da749, 641529b, 6ca6f20, 81f6ec6, 95598f4, 9ef4cdc, a3e4c86,
  dfaeeb4), todos `--is-ancestor cef90b1`; nenhum item alheio saiu (só os 15 e os três acréscimos de vizinho e de
  atribuição, achados 6a e 6b da r5 do #460); a `RECURRED 2` do item da `READ_EXTRA` saiu com o item, e as demais
  `RECURRED` ficaram como estavam; `tests/health-baseline.txt` 86 → 71 e `check-todo.sh` 71.
- **`7cc7245`:** `grep -c '^mut_'` 986, `git diff 86e16c0..cef90b1 | grep -cE '^\+mut_…\(\)'` 32, 0 removidos;
  portas 13 → 15; ledger (`LC_ALL=C`): 20 sessões, US$ 46,51, 34 518 s, uma linha `blocked` `handoff-blocked` às 04:25;
  EXEC 14 sessões, US$ 34,51.
- **`867ecdb`:** `journal.md` só com `+` (27 linhas), as horas 04:25, 09:10, 09:57 batem com o ledger e com
  `gh pr view 464` (MERGED, `cef90b1`, head `5c8436a`); o `15:23` do `handoff-L3.md` bate com o `pipeline.log` do L3;
  #463 segue OPEN; REVIEW US$ 6,21 e PR US$ 1,08 somam do ledger.

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os três achados são LOW de prosa e de registro, sem consumidor fora da suíte; vão ao próximo chore.
