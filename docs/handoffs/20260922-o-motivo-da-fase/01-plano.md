---
missao: 20260922-o-motivo-da-fase
data: 2026-09-22
---

# Plano — o motivo da fase

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

> ⚠️ **Modo de execução: INTERATIVO**, Opus + `superpowers:executing-plans`, um incremento por vez.
> **Nunca** `sdd run` / `sdd retry` nesta missão: é o kit sobre si mesmo, e o `claude -p` aninhado
> morre (memória do projeto). Os probes que precisam de sessão usam o **stub** de
> `tests/check-autonomy.sh`, nunca um `claude` real.
>
> **Antes do I1:** `cd /home/joruge/repos/sdd_agents && git switch -c feat/o-motivo-da-fase`. Os
> artefatos da PLAN (`docs/handoffs/20260922-o-motivo-da-fase/` e `docs/adr/0010-o-motivo-da-fase.md`)
> ainda não estão commitados e viajam com a branch. O primeiro commit da branch é
> `docs(plan): o motivo da fase`, só com esses arquivos.

## Contexto verificado (não re-descobrir)

Tudo medido em `147add7` (`main`), 2026-09-22. As linhas **andam** a cada incremento, então ancore
pelo nome da função e use o número só para achar a vizinhança.

**Leitura da tabela e gate de EXEC**
- `checkpoint_rows()` em `bin/sdd:434`. O laço awk apara espaço dos campos 2–6 em `bin/sdd:457`
  (`for (i = 2; i <= 6; i++) { gsub(/^[ \t]+|[ \t]+$/, "", f[i]) }`) e imprime
  `ID\tIncremento\tCheck\tStatus\tCommit`, ou seja, `f[6]` é o **Commit**. O `awk` é o **mawk**,
  orientado a byte: use só classe ASCII. A crase é ASCII, então `gsub(/`/, "", f[6])` é seguro.
- `gate_EXEC()` em `bin/sdd:917`. Os sítios da classe **célula ilegível**:
  - `:939` `done` sem commit (`"is 'done' with no commit"`);
  - `:941-942` `git cat-file -e "${commit}^{commit}"` → `"points at commit '$commit', which does not exist"`;
  - `:951` fora da história de HEAD;
  - `:958` status inválido.
  Depois vêm `checkpoint_tally` (`:979`), `blocked` (`:989`), pending (`:994`), TEST_CMD vermelho
  (`:1005`/`:1008`, os dois **citam log**: `see $LAST_CHECK_LOG`), handoff ausente (`:1011`) e o
  sucesso (`:1014`). Zero `pending` **não** é anomalia por si: os ramos `:1005/:1008/:1011` são
  trabalho legítimo de uma sessão EXEC.
- O `gate_EXEC` já publica globais para o ledger (`GATE_EXEC_PENDING`, `GATE_EXEC_TOTAL`, lidos em
  `cmd_run` logo depois do gate pós-sessão). O marcador de classe novo segue o mesmo molde.

**Derivação da fase e o subshell**
- `current_phase()` em `bin/sdd:1639`: percorre `$PHASES` e imprime o primeiro gate vermelho.
  Chamadores, todos `$(current_phase)`: `cmd_status` (`:5310`), `cmd_phase` (`:5350`), `cmd_why`
  (`:5359`), `cmd_run` (`:6556`), `cmd_retry` (`:7024`). O `graphify` **não vê** esses chamadores
  (zona cega de `$( )`, `docs/graphify.md`), então o censo sai do `grep`.
- `cmd_run` deriva em `bin/sdd:6556`: `else phase="$(current_phase)"; gate_pass_rows "$phase"; fi`.
  Os outros dois ramos são `dry_next` (projeção) e `force_phase` (`--phase X` e a volta que o retry
  força). O `gate_pass_rows()` (`:6467`) só lê arrays (`sessions`, `gate_failed`) e não chama gate.
- `run_check_cmd()` em `bin/sdd:645` memoiza por `$cmd` em `_CHECK_RC`/`_CHECK_LOG`, e
  `invalidate_checks` (`:674`) zera o cache. O **único** sítio que invalida fica no fim de
  `run_phase` (`bin/sdd:3736`). Por isso, derivar no shell pai é seguro: o gate pós-sessão já roda
  com o cache limpo.
- `TODO.md:320` (a economia depende do cache e ninguém conta) e `TODO.md:705` (o cache marca zero
  acertos porque todo leitor usa `$(current_phase)`) são a mesma causa. A decisão 6 fecha os dois.
- O gate pós-sessão do `cmd_run` **já** é chamado direto (`gate_"$phase" || gate_rc=$?`, logo
  depois de `local gate_rc=0 moved="false"`), então o `GATE_WHY` pós-sessão existe no shell pai. O do
  retry inline também (`gate_rc2`).

**O laço**
- `state_fingerprint()` em `bin/sdd:3753`: HEAD + listagem da missão + md5 do checkpoint.
- Primeira passada do `cmd_run`: `before="$(state_fingerprint)"`, `run_phase`, `after`,
  `moved`. Depois, na ordem: `session_died_escalation`, `handoff_blocked_escalation`,
  `app_down_escalation`, `hat_crossed_escalation`, `--max-phases`, gate verde → `continue`,
  `moved=true` → `dim "gate $phase not yet: … (but the session moved forward — carrying on)"` +
  `continue` (**este é o ramo do incidente**), e por fim o retry inline
  (`warn "  retrying once with the gate reason in the prompt"` → `run_phase "$phase" "$LAST_PHASE_SID"`).
- Retry inline: `after2`/`moved2`/`gate_rc2`, `session_died_escalation`, gate verde → `continue`,
  `handoff_blocked_escalation`, `app_down_escalation`, e `moved2=false` → `BLOCKED … two sessions
  without moving the disk` + `autonomy_blocked_row "no-progress"` + `return 3` (`bin/sdd:6984-6990`).
- `cmd_retry()` em `bin/sdd:6995`. Deriva com `phase="$(current_phase)"` (`:7024`), escreve a nota
  `intervention:`, checa `mission_budget_blown`, tira `before`, roda **uma** sessão, `after`,
  `kit_guard_check`, `hat_guard_check`, gate direto e linha de sessão, e com gate vermelho termina
  em `retry-gate-red`.
- `sdd kaizen` tem o próprio laço `no-progress` (`bin/sdd:8755-8805`) e fica **fora** (decisão 7).

**Ledger e escaladas**
- `autonomy_blocked_row <kind> <phase> <why>` em `bin/sdd:3235`. Chama `escalation_hook` (pager) e
  `autonomy_escalation_row "blocked" …`. Toda escalada rc 3 passa por ele.
- `is_escalation` é definido **sobre `.event`**, não sobre `.kind`: `bin/sdd:7492` (`cmd_autonomy`)
  e `bin/sdd:7982` (`kaizen_series`), ambos `.event == "blocked" or .event == "degraded"`. Um kind
  novo viaja em `event: "blocked"` e entra **sem editar** essas definições. O contrato do kind é a
  tabela em `docs/pipeline.md:987` (enum documentado de cauda aberta), a lista em
  `docs/pipeline.md:56` e a lista do `ON_ESCALATION_CMD` em `config/schema.md:174`. Os três mudam
  **no mesmo commit** do código.
- As famílias de escalada existentes, que servem de molde: `session_died_escalation`,
  `handoff_blocked_escalation`, `app_down_escalation` e `hat_crossed_escalation`. O contrato está no
  `CLAUDE.md`: **um setter por marcador, que zera o marcador na entrada**; a leitura fica numa função
  `<x>_escalation "$phase"` que devolve 0 quando escala; o marcador não sobrevive à volta; e a
  projeção (`--dry-run`) não arma nada.
- `pipeline_log_line()` em `bin/sdd:2284` escreve o journal e retorna cedo sob `DRY_RUN=1` (é o que o
  mutante `mut_RUN_inverted_journal` sabota). A linha de sessão está em `bin/sdd:3704`.

**Boot**
- `boot_prompt()` em `bin/sdd:2116`, chamado por `run_phase` como `prompt="$(boot_prompt "$pstep")"`
  (`bin/sdd:3537`). Ler global dentro do subshell funciona; escrever, não. O prompt do retry inline já
  carrega o gate (`bin/sdd:3563`: `"The gate for phase $phase failed: ${GATE_WHY}"`).
- `cmd_boot()` em `bin/sdd:7240` (`sdd boot <missão> <FASE>`) imprime `boot_prompt` sem abrir sessão.
  É o instrumento do Check do I4.

**Sensores e catálogo**
- `tests/check-gates.sh` tem `assert_phase "<nome>" "<fase esperada>"` e
  `assert_why "<nome>" "<fase>" "<trecho do motivo>"`, sobre um fixture `$MDIR` com checkpoint todo
  `done`. O molde do I1/I2 é o bloco do separador com dois-pontos (`tests/check-gates.sh:447-459`):
  `cp` para `.bak`, `sed -i` na linha, um **piso** provando que o fixture carrega o veneno
  (`fixture: …`), a asserção, e `mv` de volta.
- `tests/check-autonomy.sh` roda `"$SDD" run "$MISSION"` contra um stub em `$OUTSIDE/stub/claude`
  (molde em `tests/check-autonomy.sh:314-378`: `cat > "$OUTSIDE/stub/claude" <<STUB`, ledger em
  `$LEDGER`, `nrows`, `jq -r -s '.[N].kind' "$LEDGER"`). Um stub que **faz commit** simula a sessão
  no-op do incidente: `git -C <repo> commit --allow-empty -qm 'docs(checkpoint): no-op'`.
- Todo sensor imprime `  ok    <asserção>` na stdout e `  FAIL  <asserção>` na stderr. Todo Check
  deste plano ancora em `^  ok    ` com herestring e **nunca** leva `|` cru (`tests/check-checkpoint.sh`
  recusa).
- Catálogo de mutação: `tests/check-mutation.sh`. Cada mutante é uma função
  `mut_<SLUG>() { sed -i '<âncora em CÓDIGO>' "$1"; }` mais o `<SLUG>` na lista `CATALOG` (bloco que
  começa por volta de `tests/check-mutation.sh:3844`). O runner do catálogo **não** tem opção de
  mutante único: roda tudo (20–55 min) e é **opt-in**, fora do `TEST_CMD`. A prova de vermelho
  **por incremento** é a receita abaixo; o catálogo inteiro roda **uma vez**, no fim.
- **Receita M (provar um mutante sem o catálogo)**, na raiz do repo:
  ```bash
  d=$(mktemp -d); cp -r bin tests templates config agents "$d/"
  eval "$(sed -n '/^mut_<SLUG>() {/,/^}/p' tests/check-mutation.sh)"
  mut_<SLUG> "$d/bin/sdd"; cmp -s bin/sdd "$d/bin/sdd" && echo "NÃO APLICOU"
  SDD_MUTANT=1 bash "$d/tests/<sensor>.sh" >/dev/null 2>&1; echo "rc=$? (esperado: != 0)"
  ```
  "NÃO APLICOU" é conclusão **inválida**: a âncora apodreceu e o probe não sabotou o que diz sabotar.
- "Entra lá" são cinco lugares quando nasce **sensor novo** (`CLAUDE.md`). Esta missão **não** cria
  arquivo de sensor novo, só asserções em `check-gates.sh` e `check-autonomy.sh`, então os pisos de
  superfície não mudam.
- `tests/run-all.sh` é o `TEST_CMD`. Rode em **primeiro plano** (hook do repo limpa sandboxes a cada
  commit; nunca tarefa de fundo do Bash tool). O `sdd preflight` de dentro do Claude Code precisa de
  `env -u CLAUDECODE ./bin/sdd preflight`.
- `agents/*.md` → o espelho `.claude/agents/` se sincroniza **só** com `./bin/sdd install --force`,
  nunca com `cp`/Edit.
- O `docs/adr/*.md` está na superfície do `tests/check-lang.sh`: o ADR 0010 é **inglês** (verde hoje).
  `docs/handoffs/` é pt-BR e fica fora do sensor.

## Arquitetura da mudança

```
derive_phase (novo, CHAMADO)            gate_EXEC
  publica CURRENT_PHASE                   zera GATE_EXEC_CELL na entrada
  publica CURRENT_PHASE_WHY               arma GATE_EXEC_CELL=1 em :939/:942/:951/:958 + "não é SHA"
        │
        ├─ cmd_run (ramo derivado) ── pipeline_log_line "PHASE X reason=…"
        │        │── PORTA 1: no_work_check (b) célula | (a) mesmo motivo que a volta anterior
        │        │            → no_work_escalation → BLOCKED + kind no-work + rc 3 (antes da sessão)
        │        ├─ run_phase → boot_prompt lê CURRENT_PHASE_WHY ("Why this phase: …")
        │        └─ retry inline: PORTA 2: (b) sobre o gate pós-sessão-1, ANTES de comprar o retry
        └─ cmd_retry ── PORTA 3: (b) antes da única sessão
checkpoint_rows: gsub da crase em f[6] (único leitor → todos os consumidores)
```

- **`derive_phase`** (nome fixo, para os Checks e mutantes): a mesma varredura de `current_phase`,
  mas **chamada** e publicando `CURRENT_PHASE` e `CURRENT_PHASE_WHY` (o `GATE_WHY` do gate que
  reprovou; vazio quando o pipeline acabou). Como o gate roda no shell pai, `GATE_EXEC_CELL` também
  sobrevive. `current_phase` fica para os três leitores de fora do escopo; se couber, vira
  `derive_phase; printf '%s\n' "$CURRENT_PHASE"`, uma definição só.
- **`no_work_check <phase> <why_anterior>`**: o **único** setter de `NO_WORK_WHY`, que zera na entrada.
  Arma quando:
  - **(b)** `phase = EXEC` e `GATE_EXEC_CELL = 1`;
  - **(a)** `why_anterior` não vazio, igual ao `GATE_WHY` atual, e `gate_why_cites_log` falso.
- **`gate_why_cites_log`**: predicado **positivo**, uma definição. Casa quando o texto carrega um
  caminho `.log` depois de `see `/`See ` (as formas de `bin/sdd:1005/1008/1168/1187/1196/1201`).
  Com a admissão positiva, motivo novo que cita log de outro jeito cai do lado que **para** a linha,
  o fail-safe da guarda, e é declarado no comentário.
- **`no_work_escalation <phase>`**: lê `NO_WORK_WHY`. Quando armado, faz
  `pipeline_log_line "… BLOCKED $phase no-work: …"` + `autonomy_blocked_row "no-work" "$phase" "$NO_WORK_WHY"`
  e devolve 0. As portas o chamam como `if no_work_escalation "$phase"; then return 3; fi`, a
  **mesma grafia** das irmãs, para o censo `grep -cE '^ +if no_work_escalation "\$phase"; then' bin/sdd`
  → `3`. Sob `DRY_RUN=1` o `no_work_check` não arma nada.
- **Onde fica cada porta**:
  - **Porta 1** (`cmd_run`, primeira passada): logo depois da derivação e da linha `PHASE`, **antes**
    do teto de orçamento e do `before="$(state_fingerprint)"`, **só no ramo derivado** (sob
    `force_phase` e `dry_next` não há motivo derivado). Guarda `prev_phase`/`prev_why` como locais do
    laço, atualizados a cada volta derivada; a forma (a) compara com eles.
  - **Porta 2** (retry inline): depois do gate pós-sessão-1 e **antes** do `run_phase` do retry.
    Chama `no_work_check "$phase" ""`, só (b), sobre o gate que acabou de rodar no pai. O mundo que
    alcança é `sdd run --phase EXEC` com célula ilegível e sessão sem commit (`moved=false`): sem a
    porta, compra o retry.
  - **Porta 3** (`cmd_retry`): depois de `derive_phase` e antes da nota `intervention:`/sessão. Só
    (b). A nota `intervention:` não é escrita quando a porta recusa, porque nenhuma sessão foi aberta.
- **Boot**: `boot_prompt` ganha uma linha, em inglês (superfície do kit), por exemplo
  `Why this phase: <CURRENT_PHASE_WHY>`, quando `CURRENT_PHASE = <fase do boot>` e o motivo não é
  vazio. Com fase forçada, escreve `Why this phase: forced from the CLI — the runner did not derive it`.
  O `cmd_boot` chama `derive_phase` antes, para o instrumento mostrar o mesmo que a sessão vê.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. Cada incremento
fecha com `bash tests/run-all.sh` → `suite green`, um commit `<tipo>(<escopo>): …` com o porquê no
corpo, e a atualização do checkpoint como último ato.

### I1 — a crase na célula de commit é lida como o SHA (#55, camada 1)

**O quê:** em `checkpoint_rows`, tirar crase do campo Commit (`f[6]`) junto com o espaço. Só do
Commit: um Check **pode** legitimamente carregar crase, e o campo 4 é lido pelo `check-checkpoint.sh`.
**Onde:** `bin/sdd` (`checkpoint_rows`, vizinhança de `:457`), `tests/check-gates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** Red em uma frase: *com a célula de commit de uma linha `done` escrita
`` `<sha>` ``, `assert_phase` ainda responde EXEC.* Bloco novo depois do bloco do separador com
dois-pontos:
- `sed -i` que envolve o SHA da primeira linha `done` do fixture em crases;
- piso `fixture: the commit cell really carries backticks`;
- `assert_phase "a backticked commit cell is read as the SHA it carries" "<a fase que o fixture
  espera com tudo done — a mesma do bloco anterior, QA>"`;
- restaurar.
Depois, o `gsub` no awk.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a backticked commit cell is read as the SHA it carries' <<< "$o"` → `1`
**Sensor durável:** a asserção em `check-gates.sh` e o mutante `GATE_EXEC_backtick_kept` (apaga o
`gsub` da crase), provado vermelho pela receita M contra `check-gates.sh`.
**Reversível por:** `git revert` do commit.

### I2 — célula que não é SHA ganha motivo próprio, e o gate marca a classe (#55, camada 3 do gate)

**O quê:** no `gate_EXEC`, antes do `cat-file`, uma célula `done` cujo Commit não casa
`^[0-9a-f]{7,40}$` reprova com uma mensagem própria, por exemplo
`"increment $id: the Commit cell '$commit' is not a SHA — write the bare short hash, no backticks or words"`.
E o marcador `GATE_EXEC_CELL`: zerado na entrada do `gate_EXEC`, `1` nos sítios `:939`, `:942`,
`:951`, `:958` e no novo. O marcador é o dado da guarda (b); **nunca** classificar pelo texto.
**Onde:** `bin/sdd` (`gate_EXEC`), `tests/check-gates.sh`, `tests/check-mutation.sh`.
**Como (TDD):** Red: *com a célula `commit abc1234`, o motivo é "does not exist" e não "is not a SHA".*
Asserções:
- `a commit cell that is not a SHA gets its own reason`, via `assert_why … "EXEC" "is not a SHA"`;
- `the not-a-SHA reason is not the does-not-exist reason`: o `GATE_WHY` **não** contém
  `does not exist`, a ausência do marcador do outro ramo (régua "Red pelo motivo certo").
O marcador é provado no I5, onde tem consumidor.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a commit cell that is not a SHA gets its own reason' <<< "$o"` → `1`
**Sensor durável:** as duas asserções e o mutante `GATE_EXEC_not_a_sha_silent` (remove o ramo novo).
**Reversível por:** `git revert`.

### I3 — a fase derivada carrega o motivo, e o journal o escreve (#56)

**O quê:**
- `derive_phase` (ver Arquitetura), usado no ramo derivado do `cmd_run` e no `cmd_retry`;
- no ramo derivado, `pipeline_log_line "$(date -Iseconds)  PHASE  $CURRENT_PHASE  reason=\"$CURRENT_PHASE_WHY\""`
  quando a fase não é vazia;
- o sensor-contador do `TODO.md:320`.
**Onde:** `bin/sdd` (`current_phase`, `cmd_run`, `cmd_retry`), `tests/check-autonomy.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** Red: *depois de um `sdd run` que abre uma sessão EXEC, o `pipeline.log` não tem
nenhuma linha `PHASE  EXEC  reason=`.* Asserções:
- `every derived phase writes its reason to the journal`: a linha existe e o `reason=` carrega o
  `GATE_WHY` do fixture, por exemplo `1 of 1 increment(s) still to execute`;
- `TEST_CMD runs do not grow with the number of pending phases`: `TEST_CMD` do fixture =
  `echo x >> "$COUNTER"; true`, `sdd run --max-phases 1` em dois fixtures, um com uma fase pendente
  depois do EXEC e outro com três. Afirme que as contagens são **iguais**: asserção diferencial,
  dois mundos comparados entre si. **Meça primeiro em `main`** (antes do conserto) e anote os dois
  números em `checkpoint-notas.md`; o Red esperado é a contagem crescer.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every derived phase writes its reason to the journal' <<< "$o"` → `1`
**Sensor durável:** as duas asserções e os mutantes `RUN_phase_reason_unlogged` (apaga a linha
`PHASE`) e `RUN_derive_in_subshell` (volta o `cmd_run` para `phase="$(current_phase)"`; deve
avermelhar o contador ou o `reason=`).
**Reversível por:** `git revert`.

### I4 — toda fase sabe por que foi aberta (elo 3, decisão 1)

**O quê:** a linha `Why this phase: …` em `boot_prompt` (ver Arquitetura), e `cmd_boot` chama
`derive_phase` antes.
**Onde:** `bin/sdd` (`boot_prompt`, `cmd_boot`), `tests/check-autonomy.sh` ou `tests/check-gates.sh`
(onde já houver fixture que chame `sdd boot`; confira com `grep -n '" boot ' tests/*.sh`),
`tests/check-mutation.sh`.
**Como (TDD):** Red: *`sdd boot <missão> EXEC`, com uma linha pending, não contém
`Why this phase: 1 of 1 increment(s) still to execute`.* Asserções:
- `the boot prompt carries the phase reason`;
- `a phase the runner did not derive says so in the boot`: `sdd boot <missão> DOCS` com EXEC
  pendente fala `forced from the CLI`.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the boot prompt carries the phase reason' <<< "$o"` → `1`
(se a asserção morar em `check-gates.sh`, troque o arquivo e mantenha o texto, anotando em
`checkpoint-notas.md`).
**Sensor durável:** as asserções e o mutante `BOOT_reason_dropped`.
**Reversível por:** `git revert`.

### I5 — `no-work`: a célula ilegível para a linha antes da sessão (portas 1 e 3, forma (b))

**O quê:**
- `no_work_check`, `gate_why_cites_log` (pode nascer aqui, com probe no I6) e `no_work_escalation`;
- porta 1 com só (b) por enquanto, e porta 3;
- contrato do kind **no mesmo commit**: linha `no-work` na tabela `kind` do `docs/pipeline.md:987`,
  na lista de `docs/pipeline.md:56` e na lista do `ON_ESCALATION_CMD` em `config/schema.md:174`;
- o limite de `sdd kaizen` declarado no comentário da função.
**Onde:** `bin/sdd`, `docs/pipeline.md`, `config/schema.md`, `tests/check-autonomy.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** Red: *com uma linha `done` cujo Commit é um SHA que não existe (`deadbee`) e um
stub que faz commit vazio, `sdd run` abre uma sessão EXEC.* Asserções, cada uma com a testemunha de
que **nenhuma** sessão abriu (ledger sem linha `event:"session"` de EXEC, stub com contador em
arquivo = 0):
- `door 1: an unreadable cell stops the line before any session`: rc 3, e a última linha do
  ledger tem `kind` = `no-work`;
- `door 3: sdd retry refuses an unreadable cell before any session`: `"$SDD" retry "$MISSION"` → rc 3,
  `kind` = `no-work`, 0 sessões e **nenhuma** nota `intervention:` nova;
- `no-work rows are counted alike by both readers`: asserção **diferencial** entre a contagem de
  escaladas `no-work` do `sdd autonomy` e a do `sdd kaizen --series` sobre o mesmo ledger. Siga o
  molde dos pares diferenciais existentes (`grep -n 'differential\|compared to each other'
  tests/check-autonomy.sh`).
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    door 1: an unreadable cell stops the line before any session' <<< "$o"` → `1`
**Sensor durável:** as asserções e os mutantes `RUN_no_work_door1_blind` (apaga a chamada da porta
1), `RETRY_no_work_blind` (porta 3) e `EXEC_cell_marker_never_armed` (o gate não arma
`GATE_EXEC_CELL`).
**Reversível por:** `git revert` (código e docs juntos).

### I6 — mesmo motivo duas vezes para a linha, e o retry inline recusa a célula (forma (a) + porta 2)

**O quê:** a forma (a) na porta 1 (`prev_phase`/`prev_why`) e a porta 2 (só (b), antes do retry).
**Onde:** `bin/sdd` (`cmd_run`), `tests/check-autonomy.sh`, `tests/check-mutation.sh`.
**Como (TDD):** Red: *um stub que só faz commit vazio, com uma linha `pending` e a suíte verde,
compra uma segunda sessão EXEC com o mesmo motivo (`1 of 1 increment(s) still to execute`).*
Asserções:
- `door 1: the same reason twice stops the line as no-work`: exatamente **1** sessão, rc 3,
  `kind` `no-work`;
- `a reason that cites a log never stops the line as no-work`: `TEST_CMD=false` e todo `done`, o
  stub faz commit vazio; nenhuma linha `no-work` no ledger (o fixture termina por outro caminho,
  por exemplo teto de orçamento ou `no-progress`: afirme só a ausência de `no-work` **e** a
  presença de ≥ 2 sessões, a testemunha de que o regime repete);
- `door 2: the inline retry is refused on an unreadable cell`: `sdd run --phase EXEC`, célula
  `deadbee`, stub **sem** commit; exatamente **1** sessão, rc 3, `kind` `no-work`. Sem a porta 2,
  seriam 2 sessões e `no-progress`.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    door 1: the same reason twice stops the line as no-work' <<< "$o"` → `1`
**Sensor durável:** as asserções e os mutantes `RUN_no_work_same_reason_blind` (a comparação (a)
nunca casa), `RUN_no_work_door2_blind` (apaga a porta 2) e `RUN_no_work_cites_log_blind`
(`gate_why_cites_log` sempre falso: deve avermelhar a asserção do log).
**Reversível por:** `git revert`.

### I7 — o executor e o template sabem da célula e do caso "zero pending" (decisões 2 e 5)

**O quê:**
- `agents/sdd-executor.md`, em inglês (superfície do kit):
  - § 2, depois de "The **first** one with `Status: pending`": o caso **zero pending**, com o
    texto da decisão 2 (ler `Why this phase:` do boot; suíte ou handoff → consertar; célula →
    só reformatação, senão `blocked`; **never a no-op commit**);
  - § 5 (`:109`): `Commit` → *the bare short hash, no backticks: the runner reads the cell, and
    fencing it renders identically for a human while making the SHA unreadable to the gate*.
- `templates/checkpoint.md`: uma frase no cabeçalho sobre a célula Commit nua (pt-BR).
  **Não** mudar colunas nem headings: `check-templates.sh` os lê.
- `./bin/sdd install --force`.
**Onde:** `agents/sdd-executor.md`, `.claude/agents/sdd-executor.md` (só via install),
`templates/checkpoint.md`.
**Como (TDD):** Red: *`grep -c 'no-op commit' agents/sdd-executor.md` → `0`.* Não há sensor
comportamental possível para prosa de agente; o poka-yoke real é o I1 mais o I5 e o I6. Isto é a
camada de texto, declarada como tal.
**Check:** `grep -c 'no-op commit' agents/sdd-executor.md; cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && echo espelho-ok` → `1` (ou mais) e `espelho-ok`
**Sensor durável:** `tests/check-templates.sh` e `tests/check-hat.sh` continuam verdes, e
`env -u CLAUDECODE ./bin/sdd preflight` não acusa `agent sdd-executor stale`. Checagem efêmera
justificada: prosa de prompt não tem asserção comportamental.
**Reversível por:** `git revert` + `./bin/sdd install --force`.

### I8 — replay do incidente, e o padrão escrito (métrica + SDCA)

**O quê:**
- Dois probes de ponta a ponta em `tests/check-autonomy.sh` reproduzindo o incidente:
  - `incident replay: a backticked cell buys no EXEC session`: checkpoint todo `done`, uma célula
    `` `<sha real>` ``, suíte verde, `20-handoff-exec.md` presente, stub que faz commit vazio. O
    `sdd run --max-phases 1` não abre sessão EXEC; a primeira fase derivada é a seguinte (QA no
    fixture) e o `pipeline.log` diz `PHASE  QA`;
  - `incident replay: a missing commit ends rc 3 no-work with zero sessions`.
- Documentação: `.claude/rules/anatomia-do-agente.md` §3 (o boot carrega o motivo) e §7 (rc 3
  `no-work` na lista de portas humanas); verbete **D27** no `CONTEXT.md` (tabela de decisões,
  molde da D25: pergunta, decisão com data do grill, gemba com números, recusadas, link para o ADR
  0010); `KAIZEN_LOG.md` com antes/depois: US$ 1,94 e ≥ 2 sessões sem teto → 0 sessões; 0 → 1
  linha `PHASE` por fase derivada.
- `docs/adr/0010-o-motivo-da-fase.md`: status `proposed` → `accepted` no merge, **não** antes.
**Onde:** `tests/check-autonomy.sh`, `.claude/rules/anatomia-do-agente.md`, `CONTEXT.md`,
`KAIZEN_LOG.md`.
**Como (TDD):** Red: rode os dois probes com o I1 revertido na receita M (mutante
`GATE_EXEC_backtick_kept`); o primeiro deve avermelhar. Isso prova que o replay mede o incidente,
não o fixture.
**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    incident replay: a missing commit ends rc 3 no-work with zero sessions' <<< "$o"` → `1`
**Sensor durável:** os dois probes; o catálogo inteiro roda **uma vez** aqui (ver Verificação).
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A forma (a) para uma fase que fazia progresso real com motivo idêntico, por exemplo REVIEW com o mesmo `40-review-r<N>.md` ou QA com "N bug(s)" igual | média | o motivo de REVIEW carrega o nome da rodada e o de EXEC a contagem; o I6 prova o caso de log. Se um probe achar outro motivo estável com progresso real, **pare** (Jidoka), anote em `checkpoint-notas.md` e leve ao humano: não alargar a exclusão sozinho, porque é decisão do grill |
| `derive_phase` no pai muda a ordem de avaliação e reintroduz execução extra de `TEST_CMD` | baixa | o contador do I3 é justamente o sensor |
| Mudança no `bin/sdd` durante a execução interativa quebra um `sdd` em uso | baixa | ninguém roda `sdd run` no kit nesta missão; a última linha `{ main "$@"; exit $?; }` fica intocada |
| O catálogo de mutação acha um anchor apodrecido de mutante **antigo** (as linhas andam) | média | é o `CATALOGUE-BROKEN` (rc 90); conserte a âncora do mutante no mesmo PR, ancorada em código |
| A catraca do `sdd health` (`tests/health-baseline.txt`) muda porque um achado foi para o `TODO.md` | média | registrar achado move a baseline e mata o carimbo: registre **antes** do carimbo final |
| Yokoten da crase (`gate_REVIEW`, `gate_DOCS`, `adr_link` #50) | — | fora de escopo (00-missao) |

## Verificação end-to-end

Com os oito incrementos `done`:

1. `bash tests/run-all.sh` → `suite green`.
2. `grep -cE '^ +if no_work_escalation "\$phase"; then' bin/sdd` → `3`.
3. `bash -n bin/sdd` e `env -u CLAUDECODE ./bin/sdd preflight` verdes.
4. Os dois probes de replay do I8 e a asserção diferencial do I5 aparecem como `ok`.
5. **Ordem que economiza a hora** (`CLAUDE.md`, PR #45): abrir o PR, esperar **todos** os revisores,
   consertar numa leva, e só então `./bin/sdd health --with-mutation` **uma vez**, que carimba. O
   score esperado é `N caught of N`, com os mutantes novos (`GATE_EXEC_backtick_kept`,
   `GATE_EXEC_not_a_sha_silent`, `RUN_phase_reason_unlogged`, `RUN_derive_in_subshell`,
   `BOOT_reason_dropped`, `RUN_no_work_door1_blind`, `RETRY_no_work_blind`,
   `EXEC_cell_marker_never_armed`, `RUN_no_work_same_reason_blind`, `RUN_no_work_door2_blind`,
   `RUN_no_work_cites_log_blind`) todos pegos. O `gate_PR` exige o carimbo.
6. Depois do merge: apagar do `TODO.md` os itens das linhas `:320` e `:705` (provado por
   `git merge-base --is-ancestor <hash> main`), ajustar a catraca e fechar as issues #54, #55 e #56
   citando o hash.
