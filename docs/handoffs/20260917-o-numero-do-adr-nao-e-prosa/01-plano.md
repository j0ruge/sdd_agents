---
missao: 20260917-o-numero-do-adr-nao-e-prosa
data: 2026-09-17
---

# Plano — o número do ADR não é prosa

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Tudo que ela precisa saber e que não é óbvio está abaixo. Uma cópia expandida (com o contexto
> combinado dos exploradores) existe em
> `~/.claude/plans/home-joruge-repos-obsidian-01-projects-clever-cascade.md`; **não é necessária**.

## Contexto verificado (não re-descobrir)

Confirmado por comando em 2026-09-17, `main` = `923bc72`, branch de trabalho
`feat/o-numero-do-adr-nao-e-prosa`. ⚠️ Linhas envelhecem: ancore por **função**, use o número só
para chegar perto.

### Runner (`bin/sdd`, 7757 linhas; `set -euo pipefail :14`; última linha `{ main "$@"; exit $?; }` é contrato)
- **Despacho:** `main()` `:7528-7551`, `case` plano. O `sdd health` check 6 (`:4603-4623`) parseia
  esse `case` com `[a-z|+-]+\)` — a primeira palavra é uma só; `sdd adr new` é `adr) cmd_adr "$@" ;;`
  com o verbo lido dentro. O mesmo check exige `\bsdd adr\b` no heredoc de `cmd_help :7452-7526`.
- **Flags:** laço `while [ $# -gt 0 ]; do case "$1"` **antes** de `load_config`, `die "unknown …
  option"` — modelo `cmd_health :4300-4310`. Não existe `--format json` em nenhum comando.
- **Config:** `load_config :102-166`; defaults só na grafia `: "${KEY:=…}"` (o `health_default_keys
  :4191` extrai por regex); `OUTPUT_LANG` em `:158` — as chaves novas entram logo abaixo. Chave
  validada = modelo `BUDGET_MISSION_USD :142-145`. **Chave nova = mesmo commit** em `load_config` +
  tabela do `config/schema.md` + `config/starter.conf` + uma leitura real (check 7
  `var-never-read :4624-4636`). Não há rejeição de chave desconhecida.
- **Frontmatter:** `frontmatter <file> <key> [absent]` `:205-229`; `frontmatter_has :239`;
  `frontmatter_write <file> <key> <value>` `:263-293` — awk `index()`, nunca sed; **só reescreve
  chave existente**, ausente fica ausente (`:260`).
- **Gates:** contrato `:683-686` (sem args, `GATE_WHY`, 0/1, nunca stdout). `gate_PLAN :688-728` lê
  `aprovacao :694`, `versao :718`, regra de placeholder `[[ $v == \<* ]] :719`; sítio do verdict =
  depois do bloco `versao` (`:723`), antes da contagem de rows. `gate_EXEC :855`: resets de
  marcadores na entrada (`:857-861`), sítio logo após. Marcador lateral novo: UM setter, reset na
  entrada (`GATE_APP_DOWN :839` / `gate_QA :955` é o modelo). `PHASES :1536`; `current_phase :1539`
  despacha `gate_$ph` — nunca nomear função `gate_ADR…` em coluna 0 (check 4 fixa 8 gates, `:4564`).
- **`cmd_run`:** one-shot `degraded_logged` local em `:5227`; único writer `degraded` hoje
  `:5387-5397` (`warn` + `pipeline_log_line … DEGRADED …` + `autonomy_degraded_row
  "review-to-draft" "$phase" "$GATE_WHY"`); pré-check de EXEC **sem sessão** `:5298-5310`
  (`gate_EXEC || true` … teste de `GATE_EXEC_DIRTY`) = sítio da linha `adr-check`.
  `autonomy_degraded_row :2996` é **chamada**, nunca substituída (subshell mata globais).
