---
missao: 20261003-lote-3-a-catraca-desce
fase: EXEC
status: done
sessao: 3bfead27-6334-4c8e-b5f3-a1b563580ea5
data: 2026-10-04 10:40
gate: "tests/run-all.sh → rc 0, 'suite green' (1788 linhas '  ok ', 0 FAIL, 293 s; coordination: 187 passed, 0 failed; anchors: all 592 mutants still apply and leave valid code); checkpoint I1–I20 done, cada Commit um sha no git log; check-todo: '36 finding(s), all within 8 lines, carrying anchor + date, every anchor on target' = todo-findings 36"
---

# Handoff — EXEC — Lote 3: a catraca desce

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 20 incrementos estão `done`, executados de forma interativa (decisão 6), cada um com o Check
medido vermelho antes e verde depois. 22 itens saíram do `TODO.md` sem código (I1–I3) e 13 foram
consertados com sensor (I5–I19), os 5 fail-open entre eles; os 13 carregam `RESOLVED by`. O
`/sdd-plan` ensina o repasse do grill e o aviso de trabalho longo (I4). Catraca 57 → 36 na branch
(35 + N, N = 1: o `kaizen_reminder`), 23 depois do chore pós-merge. Catálogo 580 → 592, todos aplicam.
Próximo, pela decisão 6: push, PR, esperar TODOS os bots, consertar numa leva, `sdd health` uma vez
(o humano dispara), merge pelo humano.

## Estado do repo

- **Branch:** `fix/lote-3-a-catraca-desce`, só local (nunca empurrada)
- **Último commit:** `60d4287`, o commit deste handoff e do `KAIZEN_LOG.md`, sobre `efd001c` `chore(todo): RESOLVED by…`
- **Depois do EXEC:** a revisão final da branch (`81bf339`, `283468b`, `713126a`) levou o catálogo a 593; os números da suíte abaixo são os do fechamento do EXEC
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 293 s; 1788 asserções `ok`, 592 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)
- **Carimbo de mutação:** inválido desde o I1 (esperado); o `sdd health` roda UMA vez, depois dos bots

## O que foi feito

