---
missao: 20260901-o-revisor-so-acha
data: 2026-09-01
---

# Plano — O revisor só acha

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em 2026-09-01 sobre `main` = `35863d9` (o commit do grill, `1a51fd0`, só
tocou docs, `CLAUDE.md`, `CONTEXT.md`, `.gitignore` e `.graphifyignore`). Linhas de `bin/sdd`
deslocam com os incrementos — ancore pelo **texto** citado, nunca pelo número.

### O escritor e o laço (`bin/sdd`)

- **`run_phase()`** — `bin/sdd:2491`. Lê o custo da sessão em
  `cost="$(jq -r '.total_cost_usd // .cost_usd // "?"' "$logfile" …)"` (`:2583`); o mesmo JSON
  (`<PHASE>-<ts>.json`, destilado do stream por `stream_summary`) carrega **`num_turns`**,
  `duration_ms`, `usage`, `modelUsage`, `subagent_stats`. Publica os globais `LAST_PHASE_RC`,
  `LAST_PHASE_COST`, `LAST_PHASE_DUR`, `LAST_PHASE_STEP`, `LAST_PHASE_AGENT`, `LAST_PHASE_MODEL`,
  `LAST_PHASE_SID` (declarados logo abaixo da função, `:2611-2617`). `--dry-run` retorna antes de
  abrir sessão e não publica nada.
- **`autonomy_session_row()`** — `bin/sdd:2391`, assinatura
  `<phase> <attempt> <auto_retry> <moved> <gate> <gate_why> [<pending_before> <pending_after> <increments_total> <rounds_before> <rounds_after> <rounds_max>]`.
  Lê `cost`/`dur`/`rc`/`step`/`agent`/`model`/`session` **direto dos globais** (`--arg cost
  "$LAST_PHASE_COST"` etc.), então um campo novo lido de global **não** muda a assinatura nem os
  quatro chamadores (`cmd_run` porta 1 e retry inline, `cmd_retry`, `cmd_kaizen` ×2). Converte
  números com `($x | tonumber? // null)`. ⚠️ **Nenhum `#` dentro do bloco `jq -cn \`** — comentário
  em linha continuada quebra o comando em silêncio. Linhas de escalada (`autonomy_blocked_row`,
  `autonomy_degraded_row`) e de fechamento (`autonomy_gate_pass_row`) são construtores próprios e
  **não** ganham o campo.
- **`state_fingerprint()`** — `bin/sdd:2620`: `HEAD|<ls do MISSION_DIR>|<md5 do checkpoint>`. O
  `cmd_run` tira `before="$(state_fingerprint)"` antes de `run_phase` e compara depois (`moved`);
  `${before%%|*}` é o HEAD **antes** da sessão — é isso que o I3 usa.
- **O laço do `cmd_run`** — `bin/sdd:4380-4500`: `gate_"$phase" || gate_rc=$?` → `moved` →
  `autonomy_session_row …`. Gate verde ⇒ avança. Gate vermelho **e `moved=true`** ⇒ *"gate … not
  yet … (but the session moved forward — carrying on)"*, **sem retry**: a volta seguinte re-deriva
  `current_phase()`. Gate vermelho e **não** moveu ⇒ um retry inline com `--resume --fork-session`
  e o motivo no prompt. `cmd_retry` (`:4580-4600`) é a mesma sequência numa porta só.
- **`current_phase()`** — `bin/sdd` logo antes de `phase_model` (`:1413`): percorre
  `PHASES="PLAN TICKET EXEC QA REVIEW DOCS PR"` e devolve o primeiro gate vermelho. Ou seja: um
  checkpoint com linha `pending` faz `gate_EXEC` reprovar **antes** de `gate_REVIEW` ser lido — é
  assim que o `F<n>` da QA volta ao EXEC, e é assim que o `R<n>` voltará.
- **`gate_EXEC()`** — `bin/sdd:739`: valida cada linha (`done` sem commit, commit inexistente ou
  fora de HEAD, token inválido), conta `pending|doing` por `checkpoint_tally` (`:325`), roda
  `TEST_CMD` quando nada pende, exige `20-handoff-exec.md`. **Agnóstico ao prefixo do ID** — o
  `F<n>` da QA já prova (`docs/handoffs/20260829-o-incremento-que-andou/checkpoint.md:39`).
- **`gate_REVIEW()`** — `bin/sdd:1018`: `latest_matching "$MISSION_DIR/40-review-r*.md"` (ordem
  de versão, r10 > r3), publica `GATE_REVIEW_ROUNDS`/`GATE_REVIEW_MAX` no resolve, exige
  `### Overall Grade` com **A em toda linha** e `Rationale` com frase (placeholders recusados por
  awk, `mawk` byte a byte), campo `gate:` idem quando presente, depois `TEST_CMD` verde e árvore
  limpa. **Não muda nesta missão.**
