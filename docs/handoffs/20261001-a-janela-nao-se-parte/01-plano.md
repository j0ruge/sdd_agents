---
missao: 20261001-a-janela-nao-se-parte
data: 2026-10-01
---

# Plano — A janela não se parte

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em `c19e987` (= `origin/main`), no worktree `/home/joruge/repos/sdd_agents-a-janela`, branch
`feat/a-janela-nao-se-parte`. Números de linha **envelhecem a cada incremento**: ancore pelo nome da
função e use a linha só como ponto de partida.

**Ambiente**
- Suíte rápida verde em `c19e987`: `tests/run-all.sh` → `suite green`, **259 s**, rc 0;
  `anchors: all 515 mutants still apply and leave valid code`.
- Rode sensores de dentro do Claude Code com `env -u CLAUDECODE` quando um deles chamar `sdd`
  com `claude` stub (é o que a suíte já faz; só importa se algo reclamar de sessão aninhada).
- `git --version` = 2.43.0; `awk` é `mawk` (classe negada com multibyte não funciona — CLAUDE.md).
- O kit **é** o repo da missão (`REPO_ROOT == SDD_HOME` no worktree): a guarda de kit se exclui
  sozinha (`kit_guard_check`, `[ "$kit_root" = "$REPO_ROOT" ] && return 0`).

**Escritor do ledger (`bin/sdd`)**
- `autonomy_kit_stamp()` (~linha 3355) publica o global `AUTONOMY_KIT_STAMP="<sha>|<true|false>"`,
  ou `"|"` quando `$SDD_HOME` não é checkout git (com `warn` one-shot via `AUTONOMY_SHA_WARNED`).
  É **chamada, nunca substituída** (`$(...)` mataria o global — cicatriz documentada no comentário).
- Quatro escritores leem esse global, cada um com `autonomy_kit_stamp; local stamp="$AUTONOMY_KIT_STAMP"`
  e `--arg sha "${stamp%%|*}" --arg dirty "${stamp#*|}"`, e gravam
  `kit_sha: (if $sha == "" then null else $sha end), kit_dirty: (if $dirty == "" then null else ($dirty == "true") end)`:
  `autonomy_escalation_row` (~3910), `autonomy_gate_pass_row` (~3995), `autonomy_close_row` (~4043),
  `autonomy_session_row` (~4091). ⚠️ `${stamp#*|}` corta no **primeiro** `|`: acrescentar campos ao
  MESMO global quebraria o `dirty`. Por isso o `kit_rev` vai num **global novo** (`AUTONOMY_KIT_REV`).
