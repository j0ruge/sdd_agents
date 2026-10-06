---
missao: 20261004-lote-4-a-catraca-zera
fase: EXEC
status: done
sessao: e105121e-da96-42c2-8287-571cf7a0ecbf
data: 2026-10-05 05:13
gate: "tests/run-all.sh → rc 0, 'suite green' (1837 linhas '  ok ', 0 FAIL, 485 s com TMPDIR=/tmp); anchors: all 612 mutants still apply and leave valid code; checkpoint I1–I23 done, cada Commit um sha no git log; check-todo: '16 finding(s), all within 8 lines, carrying anchor + date, every anchor on target' = todo-findings 16, os 16 com RESOLVED by"
---

# Handoff — EXEC — Lote 4: a catraca zera

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 24 incrementos estão `done`, executados de forma interativa (decisão 6) em duas sessões (I1–I15
e I16–I24), cada um com o Check do plano medido vermelho antes e verde depois. 7 itens saíram do
`TODO.md` sem código (I1, I2, I4) e os 16 restantes foram consertados com sensor, todos com
`RESOLVED by`. Comportamento novo: o `sdd run` para no carimbo com rc 2 (I13); o publisher não roda
mais o health (I14); o ledger carrega `runner_sha` (I15); o config é relido por volta (I16);
`sdd note-manual` grava a fase feita à mão (I17–I19); o relatório na ponta da base pergunta quem o
trouxe (I20); a régua de idioma lê `docs/` por censo (I21). ADR 0015 aceita, com as emendas em
0004, 0011, 0013 e 0014. Catraca 23 → 24 na branch (16 resolvidos + N = 8 nascidos: 5 na revisão final, 2 na rodada dos bots do PR #222, 1 no carimbo) → 8 depois do chore.
Catálogo 593 → 612, todos aplicam. Próximo, pela decisão 6: push, PR, esperar TODOS os bots,
consertar numa leva, `./bin/sdd health` uma vez (o humano dispara), merge pelo humano.

## Estado do repo

- **Branch:** `fix/lote-4-a-catraca-zera`, só local (nunca empurrada; upstream aponta `origin/main` = `fe9441d`)
- **Último commit:** o commit deste handoff (I24), sobre `574d892` `chore(checkpoint): I23 done (dcfb072)`
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 485 s; 1837 linhas `ok`; 612 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)
- **Carimbo de mutação:** inválido desde o I1 (esperado); o `sdd health` roda UMA vez, depois dos bots

## O que foi feito

