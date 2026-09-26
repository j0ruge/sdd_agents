# Handoff — o sensor para no primeiro FAIL: da implementação ao merge (2026-09-25)

> Continuação autocontida do plano
> [`2026-09-25-o-sensor-para-no-primeiro-fail.md`](2026-09-25-o-sensor-para-no-primeiro-fail.md)
> (spec: [`../specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md`](../specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md)).
> As Tasks 1–4 e a revisão final do executing-plans estão **feitas**; falta a **Entrega**. Leia
> este arquivo e a seção "Entrega" do plano; o resto do plano é histórico.

## Atualização, 2026-09-25 22:20 — tudo feito até o carimbo; falta só o E6 (merge humano)

- **`/codereview:codereview`** sobre `main..HEAD` (5 agentes por arquivo + varredura de código morto,
  sonnet): segredos PASS, código morto limpo. Consertado numa leva (commit `fix(sensors): …` seguinte):
  1. **MEDIUM, confirmado e medido:** o `check-hat.sh` vazava a caixa `mktemp -d` de `boot_probes`,
     `census_probes` e `release_probes` quando o `fail()` saía no meio (a cláusula deste branch):
     **14 diretórios em `/tmp` no health nº 2**, um por mutante que o hat mata. `PROBE_BOXES` + um
     `trap … EXIT`; reproduzido 1 → 0 com três mutantes, e as duas sabotagens (sem o trap, sem o
     registro da caixa do boot) trazem o vazamento de volta. **Sem probe durável** (o mundo pede um
     mutante e um vermelho), como o conserto do filho do hook.
  2. **MEDIUM:** o cabeçalho do `check-health.sh` numera as asserções (1–16) e não citava o censo nem
     as probes `surface:` do #59/#168: itens 17 e 18.
  3. **LOW:** `CLAUDE.md` e `docs/failure-modes.md` diziam "20 a 50 min" de health: agora ~18 min.
  4. **HIGH do agente, REFUTADO por medição:** "o `sdd run` do hook (`hook_owner`) vaza se um
     `check` vermelho sair antes do `wait`". Forçado vermelho dentro de mutante, com e sem conserto:
     0 processos e 0 sobras nos dois. O `wait` extra não entrou; o comentário do `check()`, que
     prometia "every process family … this file started", passou a dizer o que o `finally` faz.
  Recusados com razão: a ordem primitiva-antes-de-isento do `census_kind_of` (deliberada); selftest do
  controle "só com `wait -n`" (as funções não dependem de `wait -n`); `run_control` "ignora `dir`"
  (premissa errada: o controle não recebe argumento, os stubs também usam variável livre); sentinela
  `999999`; tempo de sobrevivente não gravado.