- **Chapéus:** `hat_expand :1707-1718` (5 substituições quoted); `hat_writes :1720`;
  `HAT_WRITES_BASE :1687`. PLAN não passa por `run_phase`, logo não tem hat guard — o `writes:` do
  planner é declaração, não enforcement.
- **Região censada do `sdd health`:** de `# Sensor of the KIT :4163` a `cmd_status() { :4812` —
  toda captura `x="$(…)"` ali conta em `CAPTURE_FLOOR=36` (`tests/check-health.sh:1485`).
  **A biblioteca `adr_*` e `cmd_adr` entram FORA dela: depois do fim de `cmd_why` (`:4870`), antes
  do bloco de comentário do `sdd approve` (`:4872`).**
- **Preflight:** seção `context bill :4137-4152` (`ok`, nunca `_fail`); a linha `adr check:` entra
  logo após. Stale de agente por `cmp -s :4098-4122`.
- **`health_release :4280`** varre `docs/adr` por `RELEASE_FORBIDDEN_WORDS` (os identificadores de cliente e alvo
  listados no config do kit): **o ADR 0008 e toda doc nova usam exemplo genérico** ("o repo-alvo", "o ticket").
- Sem `.github/` (ADR 0004). Sem `traceab`. `bin/` = `sdd` + `sdd-link-agents`.

### Suíte (`tests/`)
- **Sensor novo = 5 registros:** `run-all.sh:235` (linha `run` após check-hat, **sem** guarda
  `SDD_MUTANT`, com o motivo em comentário — os mutantes `*_adr_*` só morrem aqui, mesmo argumento
  de `run-all.sh:224-234` para o check-preflight); `run-all.sh:131` `LINT_FLOOR=16→17`;
  `check-pipefail.sh:931` piso `15→16` **e** o fixture do selftest `:868` (`for i in 1..14` → `1..15`,
  senão três probes falham com `surface shrank`); `check-lang.sh:142` piso `45→46` (**→47 no I4**,
  glob `docs/adr/*.md` em `:50-56`).
- **`sandbox()` do catálogo** (`check-mutation.sh:3796-3819`) copia só `bin tests templates config
  agents CLAUDE.md TODO.md docs/adr`: o sensor lê só isso, constrói a fixture em `mktemp`, chama
  `bin/sdd` como subprocesso, exporta `SDD_STATE_DIR` próprio (`check-gates.sh:30-32`) e põe um
  stub `claude` que sai 97 na frente do PATH (`check-gates.sh:90-98`).
- **Mutantes:** `mut_NAME() {` em coluna 0 (`check-health.sh:133` re-deriva a contagem com
  `^mut_[A-Za-z0-9_]+\(\) \{`), âncora em CÓDIGO, range-addressed `/^fn() {/,/^}/ s@…@…@`, slug em
  `CATALOG=(` `:3467` (309 hoje), `KNOWN_GAPS=()` `:3782` fica vazio; `&` no replacement é "o match
  inteiro" (`2>\&1`). **Todo probe de sabotagem prova que sabotou** (`cmp` antes/depois; rc 90 do
  `run_mutant :3823` = "não aplicou"). `score:` sai de `:3922`.
- **`check-gates.sh`:** fixture `:80-118` (`git init` + `sdd install` + config heredoc sobrescrito
  + heredocs em `$MDIR`), `assert_phase :41`, `assert_why :48` (regex nunca `.*`), negativas por
  herestring. Fixture de terceiro com `# PROVENANCE:` = `:3175-3199`.
- **`check-hat.sh:42`** `PLACEHOLDERS='HANDOFF_DIR|MISSION|TODO_FILE|QA_DOCS_PATH|E2E_DIR'`, R2
  `:74-75`, probe modelo `:132-133`, `HAT_FLOOR=8`. `agents/` e `.claude/agents/` são duas cópias:
  sincronizar com **`sdd install --force`**, nunca `cp`/Edit.