- `8577df6` — I1: 13 saídas decididas (#138, #187 refutados; #214, #181, #102, #152, #137, #74, #122, #154, #101, #128, #93), "6 of the 30" nos três sítios
- `db2eee1` — I2: #143 (D7 emendada), #123/#124 (YAGNI Y5/Y6), #158 (anatomia §6 e gaveta)
- `4af9d0c` — I3: limites declarados de #66, #77, #90, #125, #140 nos cabeçalhos dos sensores
- `921e95e` — I4: `/sdd-plan` com o repasse do grill e o aviso de trabalho longo; chapéu do planner + espelho
- `0521972` — I5 (#113): o `calibrate()` enxerga os 16 sensores
- `41ac7a1` — I6 (#211): Check com `test -f` num caminho ignorado reprova
- `9e521d1` — I7 (#216): `done` abaixo de `blocked` reprova; `3cf0d0a` conserta o SC1010 que ele criou
- `bf660f8` — I8 (#212): o template cita o `--check` do kit; o planner manda rodá-lo
- `e7d1e2d`, `8870bab` — I9/I10 (#217): `check-todo --check <arquivo> --baseline <ref>`, a cópia resolvida contra o repo real
- `52de46e` — I11 (#127): chaves de caminho normalizadas e validadas no `load_config`
- `0ed9218` — I12 (#115): `gate_REVIEW` olha só a rodada; `gate_DOCS` recusa o próprio `45-docs.md` sujo
- `ece5895` — I13 (#63): o gênero do bug é lido do bloco do `Status:`
- `188ca87` — I14 (#121): a porta do `sdd kaizen` aceita worktree do kit; o `kaizen_reminder` vira achado (catraca 35 → 36)
- `9edd800` — I15 (#213): a série recusa linha não-objeto e campo ilegível, nomeando o arquivo
- `4f4a9b3` — I16 (#87): o preflight cobra `total_cost_usd` e `num_turns` numéricos
- `0be5e8d` — I17 (#169): um controle por assassino distinto do mapa; `0c0e13a` declara o limite do kit-guard sob `TMPDIR` longo
- `d658dca`, `ebad097` — I18/I19 (#192): `check-mutation.sh --touched <rev>`, seleção e execução (dica)
- `efd001c` — I20: `RESOLVED by` nos 13; este commit: `KAIZEN_LOG.md` e este handoff

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261003-lote-3-a-catraca-desce/checkpoint.md` | as 20 linhas `done`, com o hash de cada incremento |
| `docs/handoffs/20261003-lote-3-a-catraca-desce/checkpoint-notas.md` | uma nota por incremento: o Red medido, os desvios e as sabotagens |
| `docs/handoffs/20261003-lote-3-a-catraca-desce/triagem-57.md` | insumo do grill da leva 4 (os 22 DEC, com opções) |
| `KAIZEN_LOG.md` | a entrada de 2026-10-04 com o antes e o depois medidos |
| `tests/fixtures/killers-touched.tsv` | o mapa de fixture do Check do I19 (dados) |

## Boot da próxima fase

Ler o `01-plano.md` § "Depois do checkpoint" e seguir na ordem:

1. `git push -u origin fix/lote-3-a-catraca-desce` e o PR contra a `main` (o repo é público, mas o
   Actions não entra: a verificação é local). O corpo leva o saldo "57 → 22 + N nascidos" (N = 1), a
   lista dos 13 `RESOLVED by` e das 22 saídas, a testemunha do I10 (ui24: `0 new … (10 inherited)`)
   e a medição dos 10 controles do I17 (10/10 verdes; a primeira tentativa, 10/10 vermelha, era o
   `TMPDIR` longo, ver Riscos).
2. Esperar TODOS os bots (CodeRabbit, Copilot, Codex) e consertar numa leva só; achado de bot é
   hipótese até medir.
3. `./bin/sdd health` uma vez, depois do último commit de código, disparado pelo humano (~40–50 min,
   593 mutantes depois da revisão final; lançador desanexado). Ele tem de imprimir `the kit copy is green with no sabotage,
   in the usual order and with each of the N killer(s) of the map first`.
4. Merge pelo humano; depois o chore pós-merge (catraca 36 → 23) e o re-sync do espelho de issues.

## Pendências / Decisions for a Human

- **O momento do `sdd health`** — decisão 6: depois de todos os bots, uma vez; quem dispara é o humano.
- **Merge do PR**, e o chore pós-merge e o re-sync do espelho — `01-plano.md` § Depois do checkpoint.
- **O grill da leva 4** — as ~17 decisões dos 22 DEC (`triagem-57.md`).

## Riscos e não-feitos

- **Não verificado por nenhum probe, declarado:** as linhas do caminho principal do catálogo que
  prepõem os controles por assassino e chamam o `controls_verdict` (I17). A prova é a linha do
  próximo `sdd health`.
- **Ambiente:** a suíte rodada com um `TMPDIR` de ~100 caracteres reprova a asserção do kit-guard
  do `check-autonomy.sh` (corte de 200 do `gate_why`); declarado no sensor em `0c0e13a`. O `sdd
  health` roda com o `TMPDIR` do operador — curto ou ausente, ele passa.
- **`--touched` sem `--list`** antes do I19 recusava com rc 2; no topo da branch ele roda.
- **Desvios do plano** (todos com nota no `checkpoint-notas.md`): o `|` do Y5 escapado como `\|`; o
  comentário do `tail_of` reescrito sem apóstrofo; o #77 cita 3 itens vivos (não 4); as regras novas
  do `check-checkpoint.sh` numeradas 5 e 6 (a 3 já era a de documento), cada uma com linha ok própria
  no scan; o piso de itens vale também no `--baseline`; o `SDD_KILLERS_FILE` só vale no `--touched`;
  e uma guarda nova exige que o `--touched` lance exatamente a seleção.
- **Não-feitos deliberados:** os 22 DEC (leva 4); o conserto do `kaizen_reminder` (só registrado);
  sensor para prosa de contrato do `commands/` (#109, leva 4); `CHANGELOG.md` (decidido, #122).

## Achados fora de escopo

- O `kaizen_reminder` diz a frase de repo-alvo quando roda de um worktree do kit → `TODO.md`, seção
  `<!-- sdd:open -->` › Contrato e configuração (N = 1, catraca 35 → 36, `188ca87`)
- A frase do kit-guard cai além do corte de 200 do `gate_why` sob `TMPDIR` longo → não é item (régua
  D15: falha fechada, sem consumidor fora da suíte); limite declarado no `tests/check-autonomy.sh`
  (`0c0e13a`)