- **`review_rounds_on_disk()`** — `bin/sdd:2695`: conta os arquivos `40-review-r<N>.md`; é o
  teto `REVIEW_MAX_ITER=3` (rodadas **em total**, `sdd run` não zera) e a foto `rounds_before`.
- **`phase_task()`** — `bin/sdd:1517`; a linha de REVIEW é
  `REVIEW)   printf '%s\n' "review and fix, INSIDE this session, until every criterion is Grade A" ;;`.
  **`phase_extra()`** — `:1533`; o heredoc de REVIEW começa em *"Drive the review → fix →
  re-review loop INSIDE this session"* e diz que `/goal` não existe (verificado — continua não
  existindo). `boot_prompt()` (`:1560-1650`) cola `phase_task` e `phase_extra` no prompt de toda
  fase; o dry-run imprime esse prompt (é o que `tests/check-dry-run.sh` lê).
- **`kit_guard_check`** (`bin/sdd:2163`) é o modelo de **guarda de aviso**: uma definição, chamada
  nas portas do `cmd_run` (×2), `cmd_retry` e `cmd_close` **depois** de `moved` ser amostrado;
  `warn` + `pipeline_log_line "… KIT-TOUCHED …"`; nunca para a linha; um probe por porta
  (`CLAUDE.md § 5`). `pipeline_log_line` (`:1665`) escreve em `.sdd/logs/<missão>/pipeline.log`.
- **Última linha é contrato:** `{ main "$@"; exit $?; }` — a EXEC edita `bin/sdd` durante o
  `sdd run` que a executa (`tests/check-entrypoint.sh`).

### Os leitores

- **`cmd_autonomy()`** — `bin/sdd:4633`. A linha `--by-mission` é montada em `:4982`:
  `"  \($label)  \($n) session(s) · \($t.advanced) advanced · \($t.churned) churned · \($t.idle) idle · \($launches) launch(es) · \($reopened) reopened\($iv) · US$ \($cost | usd)"`,
  dentro de um `jq` que já agrupa as linhas locais por `(repo, mission)` (`group_by` do jq é
  estável — a ordem de arquivo sobrevive dentro do grupo). `$iv` é o exemplo de sufixo condicional
  (só imprime quando há notas). Texto de uso em `:5909-5911`.
- **`ledger_outcome_defs()`** — `bin/sdd:2060`: as definições `jq` costuradas em `cmd_autonomy` e
  `kaizen_series` (`:5095`). **Não tocar** — o juiz não muda de régua nesta missão.
- **`docs/pipeline.md`**: `§ Field reference` em `:570` (uma linha por campo; `rounds_before` em
  `:612`, `rounds_max` em `:614` — copie a forma); `--by-mission` explicado em `:678`;
  `### REVIEW — Grade A on every criterion` em `:173-208`; `## The kit guard` em `:365`.

### Os agentes e templates (o contrato em três lugares)

- **`agents/sdd-reviewer.md`**: § 1 *Load the state* (`:15`), § 2 *Run the review* (`:25`, com a
  regra de movimento/plateau em `:34-52`), **§ 3 *Fix what was raised*** (`:54-89` — o chapéu que
  sai; inclui *"Two ways this session dies"*, que fica), § 4 *Write the round report* (`:90-143`,
  com a tabela e os placeholders recusados), § 5 (`:144`), *Rules that are not negotiable*
  (`:161-172`).