- **Medido, anterior ao branch (pendência sem rota de `TODO.md` pela régua D15 — não falha aberto,
  sem consumidor fora da suíte):** cada health deixa um `/tmp/sdd-coordination-*/repo/.git` com o
  registro de dono de um `sdd run` do fixture `repo`, processos já mortos — o `rmtree(work)` do
  `finally` corre contra o supervisor que ainda escreve. É o mutante **`COORD_pidfd_unchecked`**, que
  mata o sensor por **exceção** (`fails=0`), caminho que não passa pela cláusula: 6 rodadas de cada,
  `main` (`8f2f2a9`) vazou **2**, o branch **1**. Os `sdd-ck-*` (~150 por health) também são
  anteriores (`bin/sdd:440`, 158 no health do #168).
- **Feito:** suíte rápida verde (1491 ok) e `SDD_MUTANT=1` verde, commit `e8283e6`, **health nº 3**
  21:55:51 → 22:14:15, **18 min 24 s**, 406 de 406, carimbo `1240f67f…` → `STAMP VALID`; caixas do hat
  em `/tmp` depois dele: **0** (eram 14 no nº 2).
- **Próximo: E6.** Pedir o merge do #170 ao humano; depois, com o ok, re-sync do espelho de issues
  (#144 órfã, `completed` citando `b874141`) e apagar o branch.

## Atualização, 2026-09-25 21:35 — E1 a E5 feitos; falta o `/codereview` e o E6

- **E1 feito:** branch empurrado, **PR #170** aberto contra `main`
  (<https://github.com/j0ruge/sdd_agents/pull/170>). Não abra outro.
- **E2 feito:** Copilot sem cota; Codex (pedido com `@codex review`, como no #168) e CodeRabbit
  revisaram. Três achados, todos válidos, consertados numa leva no `tests/check-mutation.sh`, cada
  um com probe vista vermelha antes e sabotagem que a deixa vermelha de novo:
  1. `SDD_MUTATION_JOBS=1` rodava o 1º mutante ao lado do controle (Codex e CodeRabbit; era o Minor
     adiado abaixo): a vaga agora é esperada **antes** de cada lançamento;
  2. um controle morto antes de escrever `control.rc` (OOM, sinal) deixava o `control_red` falso e o
     pool lançava o catálogo inteiro: `control_run` escreve `none (exit N)` quando o controle volta
     sem rc, nos dois caminhos (pool e lotes sem `wait -n`);
  3. handoff e gaveta ainda diziam "sem PR" (este texto e a linha F1 da gaveta).
  Achado ao consertar o 1: um job que termina antes de um `wait` sem argumento deixa o status na
  tabela, e o `wait -n` seguinte o devolve na hora (1 ms contra 300, bash 5.2). Com a vaga esperada
  antes do lançamento, o controle vermelho da `pool_selftest` sobrava assim e contaria como vaga
  livre no pool real, que roda no mesmo shell logo depois. `run_pool` começa por `jobs >/dev/null`.
  No HEAD anterior (`7bb0762`) a selftest deixava 0, medido: o health nº 1 não foi afetado.
- **E3 feito, adiantado:** o health nº 1 rodou **durante** a espera pelos bots, sobre `7bb0762`:
  20:47:27 → 21:06:23, **18 min 56 s**, 406 de 406, `kit healthy`, mapa com 406 linhas de 3 colunas.
  Ele só grava os tempos no mapa (por mutante, fora da chave do carimbo), então vale para o código
  consertado. Quem carimba é o nº 2, depois do conserto.
- **E4 feito:** health nº 2 sobre `f5f6aba` (o conserto dos bots): 21:11:04 → 21:29:18,
  **18 min 14 s**, 406 de 406, `kit healthy`, carimbo `e7867ba8…` escrito, `stamp-check` → `STAMP VALID`.
  O mais longo primeiro rendeu só 42 s: os 406 mutantes somam 12 031 s e o mais longo leva 86 s.
- **E5 feito:** `KAIZEN_LOG.md`, gaveta (F1 e item (b) em `FEITO`) e o topo do spec, fora da chave do
  carimbo. **Próximo passo: `/codereview:codereview` sobre `main..HEAD`**, depois o E6. Conserto em
  `bin/ tests/ templates/ config/` pede mais um health (~18 min) e `stamp-check`.

## Estado em 2026-09-25, 20:40

- Branch `perf/sensor-para-no-primeiro-fail`, a partir de `main` = `8f2f2a9`. **Não empurrado, sem
  PR, sem `sdd health`.** Árvore limpa no HEAD do código, `fa6b469`.
- Commits: `95e356a` spec · `0a4c3bb` plano · `e07e5fc` cláusula nos nove sensores + censo ·
  `75c6e09` controle no pool, mapa de 3 colunas, mais longo primeiro · `82572b2` TODO 83 → 82,
  `CLAUDE.md`, spec · `fa6b469` conserto dos 3 Important da revisão final · e o commit deste handoff.
- Em `fa6b469`: `tests/run-all.sh` → `RC=0` (suite green) e `SDD_MUTANT=1 tests/run-all.sh` → `RC=0`
  (o regime do controle do catálogo), 0 processos `hook-child`/helper sobrando.

**Medido (Task 4, amostra fixa de 24 mutantes, 12 jobs, 3 rodadas):**

| | antes (`8f2f2a9`) | depois |
|---|---|---|
| soma do passo assassino | 1328,7 s | **570,9 / 570,5 / 574,0 s** (−57%) |
| autonomy · gates · kaizen · preflight (r1) | 846,4 · 404,4 · 28,2 · 49,7 | 400,8 · 144,1 · 11,8 · 14,1 |
| CONTROL dentro do pool | rc 0 | rc 0 ×3 |
| órfãos · nFAIL por mutante | — | 0 ×3 · 1 em todos os 26 |

## Decisão do humano (2026-09-25): até o fim, `/codereview` só no final

Ordem: **E1 → E2 → E3 → E4 → E5 → `/codereview:codereview` → (conserto?) → E6.**

⚠️ **Custo conhecido dessa ordem, aceito:** o carimbo é o conteúdo de `bin/ tests/ templates/
config/`. Achado do `/codereview` consertado em um desses diretórios invalida o carimbo do E4 e
pede **mais um** `sdd health` (a ordem do mais longo primeiro já estará gravada, então ~≤ 20 min),
depois `stamp-check` de novo. Achado só de prosa (`docs/`, `CLAUDE.md`, `KAIZEN_LOG.md`, `TODO.md`
fora da catraca) não custa carimbo. Confira com o `stamp-check` antes de re-rodar por desconfiança.

## Antes de começar (sessão nova)

1. `git switch perf/sensor-para-no-primeiro-fail && git status --short && git log --oneline -3`
   e `ps -eo pid,etime,cmd | grep -E 'bin/sdd|run-all|check-mutation' | grep -v grep` (nada rodando).
2. Recrie no scratchpad **desta** sessão o lançador e o conferidor de carimbo: o texto está no
   plano, "Antes de começar", passo B (`health-launch.py` e `stamp-check.sh`). Cópias da sessão
   anterior, se o `/tmp` ainda as tiver:
   `/tmp/claude-1001/-home-joruge-repos-sdd-agents/8051097c-3663-4a0a-a282-8f25f85d9058/scratchpad/`.
3. Regras que custaram caro:
   - suíte e health **só** pelo lançador (`SIG_DFL`, sem `CLAUDE*`); nunca como tarefa de fundo do
     Bash tool; espere com `until grep -q '^RC=' <log>; do sleep 20; done` em segundo plano;
   - **nunca commite com um `sdd health` rodando** (o hook de commit apaga `/tmp/sdd-*` com mais de
     10 min e mata as sandboxes);
   - nunca exporte `SDD_MUTANT` no seu shell; nunca rode `tests/check-mutation.sh` sem argumento à mão.

## A Entrega

- **E1. FEITO — PR #170.** (Era: `git push -u origin perf/sensor-para-no-primeiro-fail`; `gh pr create --base main`, título
  `perf: the sensor stops at its first FAIL — health under 20 min (P2(b))`. Corpo: resumo; a tabela
  acima; o que o censo prova (enumera os passos de `SDD_MUTANT=1 run-all.sh --list`, junta as
  linhas continuadas, chama cada primitiva sob `SDD_MUTANT=1`/ausente/vazio, piso 9, 5 controles
  negativos antes do laço, desconhecido = SENSOR-BROKEN); as sabotagens (13 no censo, 4 nos
  selftests do pool); os achados da execução e da revisão (abaixo); `Refs` para a gaveta; test plan
  com `- [ ] sdd health twice (1st records the times, 2nd measures and stamps)`; rodapé de atribuição.)
- **E2. FEITO** (ver a atualização no topo). Era: espere **todos** os revisores (CodeRabbit; Codex — comente `@codex review` se não vier;
  Copilot pode estar sem cota). Conserte numa leva só com `/codereview:coderabbit_pr`; conserto em
  `tests/` roda de novo a suíte rápida (pelo lançador) e o `tests/check-health.sh` (censo).
- **E3. Health nº 1** — `python3 "$SP/health-launch.py" "$SP/health1.log" /home/joruge/repos/sdd_agents ./bin/sdd health`.
  Espera: `mutation: score: 406 caught, 0 known gap(s), of 406`, `kit healthy`, `RC=0`; anote START
  e END; `awk -F'\t' 'NF==3' .sdd/cache/mutation-killers.tsv | wc -l` → 406.
- **E4. Health nº 2** — mesmo comando em `$SP/health2.log`. Espera: 406 de 406, `kit healthy`,
  `mutation stamp written`, **≤ 20 min**; depois `"$SP/stamp-check.sh"` → `STAMP VALID`.
- **E5.** `KAIZEN_LOG.md` (entrada nova no topo, `## 2026-09-25 — O sensor para no primeiro FAIL`,
  formato das vizinhas: Problema / Medição com tabela antes-depois / Contramedida / Limite
  declarado; números: a amostra acima, o health 37 min 42 s → nº 1 → nº 2, o controle ×3 verde); na
  gaveta, a linha da F1 e o item (b) passam a `FEITO` com o número do nº 2; no topo do spec,
  `> **FEITO** em <data>: health <nº 2>`. Commit `docs(kaizen): …`, `stamp-check` → `STAMP VALID`, push.
- **`/codereview:codereview`** sobre o branch inteiro (`main..HEAD`). Conserto → suíte rápida +
  censo → se tocou os quatro diretórios, health mais uma vez e `stamp-check` → push.
- **E6.** Peça o merge ao humano. Depois do merge, com o ok dele: `todo-to-github-issues` para
  ressincronizar o espelho (a #144 fica órfã: feche como `completed` citando `b874141`; o plano volta
  `create=0 update=0`) e apague o branch.

## Achados que o PR e o `/codereview` precisam conhecer

**Da execução.** O controle negativo do `check-coordination.sh` chama `check(False)` de propósito e
precisa que ele volte; com a cláusula, `SDD_MUTANT=1 run-all.sh` ficou vermelho no kit intacto, mudo
(Review Focus 1 disparou de verdade). Conserto no sensor (o controle tira `SDD_MUTANT` do
`os.environ` em volta da chamada), asserção irmã da do `hat` no censo, spec §3.1 corrigido e regra no
`CLAUDE.md`: quem chama a própria primitiva de falha de propósito chama fora do mutante.

**Da revisão final (3 Important, consertados em `fa6b469`, cada um reproduzido vermelho antes):**
1. o censo certificava sensor sem cláusula: `fail()` cortado num `}` interno não compilava, o `eval`
   falhava e a probe chamava o `fail()` do próprio `check-health.sh` → `bash -n` no `census_src`,
   `unset -f fail` + `EVAL-BROKEN` (rc 97) no `census_call`;
2. o join lia uma linha só e pulava calado → `census_join` + `census_kind_of` exaustivo, exceções
   em código (`CENSUS_NOT_SENSORS`, `CENSUS_EXEMPT`);
3. o filho do hook (ignora SIGTERM) ficava órfão se um `check()` antes da liberação saísse → a
   liberação do FIFO mora também no `finally` do módulo. Provado por reprodução no scratchpad
   (mutante `COORD_hook_orphans_escape` + `check` forçado vermelho: 1 órfão → 0), **sem** probe
   durável: o mundo pede um mutante e um vermelho forçado.

**Decisões tomadas sem o humano (custo se erradas):** sabotagem desfeita por cópia byte a byte, não
`git checkout` (nenhum); `shellcheck disable=SC2034` no `census_call` (nenhum); âncora do `TODO.md`
`check-mutation.sh:4783` reapontada para `caught=0; gaps=0; errors=0` (uma linha); `set --` antes
do `source` no harness da Task 4 (nenhum). Os 10 itens que o revisor declinou são limites já
declarados no spec §4 ou medidos na Entrega.

**Minors adiados (candidatos a `TODO.md` só se passarem na régua D15):** ~~`SDD_MUTATION_JOBS=1` roda
dois jobs até o controle voltar~~ (consertado no E2); arquivo com `fail()` e `def check(` é classificado pelo primeiro
casamento; o `-le "$JOBS"` do `pool_selftest` tolera a corrida sem dizer; `"${ORDER[@]}"` vazio sob
`set -u` no bash 4.3; a palavra "fechada" no §3.2 do spec.
