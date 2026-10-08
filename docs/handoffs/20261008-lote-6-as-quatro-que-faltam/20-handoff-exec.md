---
missao: 20261008-lote-6-as-quatro-que-faltam
fase: EXEC
status: done
sessao: 489b90d7-dcd1-4b0c-8926-e5cbcb2864a4
data: 2026-10-08 15:41
gate: "tests/run-all.sh → rc 0, 'suite green' (1927 linhas '  ok ', 0 FAIL, 582 s com TMPDIR=/tmp/l6-exec, em bbff069); anchors: all 685 mutants still apply and leave valid code; checkpoint I1–I7 done, cada Commit um sha no git log; check-todo: '4 finding(s), all within 8 lines, carrying anchor + date, every anchor on target' = todo-findings 4, os 4 com RESOLVED by"
---

# Handoff — EXEC — Lote 6: as quatro que faltam

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 7 incrementos estão `done`, executados de forma interativa no worktree ligado
`~/repos/sdd_agents-lote-6` (ADR 0016 §2), cada um com o Check medido vermelho antes e verde depois.
As quatro issues (#238, #239, #236, #240) carregam `RESOLVED by` no `TODO.md`; o F8 da gaveta fechou.
Comportamento novo: o censo do `GIT_DIR` vê o git chamado por caminho e por `$GIT` (I1); os três
leitores de cerca do runner leem uma cerca CommonMark só, `FENCE_AWK`, e um exemplo cercado com `~~~`
ou fecho mais curto não vira decisão nem gênero (I2); o `sdd kaizen` recusa o checkout que os
`sdd run` dos alvos executam, nomeando o `git worktree add`, e a projeção avisa (I3, ADR 0017 aceita,
0016 com `Amended by`); o `sdd-planner` mede cada incremento contra o disco que os anteriores deixam
(I4, espelho por `./bin/sdd install --force`); a guarda de kit não passa mais o kit pelo ambiente e
aguenta milhares de caminhos sujos (I5), e vê o nome com `\n`, publicado codificado como o `md5sum` o
escapa (I6). Catálogo 676 → 685, todos aplicam. Catraca 4 na branch → 0 depois do chore. O kit congela
no merge (decisão 6). Próximo: revisão final da branch, PR, bots, uma leva, `sdd health` uma vez, merge
pelo humano.

## Estado do repo

- **Branch:** `fix/lote-6-as-quatro-que-faltam`, no worktree `~/repos/sdd_agents-lote-6`, **não
  empurrada** (base `origin/main` = `fc32329`)
- **Último commit:** o fecho do I7 (este handoff), sobre `bbff069`
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 582 s; 1927 linhas `ok`; 685 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)
- **Carimbo de mutação:** ainda não — `./bin/sdd health` roda UMA vez, depois de todos os revisores

## O que foi feito

