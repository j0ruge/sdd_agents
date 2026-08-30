---
missao: 20260829-o-incremento-que-andou
data: 2026-08-29
---

# Plano — o incremento que andou

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-08-29 sobre `ebe9702` (= `main` após o PR #28, mais o chore do
PR #29). Linhas de `bin/sdd` podem deslocar com os incrementos anteriores — ancore pelo **texto**
citado, nunca pelo número.

### O escritor (runner)

- **`gate_EXEC`** — `bin/sdd:704-748`. Reset de `GATE_EXEC_DIRTY=0` na **entrada** (`:705`) — é o
  padrão que todo global de gate segue (`GATE_HANDOFF_BLOCKED`, `GATE_APP_DOWN`, `:757`). O laço
  `while IFS=$'\t' read -r id _ _ status commit` (`:710`) valida cada linha (`done` sem commit,
  commit inexistente, commit fora da história de HEAD, status inválido) **e** conta:
  `pending|doing) pending=$((pending + 1))`, `blocked)`, `total`. A frase que o ledger carrega hoje é
  `GATE_WHY="$pending of $total increment(s) still to execute"` (`:738`). Depois dela o gate roda
  `TEST_CMD` (`run_check_cmd "$TEST_CMD" "gate-exec-test"`) e exige `20-handoff-exec.md`.
- **`checkpoint_rows`** — `bin/sdd:277`. Imprime uma linha TSV por incremento:
  `ID \t Incremento \t Check \t Status \t Commit`; pula cabeçalho e separador; remonta `\|`.
  É puro (awk sobre `$MISSION_DIR/checkpoint.md`) — o helper novo de contagem nasce em cima dele.
- **`autonomy_session_row`** — `bin/sdd:2058`, assinatura
  `<phase> <attempt> <auto_retry> <moved> <gate> <gate_why>`. Constrói a linha com `jq -cn` e
  `--arg` por campo; converte números com `($x | tonumber? // null)`. ⚠️ **Nenhum `#` dentro do
  bloco `jq -cn \`** — comentário em linha continuada quebra o comando em silêncio (`CLAUDE.md`).
  Os globais `LAST_PHASE_*` (`:2250-2252`) são do `run_phase`, não do gate.
- **Chamadores da linha de sessão** (cinco, e o fato de EXEC só interessa a três):
  - `cmd_run`, porta 1: `bin/sdd:3978-3981` — `gate_"$phase" || gate_rc=$?` → `moved` →
    `autonomy_session_row "$phase" "${attempts[$phase]}" "false" "$moved" …`;
  - `cmd_run`, retry inline: `bin/sdd:4040-4043` — `gate_"$phase" || gate_rc2=$?` →
    `autonomy_session_row … "true" "$moved2" …`;
  - `cmd_retry`: `bin/sdd:4102-4104`;
  - `cmd_kaizen`: `bin/sdd:5186` e `:5207` — fase `KAIZEN`, sem incremento: passam vazio.
- **Onde tirar a foto "antes"**: em `cmd_run`, `run_phase "$phase"` está em `:3951`, precedido de
  `kit_guard_arm` e de `before="$(state_fingerprint)"`; em `cmd_retry`, `:4098`. A foto é só para
  `phase == EXEC`; nas outras fases os três campos vão vazios (⇒ `null`). A foto do **retry inline**
  é o `pending_after` da primeira passada — o gate já rodou entre as duas.
- **`--dry-run` não abre sessão** (`:3956-3962`) e retorna antes do gate — nada a fotografar.
- **Última linha do arquivo é contrato**: `{ main "$@"; exit $?; }` (`tests/check-entrypoint.sh`).

### Os leitores

- **`ledger_outcome_defs`** — `bin/sdd:1776-1780`: três `printf '%s'` com jq **sem apóstrofo**
  (o programa é costurado dentro de string de aspas simples). `def outcome:` em `:1777`,
  `def outcome_tally:` `:1778`, `def phase_index:` `:1779`. Costurado em `cmd_autonomy`
  (`"$def""$odefs"`, `:4276`) e em `kaizen_series` (`"$(ledger_row_is_local)""$(ledger_outcome_defs)"`,
  `:4569`).
- **Onde cada leitor tem a lista de linhas locais, antes de qualquer agrupamento** — é ali que o
  caminho histórico (I3) anota a lista **uma vez**:
  - `cmd_autonomy`: `| map(select(ledger_row_is_local))` em `:4363`;
  - `kaizen_series`: `| ($file_rows | map(select(ledger_row_is_local))) as $raw` em `:4771`.
- **A rubrica do juiz** — `def phase_label:` `bin/sdd:4703-4711`; a cláusula de `leve` é
  `(.auto_retry == true or .moved == false or .gate == "fail")` (`:4708`).
- **A manchete** — `advance_rate:` `:4767-4768` (gate `pass` ÷ sessões), `moved_rate:` `:4769`.
- **`waste`** já é `churned + idle` (`:4448`, `(($t.churned + $t.idle) * 100 / $n)`) — corrige
  sozinho quando `outcome` mudar.
- **Texto de uso** do `sdd autonomy` — `bin/sdd:5230-5236` — diz "advanced · churned · idle";
  ganha uma linha dizendo que `advanced` inclui o incremento que andou.

### Os sensores

- **`tests/check-autonomy.sh`** (3180 linhas, 223 `ok` hoje):
  - stub de `claude` em `$OUTSIDE/stub/claude`, `PATH` prefixado (`:106-113`); missão fixture
    `$MDIR` com `checkpoint.md` reescrito por bloco; `"$SDD" run "$MISSION"` de verdade; linhas
    lidas com `jq -s` sobre `$LEDGER` (`rows`/`nrows`, bloco `== session rows ==` em `:224-260`);
  - um stub que **fecha** um incremento com commit real: `:488` e `:770` escrevem
    `| I1 | slice one | \`true\` → 0 | done | $(git -C "$FIX" rev-parse --short HEAD) |` — copie
    a forma, com **dois** incrementos (`I1` `done`, `I2` `pending`) para o Red do I1;
  - o fixture tri-estado: `== reader: advanced · churned · idle ==` em `:1406-1479`, linhas
    JSON via `localize`, asserções de histograma (`:1433`), `waste` (`:1443`), paridade com a
    série (`:1453`), `assert_bucket_sum`;
  - `ledger_row()` (`:1625`) fabrica uma sessão comparável em `ccccccc`.
- **`tests/check-kaizen.sh`** (1514 linhas, 143 `ok`): fixture do ledger escrito à mão (`:16`,
  formato nosso — a regra de proveniência cobre só artefato de terceiro); grupo `previous`
  (`fff9999`) com **7 sessões comparáveis** asserido literalmente em `:179-190`:
  `outcomes {"advanced":4,"churned":2,"idle":1}`, `advance_rate 0.57`, `moved_rate 0.86`, e o
  `labels {ok:0, leve:2, refez:2}` — **todos re-derivados à mão** quando o I4 mudar a régua.
  ⚠️ O frontmatter de `05-verdict.md` (`:543-560`) é copiado do veredito real `c2dd298`: não tocar.
- **`tests/check-mutation.sh`** (`CATALOG=(` ≈ `:2200`, 179 nomes = `grep -c '^mut_'`):
  - `mut_AUTONOMY_outcome_reads_moved_only` (`:2118`) ancora no **texto exato** de `def outcome:` —
    o I2 muda essa linha e o mutante vira no-op (rc 90 no `sdd health`). **Re-ancorar no mesmo
    commit**, mantendo o sentido (o mutante troca a definição pela régua velha `moved`);
  - `mut_KAIZEN_churn_reads_ok` (`:2144`) ancora em `(.auto_retry == true or .moved == false or .gate == "fail")`
    — o I4 muda a cláusula; re-ancorar;
  - `mut_KAIZEN_outcome_inlined_old` (`:2130`) substitui a costura por uma cópia da régua velha —
    continua válido como está (a cópia é deliberadamente velha);
  - o harness recusa mutante que não muda o arquivo (`cmp -s` ⇒ rc 90) e mutante que não compila
    (rc 91) — cada mutante novo é provado numa cópia antes de entrar: aplica, `diff` mostra
    **uma** linha, `bash -n`, e o sensor nomeado fica vermelho **só** na asserção nomeada.
- **`tests/run-all.sh`** é o `TEST_CMD` (~3,5 min, 666 `ok` em `ebe9702`). Lint `shellcheck -S warning`
  sobre `bin/sdd` e `tests/*.sh`. `tests/check-lang.sh` reprova português em `bin/ tests/ docs/`
  (o `docs/handoffs/` é `OUTPUT_LANG`, isento). `tests/check-checkpoint.sh` valida este checkpoint.

### Os documentos

- `docs/pipeline.md:586-596` — tabela de campos do ledger (uma linha por campo; `gate_why` é a
  última, `:596`); `:674-690` — `outcomes`, `advance_rate` ("the share whose gate passed") e os
  três rótulos (`leve` em `:684-688`).
- `agents/sdd-kaizen.md:40-46` — o que o juiz cita (`advance_rate` = "the share whose gate passed").
  ⚠️ Mexeu no agente ⇒ `./bin/sdd install --force` sincroniza `.claude/agents/sdd-kaizen.md`;
  nunca `cp`, nunca Edit — o harness recusa `.claude/` em sessão headless.
- `CONTEXT.md:17` — verbete **Churn** ("qualquer `churned` na fase ⇒ pelo menos `leve`");
  `CONTEXT.md:51` — D16 (o instrumento da D12).
- `KAIZEN_LOG.md:7-40` — a entrada de 2026-08-28 é o modelo: Problema (Gemba) · Contramedida ·
  tabela Antes/Depois com números medidos.

### Configuração e pitfalls (custam sessão quando ignorados)

- `.sdd/config.sh`: `HANDOFF_DIR="docs/handoffs"`, `OUTPUT_LANG="pt-BR"`, `MODEL_EXEC="opus"`,
  `JIRA_ENABLED=false`, `E2E_CMD=""`, `TEST_CMD="tests/run-all.sh"`, `REVIEW_MAX_ITER=3`.
- **Carimbo de mutação**: `.sdd/logs/mutation-stamp` é o md5 do conteúdo de `bin/ tests/ templates/
  config/`. `gate_PR` exige o carimbo; quem o re-emite é `./bin/sdd health` (~15 min, 179+ mutantes),
  que o `sdd-publisher` roda se o carimbo estiver inválido (`agents/sdd-publisher.md:31-39`).
  `tests/health-baseline.txt` está na chave e diz `todo-findings 77` — **não registrar achado novo
  no `TODO.md` sem mover a catraca no mesmo diff**.
- `set -euo pipefail`: `x="$(cmd)"` morre na atribuição se `cmd` devolve não-zero (`grep` sem
  match); `printf … | grep -q` devolve 141 quando ACHA — herestring sempre; função lida como
  `x="$(f)"` roda em subshell e perde globais — o gate **publica** em global e é **chamado**.
- `awk` é `mawk` (byte a byte; classe negada só com ASCII); `cd` relativo dentro de `$(...)` leva
  `CDPATH=''`.
- A fase EXEC edita `bin/sdd` **durante** o `sdd run` que a executa — a última linha
  `{ main "$@"; exit $?; }` é o que impede o bash de reler o arquivo pelo offset.

### Números de hoje (o "antes" do `KAIZEN_LOG`)

Comandos e saída de 2026-08-29, ledger `~/.sdd/autonomy-log.jsonl` com 151 linhas:

```bash
./bin/sdd autonomy --all-repos --by-mission | grep -E 'runner-sem-dividas|eixo-do-juiz|frete-cif-fob'
#  sdd_agents/20260816-runner-sem-dividas  15 session(s) · 5 advanced · 10 churned · 0 idle · 2 launch(es) · 0 reopened · 0 intervention note(s) · US$ 93.78
#  sdd_agents/20260817-eixo-do-juiz  13 session(s) · 5 advanced · 8 churned · 0 idle · 2 launch(es) · 0 reopened · 0 intervention note(s) · US$ 133.04
#  sales_quote/20260825-frete-cif-fob  23 session(s) · 6 advanced · 13 churned · 4 idle · 2 launch(es) · 0 reopened · US$ 144.88
./bin/sdd autonomy --all-repos | grep -cE '^  [0-9a-f]{7}  .* 100% waste '      # 49   (de 107 versões)
jq -rs 'map(select(.event=="session" and .phase=="EXEC")) | "\(length) · \(map(select(.gate=="pass"))|length) adv · \(map(select(.gate=="fail" and .moved==true))|length) churned · \(map(select(.gate=="fail" and .moved!=true))|length) idle"' ~/.sdd/autonomy-log.jsonl
# 72 · 19 adv · 46 churned · 7 idle
jq -rs 'map(select(.event=="session" and .phase=="EXEC" and ((.gate_why//"") | test("^[0-9]+ of [0-9]+ increment")))) | length' ~/.sdd/autonomy-log.jsonl   # 49
./bin/sdd kaizen --series | jq -c '{latest: .latest | {kit_sha, sessions, outcomes, advance_rate, labels}, guard}'
# {"latest":{"kit_sha":"25d4e1c","sessions":6,"outcomes":{"advanced":5,"churned":1,"idle":0},"advance_rate":0.83,"labels":{"ok":5,"leve":0,"refez":1}},"guard":{"missions_after_change":1,"missions_with_session":1,"sessions":6,"floor":3,"sufficient":false,"degenerate_axis":true}}
```

Churn **real** de EXEC (o `N` do `gate_why` não caiu em relação à sessão EXEC anterior da missão):
`frete-cif-fob` 1 (US$ 3,64) · `fecho-que-nao-mente` 1 (US$ 9,81) · `o-laco-da-qa` 1 (US$ 3,26) ·
`portas-do-humano` 1 (US$ 5,18) · `lote-facil` 1 (US$ 2,43) · todas as outras 0.

## Arquitetura da mudança

```
checkpoint.md ──checkpoint_rows──► checkpoint_tally (novo, puro)  "pending\ttotal\tblocked"
                                        │                    ▲
      cmd_run / cmd_retry: foto ANTES ◄──┘                    │ gate_EXEC conta por ele (uma definição)
      run_phase EXEC                                          │ e publica GATE_EXEC_PENDING / _TOTAL
      gate_EXEC ──────────────────────────────────────────────┘ DEPOIS da validação (vazio se recusou)
      autonomy_session_row … <pending_before> <pending_after> <increments_total>   ⇒ linha v:1 + 3 campos

ledger ──► ledger_outcome_defs
             def outcome           : pass ⇒ advanced │ pending_after < pending_before ⇒ advanced │ moved ⇒ churned │ idle
             def historic_progress : anota linhas EXEC SEM os campos a partir do gate_why (I3), marca progress_source
             def outcome_tally / phase_index (inalteradas)
         cmd_autonomy: anota em :4363, imprime "(N EXEC row(s) read their progress from gate_why …)"
         kaizen_series: anota em :4771; phase_label lê outcome; advance_rate lê outcome
```

Três campos novos, `v` continua `1` (esquema aditivo; leitor antigo ignora campo que não conhece).
Nada é migrado, nada é reescrito.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula. **Os nomes das asserções são contrato**: o Check
de cada incremento grepa exatamente o texto abaixo.

### I1 — o runner escreve `pending_before`, `pending_after` e `increments_total` na linha EXEC

**O quê:** (1) `checkpoint_tally()` — helper puro sobre `checkpoint_rows`, imprime
`pending<TAB>total<TAB>blocked` contando `pending|doing` como pendente; passa a ser a **única**
contagem de status do runner: o laço do `gate_EXEC` mantém a validação (`done` sem commit, commit
inalcançável, token inválido) e **deixa de contar** — os números vêm do helper, chamado uma vez.
(2) `gate_EXEC` publica `GATE_EXEC_PENDING`/`GATE_EXEC_TOTAL`: **vazios na entrada** (o mesmo
reset de `GATE_EXEC_DIRTY=0`) e atribuídos **depois** do laço de validação — um checkpoint que o
gate recusou por rótulo sem artefato (`done` sem commit) não pode virar "o incremento andou".
(3) `autonomy_session_row` ganha `${7:-}` `${8:-}` `${9:-}` → `pending_before`, `pending_after`,
`increments_total`, `tonumber? // null`. (4) `cmd_run` fotografa antes de `run_phase` quando
`phase = EXEC` (`checkpoint_tally | cut -f1`), passa `<foto> <GATE_EXEC_PENDING> <GATE_EXEC_TOTAL>`
na porta 1; no retry inline o "antes" é o `GATE_EXEC_PENDING` da primeira passada; `cmd_retry`
faz o mesmo par. `cmd_kaizen` não muda (defaults vazios). (5) `docs/pipeline.md`: três linhas na
tabela do ledger (contrato muda em três lugares no mesmo commit — aqui são o runner, a tabela e o
sensor).
**Onde:** `bin/sdd` (`checkpoint_rows` vizinhança, `gate_EXEC`, `autonomy_session_row`, `cmd_run`
×2, `cmd_retry`), `tests/check-autonomy.sh`, `tests/check-mutation.sh`, `docs/pipeline.md`.
**Como (TDD):** no bloco `== session rows ==` de `check-autonomy.sh` (`:224`), um checkpoint com
`I1 pending` e `I2 pending` e um stub `claude` que marca **`I1` `done` com commit real** (forma de
`:488`). Red: a linha EXEC não tem `pending_before`. Asserções (nomes exatos):
`an EXEC row carries pending_before, pending_after and increments_total` (espera `2 1 2` via
`jq -r '"\(.pending_before) \(.pending_after) \(.increments_total)"'`);
`a non-EXEC row carries the three as null`; `a done without commit publishes no pending_after`
(stub que escreve `done` com `—`: o gate recusa e a linha lê `null`, não `1`); `the inline retry
starts where the first pass ended` (retry com o mesmo stub morto: `pending_before` do retry ==
`pending_after` da primeira linha). Mutante `mut_LEDGER_progress_not_written` (o `jq -cn` volta a
não escrever os três campos — assassino: a primeira asserção) e `mut_EXEC_tally_counts_done`
(o helper conta `done` como pendente — assassino: a mesma, que espera `1` e lê `2`).
**Check:** `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    an EXEC row carries pending_before, pending_after and increments_total' <<< "$o"` → `1`
**Sensor durável:** as quatro asserções acima em `tests/check-autonomy.sh` + dois mutantes no
`CATALOG`.
**Reversível por:** `git revert` do commit; as linhas escritas com os campos continuam válidas
para o leitor antigo (campo desconhecido é ignorado).

### I2 — `outcome` lê o fato: incremento que andou é `advanced`, não `churned`

**O quê:** `def outcome:` passa a
`if .gate == "pass" then "advanced" elif (.pending_before != null and .pending_after != null and .pending_after < .pending_before) then "advanced" elif .moved == true then "churned" else "idle" end;`
(uma linha, sem apóstrofo). DECLARADO no cabeçalho de `ledger_outcome_defs`: a sessão que fecha o
último incremento sobre uma suíte vermelha lê `advanced` pela contagem, e o lap que ela compra lê
`churned` — o gate é o artefato do **lap seguinte**. Re-ancorar `mut_AUTONOMY_outcome_reads_moved_only`
no texto novo (mesmo sentido: régua `moved` só). Texto de uso do `sdd autonomy` ganha a frase.
**Onde:** `bin/sdd` (`ledger_outcome_defs`, usage), `tests/check-autonomy.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** fixture novo ao lado do tri-estado (`:1406`), missão `m3` com quatro linhas EXEC
novas: `(4→3, fail, moved)`, `(3→3, fail, moved)`, `(3→2, fail, moved)`, `(2→0, pass)` mais uma
`(3→3, fail, moved:false)`. Red hoje: `1 advanced · 3 churned · 1 idle`; verde: `3 advanced · 1
churned · 1 idle`. Asserções: `a session that advanced its increment reads advanced, not churned`
(a linha da versão), `waste counts only the increment that did not move` (`40% waste` — 2 de 5),
e a paridade humana×juiz do fixture novo (`.latest.outcomes` da série == tabela). Mutante
`mut_AUTONOMY_progress_ignored` (a cláusula `pending_after < pending_before` sai — assassino: a
primeira asserção).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session that advanced its increment reads advanced, not churned' <<< "$o"` → `1`
**Sensor durável:** as três asserções + o mutante novo + o re-ancorado.
**Reversível por:** `git revert`; os campos continuam no ledger sem leitor.

### I3 — o caminho histórico: linha EXEC sem os campos lê o `N of M` do `gate_why`, declarado e contado

**O quê:** `def historic_progress:` em `ledger_outcome_defs` — recebe a lista de linhas locais e a
devolve com as linhas EXEC de sessão que **não têm** `pending_before` e cujo `gate_why` casa
`^[0-9]+ of [0-9]+ increment` anotadas com `pending_after = N`, `increments_total = M`,
`pending_before` = `pending_after` da linha EXEC anterior da **mesma** `(repo, mission)` em ordem
de arquivo (primeira linha, ou `M` mudou: `M`; `gate: pass` anterior zera a memória) e
`progress_source: "gate_why"`. Implementação: `reduce .[] as $r ({seen: {}, out: []}; …) | .out`,
chave `([$r.repo, $r.mission] | tostring)`, **sem apóstrofo**. Aplicado UMA vez em cada leitor,
logo após o filtro de repo (`cmd_autonomy :4363`, `kaizen_series :4771`). `cmd_autonomy` imprime,
no parágrafo de contabilidade, `(N EXEC row(s) older than the pending fields read their progress
from gate_why)` só quando `N > 0`. DECLARADO no cabeçalho: caminho datado (2026-08-29), só para
esquema antigo, apagável quando `sdd autonomy --all-repos` não imprimir mais a frase.
**Onde:** `bin/sdd`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`.
**Como (TDD):** o mesmo histórico de `m3` (I2) escrito **duas vezes**: como linhas novas (campos) e
como linhas antigas (`gate_why` `"3 of 4 increment(s) still to execute"` …, sem os campos), em dois
ledgers. Red: o antigo lê `1 advanced · 3 churned`. Asserções: `the historical path and the fields
agree on one history` (diferencial: a linha de versão dos dois ledgers, igual), `the historical
path says how many rows it read from prose` (a frase com `4`), `a growing total is a fix
increment, not churn` (linha `pass` seguida de `"2 of 6 …"` lê `advanced`), `the historical path
never touches a row that carries the fields` (ledger misto: contagem da frase = só as antigas).
Mutante `mut_AUTONOMY_historic_progress_dropped` (a anotação vira identidade — assassino: a
diferencial).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the historical path and the fields agree on one history' <<< "$o"` → `1`
**Sensor durável:** as quatro asserções + mutante.
**Reversível por:** `git revert`; sem ele as linhas antigas voltam a ler `churned`, nada quebra.

### I4 — o juiz lê `outcome`: `leve` só com churn real, `advance_rate` conta os incrementos

**O quê:** `phase_label`: `leve` ⇐ `(.auto_retry == true or outcome != "advanced")`;
`advance_rate: ($sess | map(select(outcome == "advanced")) | length) ÷ …`. Re-ancorar
`mut_KAIZEN_churn_reads_ok` na cláusula nova. `agents/sdd-kaizen.md:40-46`: `advance_rate` = "a
parcela que avançou o incremento ou passou o gate"; `outcomes` idem; `./bin/sdd install --force`.
**Onde:** `bin/sdd` (`kaizen_series`), `tests/check-kaizen.sh`, `tests/check-mutation.sh`,
`agents/sdd-kaizen.md` + espelho.
**Como (TDD):** no fixture do `check-kaizen.sh`, uma missão nova `m7` no grupo `previous`, EXEC de
três linhas com campos `(3→2 fail)`, `(2→1 fail)`, `(1→0 pass)`, sem retry nem escalada. Red: rótulo
`leve`, e `advance_rate` do grupo cai. Asserções: `a designed loop reads ok, and advance_rate counts
the increments that advanced` (`m7 EXEC` = `ok`; `advance_rate` do grupo re-derivado à mão com as
10 sessões), `real churn still reads leve` (o `m6` existente, `gate: fail` sem campos e sem `N of
M`, continua `leve`). **Atualizar os literais** de `:179-190` e do `labels` com a conta à mão,
escrita no comentário. Mutantes `mut_KAIZEN_label_reads_gate` (a cláusula volta a `.gate == "fail"`
— assassino: a primeira) e `mut_KAIZEN_advance_rate_reads_gate` (assassino: a mesma, pela taxa).
**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a designed loop reads ok, and advance_rate counts the increments that advanced' <<< "$o"` → `1`
**Sensor durável:** as duas asserções + dois mutantes + re-ancorado.
**Reversível por:** `git revert`.

### I5 — docs, agente do juiz + espelho, `CONTEXT.md`, `KAIZEN_LOG.md` com antes → depois medidos

**O quê:** `docs/pipeline.md:674-690` (`outcomes`/`advance_rate`/`leve` dizem "o incremento
andou"; a frase de contabilidade do caminho histórico); `CONTEXT.md:17` (Churn: "`churned` é a
sessão que escreveu e **não fez o incremento andar**") e `:51` (D16: os três campos); entrada nova
no topo do `KAIZEN_LOG.md`, modelo da de 2026-08-28: Problema (os números de "Números de hoje"),
Contramedida, tabela Antes/Depois **medida depois do I4** com os mesmos comandos — a linha de
`runner-sem-dividas`, o `46 churned`, as `49 de 107`, `.latest` da série, e as contagens da suíte
(`^  ok    `), do `check-autonomy`/`check-kaizen` e do catálogo. Confirmar `.claude/agents/sdd-kaizen.md`
idêntico a `agents/sdd-kaizen.md` (`diff`).
**Onde:** `docs/pipeline.md`, `CONTEXT.md`, `KAIZEN_LOG.md`, `agents/sdd-kaizen.md` (se sobrou
frase), `.claude/agents/sdd-kaizen.md` via `sdd install --force`.
**Como (TDD):** o Check é o artefato: os cinco arquivos citam a missão, e a suíte segue verde
(o `check-lang` mede o inglês de `docs/pipeline.md` e do agente).
**Check:** `o=$(grep -l 'o-incremento-que-andou' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md); wc -l <<< "$o"; diff -q agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md; echo rc=$?` → `5 e rc=0` — a suíte verde é dever do `gate_EXEC` (`TEST_CMD` roda no gate quando os cinco estão `done`), não deste Check
**Sensor durável:** `tests/check-lang.sh` (idioma) e `tests/check-health.sh` (espelho do agente
via preflight `agent sdd-kaizen stale`); o número do KAIZEN_LOG não tem sensor — declarado.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O mutante re-ancorado (`outcome_reads_moved_only`, `churn_reads_ok`) fica no-op e o `sdd health` responde rc 90 na fase PR | média | I2 e I4 provam o mutante numa cópia antes do commit (`cmp`, `bash -n`, sensor vermelho na asserção nomeada) — é o mesmo ritual dos 6 mutantes da revisão do PR #28 |
| Os literais do `check-kaizen.sh` (`0.57 0.86`, `labels`) re-derivados errado à mão | média | a conta vai **escrita no comentário** ao lado do literal (quantas sessões, quantas `advanced`), como o fixture já faz em `:186-190` |
| `pending_before` fotografado sobre um checkpoint que a sessão anterior deixou inválido | baixa | o helper conta sem validar — a foto é um número; quem decide é o gate, que só publica `pending_after` depois de validar (vazio ⇒ `null` ⇒ `outcome` cai para `moved`, como hoje) |
| O caminho histórico anota uma linha nova por engano | baixa | guarda `has("pending_before") \| not` + asserção `never touches a row that carries the fields` + a frase de contabilidade conta o que anotou |
| `advance_rate` do `.latest` real muda e o veredito anterior do juiz fica incomparável | certa, e aceita | ADR 0001: régua mecânica é código, datada no histórico; a entrada do `KAIZEN_LOG` diz que a régua mudou em 2026-08-29 |
| A sessão EXEC edita `bin/sdd` enquanto o `sdd run` o executa | conhecida | entrypoint `{ main "$@"; exit $?; }` — não tocar na última linha |
| Registrar achado no `TODO.md` mata o carimbo (baseline na chave) | média | achado vai para o handoff `20-handoff-exec.md` § fora de escopo; o humano transporta |

## Verificação end-to-end

Com os cinco `done`:

```bash
tests/run-all.sh | tail -2                          # suite green, rc 0
./bin/sdd autonomy --all-repos --by-mission | grep runner-sem-dividas
#   → 15 session(s) · 14 advanced · 1 churned · 0 idle · …   (o 1 é a r1 do REVIEW, churn real)
./bin/sdd autonomy --all-repos | grep -cE '^  [0-9a-f]{7}  .* 100% waste '   # ≤ 10  (era 49)
./bin/sdd autonomy --all-repos | grep 'read their progress from gate_why'      # (49 EXEC row(s) …)
jq -rs 'map(select(.event=="session" and .phase=="EXEC" and .mission=="20260829-o-incremento-que-andou")) | .[0] | {pending_before, pending_after, increments_total}' ~/.sdd/autonomy-log.jsonl
#   → números, não null: a própria missão é a primeira linha nova
./bin/sdd kaizen --series | jq '.latest.advance_rate'   # a missão desta branch, lida pela régua nova
```

## Próxima missão (semente, medida em 2026-08-29 — fora de escopo aqui)

**O custo do REVIEW.** 20 rodadas no ledger, **US$ 461,95 = 39% de todo o gasto**; as quatro
rodadas mais recentes fecharam em A na r1 e custaram US$ 22–37 cada (49% da SQ-111). Anatomia,
lida dos `REVIEW-*.json` que o `run_phase` guarda (`usage`, `modelUsage`, `subagent_stats`):

| rodada | US$ | turnos | min | cache-read (M tok) | saída (k) | thinking (k) | subagentes |
|---|---|---|---|---|---|---|---|
| `condicoes-pagamento` r1 | 37,30 | 140 | 37 | 30,4 | 115 | 53 | 4 |
| `o-laco-da-qa` r1 | 32,94 | 169 | 70 | 34,9 | 145 | 79 | 2 |
| `frete-cif-fob` r1 | 22,36 | 112 | 32 | 23,4 | 86 | 36 | 4 |
| `fecho-que-nao-mente` r1 | 32,39 | 135 | 80 | 26,9 | 117 | 62 | 0 |

O custo escala com **turnos × contexto** (23–35 M tokens relidos do cache por rodada, contra 86–145 k
de saída), quase todo em `opus`; as rodadas de 2026-08-14/16 com metade dos turnos custaram
US$ 7–15. Comando para re-medir:

```bash
for f in .sdd/logs/*/REVIEW-*.json ~/repos/sales_quote/.sdd/logs/*/REVIEW-*.json; do jq -r --arg f "$f" 'select(.total_cost_usd != null) | [($f|split("/")|.[-2]), (.total_cost_usd*100|round/100), .num_turns, ((.duration_ms/60000)|round), ((.usage.cache_read_input_tokens/1e6)*10|round/10), ((.usage.output_tokens/1e3)|round), ((.modelUsage//{})|to_entries|map("\(.key)=\((.value.costUSD//0)*100|round/100)")|join(" "))] | @tsv' "$f"; done | sort
```

Hipóteses a grilar com o humano (nenhuma decidida): o `sdd-reviewer` em `sonnet` com o skill
roteando por severidade; separar "achar" (skill, barato) de "consertar" (só quando < A); cortar
turnos com um relatório de achados escrito **antes** de qualquer edição.