- **`check-templates.sh:318`** = laço das chaves de frontmatter do `missao.md` (entra `adr`).
- **Selftest canônico** (`check-pipefail.sh:466-482`, `:907-918`): `probe()` re-executa o próprio
  arquivo via `--check`, rc 90/91/92, piso de probes, dois caminhos independentes até "falhou";
  dispatch `case "${1:-}" in --selftest|--check|'')`.
- **`check-todo.sh`** → `  ok    97 finding(s)…`; `tests/health-baseline.txt:26` `todo-findings 97`.
  Item novo move a baseline no mesmo commit e **invalida o carimbo** — health por último.

### Docs e agentes
- `config/schema.md`: tabela `| Key | Required | Default | What it is |`; prosa **abaixo** da
  tabela; regra `:36-39` ("chave que o runner não lê é promessa sem cobrança").
- `config/starter.conf`: banners `# --- x ---`, placeholders `<…>`.
- `docs/pipeline.md`: PLAN `:66-95` ("Passes when" `:70-72`), EXEC `:117-139` (`:119-121`), gate
  novo chega com mutação `:36-50`, enum `event :809`, enum `kind :810` (diz "review-to-draft is the
  only degraded kind today" — reescrever), parágrafo `degraded :278`.
- `templates/missao.md:7` `aprovacao:` — `adr:` entra logo abaixo. Headings dos templates são
  contrato dos gates.
- `docs/adr/0001–0007`: `# NNNN — título` / `Date: … · Status: accepted`, inglês, sem índice.
- `agents/sdd-planner.md:1-11` frontmatter (`writes: "$HANDOFF_DIR/$MISSION/**"`); §2 Gemba
  `:48-56`. `agents/sdd-kaizen.md` escreve o plano kaizen-born. `agents/sdd-docs.md:26,49` já
  lista `docs/adr/*`.
- `.claude/rules/anatomia-do-agente.md` §4 (`:89`, "catorze sensores") e §5 (`:107`) mudam **no
  mesmo commit** do runner (regra da própria rule).
- `CONTEXT.md`: verbete **Degradação** diz "o único degraded de hoje"; D15 `:57`; D21 `:63`.
- `TODO.md:101-108`, `:420-426`, `:577-582` tocam esta missão (carimbo × `docs/adr`; piso do
  check-lang; chaves de caminho não normalizadas).
- `ACHADOS-20260917-sales-quote.md` (raiz, já commitado): **não tocar, não incluir em commit.**

### Repo-alvo (só leitura; serve às fixtures e à receita)
- ADR `# ADR NNNN — …` + `- **Status**: aceito (<ticket>, <data>)` + verbos `Reverte/Fecha/
  Qualifica/Aplica/Segue o padrão` com link relativo. SpecKit: `specs/NNN-slug/spec.md` com
  `**Status**: Draft`, sem frontmatter; `plan.md` co-localizado. `specs/023/adr/001–003` =
  namespace local. `.specify/extensions.yml`: 18 hooks git, `condition: null` em todos.

## Arquitetura da mudança

```
bin/sdd
  load_config ............ + ADR_CHECK ADR_DIR (I1) SPEC_DIR (I3); enum validado UMA vez em adr_mode
  hat_expand ............. + $ADR_DIR (I7)
  gate_PLAN / gate_EXEC .. + adr_gate_verdict <phase> (I5) — uma chamada cada; dono = sdd-planner
  cmd_run pré-check EXEC . + uma linha degraded kind:adr-check sob warn, one-shot, nunca em --dry-run (I6)
  cmd_preflight .......... + "adr check: ADR_CHECK=<mode>, N ADR(s) in <dir>[, M finding(s)]" (I7)
  [seção nova após cmd_why] adr_mode · adr_next_id · adr_reserve · adr_has_link · adr_check_mission
                            · adr_check_repo · adr_gate_verdict · cmd_adr (new|check)
  main ................... + adr) cmd_adr "$@" ;;   cmd_help + 2 linhas
tests/check-adr.sh (novo, selftest) · check-mutation.sh (+8) · run-all.sh · 3 pisos
templates/missao.md (+adr:) · check-templates.sh · agents/sdd-planner.md · agents/sdd-kaizen.md · check-hat.sh
config/schema.md · config/starter.conf · docs/pipeline.md · README.md · rules/anatomia · CONTEXT.md · KAIZEN_LOG.md · TODO.md (+baseline)
docs/adr/0008-adr-ids-are-allocated-and-links-are-checked.md — criado pelo I4 via sdd adr new
```

**Fatos fixos:** `ADR_LINK_RE='^(- )?(\*\*)?(ADR|Spec)(\*\*)?:[[:space:]]*'` definido uma vez.
`ADR_CHECK` validado positivamente em `adr_mode` (`off|warn|block`; outro valor → rc 2 no comando,
recusa com remédio no gate). Saída: `  ok    …`/`  info  …` stdout, `  FAIL  <arquivo>:<linha> —
<motivo> — <remédio>` stderr; rc 0 limpo, 1 violação, 2 config inválida; a primeira FAIL vira
`GATE_WHY`. ID vem do nome do arquivo, nunca do título. Sob `block`, `adr:` vazio, `TBD` ou
`<…>` recusam em PLAN; `none` passa; caminho exige arquivo, número no nome e `Spec:` igual a
`$HANDOFF_DIR/<m>/00-missao.md`.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia.

### I1 — chaves, esqueleto do comando, sensor e os cinco registros

**O quê:** `: "${ADR_CHECK:=off}"; : "${ADR_DIR:=docs/adr}"` após `:158`; seção nova após `:4870`
com `adr_mode()` (valida o enum; rc 2) e `cmd_adr()` (laço de flags; `case "${1:-}" in new|check|*)
usage, rc 2`); `adr) cmd_adr "$@" ;;` no `main`; duas linhas no help (`sdd adr new --slug <s>
[--ticket <T>] [--spec <path>] [--dry-run]` e `sdd adr check [--repo ROOT] [--mission <m>]
[--phase plan|exec]`); `tests/check-adr.sh` com cabeçalho (o que mede, limites declarados —
`specs/*/adr/` —, usos, tabela de rc, seção da passada adversarial), `pass/fail` de
`check-gates.sh:35-38`, fixture `git init` + `sdd install` + config heredoc, `selftest()` canônico
com `--check`; os 5 registros; `config/schema.md` seção "ADR traceability" (2 rows + limite
declarado); `config/starter.conf` (`ADR_CHECK="off"`, `ADR_DIR="docs/adr"`); `.sdd/config.sh` do
kit `ADR_CHECK="warn"`, `ADR_DIR="docs/adr"`.
**Onde:** `bin/sdd`, `tests/check-adr.sh`, `tests/run-all.sh`, `tests/check-pipefail.sh`,
`tests/check-lang.sh`, `config/schema.md`, `config/starter.conf`, `.sdd/config.sh`.
**Como (TDD):** probes `ADR_CHECK=bogus is refused with rc 2` e `sdd adr with no verb prints usage
and exits 2` — vermelhos com `unknown command: adr`.
**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    ADR_CHECK=bogus is refused with rc 2' <<< "$o"` → `1`;
e `grep -c 'adr allocator' <<< "$(bash tests/run-all.sh --list 2>/dev/null)"` → `1`.
**Sensor durável:** o próprio `check-adr.sh`; health checks 5/6/7.
**Reversível por:** `git revert` (os pisos voltam junto).

### I2 — `sdd adr check --mission`

**O quê:** `adr_has_link <file> <key> <expected-path>` (grep `$ADR_LINK_RE`);
`adr_check_mission <root> <mission> [phase]`: `adr:` ausente/vazio → FAIL (nomeia `00-missao.md` e
o remédio `sdd adr new --slug <s> --spec <path>` ou `adr: none`); `none` → ok; `TBD` → info sem
`--phase` / FAIL com `--phase plan|exec`; placeholder `<…>` = TBD; caminho → `[ -f ]`, nome casa
`^[0-9]{4}-[a-z0-9-]+\.md$`, back-link `Spec:` == `$HANDOFF_DIR/<m>/00-missao.md`.
**Onde:** `bin/sdd` (seção adr), `tests/check-adr.sh`, `tests/check-mutation.sh`.
**Como (TDD):** 6 probes (`mission without adr: fails and names 00-missao.md`, `adr: none passes`,
`adr: TBD is info by default and FAIL with --phase plan`, `adr: path to a missing file fails`,
`ADR whose Spec: points elsewhere fails`, `ADR with the back-link passes rc 0`) — vermelhos com
`unknown verb`. Mutantes no mesmo commit: `mut_ADR_backlink_blind` (o `if ! adr_has_link …` →
`if false`), `mut_ADR_number_mismatch_blind` (teste do padrão do nome → `true`); range em
`adr_check_mission`; cada um com `cmp` provando a sabotagem, e a suíte vermelha com cada um.
**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    ADR whose Spec: points elsewhere fails' <<< "$o"` → `1`.
**Sensor durável:** os probes + 2 entradas no catálogo.
**Reversível por:** `git revert`.

### I3 — escopo de repo inteiro

**O quê:** `: "${SPEC_DIR:=}"` (+ `schema.md`/`starter.conf` no **mesmo** commit, senão check 7
acusa); `adr_check_repo <root>`: (a) IDs únicos + padrão em `ADR_DIR` (duplicata → FAIL nos dois
arquivos); (b) todo `$HANDOFF_DIR/*/00-missao.md` com `adr:` caminho → `adr_check_mission`; (c)
`SPEC_DIR` não vazio → todo `$SPEC_DIR/*/spec.md` com linha `ADR` → mesma validação com back-link
== o próprio `spec.md`; sem linha → `info: N spec(s) without an ADR line`; (d) `\bADR [0-9]{4}\b`
solto em `01-plano.md`/`spec.md`/`plan.md` sem arquivo em `ADR_DIR` → FAIL; plano co-localizado
citando ID diferente do declarado → FAIL; (e) stub com `<!-- sdd adr new:` → `info: unfilled stub`.
**Como (TDD):** probes `duplicate ADR number fails both files`, `a bare ADR 0042 in 01-plano.md
with no file fails`, `spec.md without an ADR line is counted as info, rc 0`, `SPEC_DIR empty scans
no specs`. Mutante `mut_ADR_bare_number_blind` (`ADR [0-9]{4}` → `ADR NEVER`).
**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    a bare ADR 0042 in 01-plano.md with no file fails' <<< "$o"` → `1`.
**Reversível por:** `git revert`.

### I4 — `sdd adr new` e o ADR 0008 do kit

**O quê:** `adr_next_id <dir>` (max+1; vazio → 1; lacuna nunca reusada); `adr_reserve <path>` =
`( set -C; : > "$path" ) 2>/dev/null || return 1`; `adr_new`: slug `^[a-z0-9-]+$`, escreve
`# ADR NNNN — <slug>`, `- **Status**: proposed (<ticket|—>, <data>)`, `- **Spec**: <caminho|TBD>`,
`<!-- sdd adr new: body in OUTPUT_LANG=<x>; follow the newest ADR here -->`; `--spec`:
`frontmatter "$spec" adr` deve ser vazio/`TBD`/ausente, senão rc 1 "already declares"; escreve via
`frontmatter_write` no `00-missao.md` — **se a chave está ausente, insere dentro do bloco `---`
por awk `index()`** (`frontmatter_write` não cria chave); no `spec.md` SpecKit insere/substitui a
linha `**ADR**:` por awk; `--dry-run` imprime o caminho e não toca nada.
**Como (TDD):** probes `empty ADR_DIR allocates 0001`, `a gap is never reused (0001,0003 → 0004)`,
`--dry-run prints the path and creates nothing`, `--spec replaces adr: TBD with the path`,
`--spec adds adr: to a mission that lacks the key`, `--spec refuses a spec that already declares
a path`, `the reservation primitive refuses an existing path and keeps its bytes` — este é
**determinístico**: `source <(sed '$d' "$SDD")`, controle `declare -F adr_reserve`, sentinela
pré-criada, rc 1 + `cmp` inalterado (a corrida de dois processos foi recusada por não-determinismo).
Mutante `mut_ADR_alloc_no_excl` (`set -C;` → `:;`).
**Dogfood no mesmo incremento:** `./bin/sdd adr new --slug adr-ids-are-allocated-and-links-are-checked
--spec docs/handoffs/20260917-o-numero-do-adr-nao-e-prosa/00-missao.md` cria
`docs/adr/0008-…` e substitui o `adr: TBD` desta missão; escrever o corpo em **inglês** (superfície
do kit), sem os termos de `RELEASE_FORBIDDEN_WORDS`; `Status: accepted`; `check-lang.sh` 46→47.
**Check:** `./bin/sdd adr check --mission 20260917-o-numero-do-adr-nao-e-prosa; echo rc=$?` → `rc=0`.
**Reversível por:** `git revert` (leva o ADR 0008; então o I9 não pode subir para `block`).

### I5 — o verdict nos gates e a chave no template

**O quê:** `adr_gate_verdict <phase>`: `GATE_ADR_WARN_WHY=""` na entrada (único setter); `off` → 0;
roda `adr_check_mission … <phase>` capturando a primeira FAIL (**`|| rc=$?`**, nunca captura nua
sob `set -e`); `block` → `GATE_WHY="adr: <motivo> — <remédio>"`, retorna 1; `warn` → arma
`GATE_ADR_WARN_WHY`, retorna 0. Chamadas: `gate_PLAN` após o bloco `versao` (`:723`); `gate_EXEC`
após os resets (`:861`). O comentário do gate nomeia o dono do artefato: `sdd-planner`, com o
humano presente. `templates/missao.md:7` ganha `adr: <none | TBD | docs/adr/NNNN-slug.md>`;
`tests/check-templates.sh:318` ganha `adr`.
**Como (TDD):** probes por `sdd phase`/`sdd why` na fixture: `block: mission without adr: stalls
at PLAN and names sdd adr new`, `block: adr: TBD stalls at PLAN`, `block: the template placeholder
stalls at PLAN`, `block: adr: none passes to EXEC`, `block: ADR file removed after approval makes
EXEC refuse`, `warn: the same mission derives EXEC`, `off: no adr: key derives EXEC` — o par
warn × block roda sobre a **mesma** fixture (asserção diferencial). Mutantes
`mut_PLAN_adr_check_ignored`, `mut_PLAN_adr_tbd_accepted` (arm `TBD)` tratado como `none`),
`mut_EXEC_adr_drift_blind`.
**Docs no mesmo commit:** `docs/pipeline.md:70-72` (PLAN) e `:119-121` (EXEC).
**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    block: ADR file removed after approval makes EXEC refuse' <<< "$o"` → `1`.
**Reversível por:** `git revert` (a chave do template sai junto com o laço do check-templates).

### I6 — `warn` deixa rastro no ledger

**O quê:** `local adr_degraded_logged=0` ao lado de `:5227`; no pré-check de EXEC (entre
`gate_EXEC || true` e o teste de `GATE_EXEC_DIRTY`): `if [ "$DRY_RUN" != "1" ] && [ -n
"$GATE_ADR_WARN_WHY" ] && [ "$adr_degraded_logged" = 0 ]; then adr_degraded_logged=1; warn
"ADR_CHECK=warn — …"; pipeline_log_line "$(date -Iseconds)  DEGRADED  EXEC  ADR_CHECK=warn — …";
autonomy_degraded_row "adr-check" "EXEC" "$GATE_ADR_WARN_WHY"; fi`. Limites declarados no
comentário: uma volta que para no Jidoka `blocked` (`:5274`) não chega ao sítio; corrida retomada
que nunca deriva EXEC não escreve.
**Como (TDD):** probe pelo caminho determinístico `dirty-tree` (sem sessão): fixture `warn`,
incrementos `done` com commits reais, `TEST_CMD=false`, arquivo sujo, stub `claude` exit 97 →
`sdd run` rc 3, ledger com **exatamente uma** linha `event:"degraded"` `kind:"adr-check"` antes
da `dirty-tree`; `--dry-run` → 0 linhas; `off` → 0 linhas (diferencial). Mutante
`mut_RUN_adr_warn_silent` (`autonomy_degraded_row "adr-check"` → `:`).
**Docs no mesmo commit (enum = contrato, D21):** `docs/pipeline.md:810` (`kind` + `adr-check`;
reescrever "the only degraded kind today"), `:278`; `config/schema.md` prosa do `ADR_CHECK`;
`CONTEXT.md` verbete Degradação.
**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    warn: one degraded adr-check row per run, before the session' <<< "$o"` → `1`.
**Reversível por:** `git revert`.

### I7 — preflight, placeholder `$ADR_DIR`, chapéus

**O quê:** após `:4152`: `off` → `ok "adr check: ADR_CHECK=off, N ADR(s) in <dir>"`; `warn|block`
→ roda `adr_check_repo` e imprime `ok`/`warn "adr check: M finding(s) — run sdd adr check"` (nunca
`_fail`: achado de repo é dívida de migração, decisão 4). `hat_expand` +
`s="${s//\$ADR_DIR/"${ADR_DIR%/}"}"` — **`ADR_DIR` nunca pode ser vazio** (expansão vazia daria
`/**`; `adr_mode` recusa). `check-hat.sh:42` + `|ADR_DIR` + probe R2. `agents/sdd-planner.md`:
`writes: "$HANDOFF_DIR/$MISSION/**, $ADR_DIR/**"` + seção "ADR" (trade-off arquitetural →
`sdd adr new --slug … --spec docs/handoffs/<m>/00-missao.md` e escreve o corpo em `OUTPUT_LANG`;
senão `adr: none`; `TBD` só durante o grill; critério **f** na tabela PLAN-AUTO).
`agents/sdd-kaizen.md`: o plano nascido escreve `adr: none`. `sdd install --force` sincroniza os
espelhos. `tests/check-preflight.sh` + 1 asserção (`grep -c '^  ok    adr check:'`).
**Como (TDD):** probe R2 vermelho (`not a placeholder`); asserção de preflight vermelha (0).
**Check:** `o=$(bash tests/check-hat.sh selftest 2>&1); grep -c '^  ok    R2: \$ADR_DIR is a placeholder the runner expands' <<< "$o"` → `1`.
**Reversível por:** `git revert` + `sdd install --force`.

### I8 — docs e memória

**O quê:** `README.md:55-77` (2 linhas de Usage + parágrafo de adoção gradual: instalar → `warn` →
corrigir/`none` → `block` → CI); `docs/pipeline.md` subseção "ADR traceability" (gramática,
escopos, modos; **receita** de CI: job fino no alvo que instala o kit por PATH ou clone com token
e roda `sdd adr check`; **receita** SpecKit: `before_plan`/`before_implement` chamando
`sdd adr check --phase …`); `.claude/rules/anatomia-do-agente.md` §4 (quinze sensores; verificação
com dono nomeado) e §5 (alocador + validador; dívida `specs/*/adr/`); `CONTEXT.md` verbete
"Rastreabilidade de ADR"; `KAIZEN_LOG.md` (antes: 0 alocadores, "ADR 0030" escrito um dia antes
do 0030 real; depois: números dos Checks; nota de que `docs/superpowers/` fica fora do escopo
varrido); `TODO.md` item `--json` (formato de 6 linhas) + `tests/health-baseline.txt` 97→98 no
mesmo commit; `docs/failure-modes.md` sintoma "PLAN parada por `adr:` sob block".
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    98 finding(s)' <<< "$o"` → `1`.
**Reversível por:** `git revert`.

### I9 — o kit sobe para `block` e o carimbo

**Antes de editar:** `./bin/sdd adr check --mission 20260917-o-numero-do-adr-nao-e-prosa; echo $?`
→ `0`; `./bin/sdd adr check; echo $?` → `0`. **Editar** `.sdd/config.sh` → `ADR_CHECK="block"`.
**Depois:** `sdd why <m> PLAN` → `plan approved`; `sdd phase <m>` ≠ `PLAN`.
**Último passo:** `./bin/sdd health` (~15 min; chave = `bin tests templates config`; a baseline do
I8 já está commitada) → carimbo; `./bin/sdd health --release` 6/6.
**Check:** `./bin/sdd why 20260917-o-numero-do-adr-nao-e-prosa PLAN` → `plan approved`.
**Reversível por:** `ADR_CHECK="warn"`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| `RELEASE_FORBIDDEN_WORDS` vaza em ADR 0008/schema/pipeline | média | exemplos genéricos; `sdd health --release` linha 5 como Check |
| `var-never-read SPEC_DIR` entre I1 e I3 | alta | `SPEC_DIR` só entra no I3, no commit que a lê |
| Sensor lê caminho fora do `sandbox()` e o mutante morre por arquivo ausente (ponto falso) | média | ler só `bin/`, `agents/`, `config/starter.conf`; rodar `SDD_MUTANT=1 tests/run-all.sh` numa cópia antes do I2 |
| Âncora de mutante apodrece em silêncio | média | cada mutante com `cmp` provando que a sabotagem mudou o arquivo |
| `frontmatter_write` não cria chave ausente | alta | I4 insere por awk quando ausente; probe próprio |
| Captura nua sob `set -e` em `adr_gate_verdict` mata o gate | média | `\|\| rc=$?`; a região do health não é tocada, `CAPTURE_FLOOR` não move |
| Plano kaizen-born bloqueado por `adr:` sob `block` no kit | baixa | `sdd-kaizen.md` escreve `adr: none` (I7) |
| Carimbo invalidado por commit tardio em `bin/ tests/ templates/ config/` | alta | health só depois do I9; docs e TODO antes |
| Check com pipe cru na célula do checkpoint | — | todos em herestring |

## Verificação end-to-end

1. `bash -n bin/sdd && tests/run-all.sh` → `suite green`; `tests/run-all.sh --list` com 15 sensores.
2. `./bin/sdd health` → `score: 317 caught, 0 known gap(s), of 317`, carimbo escrito;
   `./bin/sdd health --release` → 6 de 6.
3. Clone descartável do kit com `SDD_STATE_DIR` próprio: `sdd adr new --slug probe --dry-run` →
   `docs/adr/0009-probe.md`; `sdd adr check` → rc 0; apagar a linha `Spec:` do 0008 → `sdd why
   <m> PLAN` nomeia o back-link e o remédio; restaurar.
4. Clone **só leitura** do repo-alvo com `ADR_CHECK=warn`, `SPEC_DIR=specs` num config temporário:
   `sdd adr check` → rc 1 só por números soltos, `info` para specs sem linha, `specs/023/adr/`
   intocado. Nada commitado lá.
5. Fixture do caso do vault no sensor (spec → ADR cujo `Spec:` aponta para outra spec) → FAIL com
   `arquivo:linha` — a métrica 1 do `00-missao.md`.