- `d20e740` — plano aprovado pelo humano (`sdd approve`), com a ADR 0017 alocada
- `aa3a0b8` — I1 (#238): o censo conta `/…/git` e a variável `GIT`; controle negativo de 5 → 8 arquivos
- `ea289b4` — I2 (#239): `FENCE_AWK` para os três leitores; 7 `fence:` + 2 mundos da sabotagem; 3 mutantes reancorados no fragmento, 2 nos leitores, 3 novos
- `3c54ac1` — I3 (#236): `kit_checkout_targets_run` e a recusa do `sdd kaizen`; o lembrete aponta o worktree; 6 `kaizen door:`, 4 mutantes; docs
- `81aef08` — I4 (F8): parágrafo no § 4 do `sdd-planner`, probe `hat:` no `check-hat.sh`; gaveta
- `d3e3db0` — I5 (#240, fatia 1): os quatro canais da guarda viram arquivos; regime 2k e o kit limpo que ganha um caminho
- `94c48ec` — I6 (#240, fatia 2): `hat_status_lines -z`, chave crua e o nome codificado uma vez na linha publicada; regime 2l e o índice do 2j; 2 mutantes
- I7 (este commit): `RESOLVED by` nos 4, ADR 0017 aceita, emenda na 0016, o congelamento na gaveta e no `CONTEXT.md`, `KAIZEN_LOG.md` e este handoff

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261008-lote-6-as-quatro-que-faltam/checkpoint-notas.md` | uma nota por incremento: Red medido, `Ruling:`s, sabotagens, `--only` |
| `docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md` | o `sdd kaizen` recusa o checkout dos alvos (emenda a 0016 §2); `accepted` |
| `KAIZEN_LOG.md` | entrada `2026-10-08 — Lote 6: as quatro que faltam` |

## Boot da próxima fase

Execução interativa, no worktree, nunca `sdd run` no kit. Ordem (`CLAUDE.md` § carimbo):

1. revisão final da branch por um revisor de contexto novo (`git merge-base origin/main HEAD`..HEAD);
   Critical/Important numa leva só, cada conserto com vermelho medido;
2. `git push -u origin fix/lote-6-as-quatro-que-faltam` e o PR com o corpo do `templates/pr-body.md`,
   declarando as mudanças de comportamento (abaixo);
3. esperar **todos** os bots (Codex, CodeRabbit; `Review rate limited` = não revisou) e consertar numa leva;
4. `./bin/sdd health` UMA vez no worktree (lançador `setsid`, env sem `CLAUDE*`/`GIT_*`, `TMPDIR` curto,
   vigiar pelo PID); o mapa de 676 já está no `.sdd/cache/` do worktree;
5. merge pelo humano; o kit congela ali.

**Mudanças de comportamento a declarar no PR:** I2 (um exemplo cercado com `~~~` dentro de crases ou
com fecho mais curto não vira mais decisão nem gênero); I3 (o `sdd kaizen` recusa o checkout para onde
o `sdd` do PATH resolve, rc 1; o `--dry-run` ali avisa); I5/I6 (a guarda de kit aguenta milhares de
caminhos sujos e vê o nome com `\n`; o motivo do `kit-touched` mostra o nome codificado, `\\`, `\n`,
`\r`); I4 (o chapéu do planner muda: yokoten no sales_quote).

## Pendências / Decisions for a Human

- O merge, o chore pós-merge (catraca 4 → 0) e o re-sync do espelho de issues (#236, #238, #239, #240 fecham).
- **Congelar o kit no merge** (decisão 6): nada em `bin agents templates config` até o veredito; o
  `sdd kaizen` de um worktree ligado (ADR 0017).
- Yokoten no sales_quote: `sdd install --force` numa branch `chore/kit-<sha>`; o PR novo substitui o #417.
- A remoção do worktree depois do merge, pelo verbete "`sdd health` in the main checkout is slow
  again after a kit mission" do `docs/failure-modes.md` (mapa por união, carimbo se a linha 6 estiver vermelha).

## Riscos e não-feitos

- **Declarados no código, sem probe:** o ramo do CR do `enc()` (só decide o que o motivo imprime); o
  `local shared_why` do `cmd_kaizen` (nada lê a variável depois do `die`/`warn`); o ramo
  `|| return 1` do `readlink -f` no `kit_checkout_targets_run` (não falha num caminho que o
  `command -v` achou); o probe do F8 degradado para ler o arquivo inteiro (o mesmo limite dos outros
  probes de texto do chapéu).
- **Desvios do plano, cada um com `Ruling:` nas notas:** o `fence_line` sem valor de retorno (I2); dois
  mundos de cerca fora do prefixo `fence: ` para o Check continuar 7 (I2); a asserção do lembrete fora
  do kit ganhou o termo novo (I3); a frase do F8 refluída para caber numa linha (I4); a árvore anterior
  por `printf '%s'` (I5); chave crua e um `enc()` só, e a asserção do 2j lendo `back\\slash.md` (I6).
- **Uso real não medido:** a primeira guarda numa máquina com milhares de caminhos sujos, o primeiro
  `sdd kaizen` recusado no checkout dos alvos.

## Achados fora de escopo

Nenhum nascido nesta leva: a catraca fica em 4 na branch, os quatro com `RESOLVED by`, e desce a 0 no
chore pós-merge.