- ⚠️ Nenhum `#` dentro de bloco `\`-continuado (`jq -cn \`): quebra o comando em silêncio e
  `bash -n` não acusa (CLAUDE.md).
- `kit_guard_arm()` / `kit_guard_check()` (~3430–3470) comparam `AUTONOMY_KIT_STAMP` antes e
  depois da sessão (`KIT_GUARD_BEFORE`). **Não mude o que eles leem.**
- Mapeamento verificado no repo real: `git log -1 --first-parent --format=%H <sha> -- bin agents templates config`
  → `5b98087`→`8dd5080`, `6323c6f`→`8dd5080`, `c19e987`→`c19e987`. Use `%H` e depois
  `git rev-parse --short <H>` para a grafia sair igual à do `kit_sha` (`rev-parse --short HEAD`).

**Leitores do ledger (`bin/sdd`)**
- `ledger_outcome_defs()` (~3336) é o molde de "jq impresso, emendado nos dois programas":
  `cmd_autonomy` faz `local odefs; odefs="$(ledger_outcome_defs)"` (~8535) e `kaizen_series` cola
  `"$(ledger_row_is_local)""$(ledger_outcome_defs)"'…'` no `jq -n` (~9178).
- Ponto de ingestão em `cmd_autonomy`: a cadeia `| historic_progress` / `| historic_rounds` /
  `| historic_steps` (~8813–8823), antes de qualquer `comparable`/`on_axis`/agrupamento.
- Ponto de ingestão em `kaizen_series`:
  `| ($file_rows | map(select(ledger_row_is_local)) | historic_progress | historic_rounds | historic_steps) as $raw` (~9524).
- Em `kaizen_series`: `def on_axis: .kit_dirty == false and .kit_sha != null;`,
  `def comparable_row`, `shas_in_file_order`, `$latest`/`$previous` por `.kit_sha == $shas[-1]`,
  `$stranded` por `.kit_sha != ($shas[-1] // null)` (~9585), e o produtor do ledger vazio
  (~9175, um literal com `latest: null` — não precisa mudar). `group_summary` monta cada fatia
  (procure `composition:` ~9483).
- `cmd_autonomy` agrupa por `.kit_sha` em ~8862–8912 e ~9020–9034. Normalizando na ingestão,
  **nenhum desses sítios muda**.
- Fora dos dois programas, `.latest.kit_sha` é lido por `gate_KAIZEN` (~9719), `kaizen_reminder`
  (~9641) e `cmd_kaizen` (~9839) — continuam valendo porque a saída mantém a chave `kit_sha`.
- `agents/sdd-kaizen.md` §2 ("## 2. Interpret with git, not with memory", ~linha 150) diz
  "The series' axis is the raw `kit_sha`" — muda no I2. Mexeu em `agents/*.md`: o espelho
  `.claude/agents/sdd-kaizen.md` é sincronizado **só** por `./bin/sdd install --force` (nunca `cp`
  nem Edit em `.claude/`; o headless recusa). O `sdd preflight` acusa `agent sdd-kaizen stale` se esquecer.
- `docs/pipeline.md` "### Field reference" (~1130) tem as linhas de `kit_sha` (~1160) e
  `kit_dirty` (~1161): os dois campos novos entram ali no I1 (contrato muda → doc no mesmo commit).

**Carimbo de mutação (`bin/sdd`)**
- `readonly MUTATION_STAMP_PATHS=(bin tests templates config)` (~1955), com o comentário que o
  justifica logo acima; `mutation_stamp_key()` (~2023) faz
  `listing="$( CDPATH='' cd "$1" … && find "${MUTATION_STAMP_PATHS[@]}" -type f -print0 … | LC_ALL=C sort -z | xargs -0 -r md5sum … )" || true`,
  `[ -n "$listing" ] || return 1`, `md5sum <<< "$listing" | cut -d' ' -f1`.
  ⚠️ O mutante `mut_PR_stamp_key_follows_head` ancora no texto `md5sum <<< "$listing"` **dentro**
  de `mutation_stamp_key` — mantenha essa linha literal.
- Leitores da chave: `gate_PR` (~2096, `key="$(mutation_stamp_key "$REPO_ROOT" || true)"`) e
  `cmd_health` 2c (~5681, ~5736 `stamp_key_before`, ~5897 `stamp_key`; recusa e `rm -f` quando
  vazio; `health_bad "the measured tree moved WHILE…"` quando antes ≠ depois;
  `ok "mutation stamp written — …"`).
- `health_ratchet()` (~6163) lê `$SDD_HOME/tests/health-baseline.txt` (a catraca `todo-findings 87`).
- Quem lê a baseline real na suíte: só `tests/check-lang.sh:54` (lista de superfície), independente
  de mutante.

**Sensores e fixtures que importam**
- Formato: todo sensor tem `pass() { printf '  ok    %s\n' "$1"; }` e `fail` na stderr com
  `  FAIL  `; `assert_eq <nome> <esperado> <obtido>` existe em `check-kaizen.sh`, `check-gates.sh`,
  `check-autonomy.sh`, `check-health.sh`.
- `tests/check-kaizen.sh`: fixtures de ledger em JSON escrito à mão; `localize` troca `"repo":"/p1"`
  pelo caminho real do repo de fixture `$FIX`; leitura com
  `( cd "$FIX" && SDD_STATE_DIR="<dir>" "$KSDD" kaizen --series 2>/dev/null )`. Molde mais próximo:
  o bloco `echo "== guard: the slice the judge cannot answer over =="` (~2148): `hrow <missão> <kit_sha> <harness>`,
  `hmeta <kit_sha>` (linha KAIZEN = onde a janela abre), `guard_read <state dir>` →
  `"<sufficient> <why> <window_broken> <stranded>"`; o mundo D (~2190) é exatamente a janela partida.
  A tabela humana é `"$KSDD" autonomy` (linhas `  <sha>  N session(s) · …`, ver `nextstep_cell` ~485).
- `tests/check-autonomy.sh`: o kit falso `FAKEKIT="$OUTSIDE/fakekit"` (~5452: `cp -r` de
  `bin templates config agents` + `git init` + um commit "chore: the kit"); `kitguard_world <dir>`
  monta um alvo parado em EXEC; `kitguard_stub "$FAKEKIT"` faz a sessão commitar `TODO.md` no kit;
  `kitguard_reset`; regimes 1–7 (~5551–5680). O **regime 1** ("kit-guard: a session that edits the
  kit during another repo's mission is warned once and journalled once") é a prova de que a guarda
  não estreitou: a sessão commita **só `TODO.md`**. `$LEDGER` é o ledger do sensor; leia com
  `jq -s`.
- `tests/check-gates.sh`, bloco do carimbo (~2297–2565): oito mundos (`i4_phase`, `i4_why`,
  `i4_verdict`, `i4_health`, `i4_write_suite`), contagem `i4_bad`, uma asserção agregada
  "gate_PR: the mutation stamp is demanded only where the catalogue lives". O mundo 3 copia só
  `bin/sdd` + `bin/sdd-coordination.py` para o fixture e escreve `tests/run-all.sh` stub; o fixture
  **não tem** `templates/` nem `config/`. O **mundo 8** move a chave escrevendo em
  `tests/scratch.ignored` (gitignored de propósito). Logo depois vem o bloco das duas árvores
  (`tree_bad`, um segundo kit fora do fixture) — ele também precisa dos quatro caminhos.
- `tests/check-health.sh`: `build_fixture()` (~180) faz `mkdir -p "$FIX/bin" "$FIX/tests" "$FIX/config"`
  e copia o runner vivo; **não há `git init`** nesse fixture; `set_baseline` escreve
  `$FIX/tests/health-baseline.txt`; `write_stub_suite` reescreve `$FIX/tests/run-all.sh`, e o stub
  grava `$FIX/tests/stub-argv.txt` **durante** a corrida; `STAMPED='mutation stamp written'`; o mundo
  `OUT_CAT_REAL` (~818) exige o carimbo, na asserção `mutation: a catalogue too small to have
  measured anything is refused`.
- `tests/check-mutation.sh`: cada mutante é `mut_<NOME>() { sed -i '<endereço por função> s@…@…@' "$1"; }`
  e o `<NOME>` (sem `mut_`) entra na lista do catálogo (perto de `PR_stamp_key_follows_head`,
  ~4970); a suíte reprova `mut_*` definido e não listado. `sandbox()` (~5332) copia `bin tests
  templates config agents CLAUDE.md TODO.md docs/adr` — **sem `.git`**. `--anchors` é o modo
  rápido. Não há `--only`.
- **Receita para provar UM mutante** (segundos a minutos, sem o catálogo), da raiz do worktree:
  ```bash
  d=$(mktemp -d) && cp -r bin tests templates config agents CLAUDE.md TODO.md "$d/" \
    && mkdir -p "$d/docs" && cp -r docs/adr "$d/docs/" \
    && eval "$(sed -n '/^mut_NOME() {/,/^}/p' tests/check-mutation.sh)" && mut_NOME "$d/bin/sdd" \
    && ! cmp -s bin/sdd "$d/bin/sdd" && echo applied
  bash "$d/tests/check-<sensor>.sh" >/dev/null 2>&1; echo "rc=$?"   # esperado: rc ≠ 0
  ```
  O sensor resolve `ROOT` pelo próprio caminho, então roda contra o `bin/sdd` sabotado.
- `tests/check-todo.sh` confere que toda âncora `bin/sdd:NNNN` de item aberto fica a ≤ 10 linhas de
  um símbolo que o item cita. **Editar `bin/sdd` desloca linhas**: os itens #67 (`bin/sdd:1955`),
  #107 (`bin/sdd:2029`) e #119 (`bin/sdd:2023`) do `TODO.md` ancoram perto de
  `MUTATION_STAMP_PATHS`/`mutation_stamp_key`. Se o `check-todo.sh` reclamar, atualize o número da
  âncora no `TODO.md` no MESMO commit (isso não move a catraca: a contagem de abertos não muda).
  Contagem atual: `87 finding(s)`; `grep -cE 'RESOLVED by [0-9a-f]{7}' TODO.md` → `1`.
- `tests/check-pipefail.sh` (RULE 1: nada de `printf … | grep -q`; RULE 2: `cd` relativo em
  `$( )` leva `CDPATH=''`; RULE 3: `grep -m` sem `-q`). Prefira `git -C "$dir"` a `cd`.
- `tests/check-lang.sh`: `bin/`, `tests/`, `agents/`, `docs/adr`, `docs/pipeline.md` são superfície
  **em inglês** (comentários, mensagens, nomes de asserção). Os artefatos desta missão
  (`docs/handoffs/…`, `TODO.md`) são pt-BR.

## Arquitetura da mudança

```
autonomy_kit_stamp ──► AUTONOMY_KIT_STAMP  "<HEAD>|<dirty árvore inteira>"  ──► kit_guard_*  (inalterado)
                   └─► AUTONOMY_KIT_REV    "<rev>|<dirty só KIT_BEHAVIOR_PATHS>" (novo)
4 escritores ──► linha: kit_sha, kit_dirty (cru, inalterado) + kit_rev, kit_rev_dirty (novos)

ledger_kit_version_defs (jq impresso, UMA definição)
   def kit_version_rows: linha com kit_rev → kit_sha:=kit_rev, kit_dirty:=kit_rev_dirty, kit_sha_raw:=cru
   emendada em kaizen_series ($raw … | historic_steps | kit_version_rows)
            e em cmd_autonomy   (… | historic_steps | kit_version_rows)
group_summary ganha kit_shas_raw (lista única, ordem do arquivo, dos crus da fatia)

mutation_stamp_key: cada um de MUTATION_STAMP_PATHS existe, raiz é checkout git,
   git -C root ls-files -z -c -- <4 dirs> ':(exclude)tests/health-baseline.txt'  → md5sum do conteúdo
```

Constantes novas, uma definição cada: `readonly KIT_BEHAVIOR_PATHS=(bin agents templates config)`
(junto de `autonomy_kit_stamp`) e `readonly MUTATION_STAMP_EXCLUDE=(tests/health-baseline.txt)`
(junto de `MUTATION_STAMP_PATHS`). Os comentários vizinhos que hoje juram outra coisa (o de
`MUTATION_STAMP_PATHS`, o de `mutation_stamp_key` sobre "all four absent", o de `autonomy_kit_stamp`)
são reescritos no mesmo incremento.

## Incrementos

### I1 — o escritor grava a versão de comportamento

**O quê:** `autonomy_kit_stamp` passa a publicar também `AUTONOMY_KIT_REV="<rev>|<true|false>"`
(`"|"` sem git, exatamente quando `AUTONOMY_KIT_STAMP` é `"|"`). `rev` =
`git rev-parse --short "$(git log -1 --first-parent --format=%H HEAD -- "${KIT_BEHAVIOR_PATHS[@]}")"`
com `-C "$SDD_HOME"` (vazio → `""` → `null`); `dirty` = `git -C "$SDD_HOME" status --porcelain -- "${KIT_BEHAVIOR_PATHS[@]}"`
não vazio. Os quatro escritores acrescentam `--arg rev … --arg rdirty …` e os campos
`kit_rev`, `kit_rev_dirty` com a mesma forma de null dos dois de hoje. `kit_guard_*` intocados.
`docs/pipeline.md` (Field reference) ganha as duas linhas, dizendo que `kit_sha`/`kit_dirty`
continuam o fato do `HEAD` e que o eixo do juiz é `kit_rev` quando presente (ADR 0014).
**Onde:** `bin/sdd` (`autonomy_kit_stamp`, os 4 escritores), `docs/pipeline.md`,
`tests/check-autonomy.sh`, `tests/check-mutation.sh`.
**Como (TDD):** bloco novo no `check-autonomy.sh`, **depois do regime 7 da guarda** (para não
mexer no `FAKEKIT` que os regimes usam), `echo "== kit_rev: the behaviour version the row carries =="`.
Reaproveite `kitguard_world` + `kitguard_stub ""` (sessão benigna) + `FAKEKIT`. Quatro mundos,
cada um seguido de `"$FAKEKIT/bin/sdd" run "$MISSION"` a partir do alvo e leitura da 1ª linha
`session` de `$LEDGER`:
1. guarde `KR_START="$(git -C "$FAKEKIT" rev-parse HEAD)"` (os regimes anteriores podem ter
   commitado `TODO.md` no fake — o regime 1 faz isso); commit em `$FAKEKIT/bin/` (ex.: um
   comentário acrescentado ao fim de `bin/sdd-link-agents`), guarde `KR_BIN` = `rev-parse --short HEAD`
   → linha: `kit_rev` = `kit_sha` = `KR_BIN`;
2. em seguida, commit em `$FAKEKIT` só de `TODO.md` (crie-o se não existir) → `kit_sha` = o novo
   `HEAD` curto, `kit_rev` = `KR_BIN` (≠ `kit_sha`). A ordem 1 → 2 é o que dá ao teste um valor
   esperado conhecido, sem recalcular o algoritmo do runner no sensor;
3. `TODO.md` sujo (não commitado) → `kit_dirty: true`, `kit_rev_dirty: false`;
4. arquivo novo não rastreado em `$FAKEKIT/agents/` → `kit_dirty: true`, `kit_rev_dirty: true`.
Sujeira que já existe antes da sessão não muda entre antes e depois, então a guarda do kit fica
calada nos mundos 3 e 4 (confira: nenhuma linha `kit-touched` no `$LEDGER`). Restaure o `FAKEKIT`
ao fim (`git -C "$FAKEKIT" reset -q --hard "$KR_START"`, `git -C "$FAKEKIT" clean -qfd`). Nomes das
asserções, exatos (a ordem acima é 1 = "inside", 2 = "outside"):
- `kit_rev: a kit commit outside the behaviour paths moves kit_sha and leaves kit_rev on the last behaviour commit`
- `kit_rev: a kit commit inside the behaviour paths moves both`
- `kit_rev: dirt outside the behaviour paths dirties kit_dirty and not kit_rev_dirty`
- `kit_rev: dirt inside the behaviour paths dirties both`
Red: os quatro falham hoje (`kit_rev` ausente → `null`).
Mutantes (cada um provado pela receita acima contra `check-autonomy.sh`, e listado no catálogo):
- `mut_RUN_kit_rev_is_head` — o `log … -- <paths>` perde a pathspec (vira `HEAD`): mundo 2 pega;
- `mut_RUN_kit_rev_dirty_whole_tree` — o `status --porcelain` do rev perde a pathspec: mundo 3 pega;
- `mut_RUN_kit_guard_reads_rev` — `kit_guard_arm`/`kit_guard_check` passam a comparar
  `AUTONOMY_KIT_REV`: o **regime 1** fica mudo e pega (é a prova da decisão 5 do grill).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    kit_rev: ' -e '^  ok    kit-guard: a session that edits the kit during' <<< "$o"` → `5`
**Sensor durável:** as quatro asserções `kit_rev:` + regime 1 + três mutantes no catálogo.
**Reversível por:** `git revert` do commit; linhas já gravadas com os campos novos são ignoradas
por leitores antigos (campo extra).

### I2 — os leitores agrupam pela versão de comportamento

**O quê:** função nova `ledger_kit_version_defs()` (jq impresso, no molde de `ledger_outcome_defs`)
com `def kit_version_rows: map(if type == "object" and .kit_rev != null then . + {kit_sha_raw: .kit_sha, kit_sha: .kit_rev, kit_dirty: .kit_rev_dirty} else . end);`
— emendada em `kaizen_series` e `cmd_autonomy` e aplicada logo após `historic_steps` nos dois.
`kit_rev` presente com `kit_rev_dirty` nulo vira `kit_dirty: null` → fora do eixo (fail-safe, de
propósito). `group_summary` ganha `kit_shas_raw` (crus únicos da fatia, ordem do arquivo:
`map(.kit_sha_raw // .kit_sha) | reduce .[] as $s ([]; if index($s) then . else . + [$s] end)`).
`agents/sdd-kaizen.md` §2: o eixo passa a ser a versão de comportamento (ADR 0014), `kit_shas_raw`
diz quais shas crus a fatia cobre, e a orientação "quando N shas são uma mudança lógica" fica para o
que o eixo ainda não une (ex.: um merge e seus fixups em `bin/`). Depois: `./bin/sdd install --force`
para o espelho.
**Onde:** `bin/sdd`, `agents/sdd-kaizen.md`, `.claude/agents/sdd-kaizen.md` (via install),
`tests/check-kaizen.sh`, `tests/check-mutation.sh`.
**Como (TDD):** bloco novo no `check-kaizen.sh`, `echo "== kit-version: a commit outside the behaviour paths does not split the slice =="`,
no molde do bloco `guard:` (helper próprio, ex. `vrow <missão> <kit_sha> <kit_rev|-> <kit_dirty> <kit_rev_dirty>`,
com `harness` fixo `2.1.283`). Ledgers:
- **A**: `hmeta`, depois missões v1 (`kit_sha aaa0001`), v2 (`aaa0001` e `aaa0002`), v3 (`aaa0002`),
  todas com `kit_rev rrr0001`;
- **B**: o gêmeo de A sem `kit_rev`/`kit_rev_dirty` (a janela 2 reproduzida);
- **C**: três missões em `rrr0001`, uma linha por missão, uma delas com `kit_dirty: true,
  kit_rev_dirty: false`, e um gêmeo em que a mesma linha tem `kit_rev_dirty: true` (é a única linha
  da sua missão, por isso `missions_with_session` cai de 3 para 2).
Nomes das asserções, exatos:
- `kit-version: three missions straddling a commit outside the behaviour paths are one slice — sufficient, nothing stranded`
  (A: `guard_read` → `true  false 0`, e `.latest.kit_sha` = `rrr0001`)
- `kit-version: ...and its twin without kit_rev is the window 2 rupture — stranded, latest on the second sha`
  (B: `window_broken` `true`, stranded ≥ 1, `.latest.kit_sha` = `aaa0002`) — **diferencial** com a anterior
- `kit-version: the slice names the raw shas it covers` (A: `.latest.kit_shas_raw | join(",")` = `aaa0001,aaa0002`)
- `kit-version: dirt outside the behaviour paths keeps a row comparable, dirt inside excludes it`
  (C × gêmeo: `excluded.non_comparable` 0 × 1, e `missions_with_session` 3 × 2)
- `kit-version: the human table reads the same versions as the judge`
  (`"$KSDD" autonomy` sobre A: há linha começando por `  rrr0001  ` e nenhuma com `aaa0002`)
Red: as cinco falham hoje (o leitor agrupa pelo cru).
Mutantes:
- `mut_KAIZEN_kit_version_ignored` — `kaizen_series` deixa de aplicar `kit_version_rows`: 1ª e 3ª asserções pegam;
- `mut_AUTONOMY_kit_version_ignored` — `cmd_autonomy` deixa de aplicar: a 5ª pega;
- `mut_KAIZEN_kit_rev_dirty_ignored` — a definição mantém o `kit_dirty` cru: a 4ª pega.
**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    kit-version: ' <<< "$o"` → `5`
**Sensor durável:** cinco asserções `kit-version:` (uma diferencial) + três mutantes.
**Reversível por:** `git revert`; o ledger não muda.

### I3 — a chave do carimbo exige os quatro caminhos (#107)

**O quê:** `mutation_stamp_key` devolve vazio + rc 1 quando qualquer um de `MUTATION_STAMP_PATHS`
não existe na raiz (`[ -e "$1/$p" ]` para cada um), antes de listar. Atualize o comentário (hoje ele
declara só o caso "todos ausentes"). Fixtures que esperam carimbo passam a ter os quatro caminhos:
`check-gates.sh` (mundo 3 em diante e o segundo kit do bloco `tree_*`) e `check-health.sh`
(`build_fixture` cria `templates/` com um arquivo). Diretório vazio não é rastreado pelo git (vai
importar no I4): ponha um arquivo em cada um.
**Onde:** `bin/sdd`, `tests/check-gates.sh`, `tests/check-health.sh`, `tests/check-mutation.sh`,
`TODO.md` (âncoras, se o `check-todo.sh` reclamar).
**Como (TDD):** no bloco do carimbo do `check-gates.sh`, um mundo novo **fora** da contagem
`i4_bad` (asserção própria), depois do mundo 8: remova `config/` do fixture e commite, rode
`i4_verdict 0 "$I4_SCORE_GREEN"; i4_health`, e exija que o gate continue em `PR` **e** que o
`sdd health` não tenha escrito o carimbo (`[ ! -f "$FIX/.sdd/logs/mutation-stamp" ]`). Hoje o health
carimba a listagem parcial e o mundo dá `DONE`. Restaure `config/` depois. Nome exato:
- `stamp-key: a root missing one of the four measured paths is never stamped`
Mutante: `mut_PR_stamp_key_partial_listing` — a guarda por caminho vira no-op: o mundo novo pega.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    stamp-key: ' -e '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `2`
**Sensor durável:** o mundo novo + o mutante.
**Reversível por:** `git revert`.

### I4 — a chave do carimbo lê só o rastreado e deixa a catraca de fora (#119, #117)

**O quê:** a listagem passa a ser
`git -C "$1" ls-files -z -c -- "${MUTATION_STAMP_PATHS[@]}" ':(exclude)tests/health-baseline.txt'`
(o exclude montado de `MUTATION_STAMP_EXCLUDE`), ordenada (`LC_ALL=C sort -z`), com o `md5sum` do
conteúdo **da árvore de trabalho** de cada arquivo (rode o `xargs -0 -r md5sum` com
`git -C "$1"`-relativo: ou `cd` com `CDPATH=''`, ou prefixe os caminhos com `$1/` e mantenha os
relativos no digest — o digest tem de carregar o caminho **relativo**, para mover quando um arquivo
só muda de lugar). Raiz que não é checkout git → vazio + rc 1. Arquivo rastreado apagado da árvore:
o `md5sum` falha para ele — trate como vazio (rc 1, sem carimbo), nunca como listagem parcial.
Comentários de `MUTATION_STAMP_PATHS` e `mutation_stamp_key` reescritos (ADR 0014; o
`check-gates.sh` e o `docs/failure-modes.md` citam esses textos — a DOCS cuida do segundo).
Fixtures:
- `check-gates.sh`: o fixture já é repo git. O **mundo 8** deixa de usar `tests/scratch.ignored`: o
  stub passa a acrescentar uma linha num arquivo **rastreado** (ex.: `tests/scratch.tracked`,
  commitado no mundo 3), e logo depois do `i4_health` o teste restaura com
  `git -C "$FIX" checkout -- tests/scratch.tracked` (árvore limpa antes do gate). Reescreva o
  comentário do `i4_write_suite` que diz "the scratch file … is gitignored".
- `check-health.sh`: o fixture vira repo git (`git init -q -b main`, `user.email`/`user.name` de
  fixture, `git add -A && git commit -qm …` ao fim de `build_fixture`). O `stub-argv.txt` que o
  stub grava durante a corrida tem de ficar **não rastreado** (não o commite), senão a janela do
  carimbo dispara. Rode o sensor inteiro: outros mundos que reescrevem arquivos em `tests/` durante
  a corrida aparecem aqui.
**Como (TDD):** dois mundos novos no `check-gates.sh`, fora da contagem, depois do mundo do I3:
1. com o carimbo de pé (rode `i4_verdict 0 …; i4_health` antes e exija `DONE`), commite uma linha
   em `tests/health-baseline.txt` + `TODO.md` do fixture → exige `DONE`;
2. com o carimbo de pé, crie `tests/debug.log` (o fixture ganha `*.log` no `.gitignore`), **sem**
   commitar → exige `DONE`.
Nomes exatos:
- `stamp-key: a commit touching only the backlog ratchet and TODO.md leaves the stamp standing`
- `stamp-key: an ignored file inside a measured directory does not move the key`
Red: os dois dão `PR` hoje.
Mutantes:
- `mut_PR_stamp_key_keeps_baseline` — o exclude some: o mundo 1 pega;
- `mut_PR_stamp_key_reads_ignored` — `ls-files` ganha `--others` (sem `--exclude-standard`): o mundo 2 pega.
`mut_PR_stamp_key_follows_head` continua aplicando (`--anchors`).
**Check:** `o=$(bash tests/check-gates.sh 2>&1; bash tests/check-health.sh 2>&1); grep -c -e '^  ok    stamp-key: ' -e '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' -e '^  ok    mutation: a catalogue too small to have measured anything is refused' <<< "$o"` → `5`
**Sensor durável:** os dois mundos + mundo 8 refeito + dois mutantes.
**Reversível por:** `git revert` (o I3 fica de pé sozinho).

### I5 — o backlog registra o que a missão fechou e o que decidiu

**O quê:** no `TODO.md`, os quatro itens fechados ganham `RESOLVED by <hash curto>` no corpo (o
commit que os consertou: #188 → I2, #117 → I4, #119 → I4, #107 → I3), sem passar de 8 linhas por
item. Na seção decidida (`<!-- sdd:decided -->`, ~linha 723), uma linha: aviso de merge durante a
janela decidido fora (missão `20261001-a-janela-nao-se-parte`, ADR 0014: depois do conserto a única
ruptura que sobra é mudança real do kit). Nenhum item aberto nasce nem morre → a catraca
`todo-findings 87` não se move. Os itens só são **apagados** depois do merge (regra do template).
**Onde:** `TODO.md`.
**Como (TDD):** o Check falha hoje (só 1 `RESOLVED by <hash>`).
**Check:** `o=''; awk '/RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/ {n++} END {exit (n != 5)}' TODO.md && o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    87 finding(s)' <<< "$o"` → `1`
**Sensor durável:** `check-todo.sh` (formato, teto, âncoras) e a catraca no `sdd health`;
justificativa: o conteúdo do backlog não tem asserção própria além dessas, e não precisa.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Fixture do `check-health.sh` vira git e um mundo que reescreve `tests/` durante a corrida passa a disparar a janela | média | rodar o sensor inteiro no I4; arquivo escrito pelo stub fica não rastreado; se um mundo legítimo quebrar, ajuste o fixture, nunca a regra |
| Edições em `bin/sdd` deslocam âncoras do `TODO.md` (#67, #107, #119) e o `check-todo.sh` reprova | alta | atualizar a âncora no mesmo commit (não move a catraca) |
| `%h` e `rev-parse --short` grafarem comprimentos diferentes | baixa | `kit_rev` sai de `rev-parse --short <%H>`, a mesma grafia do `kit_sha` |
| `kit_rev` vazio num repo sem commit nos caminhos | baixa | o escritor grava `kit_rev: null`, e a normalização deixa a linha no ramo cru (agrupa por `kit_sha`, como hoje) |
| Missão de kit continua ocupando `latest`/`previous` (`sdd kaizen --series` hoje: `5f8df0c`/`954409c`) | certa | fora de escopo (ADR 0003/0005); a janela 4 conta missões de alvo |
| Carimbo invalidado por consertos de revisão | média | carimbar UMA vez depois de todos os revisores (pendência do humano no `00-missao.md`) |

## Verificação end-to-end

1. `tests/run-all.sh` → `suite green` (inclui `--anchors`: todos os mutantes, os oito novos inclusive, aplicam).
2. Cada mutante novo provado pela receita do "Contexto verificado" contra o sensor indicado (rc ≠ 0),
   com a saída citada no `20-handoff-exec.md`: `RUN_kit_rev_is_head`, `RUN_kit_rev_dirty_whole_tree`,
   `RUN_kit_guard_reads_rev` (check-autonomy); `KAIZEN_kit_version_ignored`,
   `AUTONOMY_kit_version_ignored`, `KAIZEN_kit_rev_dirty_ignored` (check-kaizen);
   `PR_stamp_key_partial_listing`, `PR_stamp_key_keeps_baseline`, `PR_stamp_key_reads_ignored` (check-gates).
3. Medida no repo real, do worktree: `./bin/sdd kaizen --series` continua respondendo (o ledger real
   não tem `kit_rev` ainda, então a saída é a de hoje: `latest 5f8df0c`), e uma linha nova gravada
   por esta versão carrega `kit_rev` (ver `tail -1 ~/.sdd/autonomy-log.jsonl | jq '{kit_sha,kit_rev,kit_rev_dirty}'`
   depois de qualquer sessão da própria missão).
4. `./bin/sdd health` uma vez, pelo humano, antes do `gate_PR` → `score: N caught … of N` e
   `mutation stamp written`.