- `b120607` — I1: 4 saídas por decisão escrita (Y7 #88, decididos #130, #155, #109) — catraca 23 → 19
- `a1e4f12` — I2 (#180, #218): ato fora do git deixa commit de registro; passo pós-merge sai da tabela — 19 → 17
- `9c9c5e1` — I3 (#194): o executor sabota a linha nova de um `R<n>`
- `ae81ed3` — I4 (#178, #135): o TICKET não confirma no Jira; comentário de código é do código — 17 → 16
- `c2e508a` — I5 (#191): a âncora do `TODO.md` mede só o símbolo designado
- `fde1b19` — I6: a aprovação do `/sdd-plan` é a resposta do humano a uma pergunta YES/NO
- `ac0a6b2`, `ee5c550` — I7/I8 (#92): `check-checkpoint.sh --red <checkpoint>`; o planner mede o vermelho antes do PLAN-AUTO
- `ef1bc82` — I9 (#95): o starter sugere o lint do `TODO.md` no `TEST_CMD` do alvo
- `7cb9328` — I10 (#134): as ADRs antigas ganham dono e o kit passa a `ADR_CHECK=block`
- `efb5db1` — I11 (`kaizen_reminder`): o lembrete reconhece um worktree do kit
- `f05aa7a` — I12 (#67): `agents/` entra na chave do carimbo
- `bee7a63`, `fd05345` — I13/I14 (#142, #198): o `sdd run` para no carimbo; o publisher para de rodar o health
- `ed252ce`, `44de239` — I15/I16 (#129): `runner_sha` em toda linha do ledger; o config relido por volta
- `6eca40a`, `e03ca8b`, `82c2986` — I17/I18/I19 (#153): os leitores aprendem `manual`; `sdd note-manual`; a dica do `sdd status`
- `48e7870` — I20 (#179): relatório na ponta da base conta só se o commit que o trouxe carrega a missão
- `76a2a06`, `83d9258` — I21/I22 (#141, #108): censo de `docs/` e piso derivado no check-lang; os outros três pisos declaram o limite
- `dcfb072` — I23 (#98): o schema da série ganha sensor de chave contra a prosa
- este commit — I24: `RESOLVED by` nos 16, emendas das ADRs, glossário, drift, `KAIZEN_LOG.md` e este handoff
- `2dd7683` — fora da missão: nota F8 na gaveta (o plano mede contra a base, não contra os incrementos anteriores)

## Revisão final da branch (depois do I24)

Um revisor de contexto novo leu `fe9441d..409f5f5` (código e contrato), só leitura. Veredito: lote
bem construído; **1 Important e 5 Minor**. Consertados numa leva, cada um com vermelho medido antes:

- `091012c` — **Important:** `sdd note-manual` numa missão já mergeada movia o checkout para a
  branch gasta e o deixava lá. Agora volta para a branch em que o humano estava e avisa quando a
  branch da missão já é ancestral da base (squash não é visto, declarado). 2 mutantes.
- `16a0d64` — **Minor, mas regressão da leva (I16):** chave `readonly` no config matava a volta 1 com
  o erro cru do `unset`; agora para com a frase do runner. 1 mutante.

Os 5 minors restantes viraram itens do `TODO.md` por decisão do humano (catraca 16 → 21, N = 5):
`red_norm` do `--red` com array vazio sob `set -u` em bash 4.0–4.3 (não reproduz no bash 5.2 daqui);
as linhas de remédio da parada no carimbo são genéricas quando o carimbo é impossível;
`sdd run --phase PR` com só o carimbo faltando commita uma nota `intervention:` e para sem sessão; a
dica do `sdd status` pergunta de toda fase verde de missão rodada noutra máquina; o `ok` do
`note-manual` afirma "a nota" mesmo sem `checkpoint.md`. Depois da leva: suíte verde, 1839 `ok`,
377 s; 615 mutantes aplicam.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261004-lote-4-a-catraca-zera/checkpoint.md` | as 24 linhas `done`, com o hash de cada incremento |
| `docs/handoffs/20261004-lote-4-a-catraca-zera/checkpoint-notas.md` | uma nota por incremento: o Red medido, os `Ruling:`, as sabotagens e as re-âncoras |
| `docs/adr/0015-the-stamp-is-not-headless.md` | a ADR da missão, agora `accepted`, §1–§4 |
| `KAIZEN_LOG.md` | a entrada de 2026-10-05 com o antes e o depois medidos |

## Boot da próxima fase

Ler o `01-plano.md` § "Depois do checkpoint" e seguir na ordem:

1. `git push -u origin fix/lote-4-a-catraca-zera` e o PR contra a `main` (o repo é público, mas o
   Actions não entra: a verificação é local). O corpo leva: o saldo "23 → 0 + N nascidos" (N = 5, da revisão final);
   a lista dos 16 `RESOLVED by` e das 7 saídas; a ADR 0015 e as quatro emendas; o catálogo
   593 → 612; as mudanças de comportamento — o `sdd run` para no carimbo com rc 2 (I13), a volta 1
   lê o config da branch da missão (I16), o `/sdd-plan` pergunta YES/NO (I6), o slot de símbolo é
   obrigatório (I5) —; e o yokoten dos alvos (§ Pendências do `00-missao.md`).
2. Esperar TODOS os bots (CodeRabbit, Copilot, Codex) e consertar numa leva só; achado de bot é
   hipótese até medir.
3. `./bin/sdd health` uma vez, depois do último commit de código, disparado pelo humano (~45–55 min
   com 615 mutantes; lançador desanexado). Desde o I12 a chave inclui `agents/`.
4. Merge pelo humano; depois o chore pós-merge numa branch `chore/todo-pos-merge-lote-4` (apaga os
   16, catraca 24 → 8, `todo_rm.py` provando cada hash contra `origin/main`) e o re-sync do espelho
   de issues — os 16 fecham como `fixed by <hash>`, as 7 saídas (#88, #218, #130, #155, #109, #180,
   #135) à mão como `not planned`; os 8 nascidos viram issues novas.

## Pendências / Decisions for a Human

- **O momento do `sdd health`** — decisão 6: depois de todos os bots, uma vez; quem dispara é o humano.
- **Merge do PR**, o chore pós-merge e o re-sync do espelho — `01-plano.md` § Depois do checkpoint.
- **Yokoten nos alvos** e o retrofit da skill `todo-to-github-issues` (`SKILL.md:124` descreve a regra
  de âncora antiga) — § Pendências do `00-missao.md`; fora do kit.

## Riscos e não-feitos

- **Desvios do plano** (todos com `Ruling:` na nota do incremento): o protótipo punha o global do
  I15 e as funções do I16 em posições que o plano recusa (seguiu o plano); os mutantes do I17, I18 e
  I20 foram realocados para não separar um comentário da sua função; o I17 deslocou âncoras que o
  plano, medindo contra `fe9441d`, dizia que não deslocariam (F8 da gaveta); o verbete do `manual`
  diz "quinta forma de linha (o sexto evento)", porque o `docs/pipeline.md` conta formas; o I21
  acrescentou `commands/*.md` e `commands/` que o protótipo não trazia (decisão 8); antes, I6
  (ordem da chamada), I9 (números de hoje no schema), I11 (slot `kit_id`), I13 (asserção de
  `--dry-run`) e I14 (#142 e #198 em linhas diferentes).
- **Limites declarados, sem probe:** o reset do `GATE_PR_STAMP_WHY` e o `sdd retry PR` que não para
  no carimbo (I13); config quebrado no meio do run morre pelo mesmo `die` do lançamento (I16); o
  ledger da dica do `sdd status` é por máquina (I19); três casos que falham fechado no
  `tip_add_carries_mission` (I20); apagar um padrão não-docs do `SURFACE_SPECS` (I21); o sensor de
  chave da série mede nomes, não unidade (I23).
- **Mudança de comportamento a anunciar no PR:** a volta 1 do `sdd run` lê o config da branch da
  missão, depois do checkout (I16); um config quebrado só nela agora para o run na volta 1.
- **Não-feitos deliberados:** migrar checkpoints legados; o token `waiting` (Y8); dividir o
  `docs/pipeline.md` (#130); o juiz pontuar a linha `manual`; o `note-manual` escrever no
  `pipeline.log`; recusar o `note-manual` depois do merge.

## Achados fora de escopo

- 5 itens novos no `TODO.md` (N = 5), os minors da revisão final, por decisão do humano: o
  `--red` sob bash 4.0–4.3, o remédio genérico da parada no carimbo, a intervenção do `--phase PR`
  sem sessão, a dica do `sdd status` em missão de outra máquina e o `ok` do `note-manual`. A lição
  de planejamento F8 foi para a gaveta
  (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, `2dd7683`).
- 2 itens novos da rodada dos bots do PR #222 (N = 7): a linha do checkpoint com menos de cinco
  células, que os dois leitores pulam, e o fail-open residual da ADR 0015 §3 (outra missão que edite o
  checkpoint desta).
- 1 item nascido no carimbo (N = 8): a suíte herda `GIT_DIR` de quem a chama — um `git bisect run`
  fez os fixtures do `check-gates.sh` escreverem no repositório real (`core.bare`, `[user]`, tags).
