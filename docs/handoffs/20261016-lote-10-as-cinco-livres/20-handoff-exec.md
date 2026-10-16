---
missao: 20261016-lote-10-as-cinco-livres
fase: EXEC
status: done
sessao: 3575142f-8e0f-4aca-b430-9a3609c33cf2
data: 2026-10-16 20:10
gate: `tests/run-all.sh` no HEAD limpo `071f189` → `suite green`, rc 0 (20:02:33 → 20:10:30; 2008 linhas `ok`, nenhum `FAIL`, nenhum passo `✗ failed`); Check do I4 → `1 0 3 0`
---

# Handoff — EXEC — o lote 10: as cinco livres

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

I1–I4 feitos, interativos, no worktree; a janela não partiu (`git diff fec0cca..HEAD -- bin agents
templates config` vazio; `kaizen --series` às 20:01 segue em `bad6168`, `missions: 1`).
#277 e #279 viraram registros decididos (catraca 17 → 15); a regra 2 lê `2> >(…)` (e `2>>`, `2>|`, `2<>`)
como mescla (#278, 0 de 5 → 5 de 5 grafias, alvos **106 → 106**); o `/sdd-plan` corta uma branch
provisória e mantém o planner fora do checkout principal (#280, #281; `command:` 11 → 13).
Dois acréscimos do humano no I4: o FAIL do par `--no-track` nomeia as duas causas (`fbe202e`) e a
citação velha do #266 nomeia a seção pelo título (`31cfc09`).
Suíte inteira verde em `071f189`. Próximo: o PR (pendências 1 a 4 do `00-missao.md`), sem carimbo.

## Estado do repo

- **Branch:** `fix/lote-10-as-cinco-livres` — sem upstream, não empurrada.
- **Último commit de conteúdo:** `071f189` (I4, `KAIZEN_LOG.md` e gaveta); o commit do checkpoint do I4
  só toca a pasta da missão (este handoff, a linha I4 e a nota).
- **Working tree:** limpo antes do commit do checkpoint.
- **Suíte:** `tests/run-all.sh` no HEAD limpo `071f189` → `suite green`, rc 0 (20:02:33 → 20:10:30; 2008
  linhas `ok`, nenhum `FAIL`; a última etapa, `anchors: all 716 mutants still apply and leave valid code`).
- **E2E:** não se aplica (o kit não tem interface).
- **Congelamento:** `git diff fec0cca..HEAD -- bin agents templates config` → vazio em todo commit.
- **Checkout principal:** `git -C /home/joruge/repos/sdd_agents status --porcelain` → vazio.

## O que foi feito

- `d8a6290` — I1: #277 e #279 saem da seção aberta e viram dois registros decididos de uma linha, cada um
  com o evento que o reabre (uma Check real numa dessas grafias); `todo-findings 17 → 15`; o cabeçalho do
  sensor aponta o registro decidido.
- `c462a1b` — I2: o `r2_merges` lê `2>`, `2>>`, `2>|` ou `2<>` seguido de `>(` como mescla (`R2_PROCSUB_RE`,
  sobre o texto cru); um grupo de 14 probes com o seu `rule_ok`; `RULE_FLOOR` 8 → 9, `PROBE_FLOOR`
  398 → 412; 16 sabotagens, 13 mortas, as vivas declaradas no cabeçalho (#278).
- `6cb8a12` — I3: o passo 2 do `commands/sdd-plan.md` corta `-b <provisional>`; o *Then* manda o planner
  renomear a branch (`git branch -m <provisional> <branch>`) na decisão do id, enquanto não há upstream, e o
  relay exigir `cd <worktree> &&` e conferir `status --porcelain` e `HEAD` do checkout principal a cada
  devolução; dois pares no `tests/check-hat.sh`; 12 sabotagens, 12 mortas (#280, #281).
- `fbe202e` — I4, acréscimo 1 do humano: o `fail` do par `--no-track` do `check-hat.sh` nomeia as duas
  causas que o literal mede (sem `--no-track`, a branch rastreia a base; sem `<provisional>`, a receita
  nomeia a branch antes de o grill decidir o id). Nenhum probe nem selftest lê o texto; o `pass` não muda
  (é o que a Check da I5 do lote 8 lê). Cópia `tar`: íntegra rc 0; `-b <branch>` → rc 1 com o FAIL novo;
  sem `--no-track` → rc 1 com o mesmo FAIL; restaurada rc 0.
- `31cfc09` — I4: `RESOLVED by c462a1b` no #278 e `RESOLVED by 6cb8a12` no #280 e no #281 (fim da última
  linha do corpo; no #280 a última palavra desceu com o token, e o item foi a 8 linhas, o teto). Acréscimo 2
  do humano: o #266 ("A devolução do planner ao relay não tem regra de idioma", congelado) trocou
  `commands/sdd-plan.md:89` (já `:92` na `3208161`, `:111` desde o I3) pela seção
  `## Relaying the grill to the human`, com o literal "written in `OUTPUT_LANG`"; título e âncora intactos.
  A `todo-to-github-issues` foi consultada antes; `--audit` `auto=0 manual=0`; `check-todo` 15 itens.
- `071f189` — I4: a entrada `## 2026-10-16 — Lote 10: as cinco livres` no `KAIZEN_LOG.md` e a gaveta F3
  (linha do índice e o parágrafo **Hoje (2026-10-16, 20:01).**).

Os commits `chore(checkpoint): I<n> feito` (`a96b7b8`, `1c5891d`, `c88c1a7` e o do I4) só fecham a linha do
checkpoint.

**A medida final** (o I4, remedida no fecho):

| O quê | Antes | Depois | Como |
|---|---|---|---|
| recusas da regra 2 nos alvos | 106 (sensor da `3208161`) | 106 (sensor do HEAD) | mesma corrida, 19:29:18–19:29:29, 37 checkpoints, `lighthouse_project` `3794fc9`, `sales_quote` `a1ad4b74`; saídas idênticas byte a byte |
| varredura do kit | — | `199 cell(s) under the rule, 266 row(s) in 32 file(s)`, rc 0 | `bash tests/check-checkpoint.sh`, 19:29:34 |
| linhas `^  ok    command:` do `check-hat.sh` | 11 | 13 | `git archive 3208161` × HEAD, 19:30 |
| linhas `^  ok    rule:` do `--selftest` | 8 | 9 | idem |
| grafias `2>…>(` que põem a célula sob a regra | 0 de 5 | 5 de 5 | `--check` em fixture às 20:00 (quatro na célula; o `2>\|` em processo, pois o pipe cru já é recusado) |
| catraca (`--count`) | 17 | 15 | 12 depois do chore pós-merge |

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-checkpoint.sh` | `R2_PROCSUB_RE` e o teste no `r2_merges`, o grupo de probes do #278, `RULE_FLOOR=9`, `PROBE_FLOOR=412`, os limites declarados do cabeçalho |
| `tests/check-hat.sh` | `command_branch_cwd_probes` (os pares do #280 e do #281) e o FAIL do par `--no-track` com as duas causas |
| `commands/sdd-plan.md` | o passo 2 com a branch provisória; o *Then* com o rename e as duas ordens do relay |
| `TODO.md` | #277 e #279 na seção decidida; #278, #280 e #281 com `RESOLVED by`; a citação do #266 sem número de linha |
| `tests/health-baseline.txt` | `todo-findings 15` |
| `KAIZEN_LOG.md` | a entrada do lote 10, com o antes e o depois |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | a linha F3 do índice e o parágrafo de hoje do § F3 |
| `docs/handoffs/20261016-lote-10-as-cinco-livres/checkpoint-notas.md` | uma nota por incremento, com Red, Green, sabotagens e medidas |

## Boot da próxima fase

Missão do kit: o PR é do relay, interativo, a partir do worktree `/home/joruge/repos/sdd_agents-lote-10`
(nunca `sdd run` do checkout principal). Leia este TL;DR, as pendências do `00-missao.md` e, se a revisão
pedir um porquê, a nota do incremento no `checkpoint-notas.md`. Nada é visível a usuário: o diff muda um
sensor (`tests/check-checkpoint.sh`), os probes do `/sdd-plan` (`tests/check-hat.sh`), a prosa do comando
(`commands/sdd-plan.md`) e o backlog.

1. **PR e revisão (pendência 1, decisão 5).** `git push -u origin HEAD`; o corpo do `templates/pr-body.md`;
   conferir `gh api repos/j0ruge/sdd_agents/pulls/<n> --jq .head.sha` contra o sha empurrado e então
   `@codex review` num comentário; o `local/ci` pela API de Statuses só com a suíte rodada naquele sha (a
   desta fase rodou em `071f189`; o commit do checkpoint só toca a pasta da missão, mas o status vai no sha
   empurrado). A parada é a rodada limpa do Codex com `local/ci` verde. Achado no modelo do #278
   (substituição de processo como alvo da stderr) ou nas duas regras novas do `/sdd-plan` conserta no PR;
   grafia nova da regra 2 fora disso vai para os limites declarados do cabeçalho, sem item; da 4ª rodada em
   diante, `TODO.md` e o humano decide o merge. Conserto em `tests/` roda `bash tests/check-todo.sh` antes
   do commit (a âncora do #278 está em `tests/check-checkpoint.sh:463` (`r2_merges`)).
2. **Sem carimbo (pendência 2).** O `./bin/sdd health` não roda (a catraca fica em 12). Merge por merge
   commit (`gh pr merge --merge`), nunca squash; o relay pergunta de novo.
3. **O pull ocioso (pendência 3).** Depois do merge, `git -C /home/joruge/repos/sdd_agents pull --ff-only` só
   quando `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vier vazio.
4. **O chore pós-merge (pendência 4), da `main`, com a `todo-to-github-issues`.** `--fix --write` apaga
   #278, #280 e #281 (prova: `git merge-base --is-ancestor` de `c462a1b` e `6cb8a12` na `main`), catraca
   15 → 12. O plano rodado da branch no fecho (só leitura, 20:10) deu `create=0 update=4 orphans=2`:
   `UPDATE (text)` no #278, #280, #281 (o `RESOLVED by`) e no **#266** (a citação nova), e `ORPHAN … no
   RESOLVED by` no #277 e no #279. Da `main`, depois do `--fix --write`, espere `ORPHAN … fixed by` nos três
   consertados (o `--close-orphans` os fecha), `UPDATE (text)` no #266 e as duas órfãs sem `RESOLVED by`,
   que se fecham à mão como `not planned` com o registro decidido (decisão 1).

## Pendências / Decisions for a Human

- **As cinco pendências do `00-missao.md`** seguem com o humano: o PR e a revisão (a parada da 4ª rodada em
  diante é dele), o merge (pergunta nova; merge commit), o pull ocioso do checkout principal, o chore
  pós-merge com o espelho e o fechamento à mão de #277 e #279 como `not planned`, e a triagem dos 12
  congelados depois do veredito.

## Riscos e não-feitos

- **O `2>|` não se mede numa célula:** o pipe cru já é recusado pela regra do `|` nos dois sensores, então a
  grafia só é provada em processo (`mg_merges`, no selftest). Com o escape `\|` a célula também é recusada
  pelo `check-checkpoint.sh` deste repo, que manda a forma herestring.
- **Lado fechado do #278:** todo `>(…)` depois de `2>` conta como mescla, inclusive `2> >(cat >/dev/null)`,
  que não mescla (declarado). Os controles `> >(cat)`, `1> >(cat)`, `12> >(cat)` e `2>/dev/null` ficam fora.
- **Os pisos** (`RULE_FLOOR`, `PROBE_FLOOR`) são mínimos por construção; baixá-los sozinhos sobrevive à
  sabotagem, como em todo precedente (nota do I2).
- **O #280 ficou com 8 linhas**, o teto do `check-todo.sh`; o chore o apaga.
- **O #266 vira `UPDATE (text)`** no espelho por causa da citação nova; o título (a chave) não mudou.
- **Não-feitos, por decisão:** a peça de runtime do #277, recusar o `dq` com expansão do #279, renomear o
  diretório do worktree, o carimbo de mutação e os 12 congelados.

## Achados fora de escopo

- Nenhum novo nesta fase. Os dois achados que a nota do I3 registrou sem commit (a citação velha do #266 e o
  FAIL do par `--no-track` com uma causa só) foram consertados no I4 por decisão do humano (`31cfc09`,
  `fbe202e`).