- **`agents/sdd-executor.md`**: § 2 *Pick the increment* (`:28-41` — *"the first row with
  Status: pending, top to bottom. Exactly one"*), § 6 *Was that the last increment?* (`:100-114` —
  escreve/atualiza `20-handoff-exec.md`; precedente do `F1`: commit `f35ad97`, *"o handoff de
  EXEC com a correção que a QA pediu"*).
- **`agents/sdd-qa.md § 4`** (`:75-95`) é o **modelo** do `R<n>`: forma da linha, Check com
  regressão + re-walk, e a frase *"The runner sees a pending increment and hands the ball back to
  sdd-executor on its own"*.
- **`templates/review.md`**: frontmatter + `## TL;DR` + `## Nota da rodada` (com o aviso do
  `###`) + `### Overall Grade` + seções `## Achados da rodada`, `## O que foi corrigido`,
  `## O que foi refutado`, `## Achados fora de escopo`, `## Pendências / Decisions for a Human`
  (ver o arquivo; `tests/check-templates.sh` deriva asserções do heading
  `^###[[:space:]]+Overall Grade`, `:165-190`).
- **`templates/checkpoint.md`**: seção `## Incrementos de fix (QA)` em `:63`.
- **Espelhos**: `.claude/agents/*.md` sincronizados **só** por `./bin/sdd install --force`
  (nunca `cp`, nunca Edit — o harness recusa `.claude/` em sessão headless); `sdd preflight`
  reprova `agent <nome> stale`.

### Os sensores

- **`tests/check-autonomy.sh`** (293 asserções): stub de `claude` em `$OUTSIDE/stub/claude`
  (`:106-113`) — é ele que escreve o `result` JSON que `stream_summary` destila; bloco
  `== session rows ==` em `:224`; `localize()` `:151`; missão fixture `$MDIR` com `checkpoint.md`
  reescrito por bloco; um stub que **fecha** um incremento com commit real em `:488` e `:770`
  (`| I1 | slice one | \`true\` → 0 | done | $(git -C "$FIX" rev-parse --short HEAD) |`);
  `ledger_row()` `:2660` fabrica uma sessão comparável; blocos `== reader: --by-mission … ==`
  `:2787-2943` (o de `:2787` é o modelo para o `review loop`); `== the REVIEW row carries the
  round it advanced ==` `:1045` roda `"$SDD" run "$MISSION" --phase REVIEW --max-phases 1`.
- **`tests/check-gates.sh`**: `assert_phase <nome> <fase esperada>` (`:43`) e `assert_why`
  (`:55`); `MDIR` `:116`; `== REVIEW phase ==` em `:865-1010` com fixtures `40-review-r1.md`
  (B), `r2` (`—`), `r3`, `r10`, `r11` escritas por heredoc; o bloco `== QA phase — project
  WITHOUT an interface ==` (`:846-863`) deixa a QA verde para o bloco de REVIEW.
- **`tests/check-dry-run.sh`**: projeção `EXEC→QA→REVIEW→DOCS→PR` com agentes (`:141`);
  asserções sobre o **texto do boot prompt** projetado (`:251-300`, `OUTPUT_LANG` e o slash da
  QA) — copie a forma para ler o prompt de REVIEW; `budget_of` `:232`.
- **`tests/check-templates.sh`**: `== templates/review.md ==` `:188`; asserção por heading com
  controle negativo (cabeçalho do arquivo explica o `REVIEW_FLOOR`).
- **`tests/check-mutation.sh`**: 218 mutantes (`grep -cE '^mut_[A-Za-z0-9_]+\(\) \{'`),
  `CATALOG=(` em `:2679`; família `mut_REVIEW_*` `:415-470`; `mut_LEDGER_progress_not_written`
  `:2224` é o modelo de "o writer deixa de escrever o campo"; `mut_RUN_ignores_output_lang` `:652`
  é o modelo de "o prompt perde uma frase". O harness recusa mutante que não muda o arquivo
  (rc 90) e que não compila (rc 91): **cada mutante novo é provado numa cópia antes de entrar**
  — aplica, `cmp` mostra diferença, `bash -n`, e o sensor nomeado fica vermelho **só** na
  asserção nomeada.
- **`tests/check-lang.sh`**: `surface()` em `:50-53` **enumera** os arquivos (`docs/pipeline.md
  docs/failure-modes.md docs/adr/*.md README.md …`) — `docs/graphify.md` (inglês, criado no
  commit do grill) está **fora** dela hoje; o piso anti-vacuidade fica em `:123-130` com o
  histórico das recontagens no comentário (é o que o I4 mexe).
- **`tests/run-all.sh`** é o `TEST_CMD` (~85 s; `suite green` na última linha; conta de `^  ok`
  reconcilia com o handoff anterior). `tests/check-checkpoint.sh` valida este checkpoint (sem `|`
  cru; `^  ok    ` com herestring).

### Configuração e pitfalls

- `.sdd/config.sh`: `TEST_CMD="tests/run-all.sh"`, `E2E_CMD=""`, `OUTPUT_LANG="pt-BR"`,
  `JIRA_ENABLED=false`, `MODEL_*="opus"`, `REVIEW_MAX_ITER=3`, `BUDGET_REVIEW_USD=40`,
  `ALLOWED_TOOLS="Bash"`.
- **Carimbo de mutação** (`.sdd/logs/mutation-stamp`, hoje `2d0cb366…` sobre `35863d9`) é o md5
  de `bin/ tests/ templates/ config/`; `gate_PR` o exige; I1–I3 o invalidam e a fase DOCS re-emite
  (`./bin/sdd health`, 15–50 min, **depois do último commit de código**). `tests/health-baseline.txt`
  está na chave ⇒ **não registrar achado no `TODO.md` nas fases EXEC/QA/REVIEW** — achado vai para
  `20-handoff-exec.md § fora de escopo` (ou `40-review-r<N>.md § Achados fora de escopo`) e a DOCS
  transporta com a catraca no mesmo diff.
- `set -euo pipefail`: `x="$(cmd)"` morre na atribuição se `cmd` devolve não-zero (`grep` sem
  match, `jq` sobre campo ausente); `printf … | grep -q` devolve 141 quando ACHA — herestring;
  função lida como `x="$(f)"` roda em subshell e perde globais — **publicar em global e chamar**.
- `awk` é `mawk` (byte a byte; classe negada só ASCII); `cd` relativo dentro de `$( )` leva
  `CDPATH=''`.
- **Idioma:** a superfície do kit (`bin/sdd`, `agents/`, `docs/`, `config/`, `tests/`,
  `templates/` de código) é **inglês**; estes artefatos, `KAIZEN_LOG.md`, `CONTEXT.md` e
  `CLAUDE.md` são PT-BR. Prosa de agente, doc e comentário de código: inglês.

### Números de hoje (o "antes" do `KAIZEN_LOG`)

```bash
jq -rs 'map(select(.event=="session")) | group_by(.phase) | map({phase: .[0].phase, n: length, usd: (map(.cost_usd // 0) | add | . * 100 | round / 100)}) | .[] | "\(.phase)\t\(.n)\t\(.usd)"' ~/.sdd/autonomy-log.jsonl
# DOCS 16 147.95 · EXEC 89 542.72 · KAIZEN 4 16.69 · PR 19 39.71 · QA 29 221.68 · REVIEW 27 636.66 · TICKET 6 9.46
jq -rs 'map(select(.event=="session" and .mission=="20260830-a-tela-que-mente-o-pagamento")) | group_by(.phase) | map("\(.[0].phase) \(length) US$ \(map(.cost_usd)|add|.*100|round/100)") | .[]' ~/.sdd/autonomy-log.jsonl
# DOCS 1 5.13 · EXEC 2 14.93 · PR 1 2.23 · QA 1 12.61 · REVIEW 2 47.81 · TICKET 1 1.71   (REVIEW = 60%)
for f in .sdd/logs/*/REVIEW-*.json ~/repos/sales_quote/.sdd/logs/*/REVIEW-*.json; do jq -r --arg f "$f" 'select(.total_cost_usd != null) | [($f|split("/")|.[-2]), (.total_cost_usd*100|round/100), .num_turns, ((.duration_ms/60000)|round), ((.usage.cache_read_input_tokens/1e6)*10|round/10), ((.usage.output_tokens/1e3)|round)] | @tsv' "$f"; done | sort | tail -6
# 20260830-a-tela r1 16.90 27 7 6.6 24 · r2 30.91 150 52 37.3 115 · 20260831-a-rodada r1 37.10 104 30 18.9 81 · r2 29.24 154 64 28.9 125 · …
```

Anatomia por stream (chamadas de ferramenta e bytes de tool_result por rodada) e o corte
antes/depois do primeiro `Edit` estão resumidos no `00-missao.md § Problema` — os comandos `jq`
sobre `.stream.jsonl` contam `tool_use` por `.name` e somam `.content` dos `tool_result`.

## Arquitetura da mudança

```
REVIEW (sdd-reviewer, read-only)                  EXEC (sdd-executor, TDD)          REVIEW r2
  /codereview → reproduz/refuta                     pega R1 (1ª pending)              /codereview de novo
  escreve 40-review-r1.md (nota HONESTA, B)   ──►   Red = asserção nomeada no Check  ──►  A → DOCS
  escreve R1..Rn no checkpoint (+TODO_FILE)         Green + commit + checkpoint           ou R<n+1> → EXEC → r3
  commita SÓ handoff/checkpoint/TODO/baseline       atualiza 20-handoff-exec.md           (teto 3 → BLOCKED/draft)
        gate_REVIEW: B ⇒ fail, moved ⇒ carry on  ·  current_phase(): R1 pending ⇒ EXEC  ·  gate_EXEC/QA/REVIEW re-derivados
```

Nada muda em `gate_*`, `current_phase`, `checkpoint_tally`, no teto de rodadas ou nas definições
do juiz. Muda o **contrato da sessão REVIEW** (o que ela escreve e o que não toca), e entram dois
instrumentos: `turns` na linha do ledger + `review loop` na leitura por missão (I1), e a guarda de
aviso `REVIEW-EDITED-CODE` (I3). Esquema do ledger aditivo, `v` continua `1`, nada é migrado.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. **Os nomes das
asserções são contrato**: o Check de cada incremento grepa exatamente o texto abaixo. Ordem
obrigatória: instrumento → contrato → guarda → docs.

### I1 — o ledger carrega `turns`, e a leitura por missão imprime o laço de revisão

**O quê:** (1) `run_phase` publica `LAST_PHASE_TURNS` lendo `.num_turns // ""` do mesmo
`$logfile` de onde lê o custo (`bin/sdd:2583`); o global entra na lista declarada abaixo da função.
(2) `autonomy_session_row` ganha `--arg turns "$LAST_PHASE_TURNS"` e, no objeto,
`turns: ($turns | tonumber? // null)` — lido do global como `cost`, **sem** argumento novo e sem
tocar os chamadores; escalada e `gate_pass` não carregam o campo. (3) `cmd_autonomy --by-mission`:
para cada `(repo, missão)` em ordem de arquivo, `$fr` = índice da primeira linha com
`phase == "REVIEW"` (sessão); `loop` = soma de `cost_usd` das sessões `REVIEW` mais as sessões
`EXEC` de índice > `$fr`; a linha ganha o sufixo `· review loop US$ X (N%)` **só** quando `$fr`
existe (forma do `$iv`). (4) `docs/pipeline.md`: linha `turns` na tabela de campos (`:570`, forma
das linhas vizinhas), a frase do `review loop` na seção `--by-mission` (`:678`), e o texto de uso
(`:5909`).
**Onde:** `bin/sdd` (`run_phase`, `autonomy_session_row`, `cmd_autonomy`, usage),
`tests/check-autonomy.sh`, `tests/check-mutation.sh`, `docs/pipeline.md`.
**Como (TDD):** no bloco `== session rows ==` (`:224`) o stub `claude` passa a escrever
`"num_turns": 7` no objeto `result`. Red: a linha não tem `turns`. Asserções (nomes exatos):
`a session row carries the turns the session spent` (lê `7` via `jq -r '.turns'`); `an
escalation row carries no turns` (uma linha `blocked` do mesmo fixture: `has("turns")` é `false`).
Fixture novo ao lado de `== reader: --by-mission ==` (`:2787`), via `ledger_row()`/`localize`:
uma missão com EXEC (US$ 4) · REVIEW (US$ 10) · EXEC (US$ 6) · DOCS (US$ 2) → a linha imprime
`review loop US$ 16.00 (73%)`; asserção **diferencial** `the review loop counts REVIEW and the
EXEC sessions after it, never the EXEC before` — a mesma missão **sem** a linha REVIEW não imprime
`review loop`, e com ela o número é 16, não 20. Mutantes: `mut_LEDGER_turns_not_written` (o
`jq -cn` deixa de escrever `turns`; assassino: a primeira asserção) e
`mut_AUTONOMY_review_loop_counts_every_exec` (o filtro de índice sai; assassino: a diferencial).
Cada um provado numa cópia (`cmp`, `bash -n`, vermelho só na asserção nomeada) antes do commit.
**Check:** `bash -n bin/sdd; o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a session row carries the turns the session spent' <<< "$o"; grep -c '^  ok    the review loop counts REVIEW and the EXEC sessions after it, never the EXEC before' <<< "$o"` → `1` e `1`
**Sensor durável:** as 3 asserções em `tests/check-autonomy.sh` + 2 mutantes no `CATALOG`.
**Reversível por:** `git revert`; campo desconhecido é ignorado por leitor antigo.

### I2 — o contrato: o revisor só acha, achado vira incremento R

**O quê (um commit — contrato em três lugares, `CLAUDE.md § Ao mexer no runner`):**
(1) `bin/sdd`: `phase_task REVIEW` → `"review, reproduce and grade honestly; every finding that
must be fixed becomes an R<n> increment in the checkpoint — you do not fix"`; `phase_extra REVIEW`
reescrito: o laço é achar → escrever `R<n>` → (o EXEC conserta) → a rodada seguinte re-avalia;
esta sessão commita **só** `40-review-r<N>.md`, `checkpoint.md`, `TODO_FILE` (+ baseline); nota
real mesmo que B; a sessão termina depois de commitar o relatório; `/goal` não existe (manter).
(2) `agents/sdd-reviewer.md`: § 2 mantém o `codereview` e a regra de movimento/plateau (as
"commits de conserto" entre rodadas passam a ser os `R<n>` executados pelo EXEC); **§ 3 vira
"Findings become increments"**: CRITICAL/HIGH → um `R<n>` cada, linha na forma
`| R1 | <achado #k em uma frase> | \`o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção que o executor vai escrever>' <<< "$o"\` → \`1\` | pending | — |`
(num alvo com interface: `E2E_CMD` verde + re-walk da jornada, como o `F<n>`); MEDIUM/LOW baratos
→ **um** `R<n>` de lote por rodada (`"achados #4–#7 da r1"`), com um Check por achado dentro da
célula; caros → `TODO_FILE`; decisão humana → § Pendências, sem `R<n>`. As regras de rigor
(reproduzir antes de concluir, refutar com evidência, *"receive criticism with rigour"*, *"never
end your turn with a command still running"*) **ficam**. § 4: o relatório ganha a seção
`## Incrementos de conserto (R<n>)` listando as linhas escritas, e "O que foi corrigido" passa a
"O que virou incremento". **Proibido editar código** (`bin/`, `tests/`, `templates/`, `config/`,
`src/`, …): a sessão que conserta perdeu o chapéu. *Rules that are not negotiable* atualizadas.
(3) `agents/sdd-executor.md § 2`: uma linha `R<n>` tem o detalhe do achado no `40-review-r<N>.md`
mais recente (`F<n>`: no arquivo do bug); § 6: ao fechar o último `pending` depois de uma rodada,
**atualizar** `20-handoff-exec.md` com a seção dos `R<n>` (precedente `F1`, `f35ad97`).
(4) `templates/review.md`: seção `## Incrementos de conserto (R<n>)` logo depois da tabela de
achados; `templates/checkpoint.md`: a seção `## Incrementos de fix (QA)` passa a
`## Incrementos de fix (QA e REVIEW)` e explica o `R<n>` ao lado do `F<n>`.
(5) `docs/pipeline.md § REVIEW` (`:173-208`): o laço REVIEW⇄EXEC, o que a sessão commita, r1 é B
quando há o que consertar, o teto conta rodadas de **achar**; a linha `REVIEW` da tabela de fases
(`:128` vizinhança) diz "findings → R<n>".
(6) `./bin/sdd install --force` sincroniza `.claude/agents/sdd-reviewer.md` e
`.claude/agents/sdd-executor.md`; conferir `diff -q` vazio.
**Onde:** `bin/sdd`, `agents/sdd-reviewer.md`, `agents/sdd-executor.md`, `.claude/agents/*` (via
install), `templates/review.md`, `templates/checkpoint.md`, `docs/pipeline.md`,
`tests/check-gates.sh`, `tests/check-dry-run.sh`, `tests/check-templates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** `check-gates.sh`, no bloco `== REVIEW phase ==` (`:865`): fixture com
`40-review-r1.md` graduado B **e** uma linha `| R1 | … | \`true\` → 0 | pending | — |` no
checkpoint → `assert_phase "a review graded B with a pending R1 hands the ball to EXEC" "EXEC"`
(Red hoje: reprova porque hoje o fixture não tem R1 — escreva a linha e a asserção juntas; o Red é
a asserção seguinte); marcar `R1 done` com commit real (forma de `check-autonomy.sh:488`) →
`assert_phase "and once R1 is done the ball comes back to REVIEW" "REVIEW"`. `check-dry-run.sh`:
`the REVIEW boot prompt sends findings to R increments and never fixes in-session` — o prompt
projetado de REVIEW contém `R<n> increment` **e não** contém `review and fix, INSIDE`.
`check-templates.sh`: `templates/review.md` carrega o heading `## Incrementos de conserto`.
Mutante `mut_RUN_review_fixes_inline` (restaura o texto antigo de `phase_task REVIEW`; assassino: a
asserção do dry-run).
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a review graded B with a pending R1 hands the ball to EXEC' <<< "$o"; o2=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    the REVIEW boot prompt sends findings to R increments and never fixes in-session' <<< "$o2"; diff -q agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; echo rc=$?` → `1`, `1` e `rc=0`
**Sensor durável:** 4 asserções + 1 mutante; `tests/check-health.sh` cobra o espelho via preflight.
**Reversível por:** `git revert` + `./bin/sdd install --force`.

### I3 — a guarda de aviso `REVIEW-EDITED-CODE`

**O quê:** `review_scope_check <before_head>` — uma definição, ao lado de `kit_guard_check`
(`bin/sdd:2163`): só para `phase == REVIEW`, `git diff --name-only <before_head> HEAD`
(`${before%%|*}`, o primeiro campo do `state_fingerprint`); qualquer caminho fora de
`$HANDOFF_DIR/$MISSION/`, `$TODO_FILE` e `tests/health-baseline.txt` ⇒ `warn` +
`pipeline_log_line "$(date -Iseconds)  REVIEW-EDITED-CODE  REVIEW  <n> file(s) outside the mission directory: <lista>"`.
Chamada nas portas do `cmd_run` (porta 1 **e** retry inline, com o `before` da primeira passada)
e do `cmd_retry`, **depois** de `moved` ser amostrado. Aviso, **não fronteira**. `--dry-run` não
arma (não há HEAD depois). Cabeçalho declara o que não cobre: `commit --amend` que reescreve o
HEAD anterior (o diff lê o HEAD novo contra o antigo, que pode não existir mais — a função devolve
0 e não avisa). `docs/pipeline.md § The kit guard` ganha o parágrafo do irmão.
**Onde:** `bin/sdd`, `tests/check-autonomy.sh`, `tests/check-mutation.sh`, `docs/pipeline.md`.
**Como (TDD):** no `check-autonomy.sh`, um stub `claude` que, em REVIEW, commita `bin/x` além do
relatório (forma dos stubs que commitam, `:488`) e um `sdd run --phase REVIEW --max-phases 1` como
em `:1083`. Red: nenhuma linha no `pipeline.log`. Asserções: `a REVIEW session that edited code
outside the mission directory is logged REVIEW-EDITED-CODE` (porta 1); `the retry door logs
REVIEW-EDITED-CODE too` (porta do `cmd_retry`, mesmo stub); `a REVIEW session that only wrote the
round and the checkpoint is not flagged` (controle negativo: stub que só escreve o relatório).
Mutante `mut_RUN_review_scope_blind` (a função vira `return 0`; assassino: a primeira).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a REVIEW session that edited code outside the mission directory is logged REVIEW-EDITED-CODE' <<< "$o"; grep -c '^  ok    a REVIEW session that only wrote the round and the checkpoint is not flagged' <<< "$o"` → `1` e `1`
**Sensor durável:** 3 asserções + 1 mutante.
**Reversível por:** `git revert`.

### I4 — docs: schema, failure-modes, `CONTEXT.md`, `KAIZEN_LOG.md` (antes), superfície do `check-lang`

**O quê:** `config/schema.md:99` — a justificativa de `BUDGET_REVIEW_USD` deixa de dizer *"the
session fixes inside itself"* (o teto **fica 40**, decisão 9, e o texto diz por quê: um teto que
morde no meio da sessão joga dinheiro fora com nada em disco; a distribuição das sessões de achar
sai do `turns` e decide o teto na missão seguinte); `REVIEW_MAX_ITER` — r1 é B quando há o que
consertar, o caminho normal usa duas rodadas. `docs/failure-modes.md § The review does not close
at Grade A` (`:413`): o que olhar são os `R<n>` da última rodada e o `REVIEW-EDITED-CODE` no
`pipeline.log`. `CONTEXT.md`: conferir que D22 e o verbete *Laço REVIEW⇄EXEC* (escritos no commit
do grill) batem com o que I2/I3 fizeram — corrigir se divergiu. `KAIZEN_LOG.md`: entrada no
**topo**, modelo da de 2026-08-31 — *Problema (Gemba)* com os números de "Números de hoje",
*Contramedida*, tabela **Antes / Depois** com a coluna Depois preenchida com
`(medido pela fase DOCS desta missão — ver 01-plano.md § Para a fase DOCS)` em cada célula.
`tests/check-lang.sh`: `docs/graphify.md` entra em `surface()` (`:50-53`) e o piso de `:123-130`
sobe em 1, com a recontagem no comentário (é a forma da D9). Conferir `diff -q agents/*.md
.claude/agents/*.md` vazio.
**Onde:** `config/schema.md`, `docs/failure-modes.md`, `CONTEXT.md`, `KAIZEN_LOG.md`,
`tests/check-lang.sh`.
**Como (TDD):** o Check é o artefato; `check-lang.sh` mede o inglês de `docs/` e `config/` — com
`docs/graphify.md` na superfície, um parágrafo em português lá passa a reprovar a suíte.
**Check:** `o=$(grep -l 'o-revisor-so-acha' KAIZEN_LOG.md CONTEXT.md docs/pipeline.md config/schema.md docs/failure-modes.md); wc -l <<< "$o"; s=$(sed -n '/^surface()/,/^}/p' tests/check-lang.sh); grep -c 'docs/graphify.md' <<< "$s"; bash tests/check-lang.sh >/dev/null 2>/dev/null; echo rc=$?` → `5`, `1` e `rc=0`
⚠️ O `2>/dev/null` (e não `2>&1`) é deliberado: `tests/check-checkpoint.sh` recusa célula que
mescla a saída de um sensor sem ancorar em `^  ok    `; aqui só o `rc` interessa.
**Sensor durável:** `check-lang.sh` (idioma + superfície), `check-health.sh` (espelho); o número
do KAIZEN_LOG não tem sensor — declarado.
**Reversível por:** `git revert`.

## Para a fase DOCS (`sdd-docs`) — o "depois" desta missão

A fase REVIEW **desta** missão é a primeira a rodar no contrato novo; os números dela são o
"depois" imediato (M2). Antes de re-carimbar:

```bash
./bin/sdd autonomy --by-mission | grep o-revisor-so-acha            # · review loop US$ X (N%)
jq -rs 'map(select(.event=="session" and .mission=="20260901-o-revisor-so-acha" and (.phase=="REVIEW" or .phase=="EXEC"))) | .[] | "\(.phase) \(.step) \(.turns) turns · US$ \(.cost_usd) · rounds \(.rounds_before)→\(.rounds_after) · pending \(.pending_before)→\(.pending_after)"' ~/.sdd/autonomy-log.jsonl
grep -c REVIEW-EDITED-CODE .sdd/logs/20260901-o-revisor-so-acha/pipeline.log   # 0 esperado
```

Preencher a coluna Depois do `KAIZEN_LOG.md` com essas linhas (turnos e US$ por sessão REVIEW; o
`review loop`; quantos `R<n>` a r1 escreveu e quanto custaram no EXEC), transportar os achados
de `20-handoff-exec.md § fora de escopo` e `40-review-r<N>.md § Achados fora de escopo` para o
`TODO.md` **com a catraca de `tests/health-baseline.txt` no mesmo diff**, e só então
`./bin/sdd health` (re-emite o carimbo que I1–I3 mataram).

## Achados do planejamento (fora de escopo — a DOCS transporta ao `TODO.md`)

- [ ] `run_phase` não limpa o ambiente do harness antes do `claude -p` — `bin/sdd:2491` — um
  `sdd run` lançado de dentro de uma sessão do Claude Code herda `CLAUDE_CODE_CHILD_SESSION`,
  `CLAUDE_CODE_MESSAGING_SOCKET` e afins e é morto pelo harness sem ação humana (2× em
  2026-08-30); a saída é `env -u CLAUDECODE -u CLAUDE_CODE_* …` no próprio `run_phase`, com o
  probe correspondente — descoberto por `humano` na missão `20260830-invariante-do-frete-no-agregado`
  (2026-08-30), registrado aqui por `sdd-planner` (2026-09-01)
- [ ] `tests/check-lang.sh` `surface()` enumera arquivos em vez de `docs/*.md` — `tests/check-lang.sh:50` —
  um doc novo em `docs/` nasce **fora** da régua de idioma e o `CLAUDE.md § Idioma` promete
  `docs/` inteiro; o I4 cobre `docs/graphify.md`, o glob fica como decisão — descoberto por
  `sdd-planner` na missão `20260901-o-revisor-so-acha` (2026-09-01)

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O revisor volta a consertar por hábito ou por prompt residual | média | I3 registra `REVIEW-EDITED-CODE`; `turns` (I1) expõe; a REVIEW desta missão é o primeiro teste real, lido pela DOCS |
| `R<n>` de lote vira sessão grande demais | média | lote só de MEDIUM/LOW **baratos**; o executor pode dividir a linha em duas e marcar `blocked` — Jidoka |
| Mais rodadas por missão (r1 B é o normal) muda a leitura de `rounds` entre janelas | certa, aceita | régua declarada no `KAIZEN_LOG.md` e no `CONTEXT.md` (D22), como #33 fez |
| O ganho fica abaixo de 20% em missão que já fechava em A na r1 | alta | esperado e escrito: o corte é no laço caro; M1 mede mediana **e** máximo |
| QA re-bloqueia depois do REVIEW e cai no laço | baixa | limite declarado da M1 |
| Registrar achado no `TODO.md` no EXEC mata o carimbo | média | achados → handoff `§ fora de escopo`; a DOCS transporta e re-carimba |
| A EXEC edita `bin/sdd` durante o `sdd run` que a executa | conhecida | última linha `{ main "$@"; exit $?; }` — não tocar |
| Mutante novo fica no-op (rc 90 no `sdd health`) | média | cada mutante provado numa cópia antes do commit |
| Asserção nova passa pelo regime do fixture e não pela propriedade | média | controle negativo em I3; diferencial em I1; `assert_phase` com as duas direções em I2 |

## Verificação end-to-end

Com os quatro `done` e o pipeline fechado (QA → REVIEW no contrato novo → EXEC `R<n>` → REVIEW
r2 → DOCS → PR):

```bash
tests/run-all.sh | tail -2                                              # suite green, rc 0
./bin/sdd autonomy --by-mission | grep o-revisor-so-acha                 # · review loop US$ X (N%)
jq -rs 'map(select(.event=="session" and .mission=="20260901-o-revisor-so-acha" and .phase=="REVIEW")) | .[] | "\(.turns) turns · US$ \(.cost_usd) · rounds \(.rounds_before)→\(.rounds_after)"' ~/.sdd/autonomy-log.jsonl   # cada uma ≤ 60 turnos, ≤ US$ 15
grep -c '^| R' docs/handoffs/20260901-o-revisor-so-acha/checkpoint.md   # os R<n> que a r1 escreveu
grep -cE '^\| [0-9]+ \| (CRITICAL|HIGH|MEDIUM|LOW)' docs/handoffs/20260901-o-revisor-so-acha/40-review-r1.md   # achados por severidade (M3)
grep REVIEW-EDITED-CODE .sdd/logs/20260901-o-revisor-so-acha/pipeline.log; echo "rc=$? (1 = nenhuma sessão REVIEW editou código)"
```

## Como rodar (humano)

Do **terminal**, nunca do Bash tool de uma sessão do Claude Code (o `claude -p` aninhado é morto
pelo harness — achado acima):

```bash
cd ~/repos/sdd_agents && git checkout feat/o-revisor-so-acha && ./bin/sdd preflight
env -u CLAUDECODE -u CLAUDE_CODE_CHILD_SESSION -u CLAUDE_CODE_MESSAGING_SOCKET -u CLAUDE_CODE_MESSAGING_TOKEN -u CLAUDE_PID -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_BRIDGE_SESSION_ID \
  setsid nohup ./bin/sdd run 20260901-o-revisor-so-acha >> ~/sdd-run-20260901.log 2>&1 < /dev/null & disown
tail -F ~/sdd-run-20260901.log        # ou ./bin/sdd status 20260901-o-revisor-so-acha
```

Retomar depois de uma morte é seguro: o runner deriva a fase do disco.
