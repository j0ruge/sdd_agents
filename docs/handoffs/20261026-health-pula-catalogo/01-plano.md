---
missao: 20261026-health-pula-catalogo
data: 2026-10-26
---

# Plano — o `sdd health` pula o catálogo com a chave já medida

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido pelo planner em 2026-10-25 22:00 → 2026-10-26 00:40, na worktree, base `6dd1a77` avançada por
fast-forward para `c114e36` (PR #328, só `TODO.md`) antes de escrever. Os números de linha abaixo são de
`c114e36`.

### Onde e como se trabalha

- **Raiz da missão:** a worktree ligada `/home/pc_admin/repos/sdd_agents-health-pula-catalogo`, branch
  `fix/health-pula-catalogo` (renomeada de `plan/health-pula-catalogo`; sem upstream —
  `git rev-parse --abbrev-ref @{u}` → `fatal: no upstream configured`). O checkout principal
  `/home/pc_admin/repos/sdd_agents` está na `main`, limpo (`git -C … status --porcelain` vazio).
- **Todo comando roda como `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`.** A sessão herda
  outro cwd, e nada se escreve no checkout principal: rascunho, fixture e saída de medição vão para caminho
  **absoluto** fora dele (`mktemp -d` ou `/home/pc_admin/.wt/plan-health-pula-catalogo/`). Antes de
  devolver, `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio.
  ⚠️ **Exceção que a própria missão cria, e é o produto:** o `./bin/sdd health` desta branch grava em
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/` (o `git-common-dir`). Isso é o desenho (decisão 1),
  não sujeira: o `git status --porcelain` não vê `.git/`. Nenhum sensor grava ali — todo fixture é um
  repositório próprio em `mktemp -d`.
- `.sdd/config.sh` da worktree: `HANDOFF_DIR=docs/handoffs`, `OUTPUT_LANG=pt-BR`, `DEFAULT_BRANCH=main`,
  `TODO_FILE=TODO.md`, `JIRA_ENABLED=false`, `ADR_CHECK=block`, `TEST_CMD=tests/run-all.sh`.
- **Execução interativa**, um subagente `sdd-executor` por incremento, nunca `sdd run` do kit a partir do
  checkout principal. Dentro da worktree, `health`, `preflight` e `install` rodam como `./bin/sdd`.
  **Nenhum `./bin/sdd health` durante o EXEC** (é o carimbo do operador, depois dos bots — pendência).
- **Ferramentas desta máquina:** GNU bash 5.2.21, GNU grep 3.11, python 3.12.3, git 2.43.0, `nproc` 8.
  **Não há `shellcheck`** (`command -v shellcheck` vazio): o passo `lint:` da suíte imprime
  `(linter absent — skipped)`; não há lint a rodar antes do commit. No zsh, `echo ====` falha (expansão
  `=`): use `echo '----'`.
- **A suíte rápida** (`tests/run-all.sh`, o `TEST_CMD`) levou **672 s** nesta worktree (2026-10-25 23:59 →
  00:10), rc 0, 2046 linhas `ok`, 0 FAIL. O Bash em primeiro plano para em 10 min: rode-a em segundo plano
  e espere a notificação. Os passos que esta missão toca e os seus prazos (`step_timeout`,
  `tests/run-all.sh:176–197`): `gate state machine` 600 s, `sdd health discriminates` 180 s (o
  `check-health.sh` levou ~40 s), `every hat declares its boundary` 60 s, `catalogue anchors` 60 s.
- **Antes de cada commit:** `bash tests/check-todo.sh` (forma e âncoras do `TODO.md`), `bash
  tests/check-lang.sh` (superfície inglesa: todo comentário, mensagem e asserção nova em `bin/`, `tests/`,
  `commands/` e `docs/adr/` é inglês), `bash tests/check-pipefail.sh` e `bash tests/check-mutation.sh
  --anchors` (todo mutante ainda se aplica). Nenhum commit com um `tests/run-all.sh` vivo.
- **Antes de mexer em item do `TODO.md`** (`RESOLVED by`, reancorar), invoque a skill `todo-to-github-issues`
  (ferramenta `Skill`) e siga a forma dela; depois, o `--audit` dela, que só lê
  (`python3 ~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py --audit`). Nunca `--apply` da branch
  e nunca mude o título de um item: o título é a chave do espelho.
- **A ADR 0021 e o `Amended by` das ADRs 0004 e 0016 nascem sem commit:** o `sdd approve` commita só a pasta da
  missão. Se ao começar o I1 `git status --porcelain -- docs/adr` ainda os mostrar, commite-os sozinhos antes
  (`docs(adr): 0021 — the stamp is a set of keys in the git common directory`), sem mudar o texto.
- **O `TODO.md` tem uma mudança sem commit, de propósito:** a linha `RECURRED 6` do achado "O `/sdd-plan`
  delega ao `sdd-planner` sem saída para o agente não registrado" (`TODO.md:225`), pedida pelo humano no
  grill. Ela entra no commit dos achados que o humano faz depois do `sdd approve`; se ela ainda estiver
  fora de commit quando o I1 começar, **não a reverta** — commite-a sozinha antes
  (`chore(todo): RECURRED 6 …`) e siga.

### O carimbo hoje (`bin/sdd`, `c114e36`)

- `MUTATION_STAMP_PATHS=(bin tests templates config agents)` e `MUTATION_STAMP_EXCLUDE=(tests/health-baseline.txt)`
  em `:2435–2436`; `MUTATION_STAMP_PATHSPEC` em `:2440–2445`; `readonly MUTATION_STAMP_REL='.sdd/logs/mutation-stamp'`
  em `:2451` (usado em `:2676`, `:7250`, `:7467` e em nenhum outro lugar do `bin/sdd`).
- `has_mutation_catalogue` `:2462`; `health_kit_root` `:2475`; `mutation_stamp_missing` `:2532`;
  `mutation_stamp_why` `:2548` (publica `MUTATION_STAMP_WHY`/`_KIND`); `mutation_stamp_key` `:2578` (imprime a
  chave ou nada e rc 1). Nenhum destes muda de semântica nesta missão.
- `gate_PR` `:2614`; o bloco do carimbo `:2672–2706`: `key="$(mutation_stamp_key "$REPO_ROOT" || true)"`,
  `stamp="$(cat "$REPO_ROOT/$MUTATION_STAMP_REL" …)"`, e a recusa `no green mutation catalogue for this content —
  run 'sdd health' …` quando `[ -z "$key" ] || [ "$stamp" != "$key" ]`. `GATE_PR_STAMP_WHY` (`:2607`) e
  `GATE_PR_STAMP_IMPOSSIBLE` (`:2612`) são lidos pelo `cmd_run` em `:9402–9404` (para com rc 2 sem abrir sessão).
- `health_release` `:7168`; a linha 6 em `:7248–7252` (`key=…; stamp="$(cat "$kit/$MUTATION_STAMP_REL" …)"`).
- `cmd_health` `:7258`: o laço de opções `:7262–7271` (`--release`, `--with-mutation) : ;;` em `:7267`, e o `die`
  `unknown option '$1' (accepted: --release, --with-mutation)` em `:7268`); `kit="$(printf '%s' "$COORDINATION_ROOT" || true)"`
  em `:7281`; `stamp_key_before` em `:7304`; a chamada `out="$( cd "$kit" && tests/run-all.sh --with-mutation 2>&1 )" || rc=$?`
  em `:7313`; a verificação 2 (score) `:7322–7397` (`catalogue_green=1` só com score limpo **e** `rc -eq 0`, `:7400`);
  a 2c (carimbo) `:7467–7509`: `rm -f "$stamp_path"` quando `catalogue_green != 1` (`:7473`), o ramo da chave vazia
  (`:7474–7495`, `not-git` só avisa), a janela `stamp_key != stamp_key_before` (`:7496–7501`) e a gravação (`:7502–7509`).
- A ajuda: `sdd health` em `bin/sdd:11913–11915` (`[--release]` e a sua linha).
- O `COORDINATION_ROOT` do `sdd health` é `health_kit_root` (`coordination_enter`, `bin/sdd:12094`) e o
  `COORDINATION_DIR` é o `--absolute-git-dir` **da worktree** (`coordination_paths`, `:12068–12077`): o lock é
  por worktree, o lugar novo é por repositório — não confunda os dois.
- **O precedente da grafia:** `ledger_repo_root` (`bin/sdd:3641`) lê
  `git -C "$start" rev-parse --path-format=absolute --git-common-dir` (`:3651`) e só aceita resposta
  **absoluta de uma linha** (o git < 2.31 ecoa o flag desconhecido); copie a prova, não só o comando.
  Nesta worktree a resposta é `/home/pc_admin/repos/sdd_agents/.git`.
- **A guarda do kit não vê `.git/`:** `autonomy_kit_stamp` (`bin/sdd:4116`) é `rev-parse HEAD` +
  `git status --porcelain`; gravar em `.git/sdd-mutation/` não muda nenhum dos dois.
- **O `gate_REVIEW` roda o `TEST_CMD`** (`bin/sdd:2088`), e o `current_phase` reavalia os gates em ordem:
  uma suíte vermelha para a linha antes do `gate_PR`, com ou sem chave (premissa da decisão 3).
- No checkout principal hoje: `.sdd/logs/mutation-stamp` = `b04da602…` (velho) e
  `.sdd/cache/mutation-killers.tsv` de 775 linhas; nesta worktree a cópia do mapa (775 linhas) em
  `.sdd/cache/` e nenhum `.sdd/logs/`. Precedente de nome na raiz do git dir: `sdd-coordination.lock`.

### O mapa hoje (`tests/check-mutation.sh`, `c114e36`)

- `. "$(dirname …)/isolate-git.sh"` no topo (`:32`) limpa `GIT_DIR` e afins; `ROOT` em `:42`.
- `declare -A KILLER=() SECS=()` em `:146`; `load_killer_map <tsv>` em `:151` (arquivo ausente = mapa vazio;
  segunda coluna obrigatória, terceira só dígitos).
- `KILLERS_FILE="$ROOT/.sdd/cache/mutation-killers.tsv"` em `:7550`, com o comentário do mapa em `:7537–7549`.
- Os três leitores: `--only` (`:7758`), `--touched` (`:7805–7806`, `TOUCHED_MAP="${SDD_KILLERS_FILE:-$KILLERS_FILE}"`)
  e o catálogo (`:7900`).
- O escritor: `:7976–7991` — reescreve o mapa **desta rodada só**, por `"$KILLERS_FILE.tmp.$$"` + `mv -f`.
- Os selftests do harness rodam **antes** do despacho de modo (`controls_selftest` `:312`, chamado em `:7599`;
  `touched_selftest` `:358`, chamado em `:7605`; o despacho começa em `:7622`), então rodam também no
  `--anchors`, que é o modo da suíte rápida. Um `killers_selftest` novo entra ao lado deles, com um `pass`
  `killers: …` e `exit 1` no vermelho, na mesma forma.
- `sandbox()` copia `bin tests templates config agents CLAUDE.md TODO.md docs/adr docs/pipeline.md commands` —
  **não** copia `.sdd/` nem `.git/`; o mutante nunca lê o mapa (recebe `SDD_MUTANT_FIRST`).

### Os sensores que a missão toca

- **`tests/check-gates.sh`** — o bloco do carimbo (o `i4`): `i4_phase` `:3214`; `i4_health` `:3243`
  (`( cd "$FIX" && HOME="$i4_home" NO_COLOR=1 "$FIX/bin/sdd" health >/dev/null 2>&1 ) || true`); `i4_verdict`
  `:3248` (o veredito do stub mora em `$FIX/.sdd/logs/stub-verdict`, fora da chave); `i4_write_suite` `:3260`
  (o stub embute caminhos absolutos de `$FIX`, então uma worktree ligada do `$FIX` roda o mesmo stub). Os
  mundos: 3b `:3384`, 4 `:3396`, 4b `:3404`, **5 `:3443`, 6 `:3447` ("a red suite takes the stamp away")**, 7
  `:3453`, 8 (janela) `:3462`, 9 (raiz parcial), 9b, 10 (catraca), 11, 11b, 12, 13; o bloco das duas árvores
  `:3615–3757` (`TREE_STAMP=".sdd/logs/mutation-stamp"` `:3642`, `tree_stamped` `:3643`, `tree_health` `:3693`,
  o `TREE_KIT` é outro repositório, então segue sem dividir o lugar com o `$FIX`). As **11** linhas que citam o
  arquivo velho: `:3473 3476 3503 3508 3587 3590 3604 3607 3642 3748 3767`.
- **`tests/check-health.sh`** — o fixture é um checkout git (`:236–241`, `.gitignore` = `home/`); o stub da suíte
  `write_stub_suite` `:252` grava o próprio argv em `$FIX/tests/stub-argv.txt` (`:269`); `health_run` `:355`
  (~45 chamadas, ~0,9 s cada); `green_world` `:781`; a asserção do argv `surface: cmd_health asks the suite
  for the mutation catalogue` `:1417–1437`; `STAMPED='mutation stamp written'` `:903`; o mundo sem git `:1003`.
  ⚠️ **Limite declarado do próprio sensor (`:40–44`):** o `stub-argv.txt` nunca é apagado entre mundos, "the day
  cmd_health grows a SECOND path to the suite, the last write wins in silence; delete the file in
  green_world then" — **esta missão cria esse segundo caminho**: o I2 apaga o arquivo antes de cada `health_run`.
  ⚠️ **`CAPTURE_FLOOR=40` (`:2467`) é exato:** o censo `guard:` conta toda captura `x="$(…)"` da região do
  `sdd health` (de `health_release` até `cmd_status() {`, mais todo corpo `health_*()`), e reprova nos dois
  sentidos; toda captura nova é guardada (`|| true`, `|| rc=$?`) e o piso anda no mesmo commit, com uma linha
  no registro logo acima dele (`# 40 → N: …`).
- **`tests/check-hat.sh`** — `command_worktree_return_probes` `:584` (chamada em `:826`) segura as frases do
  `commands/sdd-plan.md:49–54`; `release_probes` `:758` (chamada em `:830`) monta uma caixa git e lê as seis
  linhas do `--release`, **sem nenhuma asserção sobre a linha 6**; `:779–783` segura `--with-mutation` como sinônimo.
- **`tests/check-mutation.sh`** — 775 mutantes; os de carimbo e mapa: `mut_PR_stamp_blind` `:1458`,
  `mut_PR_stamp_key_*` `:1483–1577`, `mut_PR_stamp_why_*` `:1583–1602`, `mut_HEALTH_unstampable_silent` `:1503`,
  `mut_RUN_stamp_*` `:1533/1550`, `mut_PR_stamp_marker_always` `:1539`, `mut_PR_stamp_impossible_unmarked` `:1547`,
  `mut_HEALTH_stamp_tree_blind` `:1615`, `mut_HEALTH_stamp_window_blind` `:1625` (ancora em
  `elif \[ "\$stamp_key" != "\$stamp_key_before" \]; then` dentro do `cmd_health`).
  ⚠️ `mut_HEALTH_suite_without_mutation` (`:4202`) é **sem endereço**:
  `sed -i 's@tests/run-all.sh --with-mutation 2>\&1@tests/run-all.sh 2>\&1@'` — se a chamada do `cmd_health`
  mudar de grafia, a âncora quebra e o `--anchors` acusa (rc 90). Re-ancorar e endereçar ao corpo do `cmd_health`.
- **`commands/sdd-plan.md:49–54`** manda o humano trazer o mapa e, com a linha 6 vermelha, o carimbo de volta
  antes do `git worktree remove`, citando `docs/failure-modes.md` "`sdd health` in the main checkout is slow
  again after a kit mission".

### As âncoras do `TODO.md` que os incrementos empurram

`bash tests/check-todo.sh --anchors TODO.md` no HEAD → `anchors: 61 measured, 0 off target`. A regra: o
símbolo designado (`` `arquivo:N` (`símbolo`) ``) tem de estar a até **10 linhas** de `N`. Toda inserção
líquida de mais de 10 linhas empurra os itens abaixo dela; reancore **no commit do próprio incremento**,
pelo número que o `--anchors` sugere ("nearest … is at line N"), conferido a olho:

- `bin/sdd`, itens com âncora depois de `:2440` (I1 insere ali, I2 dentro do `cmd_health`): `2614` (`gate_PR`),
  `2713` (`PHASES`), `3365`, `4116`, `4349`, `4616`, `5461`, `5620`, `5806`, `6073`, `6089`, `6155`, `6314`,
  `6567`, `6813`, `6951`, `7042`, `7311` (`--with-mutation`, o item desta missão), `7839`, `7896`, `8555`,
  `9368`, `11792`, `11920`, `12051`. **Dica para reancorar pouco:** ponha os helpers novos do I1 perto do
  `cmd_health` (depois de `health_release`), não ao lado do `mutation_stamp_key`, e mantenha líquido ≤ 10
  linhas o diff acima de `:7168` — assim só os itens de `7311` para baixo andam.
- `tests/check-mutation.sh:7550` (`KILLERS_FILE`), o item vizinho: o I3 muda essa linha; reancore se o
  símbolo andar mais de 10 linhas.
- `commands/sdd-plan.md` (I4 edita `:49–54`): itens em `:56`, `:75`, `:89`, `:104`, `:119`, `:132`, `:150`,
  `:201` (e `:30`, acima, intocado).

## Arquitetura da mudança

### O lugar: um diretório do kit dentro do `git-common-dir`

- `<common>` = `git -C <raiz> rev-parse --path-format=absolute --git-common-dir`, com a mesma prova de resposta
  absoluta de uma linha do `ledger_repo_root`. No checkout principal e em toda worktree ligada é o mesmo
  diretório.
- Dentro dele, `sdd-mutation/`:
  - `sdd-mutation/stamps/<chave>` — um arquivo por chave medida verde; **a primeira linha é a própria chave**, as
    seguintes a procedência (`measured: <ISO>`, `root: <raiz>`, a linha `score: …`), para gente e para a linha do
    pulo;
  - `sdd-mutation/killers.tsv` — o mapa, no formato de hoje (`slug TAB step TAB secs`).
- Raiz sem git (kit instalado como cópia): sem carimbo, como hoje (`not-git` só avisa); o mapa fica no
  `.sdd/cache/mutation-killers.tsv` da raiz, como hoje.

### O carimbo como conjunto (`bin/sdd`)

- **Uma definição do lugar e uma da pergunta**, lidas pelos três leitores (regra do `CLAUDE.md`: enum lido em
  mais de um ponto vira uma definição por programa): `mutation_stamp_dir <raiz>` imprime
  `<common>/sdd-mutation/stamps` (ou nada e rc 1 sem git), e `mutation_stamp_valid <raiz> <chave>` responde rc 0
  só com chave não vazia **e** `stamps/<chave>` legível **e** primeira linha igual à chave. `gate_PR`, a linha 6
  do `--release` e o pulo do `cmd_health` chamam `mutation_stamp_valid`; nenhum lê mais `.sdd/logs/mutation-stamp`
  (decisão 4) e o `MUTATION_STAMP_REL` sai.
- **Gravar** (verificação 2c): só com `catalogue_green=1` (suíte verde **e** score limpo, como hoje), chave não
  vazia e igual à de antes — `mkdir -p` + tmp + `mv` para `stamps/<chave>`. O `ok` diz onde gravou.
- **Apagar** (decisão 3): só quando o catálogo rodou e o **score** fala contra a chave — o ramo do censo
  (`total != defined` ou abaixo do piso), o do gap e o do sobrevivente (`caught != total`, que é onde chega o
  TIMED-OUT). Suíte vermelha com score limpo, score ausente (controle vermelho), score que não parseia e janela
  não gravam nem apagam nada. Quem apaga apaga `stamps/<stamp_key_before>`.
- As frases do `gate_PR` e o `GATE_PR_STAMP_*` não mudam: a recusa continua nomeando `sdd health`.

### O pulo (`cmd_health`)

- Opções: `--release`, `--with-mutation` (sinônimo do padrão, decisão 2) e `--full` (novo). `--full` junto
  de `--release` morre pelo nome (`die "sdd health: --full measures the catalogue, and --release never runs the
  suite — pick one"`). O `die` de opção desconhecida passa a listar as três. A ajuda (`bin/sdd:11913–11915`)
  ganha a linha do `[--full]`.
- Sem `--full`, com `stamp_key_before` não vazia e `mutation_stamp_valid "$kit" "$stamp_key_before"`: a suíte roda
  **sem** `--with-mutation`. Escreva a chamada uma vez só, com o argumento numa variável/array
  (`tests/run-all.sh ${suite_flag:+"$suite_flag"} 2>&1` ou equivalente), e re-ancore o
  `mut_HEALTH_suite_without_mutation` nessa grafia, endereçado a `/^cmd_health() {/,/^}/`.
- No pulo a verificação 1 diz `suite green` ou `suite red (rc N) — run tests/run-all.sh to see it` (o comando que
  reproduz o que rodou), com as linhas FAIL e a cauda; a verificação 2 vira **uma** linha `ok` com
  `catalogue skipped`, a procedência da chave e `./bin/sdd health --full` (a M1 lê `--full` nessa linha); a 2c não
  grava nem apaga, mas a janela (chave depois ≠ antes) continua `health_bad`; 2b, 3 (a contagem do `TODO.md`, que
  a suíte rápida imprime: `ok    61 finding(s)…`), 4–8 e a catraca correm como hoje.

### O mapa (`tests/check-mutation.sh`)

- `KILLERS_FILE` passa a ser `<common>/sdd-mutation/killers.tsv` quando `$ROOT` é checkout git, senão o
  `$ROOT/.sdd/cache/mutation-killers.tsv` de hoje; `LEGACY_KILLERS_FILE="$ROOT/.sdd/cache/mutation-killers.tsv"`.
  A resolução é uma função pura de `<raiz>` (`killers_paths <raiz>` ou equivalente), para o selftest medir.
- **Leitura (decisão 4):** o compartilhado primeiro, depois o legado **só para os slugs que o compartilhado não
  conhece** (um modo "não sobrescreve" no `load_killer_map`, ou uma segunda função). Vale nos três leitores; o
  `SDD_KILLERS_FILE` segue sobrepondo só no `--touched`.
- **Gravação:** só no compartilhado, por união lida **na hora de gravar**: os slugs do `CATALOG` desta rodada
  levam a linha desta rodada (e saem se não têm matador, como hoje); todo slug fora do `CATALOG` mantém a linha
  que o compartilhado — ou, na falta, o legado — tinha. `mkdir -p` + tmp + `mv`, como hoje. O legado nunca é
  regravado nem apagado.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. Todo incremento termina com
`tests/run-all.sh` verde (em segundo plano, ~11 min) e `bash tests/check-mutation.sh --anchors` verde, e cada
regra nova do `bin/sdd` ganha um mutante no catálogo (`mut_<FASE>_<nome>() { sed -i '/^<função>() {/,/^}/ s|…|…|' "$1"; }`,
listado no `CATALOG`, com o comentário dizendo qual asserção o mata) — o `--anchors` prova que ele se aplica; quem
prova que ele morre é o `--only <slug> <sensor>` (segundos contra um sensor: `bash tests/check-mutation.sh --only
<slug> tests/check-gates.sh` → exit 0 = pego). Rode o `--only` de cada mutante novo antes do commit, e registre o
resultado numa nota do `checkpoint-notas.md`.

### I1 — o carimbo mora no `git-common-dir`

**O quê:** os helpers `mutation_stamp_dir` e `mutation_stamp_valid` (Arquitetura); o `cmd_health` grava
`stamps/<chave>` em vez de `.sdd/logs/mutation-stamp`, e onde hoje faz `rm -f "$stamp_path"` apaga
`stamps/<chave>` (neste incremento a regra de apagar **não muda** — a decisão 3 é do I2); o `gate_PR`
(`:2672–2706`) e a linha 6 do `--release` (`:7248–7252`) perguntam a `mutation_stamp_valid`; o `MUTATION_STAMP_REL`
sai.
**Onde:** `bin/sdd`; `tests/check-gates.sh` (as 11 linhas do arquivo velho viram o lugar novo — escreva um helper
de fixture, p.ex. `fixture_stamps() { printf '%s/sdd-mutation/stamps' "$(git -C "$1" rev-parse --path-format=absolute --git-common-dir)"; }`,
e use-o no `rm`, no `[ -f ]` e no `tree_stamped`, que passa a perguntar "o diretório tem algum arquivo"); o
mundo novo; `tests/check-hat.sh` (a asserção da linha 6); `tests/check-health.sh` só se alguma asserção ler o
arquivo velho (o mundo sem git `:1003` lê a saída, não o arquivo); `tests/check-mutation.sh` (mutantes novos e
âncoras dos antigos que citem `MUTATION_STAMP_REL` ou o `cat` do carimbo).
**Como (TDD):** primeiro o mundo novo do `check-gates.sh`, logo depois do mundo 13 e antes do bloco das duas
árvores: `git -C "$FIX" worktree add -q "$SDD_STATE_FIX/kit-wt"` (o `$FIX` está commitado nesse ponto; confira
com `git -C "$FIX" status --porcelain` vazio antes), apaga o lugar, `i4_verdict 0 "$I4_SCORE_GREEN"`, roda o
health **na worktree** (`( cd "$SDD_STATE_FIX/kit-wt" && HOME="$i4_home" NO_COLOR=1 ./bin/sdd health >/dev/null 2>&1 ) || true`)
e pergunta a fase **no `$FIX`** → `DONE`; depois apaga o lugar, escreve **só** o arquivo velho
`$FIX/.sdd/logs/mutation-stamp` com a chave certa (`git ls-files … | md5sum`, a receita de
`docs/failure-modes.md:1085–1086`) e pergunta a fase → `PR`; remove a worktree (`git -C "$FIX" worktree remove --force …`).
Uma asserção só: `stamp: gate_PR reads the key a linked worktree stamped, and the old .sdd/logs/mutation-stamp alone opens nothing`
(`DONE|PR`). No HEAD ela não existe (Check → `0`); com o lugar novo e o leitor velho ela fica `PR|DONE`.
Depois o `bin/sdd`, depois a migração das 11 linhas, depois a linha 6 do `--release` no `check-hat.sh`
(`release: line 6 reads the key from the git common dir — red before the key is stored, green after`, na
caixa do `release_probes`, gravando `stamps/<chave>` à mão com a mesma receita).
**Mutantes novos:** `mut_PR_stamp_dir_per_worktree` (no `mutation_stamp_dir`, `--git-common-dir` → `--absolute-git-dir`:
a worktree grava no git dir dela e o `$FIX` não vê — o mundo novo morre com `PR|PR`);
`mut_PR_stamp_valid_any_key` (o `mutation_stamp_valid` aceita qualquer arquivo do diretório: o mundo 4 —
`tests/` mudou — passa a dar `DONE`); `mut_HEALTH_release_line6_blind` (a linha 6 sempre `ok`: a asserção nova
do `check-hat.sh` morre). Mantenha o `mut_PR_stamp_blind` e os `mut_PR_stamp_key_*` aplicando.
**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp: gate_PR reads the key a linked worktree stamped' <<< "$o"` → `1`
(no HEAD: `0`).
**Sensor durável:** a asserção nova do `check-gates.sh`, a da linha 6 no `check-hat.sh` e os três mutantes.
**Âncoras:** os itens de `bin/sdd` empurrados (lista acima), no commit do I1; `CAPTURE_FLOOR` se o diff mexer nas
capturas da região do health (a do `cat` do carimbo na linha 6 e na 2c some ou muda).
**Reversível por:** `git revert` do commit; nenhum dado de usuário muda de lugar além do carimbo, que se refaz
com um `./bin/sdd health`.

### I2 — o pulo, o `--full` e a regra de apagar

**O quê:** o `--full`; o pulo (Arquitetura § O pulo); a regra da decisão 3 na 2c (apaga só pelo score; grava só
com o catálogo todo verde; suíte vermelha, score ausente, janela: nada).
**Onde:** `bin/sdd` (`cmd_health`, a ajuda); `tests/check-health.sh`; `tests/check-gates.sh` (mundos 6 e 7);
`tests/check-mutation.sh` (mutantes, a âncora do `mut_HEALTH_suite_without_mutation`).
**Como (TDD):** primeiro, no `check-health.sh`, o `health_run` passa a apagar antes de cada rodada o lugar do
fixture (`rm -rf "$FIX/.git/sdd-mutation/stamps"`) e o `$FIX/tests/stub-argv.txt` — assim todo mundo existente
continua sendo "primeira medida" e o `surface:` do argv continua lendo o catálogo —, e um `health_run_keep` (ou
um parâmetro) que **não** apaga, só para os mundos do pulo. Então as cinco asserções, prefixo `skip:` (no HEAD,
0; a Check espera 5):
1. `skip: a key measured green runs the suite without the catalogue, and the line names --full` — `green_world`,
   `health_run` (mede e grava), `health_run_keep`: argv sem `--with-mutation` (o arquivo **existe**: a suíte foi
   chamada), rc 0, uma linha com `catalogue skipped` e `--full`.
2. `skip: --full runs the catalogue over a key already measured, and --full beside --release is refused` —
   depois de 1, `--full` com o lugar guardado: argv com `--with-mutation`; e `health --full --release` → rc ≠ 0 com
   a frase da recusa.
3. `skip: a red suite over a measured key fails health and keeps the key` — chave guardada, `write_stub_suite
   with-count with-score 1`: argv sem o flag, rc 1, `suite red`, e `stamps/<chave>` ainda lá. ⚠️ A chave é do
   **conteúdo**: reescrever `tests/run-all.sh` com outro rc muda a chave (é arquivo rastreado). Grave a chave
   com o stub vermelho no lugar (ou escreva o arquivo `stamps/<chave>` à mão com a chave do estado vermelho),
   senão o mundo não pula.
4. `skip: only the catalogue's verdict takes a key away — a survivor does, a red suite over a clean score does not` —
   `--full` com score de sobrevivente → o arquivo some; `--full` com rc 1 e score limpo → o arquivo fica.
5. `skip: a linked worktree skips over the key its main checkout measured` — `green_world` com o stub **igual ao
   commitado** (o fixture commita a versão `with-count`; confira `git -C "$FIX" status --porcelain -- tests/run-all.sh`
   vazio), `health_run` no `$FIX`, `git -C "$FIX" worktree add -q <wt>`, health na worktree
   (`( cd <wt> && HOME="$FIX/home" NO_COLOR=1 ./bin/sdd health 2>&1 )`): o stub da worktree grava o argv em
   `$FIX/tests/stub-argv.txt` (caminho absoluto embutido) — argv sem o flag e a linha `catalogue skipped`. A
   worktree não tem a baseline (não rastreada), então o rc não entra nesta asserção. Remova a worktree no fim.
Depois o `bin/sdd`. No `check-gates.sh`: o mundo 6 se inverte — `i4_verdict 1 "$I4_SCORE_GREEN"` sobre a chave
gravada no mundo 5 agora **pula** e mantém a chave: `i4_phase "a red suite over a measured key leaves the stamp standing — only the catalogue's verdict takes it away" "DONE"`;
o `i4_health` ganha um argumento opcional repassado ao health, e o mundo 7 usa `--full` para o sobrevivente
(`i4_verdict 0 "$I4_SCORE_SURVIVOR"; i4_health --full` → `PR`); o "green again" do 7 vira desnecessário — releia o
comentário e reescreva-o pela regra nova, sem deixar frase que diga "a red suite takes the stamp away".
**Mutantes novos:** `mut_HEALTH_skip_never` (o predicado do pulo vira `false`: asserções 1 e 5 morrem);
`mut_HEALTH_full_ignored` (o `--full` deixa de forçar: a 2); `mut_HEALTH_skip_red_drops_key` e
`mut_HEALTH_red_suite_drops_key` (suíte vermelha apaga: a 3 e a 4); `mut_HEALTH_survivor_keeps_key` (o ramo do
sobrevivente não apaga: a 4); `mut_HEALTH_skip_without_suite` (o pulo não roda a suíte: a 3, que espera rc 1);
`mut_HEALTH_full_with_release_accepted` (a recusa some: a 2).
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    skip: ' <<< "$o"` → `5` (no HEAD: `0`).
**Sensor durável:** as cinco asserções `skip:`, os mundos 6 e 7 reescritos e os sete mutantes.
**Âncoras:** os itens de `bin/sdd` de `7311` para baixo; o `CAPTURE_FLOOR` (toda captura nova guardada, o piso
no mesmo commit, com a linha do registro); o limite declarado de `check-health.sh:40–44` deixa de ser limite
(o arquivo é apagado) — reescreva o parágrafo.
**Reversível por:** `git revert`; o comportamento volta a ser "o catálogo sempre".

### I3 — o mapa no `git-common-dir`, o legado como semente

**O quê:** Arquitetura § O mapa.
**Onde:** `tests/check-mutation.sh` (`KILLERS_FILE` `:7550` e o comentário `:7537–7549`, os três leitores, o
escritor `:7976–7991`, o `killers_selftest` novo ao lado de `controls_selftest`/`touched_selftest`).
**Como (TDD):** o selftest primeiro, num repositório de fixture em `mktemp -d` com uma worktree ligada (o
`touched_selftest` `:358` já monta um repositório de fixture: copie a forma), medindo as funções puras:
(a) a resolução do caminho na raiz e na worktree dá o **mesmo** arquivo, dentro do `git-common-dir`, e numa
pasta sem git dá o `.sdd/cache/` dela; (b) a leitura: compartilhado `{A step1 10}`, legado `{A step9 99, B step2 20}`
→ `KILLER[A]=step1`, `KILLER[B]=step2`; (c) a gravação com `CATALOG=(A C)`, rodada que matou `C` com `step3`, `A` sem
matador, mapa anterior com `A` e `Z` → o arquivo tem `C` e `Z`, não `A`. Uma linha só: `pass "killers: the map
lives in the git common dir a linked worktree shares, the .sdd/cache map seeds it and the shared line wins, and a
write keeps the slugs outside this catalogue (selftest)"`, e `exit 1` com frase própria no vermelho.
O harness não é alcançado pelo catálogo (ele mora fora do `bin/sdd`), então quem o prova é o selftest com o
caso sabotado: antes do commit, sabote cada uma das três partes à mão numa cópia e veja o selftest vermelho
(registre numa nota).
**Check:** `o=$(bash tests/check-mutation.sh --anchors 2>&1); grep -c '^  ok    killers: ' <<< "$o"` → `1` (no HEAD: `0`).
**Sensor durável:** o `killers_selftest`, que roda em todo `--anchors` da suíte rápida.
**Âncoras:** o item `TODO.md:502` (`tests/check-mutation.sh:7550` (`KILLERS_FILE`)) se o símbolo andar mais de 10
linhas.
**Reversível por:** `git revert`; o mapa legado não é tocado, então nada se perde.

### I4 — o `/sdd-plan` para de mandar trazer mapa e carimbo de volta

**O quê:** `commands/sdd-plan.md:49–54` deixa de pedir a volta e diz que o mapa e o carimbo moram no
`git-common-dir` que a worktree divide com este checkout, então o `git worktree remove` os mantém; a cópia do
mapa **para dentro** da worktree também deixa de ser necessária. A probe `command_worktree_return_probes`
(`tests/check-hat.sh:578–593`) passa a segurar a frase nova e a recusar a velha (presença de
`outlive \`git worktree remove\`` e ausência de `its killer map comes back to this checkout`).
**Onde:** `commands/sdd-plan.md`, `tests/check-hat.sh`.
**Como (TDD):** a probe primeiro, com o nome novo `command: /sdd-plan says the killer map and the stamp outlive git worktree remove`
— vermelha sobre o texto de hoje —, depois a frase.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan says the killer map and the stamp outlive git worktree remove' <<< "$o"` → `1`
(no HEAD: `0`).
**Sensor durável:** a probe reescrita do `check-hat.sh`.
**Âncoras:** os itens de `commands/sdd-plan.md` de `:56` para baixo, se a edição mudar o número de linhas em mais
de 10 (o mais provável é não mudar).
**Reversível por:** `git revert`.

### I5 — o fecho

**O quê:** `RESOLVED by <hash>` nos dois achados que a missão fecha — o de `TODO.md:26` com o hash do commit do
I2 (o pulo) e o de `TODO.md:502` com o do I3 (o mapa) —, no fim da última linha do corpo (forma do
`templates/todo.pt-BR.md:43–46`; sem espaço nos 120 caracteres, encurte o corpo); as âncoras medidas de novo. Os
itens **não** saem do arquivo nem a catraca anda: saem no chore pós-merge, quando o hash estiver na `main`.
**Onde:** `TODO.md`.
**Como:** a skill `todo-to-github-issues` primeiro (Contexto § Onde e como), depois a edição, `bash tests/check-todo.sh`
e o `--audit`.
**Check:** `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f]…/{n++} END{print n+0}' TODO.md); b=$(bash tests/check-todo.sh --anchors TODO.md >/dev/null 2>&1; echo $?); echo "$a $b"`
→ `2 0` (no HEAD: `0 0`; a célula exata está no `checkpoint.md`).
**Sensor durável:** o `check-todo.sh` da suíte (forma e âncoras); o `RESOLVED by` é o registro que o ciclo de vida lê.
**Reversível por:** `git revert`.

Depois do I5, o `sdd-executor` escreve o `20-handoff-exec.md` (o `gate_EXEC` o exige, `bin/sdd:1522`).

### Para a fase DOCS (não são incrementos)

O que cita o lugar velho ou a volta manual, medido por `grep -rlE 'mutation-stamp|mutation-killers'` fora de
`docs/handoffs/`: `README.md:173–182`, `CLAUDE.md:299` e `:311` (o mapa em `.sdd/cache/`), `CONTEXT.md:32` (verbete
"Carimbo de mutação"), `docs/pipeline.md:528–545`, `docs/failure-modes.md` (a receita da chave em `:1085–1086` compara com
`.sdd/logs/mutation-stamp`; a seção `:1104` "`sdd health` in the main checkout is slow again after a kit mission"
perde o motivo), `docs/qa/journeys/J-health-verdict.md` (o fluxo ganha o ramo do pulo e do `--full`) e
`J-certify-mission-close.md`, a anatomia (`.claude/rules/anatomia-do-agente.md` §6, se citar a cópia do mapa) e a
entrada do `KAIZEN_LOG.md` (K8: antes/depois — 10 h 58 → o pulo; a volta manual → nenhuma). As ADRs 0004 e 0016 já
ganharam o "Amended by: 0021" no PLAN.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Um mundo existente do `check-health.sh`/`check-gates.sh` passa a pular o catálogo sem querer (mesma chave de uma rodada anterior) e fica verde/vermelho pelo motivo errado | alta | o `health_run` e o `tree_health` apagam o lugar antes de cada rodada; só os mundos do pulo o mantêm; o mundo 6/7 do `check-gates.sh` reescritos de propósito |
| O `stub-argv.txt` herdado de um mundo anterior responde por um mundo que não chamou a suíte | média | apagado antes de cada `health_run` (I2); a asserção 1 exige o arquivo presente |
| Uma captura nova sem guarda mata o `sdd health` sob `set -e` | média | o censo `guard:` do `check-health.sh` e o `CAPTURE_FLOOR` exato |
| O `git rev-parse --git-common-dir` responde relativo (`.git`) ou ecoa o flag num git antigo | baixa | a prova do `ledger_repo_root` (`bin/sdd:3651`): só resposta absoluta de uma linha vale |
| A âncora sem endereço do `mut_HEALTH_suite_without_mutation` quebra | alta | re-ancorar no I2 e endereçar ao `cmd_health`; o `--anchors` da suíte acusa |
| O passo `sdd health discriminates` passa do prazo de 180 s com os mundos novos | baixa | ~40 s hoje e ~1 s por `health_run`; meça o `check-health.sh` sozinho no I2 |
| Duas rodadas do catálogo gravam o mapa no mesmo instante | baixa | declarado (ADR 0021): perde-se tempo, nunca veredito |
| A chave não vê troca de máquina ou de ferramenta | baixa | declarado; `--full` é o remédio, como o `gate_PR` sempre foi |

## Verificação end-to-end

- Os cinco Checks do `checkpoint.md` verdes, `tests/run-all.sh` verde (rc 0, 0 FAIL), `bash tests/check-mutation.sh
  --anchors` com os mutantes novos aplicando, `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`, catraca
  `todo-findings 61`.
- Uma rodada à mão do pulo, sem catálogo, num fixture: `cd "$(mktemp -d)"`, `git clone -q /home/pc_admin/repos/sdd_agents-health-pula-catalogo k && cd k`,
  troque `tests/run-all.sh` por um stub que imprime a linha `score:` certa e `  ok    61 finding(s)…` (como o
  `write_stub_suite`), commite, `./bin/sdd health` duas vezes: a primeira grava `.git/sdd-mutation/stamps/<chave>`,
  a segunda imprime `catalogue skipped … --full` e não passa `--with-mutation`. Isso é M1 fora do sensor; a M3 de
  verdade é do humano, depois do merge.
- Depois do carimbo do operador (pendência), `ls /home/pc_admin/repos/sdd_agents/.git/sdd-mutation/stamps/` mostra a
  chave da branch, e `./bin/sdd health --release` na worktree dá a linha 6 verde.

## Teste de autocontenção

Feito pelo planner contra o I1, lendo só os três arquivos: o caminho da worktree e a regra do `cd`; a branch; os
números de linha de todo símbolo que o I1 lê ou edita (`MUTATION_STAMP_REL :2451`, `gate_PR :2672–2706`, a linha 6
`:7248–7252`, a 2c `:7467–7509`, as 11 linhas do `check-gates.sh`, `i4_health :3243`, `release_probes :758`); a grafia
do `git-common-dir` e a prova dela (`:3651`); a receita da chave para o mundo do arquivo velho
(`docs/failure-modes.md:1085–1086`); o nome exato da asserção que o Check lê; os mutantes a criar e o comando que prova cada
um (`--only <slug> <sensor>`); a lista de âncoras do `TODO.md` a reancorar e o comando; o `CAPTURE_FLOOR`; a ausência de
`shellcheck`; o tempo da suíte e o limite de 10 min do Bash em primeiro plano. Nada do I1 depende de saber o grill além
das oito decisões escritas no `00-missao.md`.
