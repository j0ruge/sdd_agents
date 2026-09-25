# Handoff — o sensor para no primeiro FAIL: da implementação ao merge (2026-09-25)

> Continuação autocontida do plano
> [`2026-09-25-o-sensor-para-no-primeiro-fail.md`](2026-09-25-o-sensor-para-no-primeiro-fail.md)
> (spec: [`../specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md`](../specs/2026-09-25-o-sensor-para-no-primeiro-fail-design.md)).
> As Tasks 1–4 e a revisão final do executing-plans estão **feitas**; falta a **Entrega**. Leia
> este arquivo e a seção "Entrega" do plano; o resto do plano é histórico.

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

- **E1.** `git push -u origin perf/sensor-para-no-primeiro-fail`; `gh pr create --base main`, título
  `perf: the sensor stops at its first FAIL — health under 20 min (P2(b))`. Corpo: resumo; a tabela
  acima; o que o censo prova (enumera os passos de `SDD_MUTANT=1 run-all.sh --list`, junta as
  linhas continuadas, chama cada primitiva sob `SDD_MUTANT=1`/ausente/vazio, piso 9, 5 controles
  negativos antes do laço, desconhecido = SENSOR-BROKEN); as sabotagens (13 no censo, 4 nos
  selftests do pool); os achados da execução e da revisão (abaixo); `Refs` para a gaveta; test plan
  com `- [ ] sdd health twice (1st records the times, 2nd measures and stamps)`; rodapé de atribuição.
- **E2.** Espere **todos** os revisores (CodeRabbit; Codex — comente `@codex review` se não vier;
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

**Minors adiados (candidatos a `TODO.md` só se passarem na régua D15):** `SDD_MUTATION_JOBS=1` roda
dois jobs até o controle voltar; arquivo com `fail()` e `def check(` é classificado pelo primeiro
casamento; o `-le "$JOBS"` do `pool_selftest` tolera a corrida sem dizer; `"${ORDER[@]}"` vazio sob
`set -u` no bash 4.3; a palavra "fechada" no §3.2 do spec.
