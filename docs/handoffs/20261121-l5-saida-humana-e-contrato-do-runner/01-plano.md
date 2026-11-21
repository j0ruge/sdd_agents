---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
data: 2026-11-21
---

# Plano — L5: saída humana e contrato do runner

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-21, no commit `86e16c0`, no worktree `/home/joruge/repos/sdd_agents-l5`. **A base
vai ter andado quando você ler isto** (pendência 1 do `00-missao.md`: o L4 e o PR #460 mergeiam
antes, e a `main` entra neste branch). Todo número de linha abaixo é pista, nunca instrução: ache
cada trecho pelo `grep` do nome da função ou da frase que o incremento dá. Ao lado de cada contagem
está o comando que a mediu.

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit (`git rev-parse --git-dir --git-common-dir` →
  `/home/joruge/repos/sdd_agents/.git/worktrees/sdd_agents-l5` e `/home/joruge/repos/sdd_agents/.git`).
  O `sdd` do PATH é o do checkout principal (`/home/joruge/repos/sdd_agents`), com o runner de
  **antes** deste lote: é ele que julga os gates desta corrida. O `./bin/sdd` é o deste worktree,
  com o que você escreveu. **Nunca escreva, commite ou entre no checkout principal**: a guarda de
  kit de toda corrida da máquina compara o `HEAD` e o `git status` dele.
- Quem espelha um chapéu é **`./bin/sdd install --force`**, com o `./`. `.claude/agents/` é
  rastreado aqui, então o espelho entra no mesmo commit do chapéu (I10, I16 e I17 editam chapéus).
  Nunca `cp`, nunca `Edit`/`Write` em `.claude/`. Confira com
  `cmp -s agents/<chapéu>.md .claude/agents/<chapéu>.md; echo $?` → `0`. Se o comando responder
  `CHECKOUT-BUSY` (rc 75), não contorne: anote o comando, o rc e a saída nas notas, marque
  `blocked` e pare.
- Config (`grep -vE '^\s*#' .sdd/config.sh`): `DEFAULT_BRANCH="main"`, `TEST_CMD="tests/run-all.sh"`,
  `HANDOFF_DIR="docs/handoffs"`, `TODO_FILE="TODO.md"`, `JIRA_ENABLED=false`, `OUTPUT_LANG="pt-BR"`,
  `ADR_CHECK="block"`, `ADR_DIR="docs/adr"`, `BUDGET_PER_PHASE_USD=40`. A linha
  `EFFORT_EXEC="${EFFORT_EXEC:-medium}"` não é sua: não mexa nela.
- **O ADR da missão já existe**: `docs/adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md`, alocado e escrito pelo planner (decisão 8). Não rode
  `sdd adr new` nesta missão. O status dele fica `proposed` até o `sdd approve`.
- **Não escreva no worktree enquanto um sensor dele roda.** O `tests/check-autonomy.sh` e o
  `tests/check-gates.sh` têm probes da guarda de kit que comparam o `git status` do kit que os
  executa, que é este worktree: um arquivo gravado no meio da suíte já deu quatro `FAIL` falsos
  (L2, r3). Rode o sensor, espere acabar, e só então edite.

**A suíte, os sensores e os mutantes**

- `TEST_CMD` é `tests/run-all.sh` (8 a 15 min). A chamada `Bash` do harness para de esperar aos
  120 s por padrão e 600 s no máximo: rode a suíte com o `timeout` da chamada em 600000 ms, ou
  destacada com a saída num arquivo. Use o sensor sozinho para o Red e o Green; a suíte inteira
  fica para antes do commit.
- Tempo de cada sensor sozinho em `86e16c0`, com as suítes do L4 rodando na máquina (medido com
  `s=$(date +%s); bash tests/<sensor>.sh; echo $(( $(date +%s) - s ))`): `check-templates.sh` 1 s,
  `check-hat.sh` 5 s, `check-adr.sh` 11 s, `check-dry-run.sh` 12 s, `check-kaizen.sh` 24 s,
  `check-coordination.sh` 35 s, `check-worker.sh` 56 s, `check-preflight.sh` 58 s,
  `check-gates.sh` 155 s. Todos rc 0. O `check-autonomy.sh` não foi medido e nenhum Check o lê.
- Todo sensor imprime `  ok    <frase>` na stdout e `  FAIL  <frase>` na stderr. Os ajudantes de
  cada um (`grep -n '^pass()\|^fail()\|^assert_[a-z_]*()\|^check()' tests/<sensor>.sh`):
  - `tests/check-adr.sh`: `pass` (`:227`), `fail` (`:230`), `fixture <nome> [linhas de config]`
    (`:246`, um repo git próprio com `sdd install`), `mission` (`:275`), `adr_file` (`:291`),
    `run_adr <dir> <args>` (`:307`, publica `ADR_OUT` e `ADR_RC`, com stderr junto),
    `assert_adr <desc> <dir> <rc> <regex> <args>` (`:317`). Os probes do alocador começam em
    `grep -n 'R17..R22: the allocator' tests/check-adr.sh` → `:674`. `PROBE_FLOOR=79` (`:225`) é
    piso, e hoje o sensor imprime 81 linhas `  ok    `: não precisa subir.
  - `tests/check-preflight.sh`: `pass` (`:41`), `fail "<frase>" "<esperado>" "<obtido>"` (`:44`),
    `assert_has` (`:48`), `assert_lacks` (`:54`), `assert_eq` (`:63`). O `claude` é um stub. Mundos
    que você reusa: `seed_lang <idioma>` (`:2122`, o `install` sobre `OUTPUT_LANG`); o bloco do
    `link-agents` (`grep -n 'link-agents' tests/check-preflight.sh` → `:2191`, `:2565` a `:2607`);
    `kp_world` (uma **cópia do kit** num diretório próprio, rodada pelo `bin/sdd` da cópia;
    `grep -n 'kp_world' tests/check-preflight.sh`); os probes de skill trocam a home com
    `HOME="$1" … "$SDD" preflight` (`:1515`), que é a forma de dar ao preflight um
    `~/.claude/commands` de fixture.
  - `tests/check-hat.sh`: `pass`/`fail` levam **um** argumento (`:45`, `:48`). As famílias são
    funções `*_probes()` chamadas numa lista no fim do arquivo (`:1668` a `:1682`); família nova
    entra nessa lista. `help_probes` (`:1197`) roda o `bin/sdd help` de verdade e lê o bloco de uma
    entrada com `awk`: é o molde do I3.
  - `tests/check-gates.sh`: `pass` (`:44`), `fail` (`:47`), `assert_eq` (`:53`), `assert_phase`,
    `assert_why`, `assert_why_absent`. Seções que você reusa
    (`grep -n '^echo "== ' tests/check-gates.sh`): `base branch warning` (`:4749`),
    `the declared mission branch` (`:5453`), `sdd close: the artifact decides` (`:6681`, com o stub
    do `gh` em `$FIX/.stub/gh`, `:3984` e `:4008`), `sdd status --no-gates` (`:7180`). O par do app
    morto usa `APP_URL="http://example.invalid"` ao lado de um `E2E_CMD` vermelho
    (`grep -n 'example.invalid' tests/check-gates.sh`).
  - `tests/check-kaizen.sh`: `pass` (`:39`), `fail` (`:42`), `assert_eq` (`:44`). Seções:
    `reminder: pipeline complete points at the judge` (`:1209`), `reminder: outside the kit it tells
    the truth about the judge` (`:1277`), `the checkout the targets run is refused to the judge`
    (`:1903`).
  - `tests/check-coordination.sh`: os probes são Python embutido; a linha sai como
    `  ok    <nome>: <detalhe>` (`tail -3` da saída: `  ok    orphan completion recovers:
    owner/escaped`). Os que leem o `CHECKOUT-BUSY` estão em
    `grep -n 'CHECKOUT-BUSY' tests/check-coordination.sh` → `:270`, `:591`, `:689`, `:796`.
  - `tests/check-worker.sh`: `pass`/`fail` (`:542`, `:543`), a frase com um prefixo de família
    (`  ok    committed: a mission folder with a change not committed, staged, untracked or ignored
    fails review`). `PROBE_FLOOR=40` (`:540`), 71 linhas `  ok    ` hoje.
  - `tests/check-templates.sh`: `check <arquivo> <regex> <descrição>` (`:77`) imprime
    `  ok    <nome do arquivo>: <descrição>`, com o nome **sem** `templates/` (`  ok    pr-body.md:
    section 'Plano'`, `  ok    todo.md: the kit token for a finding fixed by a commit`). É o único
    sensor em que um literal em português pode morar. `REVIEW_FLOOR=28` (`:759`) é piso.
  - `tests/check-todo.sh --selftest`: uma linha `  ok    rule: <texto> (N probe(s))` por regra,
    entre `rule_begin` e `rule_end <piso> <texto>` (`:873`, `:874`); `RULES_FLOOR=14` (`:872`) conta
    as regras reportadas e **sobe um** com a regra nova do I10 (o L4 também o sobe: depois do merge
    da `main`, o valor é o que estiver lá mais um). Os modos são um `case` no fim do arquivo
    (`--selftest` `:2892`, `--check` `:2895`, `--count` `:2912`, `--anchors` `:2913`).
- **Toda frase que uma asserção lê cabe numa linha física.** As 46 frases dos incrementos abaixo
  são **exatas**: os Checks do `checkpoint.md` as leem byte a byte. Não as reescreva, nem para
  corrigir estilo.
- **Mutante novo são duas coisas** em `tests/check-mutation.sh` (`grep -c '^mut_' tests/check-mutation.sh`
  → `954` em `86e16c0`): a função `mut_<slug>() { … }`, que aplica um `sed -i` em `"$1"` (a cópia
  do `bin/sdd`), endereçado à função alvo (`sed -i '/^cmd_x() {/,/^}/ s|…|…|' "$1"`), e o `<slug>`
  na lista do catálogo (ache um vizinho com `grep -n '^  ADR_alloc_no_excl$' tests/check-mutation.sh`).
  O irmão do `bin/sdd` se alcança por `"${1%/*}/sdd-worker"` ou `"${1%/*}/sdd-coordination.py"`
  (`grep -n 'sdd-coordination.py"$' tests/check-mutation.sh` → `:6653` e seguintes). Prove cada um
  antes do commit: `bash tests/check-mutation.sh --only <slug> tests/<sensor>.sh` → rc 0 (pego).
  **Mutante que o `--only` não pega significa que a asserção não mede**: conserte a asserção, nunca
  o mutante. O `--anchors` (`bash tests/check-mutation.sh --anchors`, segundos) roda na suíte e
  reprova o mutante que não se aplica. O catálogo inteiro (`./bin/sdd health`) **não roda** nesta
  missão.
- **A sandbox de mutação copia o kit sem git.** Probe que precisa do git monta o seu próprio
  repositório de fixture (o `fixture` do `check-adr.sh`, o `kp_world` do `check-preflight.sh`),
  nunca o git do kit real.
- **O catálogo não alcança três coisas deste lote**: o `tests/check-todo.sh` (I10), os templates e
  os chapéus (I10, I16, I17). No I10 a prova da regra nova é a **sabotagem à mão**, anotada nas
  notas: degrade a regra numa cópia do sensor fora do worktree, rode o selftest da cópia e exija
  vermelho; o probe prova primeiro que sabotou o que dizia sabotar. O I16 e o I17 são prosa: a
  régua A do dono dispensa a passada de sabotagem, e o I17 leva um controle negativo (a segunda
  frase dele).
- Antes de cada commit em `bin/` ou `tests/`: `bash -n bin/sdd`, `shellcheck -S warning` nos
  arquivos tocados (`shellcheck --version` → `0.10.0`; a superfície sai limpa em `86e16c0`:
  `shellcheck -S warning bin/sdd bin/sdd-worker bin/sdd-link-agents tests/*.sh` → rc 0) e
  `bash tests/check-lang.sh` (a superfície do kit é inglês).
- **Nenhum sensor novo nasce neste lote.** Não mexa em `LINT_FLOOR` (`tests/run-all.sh:261`, `22`),
  no piso do `check-pipefail.sh`, no `CALIBRATE_FLOOR` (`tests/check-checkpoint.sh:1539`, `17`) nem
  no `GITENV_FLOOR` (`tests/check-health.sh:1950`, `18`).

**Armadilhas do `bin/sdd` que este lote pisa**

- O arquivo roda sob `set -euo pipefail`: `x="$(cmd)"` mata o processo na atribuição quando `cmd`
  devolve não-zero. Toda captura nova leva `|| true`, `|| rc=$?` ou `if x="$(…)"; then`. O
  `git for-each-ref`, o `git ls-tree`, o `git worktree list`, o `git merge-base --is-ancestor`, o
  `git grep` (rc 1 = nada achado) e o `gh` deste lote são todos desse tipo.
- Função lida como `x="$(f)"` roda num subshell: atribuição a global dentro dela morre. Função que
  **publica** global é **chamada**, nunca substituída (é o caso do `adr_next_id` novo, no I1). Um
  `die` dentro de `$( )` só encerra o subshell.
- `printf … | grep -q` devolve 141 sob `pipefail` quando o grep acha: use herestring.
- O `awk` é o `mawk`, orientado a byte: classe negada só com ASCII; para literal use `index()`.
- Comentário `#` dentro de um bloco continuado por `\` quebra o comando em silêncio.
- `cd` com operando relativo dentro de `$( )` leva `CDPATH=''`.
- A lista que pode ser vazia chega a um comando por `${lista[@]+"${lista[@]}"}` (bash 4.0 a 4.3).
- `ok`, `warn`, `dim`, `info`, `bad` e `die` são as vozes do runner; dentro do `cmd_preflight`,
  `_fail` soma em `fails` e `warn` não.
- Todo aviso, falha e frase de asserção é em **inglês** (superfície do kit). Os templates são
  pt-BR, fora o `templates/todo.md`, que é a variante em inglês.

**O que o gemba mediu, item a item** (as funções em `86e16c0`:
`grep -n '^<função>() *{' bin/sdd`)

- **Item 17, o alocador** — `adr_next_id` (`:9061`) faz MAX+1 sobre
  `find "$dir" -maxdepth 1 -type f -name '*.md'` e nada mais; é lido por `$( )` num sítio só
  (`grep -n 'adr_next_id "' bin/sdd` → `:9233`, dentro do `adr_new`, `:9228`). `ADR_FILE_RE` está em
  `:8698`. O custo de ler todo ref: `git for-each-ref refs/heads refs/remotes --format='%(refname)'`
  com um `git ls-tree --name-only <ref> docs/adr/` por ref → 0,44 s sobre 158 refs e 22 worktrees
  deste clone, e o maior número em qualquer ref é o `0024`. A linha da ajuda que cita a alocação:
  `grep -n 'never handed out twice' bin/sdd` → `:12678`. O `--dry-run` imprime o caminho sozinho
  numa linha da stdout (`assert_adr … '^docs/adr/0004-d\.md$' new --slug d --dry-run`,
  `tests/check-adr.sh:684`): a linha nova que nomeia a origem vai na **stderr**.
- **Item 5, o `/sdd-plan`** — `cmd_link_agents` (`:12729`) liga só `"$SDD_HOME"/agents/sdd-*.md`
  em `.claude/agents/`, tira do índice o que era rastreado, grava no `.gitignore` o marcador
  `.claude/agents/sdd-*.md` uma vez, e termina em `Next: $ /sdd-plan` (`:12788`). Ele recusa o
  próprio kit (`refusing to link the kit to itself`). `ls commands/` → `sdd-plan.md sdd-worker.md`.
  O `README.md:169` a `:174` diz que nada instala os comandos e ensina o `ln -s` à mão: a frase
  fica falsa com o I2. `bin/sdd-link-agents` termina em `exec bin/sdd link-agents "$@"`.
- **Item 14, a ajuda** — a entrada é uma linha
  (`grep -n 'sdd run <mission>  ' bin/sdd` → `:12645`), dentro do heredoc do `cmd_help` (`:12628`).
  A forma destacada já está em `docs/failure-modes.md:808` (`setsid nohup`) e em
  `commands/sdd-worker.md:163`; `grep -c 'setsid' README.md` → `0`. O log da corrida é
  `.sdd/logs/pipeline.log` (`grep -n 'PIPELINE_LOG=' bin/sdd`).
- **Item 9, o índice** — reproduzido no git 2.43.0 num repo de rascunho: com um arquivo no índice
  e um `touch` nele, `stat -c '%i %Y' .git/index` dá `29338 1795296017` antes,
  `29338 1795296017` depois de `GIT_OPTIONAL_LOCKS=0 git status --porcelain`, e
  `29341 1795296018` depois do `git status --porcelain` puro: o inode troca. Os sítios sem a
  variável: o laço do `session_leftovers` (`:8517`), em `done < <(hat_status_lines)` (`:8569`); o
  `cmd_pr_ready` do worker (`grep -n 'status --porcelain' bin/sdd-worker` → `:1349`); e os dois
  `git -C "$SDD_HOME" status --porcelain` do `autonomy_kit_stamp` (`:4533`, `:4541`). Os que já a
  têm: `grep -n 'GIT_OPTIONAL_LOCKS' bin/sdd` → `:4627`, `:4633`, `:13345`, `:13353`.
- **Item 6, o hífen** — `resolve_mission` (`:341`) casa por
  `find … -name "*${want}*"`. Reproduzido num repo de rascunho com as pastas
  `20261020-lote-de-consertos` e `20261020-narracao`: `sdd why -l` →
  `PLAN: missing 00-missao.md — …` (casou a primeira), `sdd phase -n` → `PLAN` (casou a segunda),
  `sdd run -l` → `error: unknown run option: -l`, `sdd status -l --no-gates` →
  `error: unknown status option: -l`, e `sdd close --help` → a ajuda (o `main`, `:12883`, lê
  `-h`/`--help` antes do despacho desde o PR #391). Os chamadores:
  `grep -n 'resolve_mission "' bin/sdd` → 11 linhas.
- **Item 3, o `--no-track`** — o motivo está no `cmd_kaizen` (`:12443`), em `shared_why`
  (`:12517`): `… worktree add $q_wt -b kaizen/$(date +%Y%m%d) $q_base`. As duas citações:
  `grep -n 'worktree add ../<repo>-kaizen' docs/failure-modes.md docs/pipeline.md` →
  `docs/failure-modes.md:691` e `docs/pipeline.md:1680`, esta com o `-b kaizen/<YYYYMMDD>` na
  linha seguinte. Reproduzido num clone de rascunho: `git worktree add ../k1 -b kaizen/a
  origin/main` → `git rev-parse --abbrev-ref 'kaizen/a@{u}'` → `origin/main`; com `--no-track`,
  `fatal: no upstream configured for branch 'kaizen/b'`.
- **Item 16, o `CHECKOUT-BUSY`** — a recusa sai do `bin/sdd-coordination.py:576`
  (`print(describe('CHECKOUT-BUSY', …), file=sys.stderr)`), e o `main` do `bin/sdd` devolve o rc
  sem dizer mais nada: `[ "$COORDINATION_ADMITTED" = 1 ] || return "$admission"` (`:12898`). O rc é
  75. A missão inexistente já aponta o `--no-gates` (`:355`).
- **Item 10, o app fora do ar** — o rodapé do `cmd_status` (`:8391`) está em `:8454` a `:8462`:
  `"gate_$next" || true`, depois `next phase: … — $GATE_WHY` e `run: sdd run $MISSION`. O
  `gate_QA` arma `GATE_APP_DOWN=1` em dois braços (`grep -n 'GATE_APP_DOWN=1' bin/sdd` → `:2048`,
  `:2072`) e o zera na entrada (`:1824`); o `cmd_status` **chama** o gate, então o global está
  vivo no rodapé. O remédio da escalada está em `app_down_escalation` (`:9809`).
- **Item 11, o `sdd close`** — as duas frases: `grep -n 'only the merge is left' bin/sdd` →
  `:8457` (`cmd_status`) e `:10093` (`cmd_run`). `grep -c 'sdd close' templates/pr-body.md
  agents/sdd-publisher.md` → `0` e `0`.
- **Itens 1 e 12, o `RESOLVED by`** — o ciclo de vida está em `templates/todo.pt-BR.md:40` a `:47`
  e no mesmo parágrafo do `templates/todo.md`
  (`grep -n 'merge-base --is-ancestor' templates/todo*.md`). O `agents/sdd-kaizen.md:232` a `:238`
  manda o juiz provar por `git merge-base --is-ancestor <hash> main` e diz "Proving by the hash and
  not by the PR label". Ninguém no `bin/` lê o token (`grep -c 'RESOLVED' bin/sdd bin/sdd-worker`
  → `0` e `0`). O `cmd_close` (`:13135`) lê o `pr_url` do `50-pr.md`, pergunta
  `gh pr view "$prurl" --json state --jq .state` e morre se não for `MERGED`; os três caminhos que fecham
  (`grep -n 'close_return_home "\$merge_seen"' bin/sdd` → `:13156`, sem JIRA; `:13186`, a issue já
  `Done`; `:13314`, depois da sessão que fecha a issue) chamam o `close_return_home` (`:13073`),
  que volta à base e faz o `merge --ff-only`. O `gh` acha o PR pelo hash:
  `gh pr list --search 3000409 --state merged --json number,mergeCommit` → o PR 458, merge
  `86e16c0`.
- **Item 8, o `PR #N aberto`** — nada lista hoje; o número do PR sai do `pr_url`
  (`https://github.com/<dono>/<repo>/pull/<N>`).
- **Item 13, o aviso da base** — `warn_if_on_base_branch` (`:6762`) compara só o branch atual com
  o `DEFAULT_BRANCH`; os chamadores: `grep -n '^ *warn_if_on_base_branch$' bin/sdd` → `:7501`,
  `:9638` (`cmd_approve`), `:10017` (`cmd_run`), `:10729` (`cmd_retry`), `:12527` (`cmd_kaizen`).
  `mission_branch_declared` (`:6808`) devolve vazio para o placeholder.
- **Item 15, o lembrete** — `kaizen_reminder` (`:12207`) imprime uma de duas linhas `dim`
  (`grep -n 'autonomy series:' bin/sdd` → `:12233`, `:12246`). A contagem do backlog é
  `bash tests/check-todo.sh --count <arquivo>` (→ `91` no kit hoje). `config_read_key <arquivo>
  <chave>` (`:123`) lê uma chave sem carregar a config.
- **Item 4, a semente** — o `cmd_install` (`:6487`) lê `inst_lang` (`:6603`) e escolhe a semente
  em `:6623` a `:6626`. Reproduzido: `sdd install` num repo novo → `OUTPUT_LANG=""` na config e
  `# TODO` + "Findings that **do not fit the current mission**" no arquivo; com a chave em `pt-BR`,
  o segundo `sdd install` → `ok   TODO.md already exists (preserved)`. O precedente de trocar o
  arquivo que é byte a byte uma semente antiga está logo abaixo
  (`grep -n 'The blob of the seed' bin/sdd`).
  `ls templates/todo*.md` → `templates/todo.md templates/todo.pt-BR.md`.
- **Item 2, a prosa** — o que os sensores medem hoje: a regra 2 do `tests/check-checkpoint.sh`
  (cabeçalho, `:38` a `:50`) aceita no começo do padrão a marca de aprovação de um test runner
  (`'^ *✓ '`), cobra a âncora só do grep que lê a saída mesclada, vale para toda grafia de mescla,
  e isenta o grep de contagem cujo esperado é só zeros; a regra 5 do `tests/check-todo.sh`
  (cabeçalho, `:26` a `:31` e `:44` a `:58`) isenta do teto de 120 a linha que, depois do recuo,
  carrega só a âncora, e a `RECURRED` bem formada. As cinco frases que dizem menos:
  `templates/checkpoint.md:27` a `:33`, `agents/sdd-planner.md` § 4 (`grep -n 'anchors on' agents/sdd-planner.md`),
  `templates/todo.md:26`, `templates/todo.pt-BR.md:26` e `agents/sdd-executor.md:178`
  ("none wider than 120 characters").
- **Item 7, a citação** — as citações de ADR pelo número nu, fora o `agents/sdd-kaizen.md`
  (`grep -n 'ADR 00[0-9][0-9]' templates/*.md agents/*.md commands/*.md` e tire as linhas com
  `kit`): `templates/missao.md:43`; `agents/sdd-planner.md:62`, `:74`, `:243`;
  `agents/sdd-docs.md:57`; `agents/sdd-publisher.md:37`; `agents/sdd-reviewer.md:52`, `:254`;
  `commands/sdd-plan.md:76`, `:80`; `commands/sdd-worker.md:13`. São 11. O molde é o
  `templates/todo.md:27`: `([ADR 0011 of the sdd kit](https://github.com/j0ruge/sdd_agents/blob/main/docs/adr/…))`.

**O que a skill do espelho diz** (regra do dono: consultar a `todo-to-github-issues` antes de mexer
na estrutura do `TODO.md`; lida em 2026-11-21)

- `~/.claude/skills/todo-to-github-issues/SKILL.md:78` e `:121` a `:123`: o `--fix` só apaga o item
  cujo hash já está na branch padrão, provado por `git merge-base --is-ancestor`. A skill é de
  outro repositório (`~/repos/skills`). Este lote muda os dois templates do kit e o que o
  `sdd close` lista; a skill fica mais estrita que o template até o retrofit dela (pendência 3 do
  `00-missao.md`): ela nunca apaga a mais, só deixa de apagar sob squash.
- O título do item é a chave do espelho, a âncora é medida, e o `RESOLVED by` e o teto de 8 linhas
  são o que o espelho lê. Este lote não muda nenhum dos quatro.

**O `TODO.md`**

- `bash tests/check-todo.sh --count TODO.md` → `91` em `86e16c0`. **Não toque em
  `tests/health-baseline.txt`.**
- O título de um item (o texto entre `**`) é a chave do espelho de issues: **nunca mude um título.**
  Os 17 estão na tabela do `00-missao.md`.
- A âncora de cada item é medida: `` `arquivo:linha` (`símbolo`) ``, e o símbolo tem de ocorrer no
  arquivo a até 10 linhas da linha. Antes de **todo** commit:
  `bash tests/check-todo.sh --anchors TODO.md` → `0 off target` (em `86e16c0`:
  `anchors: 91 measured, 0 off target`). Âncora que saiu do alvo se conserta no mesmo commit,
  mudando o número da linha (ou o símbolo, quando o conserto o apagou), nunca o título.
- O `bin/sdd` é o arquivo mais ancorado (`grep -c 'bin/sdd:[0-9]' TODO.md` → `56` linhas). Todo
  incremento de I1 a I15 edita o `bin/sdd`, quase sempre **acima** de âncoras de outros lotes:
  espere re-ancorar vários itens em cada commit. O I1 (perto da `:9061`), o I2 (`:12729`), o I11 e
  o I12 (`:13073`) e o I15 (`:6487`) somam mais de 10 linhas cada. Outros arquivos ancorados que o
  lote edita: `bin/sdd-worker` (7 itens; o I4 troca uma linha), `commands/sdd-worker.md` (8) e
  `commands/sdd-plan.md` (2), `agents/sdd-publisher.md` (5), `agents/sdd-docs.md` (2),
  `templates/checkpoint.md` (2) e `templates/missao.md` (1), todos no I16 ou no I17, que trocam
  texto na mesma linha; `docs/failure-modes.md` (2) e `docs/pipeline.md` (2), no I6.
- **Símbolos que o conserto pode apagar**, e o que fazer: item 7, `ADR 0018 §3` (a citação ganha
  "do kit sdd" depois: o símbolo continua, fica); item 2, `check-x.sh` (o exemplo continua: fica);
  item 11, `pipeline complete` (fica); item 16, `coordination_enter` (fica); item 9,
  `hat_status_lines` (fica). Se um símbolo sumir mesmo assim, troque-o pelo nome da função nova no
  mesmo commit.
- `RESOLVED by <hash>` vai no fim da última linha do corpo, **antes** do `— descoberto por` (ou do
  `Fonte:`), nunca numa linha própria, nunca na linha `RECURRED`; nenhum item passa de 8 linhas
  (`bash tests/check-todo.sh --check TODO.md` → rc 0). É o I18 que as escreve.
- Achado fora de escopo que você encontrar vira item novo no `TODO.md` (formato em
  `templates/todo.pt-BR.md`), ou entrada na linha `RECURRED` de um item aberto equivalente.

**Onde o L5 toca os mesmos arquivos que o L4 e o PR #460** (os dois mergeiam antes; pendência 1)

- O L4 (`20261121-l4-preflight-health-e-sensores`, plano em
  `/home/joruge/repos/sdd_agents-l4/docs/handoffs/20261121-l4-preflight-health-e-sensores/01-plano.md`,
  só leitura): o I5 dele mexe no braço `already exists (preserved)` do `cmd_install` e põe o
  preâmbulo do `TODO_FILE` no `cmd_preflight`, os mesmos trechos do I15 daqui; o I4 dele põe a
  forma do `TODO_FILE` no preflight; o I6 e o I8 dele mexem no lançamento do `cmd_run`, perto do
  aviso do I13 daqui; o I12 dele acrescenta uma regra ao `tests/check-todo.sh` e sobe o
  `RULES_FLOOR`, como o I10 daqui; e ele acrescenta mutantes à lista do `tests/check-mutation.sh`.
  **Se o `todo_preamble_verdict` do L4 já existir quando o I15 começar**, o aviso do I15 no
  preflight fica ao lado do dele, e as duas mensagens não se repetem: a semente intocada de outro
  idioma é dita pelo I15, e o I5 do L4 cala para ela (escreva o probe desse mundo).
- O PR #460 (`chore/l3-pos-merge`): apaga do `TODO.md` os 13 itens que o L3 fechou e acrescenta
  três (`bash tests/check-todo.sh --count` passa a `81`), e mexe em `bin/sdd`, `commands/sdd-plan.md`,
  `docs/failure-modes.md`, `tests/check-gates.sh` e `KAIZEN_LOG.md`. Nenhum dos 17 itens deste lote
  sai nele.

**Para a fase DOCS**

- A entrada do `KAIZEN_LOG.md` cita o id inteiro `20261121-l5-saida-humana-e-contrato-do-runner`
  sob um título `## ` novo, com o antes e o depois de cada item (o valor de antes e o de depois de
  cada Check), as 46 asserções e os 28 mutantes novos, a contagem de `^mut_` antes (`954` em
  `86e16c0`; meça de novo no merge-base) e depois, e a linha do L5 na tabela de custo e tempo da
  campanha, ao lado dos L1 a L4 (as linhas `"event":"session"` com `"phase":"EXEC"` desta missão
  em `~/.sdd/autonomy-log.jsonl`; some com `jq`, ou com `LC_ALL=C awk`).
- `README.md`, `docs/pipeline.md`, `docs/plan-only.md`, `docs/failure-modes.md` e
  `config/schema.md`: o que cada incremento desatualiza e não consertou no próprio commit.
- As linhas `⛔` da pendência 4 do `00-missao.md` (o `CLAUDE.md:152` e a rule da anatomia):
  proponha o texto, não edite.

## Arquitetura da mudança

Nada de arquitetura nova. São dezessete consertos em cinco lugares:

1. **A saída do runner** (`bin/sdd`): a ajuda (I3), a recusa do `CHECKOUT-BUSY` (I7), o rodapé do
   `sdd status` (I8, I9), o fim do `sdd run` (I9), o aviso da base (I13), o lembrete do juiz (I14),
   o remédio do `sdd kaizen` (I6) e a recusa do argumento com hífen (I5). Cada um troca ou
   acrescenta uma frase, com a asserção que a lê e o mutante que a apaga.
2. **O `sdd close`** ganha duas listas depois do fast-forward (I11, I12), e não apaga nada. A
   leitura dos itens resolvidos é do `tests/check-todo.sh` (o modo novo `--resolved`, I10), que já
   sabe onde a seção aberta termina e o que é bloco cercado: o `bin/sdd` não ganha um segundo
   parser do `TODO.md`.
3. **Três contratos deixam de depender de alguém lembrar**: o `adr_next_id` lê o disco, os refs e
   os outros worktrees (I1); o `cmd_link_agents` liga também `commands/sdd-*.md` (I2); o
   `cmd_install` troca a semente intocada de outro idioma (I15). O `cmd_preflight` ganha dois
   avisos (I2, I15).
4. **Duas leituras de `git status`** passam a rodar com `GIT_OPTIONAL_LOCKS=0` (I4).
5. **A prosa**: os dois templates do `TODO.md` (o ciclo de vida com as duas provas, I10; o teto de
   largura, I16), o `templates/checkpoint.md` e dois chapéus (I16), as 11 citações de ADR (I17), o
   `templates/pr-body.md` (I9) e o `agents/sdd-kaizen.md` (I10).

Contrato de artefato: o token `RESOLVED by <hash>`, a gramática do `TODO.md`, as chaves de config e
os tokens de status ficam como estão. Muda **o que prova** que um `RESOLVED by` pode sair (duas
provas em vez de uma) e **de onde** o alocador de ADR lê; as duas mudanças estão no ADR da missão,
`docs/adr/0025-ids-across-refs-and-the-second-proof-of-a-resolution.md`, que emenda a ADR 0008.

**As duas provas, como comandos** (decisão 5; nunca um rótulo):

1. `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>` → rc 0; ou
2. `git merge-base --is-ancestor <hash> <head do PR>` → rc 0 **e** o estado `MERGED` desse PR lido
   do `gh` na hora (`gh pr view <PR> --json state,headRefOid`). O PR de um hash se acha com
   `gh pr list --search <hash> --state merged --json number,headRefOid`. Um texto que diga
   "mergeado" não prova nada.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

**Em todo incremento, nesta ordem:** (1) escreva a asserção e veja-a vermelha no sensor sozinho,
pelo motivo certo; (2) implemente; (3) veja-a verde; (4) escreva o mutante e prove-o com `--only`
(anote nas notas `<slug> caught by <sensor>`), ou faça a sabotagem à mão onde o catálogo não
alcança; (5) `bash -n bin/sdd`, `shellcheck -S warning` nos arquivos tocados,
`bash tests/check-lang.sh`, `bash tests/check-todo.sh --anchors TODO.md` (`0 off target`), e, se
editou um chapéu, `./bin/sdd install --force` e o `cmp` do espelho; (6) a suíte inteira, sem
escrever no worktree enquanto ela roda; (7) o commit, com o porquê no corpo; (8) o checkpoint e a
nota, como último ato, com a hora de `date '+%Y-%m-%d %H:%M'` rodado no mesmo lote de comandos.

A doc que uma frase nova torna falsa (uma linha da ajuda, do `README.md`, do `docs/pipeline.md`)
se conserta no mesmo commit quando o incremento a nomeia abaixo; o resto é da fase DOCS.

A ordem: os quatro itens com `RECURRED` vêm primeiro (I1 a I4), por ordem do dono de 2026-11-19.

### I1 — O `sdd adr new` lê os números de todo ref e de todo worktree (item 17, decisão 2)

**O quê:** o `adr_next_id` passa a ser **chamado** (nunca lido por `$( )`) e publica dois globais:
`ADR_NEXT_ID` (o número, quatro dígitos) e `ADR_NEXT_SOURCE` (vazio quando o máximo está no disco
do checkout; senão o ref ou o caminho do worktree que o carrega). O máximo sai de três leituras,
todas filtradas pelo `ADR_FILE_RE`: (a) o `find` de hoje no `$root/$ADR_DIR`; (b) para cada ref de
`git -C "$root" for-each-ref --format='%(refname)' refs/heads refs/remotes`, os nomes de
`git -C "$root" ls-tree --name-only "$ref" -- "${ADR_DIR%/}/"`; (c) para cada outro worktree de
`git -C "$root" worktree list --porcelain -z` (as entradas `worktree <caminho>`), o `find` no
`<caminho>/$ADR_DIR`. Toda captura é guardada: fora de um repositório git, com um ref que o
`ls-tree` não lê, ou com um git que não conhece o `-z` do `worktree list` (ele chegou no 2.36; a
máquina tem o 2.43.0), a leitura contribui com nada e o alocador segue. Quando `ADR_NEXT_SOURCE` não é
vazio, o `adr_new` diz na **stderr**, antes de reservar e também no `--dry-run`, uma linha `info`
com o número mais alto visto e onde: `id NNNN is in use on <ref ou worktree> — allocating MMMM`.
A linha da ajuda (`never handed out twice`) ganha "across the branches and worktrees of this
clone".
**Onde:** `bin/sdd` (`adr_next_id`, `adr_new`, `cmd_help`), `tests/check-adr.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** quatro mundos no `tests/check-adr.sh`, cada um num `fixture` próprio (repo git com
um commit): (1) um branch local `other` com `docs/adr/0007-x.md` commitado e o checkout de volta em
`main`, sem o arquivo → `new --slug y --dry-run` imprime `docs/adr/0008-y.md` e a saída cita
`refs/heads/other`; (2) o mesmo com o arquivo só num ref `refs/remotes/origin/far` (crie com
`git update-ref refs/remotes/origin/far <commit>` e apague o branch local) → `0008`; (3) um
`git worktree add` com um `docs/adr/0009-w.md` **não commitado** no disco dele → `0010`, e a saída
cita o caminho do worktree; (4) o fixture de sempre, um ref e um worktree, → o número de antes e
**nenhuma** linha `is in use on`. O Red de hoje: os três primeiros devolvem `0001`.
**As frases:**
- `an id used only on another local branch is never handed out again, and the answer names the ref`
- `an id used only on a remote-tracking ref is never handed out again`
- `an id used only on the disk of another worktree is never handed out again, and the answer names the worktree`
- `a repository with a single ref and a single worktree allocates from the disk and names no other source`
**Mutantes:** `ADR_alloc_refs_unread`, `ADR_alloc_worktrees_unread`, `ADR_alloc_source_unnamed`.
**Check:** linha I1 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções e os três mutantes.
**Reversível por:** `git revert` do commit.
**Limite declarado** (escreva-o no comentário do `adr_next_id`): branch nunca empurrada em outra
máquina continua invisível; a colisão dela só aparece no merge, como hoje.

### I2 — O `link-agents` liga os comandos do kit, e o preflight avisa a falta do `/sdd-plan` (item 5, decisão 3)

**O quê:** o laço do `cmd_link_agents` passa a servir dois diretórios: `agents/sdd-*.md` →
`.claude/agents/` (como hoje) e `commands/sdd-*.md` → `.claude/commands/`. O mesmo tratamento nos
dois: tira do índice o que era rastreado, pula o link que já aponta para o kit, `ln -sfn` no resto,
e um marcador por diretório no `.gitignore`, gravado uma vez (`.claude/commands/sdd-*.md`). A saída
conta os dois (`N command(s) linked`). Nada é escrito fora do repo-alvo. No `cmd_preflight`, um
`warn` (nunca `_fail`) quando `sdd-plan.md` não existe nem em `$REPO_ROOT/.claude/commands/` nem em
`$HOME/.claude/commands/`: fora do kit ele nomeia `sdd-link-agents` e o
`ln -s <kit>/commands/sdd-plan.md <repo>/.claude/commands/`; no próprio kit
(`REPO_ROOT` igual ao `SDD_HOME`, onde o `link-agents` se recusa) nomeia só o
`ln -s … ~/.claude/commands/`. Com o arquivo num dos dois lugares, nenhuma linha. O
`README.md:169` a `:174` passa a dizer que o `sdd-link-agents` liga os comandos, e o `ln -s` fica
como o caminho de quem instalou por cópia.
**Onde:** `bin/sdd` (`cmd_link_agents`, `cmd_preflight`), `bin/sdd-link-agents` (só o comentário do
cabeçalho), `README.md`, `tests/check-preflight.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no bloco do `link-agents` do `tests/check-preflight.sh`: um alvo instalado, rode
`sdd link-agents` e leia `.claude/commands/sdd-plan.md` e `sdd-worker.md` como links para o kit;
rode de novo e exija zero links novos e uma linha só do marcador no `.gitignore`. Para o preflight,
use a troca de home dos probes de skill (`HOME="<fixture>"`): home sem `.claude/commands` e repo
sem link → o `warn` com as duas saídas; link no repo → nada; arquivo na home → nada; a cópia do
kit (`kp_world`) com a home vazia → o `warn` sem `sdd-link-agents`.
**As frases:**
- `link-agents links every kit command into .claude/commands of the target, and a second run links nothing`
- `link-agents ignores the linked commands by one .gitignore rule, appended once`
- `preflight warns that /sdd-plan is in neither commands directory, naming sdd-link-agents and the ln -s by hand`
- `preflight says nothing about /sdd-plan when the repo or the user directory has it`
- `in the kit itself the warning names only the ln -s into the user directory`
**Mutantes:** `LINK_commands_unlinked`, `LINK_commands_gitignore_dropped`,
`PRE_sdd_plan_missing_silent`, `PRE_sdd_plan_kit_names_link_agents`.
**Check:** linha I2 → `1 1 1 1 1`. Antes: `0 0 0 0 0`.
**Sensor durável:** as cinco asserções e os quatro mutantes.
**Reversível por:** `git revert` do commit.
**Cuidado:** o preflight desta máquina não pode mudar de cor por este aviso: é `warn`. E a suíte
roda sensores com a home real, onde `~/.claude/commands/sdd-plan.md` existe; todo probe novo fixa a
home de fixture, para o resultado não depender da máquina.

### I3 — A ajuda do `sdd run` mostra a forma destacada e onde ler o progresso (item 14, decisão 4)

**O quê:** a entrada `sdd run <mission>` do `cmd_help` ganha linhas de continuação (o mesmo recuo
das outras entradas): a forma `setsid nohup sdd run <mission> > <log> 2>&1 < /dev/null &` para
quando a sessão ou o terminal que o dispara vai fechar, e onde ler depois:
`.sdd/logs/pipeline.log` e `sdd status <mission> --no-gates`. O `README.md` ganha **uma** linha
com `setsid nohup sdd run` que aponta para `sdd help` e para o `docs/failure-modes.md`. É só texto:
nenhuma flag, nada na trava do checkout.
**Onde:** `bin/sdd` (`cmd_help`), `README.md`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** em `help_probes` do `tests/check-hat.sh`, no molde do probe do `sdd why`: recorte
o bloco da entrada `  sdd run <mission>` com o `awk` e exija `setsid nohup sdd run`,
`pipeline.log` e `--no-gates` dentro dele.
**A frase:**
- `help: sdd run shows its detached form and where to read the progress afterwards`
**Mutante:** `HELP_run_detached_form_dropped`.
**Check:** linha I3 → `1 1` (a frase, e uma linha do `README.md` com `setsid nohup sdd run`).
Antes: `0 0`.
**Sensor durável:** a asserção e o mutante.
**Reversível por:** `git revert` do commit.

### I4 — O `git status` de leitura não reescreve o índice (item 9)

**O quê:** `GIT_OPTIONAL_LOCKS=0` em quatro leituras: o `hat_status_lines` que o
`session_leftovers` chama (`done < <( GIT_OPTIONAL_LOCKS=0 hat_status_lines )`, a grafia do
`kit_guard_tree`), o `git status` do `cmd_pr_ready` do `bin/sdd-worker`, e os dois
`git -C "$SDD_HOME" status --porcelain` do `autonomy_kit_stamp`. Os dois últimos são a mesma
família (o runner de um alvo lendo o índice do kit, onde alguém pode estar commitando) e entram
sem probe próprio: **declare isso no comentário**, como o `kit_guard_tree` já declara
(`grep -n 'DECLARED' bin/sdd`, perto da `:4630`). O `docs/pipeline.md` (`grep -n 'does not take
down\|monitor' docs/pipeline.md`, perto da `:51`) passa a dizer que a leitura também não disputa
o `index.lock`.
**Onde:** `bin/sdd` (`session_leftovers`, `autonomy_kit_stamp`), `bin/sdd-worker` (`cmd_pr_ready`),
`docs/pipeline.md`, `tests/check-gates.sh`, `tests/check-worker.sh`, `tests/check-mutation.sh`.
**Como (TDD):** o probe é o do gemba: no fixture, com a árvore limpa, dê um `touch` num arquivo
rastreado (um segundo depois do commit, para o `mtime` mudar), guarde
`stat -c '%i' .git/index`, rode `sdd status <missão> --no-gates`, e exija o mesmo inode. **A
testemunha vem primeiro, e é obrigatória**: no mesmo mundo, um `git status --porcelain` puro tem
de trocar o inode; se não trocar, o probe morre alto (`SENSOR-BROKEN`), porque um mundo em que o
git não reescreve o índice não mede nada. O mesmo par no `tests/check-worker.sh`, sobre o
`pr-ready` (a pasta da missão limpa, o `touch` num arquivo rastreado fora dela).
**As frases:**
- `sdd status --no-gates reads the tree without rewriting the index of the checkout`
- `index: pr-ready reads the tree without rewriting the index of the checkout`
**Mutantes:** `STATUS_leftovers_rewrites_index` (no `bin/sdd`), `WORKER_pr_ready_rewrites_index`
(no `"${1%/*}/sdd-worker"`).
**Check:** linha I4 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções, com a testemunha, e os dois mutantes.
**Reversível por:** `git revert` do commit.

### I5 — O argumento de missão que começa com hífen é recusado (item 6)

**O quê:** no `resolve_mission`, antes de qualquer `find`: um `$want` que começa com `-` morre com
`'<arg>' is an option, not a mission — see 'sdd help'`. Uma definição, e os onze chamadores a
herdam. A metade do `--help` **já está feita** (PR #391) e não se refaz: o corpo do commit diz
isso.
**Onde:** `bin/sdd` (`resolve_mission`), `tests/check-gates.sh`, `tests/check-mutation.sh`.
**Como (TDD):** um fixture com as pastas `20261020-lote-de-consertos` e `20261020-narracao`; para
cada um de `why -l`, `phase -n`, `boot -l EXEC`, `census -l`, `approve -l`, `close -l` e
`note-manual -l EXEC`: rc diferente de 0 e a frase `is an option, not a mission` na saída. A
segunda asserção olha o efeito: o `git status --porcelain` do fixture e o `HEAD` são os mesmos
antes e depois das sete chamadas, e nenhuma saída cita o nome de uma das duas pastas.
**As frases:**
- `a mission argument that starts with a dash is refused by name in why, phase, boot, census, approve, close and note-manual`
- `the refusal of a dash argument resolves no mission, with a folder whose name contains it on disk`
**Mutante:** `RUN_mission_dash_unrefused`.
**Check:** linha I5 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções e o mutante.
**Reversível por:** `git revert` do commit.

### I6 — O remédio do `sdd kaizen` recusado leva `--no-track` (item 3)

**O quê:** o `shared_why` do `cmd_kaizen` passa a mandar
`worktree add <wt> --no-track -b kaizen/<data> <base>`, na ordem que o `commands/sdd-plan.md:60` já
usa. As duas citações do motivo (`docs/failure-modes.md` e `docs/pipeline.md`) ganham o mesmo
`--no-track`, cada uma com `--no-track -b kaizen/` **numa linha física só** (o Check conta as
duas).
**Onde:** `bin/sdd` (`cmd_kaizen`), `docs/failure-modes.md`, `docs/pipeline.md`,
`tests/check-kaizen.sh`, `tests/check-mutation.sh`.
**Como (TDD):** na seção `the checkout the targets run is refused to the judge` do
`tests/check-kaizen.sh`, leia o motivo e exija ` --no-track -b kaizen/` nele, na recusa e na
projeção (`--dry-run`). As asserções de hoje que leem o motivo literal mudam junto.
**A frase:**
- `the refusal in the checkout the targets run names a worktree add with --no-track`
**Mutante:** `KAIZEN_remedy_tracks_the_base`.
**Check:** linha I6 → `1 2` (a frase, e as duas citações). Antes: `0 0`.
**Sensor durável:** a asserção e o mutante.
**Reversível por:** `git revert` do commit.

### I7 — O `CHECKOUT-BUSY` aponta o `sdd status --no-gates` (item 16)

**O quê:** no `main` do `bin/sdd`, quando a admissão volta com rc 75, uma linha a mais na stderr,
depois da recusa do helper: `sdd status <mission> --no-gates reads the mission off the disk with no
lock, while the owner runs`. Vale para todo subcomando que pede a trava. Não é escalada: nenhum
ledger, nenhum hook, o rc continua 75.
**Onde:** `bin/sdd` (`main`), `tests/check-coordination.sh`, `tests/check-mutation.sh`.
**Como (TDD):** no probe que já provoca um `CHECKOUT-BUSY` (`tests/check-coordination.sh:270`),
leia a saída da chamada recusada e exija `--no-gates` nela, com o rc 75. A chamada com
`--no-gates` não pede a trava e não imprime a linha (é a testemunha do outro lado).
**A frase:**
- `a CHECKOUT-BUSY refusal names sdd status --no-gates as the read that takes no lock`
**Mutante:** `COORD_busy_no_gates_unnamed`.
**Check:** linha I7 → `1`. Antes: `0`.
**Sensor durável:** a asserção e o mutante.
**Reversível por:** `git revert` do commit.

### I8 — O `sdd status` com o app fora do ar manda subir o app (item 10)

**O quê:** no rodapé do `cmd_status`, depois do `"gate_$next" || true`: com `GATE_APP_DOWN` em `1`,
a linha `run: sdd run <missão>` dá lugar ao remédio da escalada
(`start the app (or stop the one on its port), then 'sdd status' again — 'sdd run' now would only
escalate app-down`), e, quando o `30-handoff-qa.md` da missão diz `status: done`, uma linha antes
dela: `QA is closed on disk (30-handoff-qa.md: done); its e2e cannot be re-verified now`. A linha
da fase na tabela não muda (o motivo do gate já diz que o app caiu). Com o app respondendo, o
rodapé é o de hoje.
**Onde:** `bin/sdd` (`cmd_status`), `tests/check-gates.sh`, `tests/check-mutation.sh`.
O `status:` do handoff se lê com `frontmatter "$MISSION_DIR/30-handoff-qa.md" status`.
**Como (TDD):** três mundos sobre o fixture do par do app morto: e2e vermelha com
`APP_URL="http://example.invalid"` e o handoff de QA `done` → as duas linhas novas e nenhuma
`run: sdd run`; o mesmo sem o handoff → o remédio, sem a linha do "closed on disk"; e2e vermelha
com o `APP_URL` vazio (o controle que a seção já usa) → `run: sdd run`, como hoje.
**As frases:**
- `sdd status with the e2e red and the app down names starting the app, never sdd run`
- `sdd status with the app down says the QA is closed on disk when 30-handoff-qa.md is done`
- `sdd status with the e2e red and the app answering still names sdd run`
**Mutantes:** `STATUS_app_down_names_run`, `STATUS_app_down_closed_unsaid`.
**Check:** linha I8 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.
**Fora:** o `sdd run` continua comprando uma sessão antes de escalar `app-down` (pendência 5 do
`00-missao.md`).

### I9 — O fim da corrida, o `sdd status` e o corpo do PR nomeiam o `sdd close` (item 11)

**O quê:** as duas frases `only the merge is left` (no `cmd_run` e no `cmd_status`) ganham uma
linha `dim` logo abaixo, a mesma nos dois braços do JIRA:
`after the merge: sdd close <missão> — comes home, fast-forwards <base>, lists what the merge
resolved, and closes the JIRA issue when JIRA_ENABLED=true`. O `templates/pr-body.md` ganha, no
bloco de citação do topo (ao lado de "Único gate humano: o merge"), a linha
`Depois do merge: \`sdd close <missão>\`.` O `agents/sdd-publisher.md` não muda: ele copia o
template.
**Onde:** `bin/sdd` (`cmd_run`, `cmd_status`), `templates/pr-body.md`, `tests/check-kaizen.sh`,
`tests/check-templates.sh`, `tests/check-mutation.sh`.
**Como (TDD):** a seção `reminder: pipeline complete points at the judge` do
`tests/check-kaizen.sh` já leva um fixture até `pipeline complete`: leia a saída desse `sdd run` e
a de um `sdd status <missão>` sobre o mesmo fixture, e exija `sdd close <id da missão>` em cada
uma. No `tests/check-templates.sh`, um `check pr-body.md '<regex>' 'names sdd close as the step
after the merge'`.
**As frases:**
- `the end of sdd run names sdd close as the step after the merge`
- `sdd status of a complete mission names sdd close as the step after the merge`
- `pr-body.md: names sdd close as the step after the merge`
**Mutantes:** `RUN_complete_close_unnamed`, `STATUS_complete_close_unnamed`.
**Check:** linha I9 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.
**Cuidado:** a linha é escrita aqui dizendo "lists what the merge resolved", que só fica verdade
no I11. A ordem está certa (o I11 vem depois, na mesma missão); se o I11 ficar `blocked`, volte
aqui e tire a oração.

### I10 — O ciclo de vida diz as duas provas, e o `check-todo.sh` lista os resolvidos (item 1, decisão 5)

**O quê:** três coisas, um commit.
(a) Os dois templates do `TODO.md` (o parágrafo "Ciclo de vida" / "Lifecycle"): o item sai quando
vale **uma de duas provas**, escritas como os comandos da seção "As duas provas" acima, com o
`gh pr list --search <hash> --state merged` para achar o PR de um hash. Uma frase a mais: a
subseção que fica vazia mantém o título. O parágrafo continua dentro da citação (`> `), e as duas
variantes continuam com o mesmo esqueleto, linha por linha (o `tests/check-templates.sh` cobra).
(b) O `tests/check-todo.sh` ganha o modo `--resolved <arquivo>`: uma linha por item **aberto** cujo
corpo traz `RESOLVED by <hash>`, no formato `<linha em que o item abre><TAB><hash>[,<hash>…]<TAB><título>`,
com todos os hashes do item, lidos pelo mesmo parser das outras regras (fora de bloco cercado,
dentro da seção aberta). rc 0 com ou sem linhas; o arquivo sem os dois marcadores sai como o
`--count` sai hoje. Entra no cabeçalho do sensor e no `case` dos modos, com uma regra de selftest
entre `rule_begin` e `rule_end`, e o `RULES_FLOOR` sobe um.
(c) O `agents/sdd-kaizen.md` (o parágrafo "The triage is also the sweep") passa a dizer as duas
provas, e a frase "Proving by the hash and not by the PR label" vira: a prova é sempre um comando,
o `git merge-base` ou ele mais o estado lido do `gh`, nunca um rótulo. Espelhe com
`./bin/sdd install --force`.
**Onde:** `templates/todo.md`, `templates/todo.pt-BR.md`, `tests/check-todo.sh`,
`tests/check-templates.sh`, `agents/sdd-kaizen.md`, `.claude/agents/sdd-kaizen.md` (pelo install),
`tests/check-hat.sh`.
**Como (TDD):** no selftest do `check-todo.sh`, um arquivo com: um item aberto com um hash, um com
dois, um sem nenhum, um `RESOLVED by` dentro de bloco cercado, e um registro decidido que cita o
token → duas linhas, com os hashes certos. No `check-templates.sh`, um `check` por variante com a
regex das duas provas (`merge-base --is-ancestor` duas vezes e `gh pr` no parágrafo). No
`check-hat.sh`, uma família nova que lê o parágrafo do `sdd-kaizen.md`.
**As frases:**
- `rule: --resolved prints one line per open item that carries RESOLVED by`
- `todo.md: the lifecycle names both proofs of a resolution`
- `todo.pt-BR.md: the lifecycle names both proofs of a resolution`
- `kaizen: the sweep of the judge names both proofs of a resolution`
**Mutantes:** nenhum (o catálogo não alcança estes arquivos). **Sabotagem à mão** do `--resolved`,
anotada nas notas: numa cópia do sensor fora do worktree, faça o modo ler também o bloco cercado,
e depois a seção decidida; o selftest da cópia fica vermelho nas duas.
**Check:** linha I10 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções, que a suíte roda.
**Reversível por:** `git revert` do commit.
**Cuidado:** o preâmbulo do `TODO.md` do próprio kit é de autor, não é cópia do template
(`diff <(sed -n '1,/<!-- sdd:open -->/p' TODO.md) <(sed -n '1,/<!-- sdd:open -->/p' templates/todo.pt-BR.md)`
difere desde a linha 1): não há o que sincronizar nele. A skill do espelho fica como está
(pendência 3).

### I11 — O `sdd close` lista os `RESOLVED by` que já podem sair (item 12, decisão 6)

**O quê:** uma função nova, `close_list_resolved <verified|unverified> <head do PR ou vazio>`,
chamada pelo `close_return_home` em todo caminho que termina na base com a árvore limpa (depois do
fast-forward, e também quando não havia o que avançar), a partir dos três sítios do `cmd_close`. Ela roda
`bash "$SDD_HOME/tests/check-todo.sh" --resolved "$REPO_ROOT/$TODO_FILE"` (captura guardada; sem o
arquivo, sem o sensor ou com rc diferente de 0, não diz nada) e, para cada item, testa **todos** os
hashes dele: `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>`; senão, só quando o close viu o
PR da missão `MERGED`, `git merge-base --is-ancestor <hash> <head do PR>`. O item entra na lista
quando todo hash passa numa das duas. A saída: uma linha de título
(`N finding(s) in <TODO_FILE> can go — their RESOLVED by is merged:`) e uma por item,
`<TODO_FILE>:<linha>  <título>  (<hash>: in <base> | in the head of the merged PR)`. **Só lista**:
não edita, não commita. O `cmd_close` passa a pedir `state,headRefOid` ao `gh` numa chamada só
(`--json state,headRefOid --jq '.state, .headRefOid'`, o molde do `gate_PR`) e entrega o head ao
`close_return_home`, cujo segundo argumento é novo.
**Onde:** `bin/sdd` (`cmd_close`, `close_return_home`, a função nova), `tests/check-gates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** na seção `sdd close: the artifact decides` (ache o stub do `gh` que ela usa com
`awk 'NR>6681 && /\.stub\/gh/' tests/check-gates.sh`, e faça-o responder as duas linhas do
`--json state,headRefOid`: `MERGED` e um head que o teste escolhe). Confirme antes qual kit a seção
roda (`$SDD` e o `SDD_HOME` que ele resolve): o `tests/check-todo.sh` tem de existir nele.
Com o stub respondendo `MERGED` e um head: um `TODO.md` de fixture com quatro itens abertos — (1) hash ancestral da base;
(2) hash que só é ancestral do head do PR (um branch lateral que o fixture **não** mergeia na
base: é o mundo do squash); (3) hash que não é ancestral de nenhum dos dois; (4) sem `RESOLVED by`.
A lista traz o 1 com `in main` e o 2 com `in the head of the merged PR`, e nem o 3 nem o 4. O
mesmo close com `JIRA_ENABLED=true` e a issue já `Done` (o braço sem sessão) traz a mesma lista, e
o `md5sum` do `TODO.md` é igual antes e depois nos dois braços. O terceiro sítio (depois da sessão
que fecha a issue) recebe o mesmo argumento e não ganha probe próprio: declare-o no comentário. Sem `pr_url` no `50-pr.md`
(`unverified`), o item 2 não entra.
**As frases:**
- `sdd close lists the open item whose RESOLVED by hash is an ancestor of the base, with file, line, title and proof`
- `sdd close lists the item whose hash is an ancestor of the head of the mission PR it saw MERGED, the squash case`
- `sdd close lists no item whose hash passes neither proof, and none without RESOLVED by`
- `sdd close lists the resolved items with and without JIRA, and deletes nothing`
**Mutantes:** `CLOSE_resolved_unlisted`, `CLOSE_resolved_squash_proof_unread`,
`CLOSE_resolved_lists_unproven`.
**Check:** linha I11 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções e os três mutantes.
**Reversível por:** `git revert` do commit.
**Limites declarados** (no comentário da função): sob squash, o hash de **outra** missão não é
listado (para ele fica o `gh pr list --search` do template); o head do PR que não está no
repositório local não prova nada (falha fechada: o item não entra).

### I12 — O `sdd close` lista as linhas que ainda dão o PR mergeado como aberto (item 8)

**O quê:** outra função, `close_list_open_pr_lines <número do PR>`, chamada pelo
`close_return_home` no mesmo ponto do I11, **só** com o merge verificado. Ela roda
`git -C "$REPO_ROOT" grep -nE "PR #<N> (aberto|open)\b" -- . ":(exclude)$HANDOFF_DIR"` (captura
guardada: rc 1 é "nada") e imprime uma linha de título
(`N line(s) still give PR #<N> as open:`) e uma por achado, `<arquivo>:<linha>: <texto>`. Só
lista. O número sai do `pr_url` (o último componente, só dígitos; outra forma de URL não lista
nada).
**Onde:** `bin/sdd` (`cmd_close`, `close_return_home`, a função nova), `tests/check-gates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** no fixture do close, commite na base um `docs/roadmap.md` com `PR #7 aberto` e um
`KAIZEN_LOG.md` com `PR #7 open`, mais `PR #70 aberto` (outro número) e `PR #7 aberto` dentro da
pasta da missão. Com o `pr_url` terminando em `/pull/7`: as duas linhas de fora da pasta, e nem a
do `#70` nem a de dentro. Sem nenhuma dessas linhas, e também sem `pr_url`: nenhuma linha
`still give`.
**As frases:**
- `sdd close lists the tracked lines that still give the merged PR as open, outside the handoff directory`
- `sdd close says nothing about open-PR lines when none is left, or when the merge was not verified`
**Mutantes:** `CLOSE_open_pr_lines_unlisted`, `CLOSE_open_pr_lines_unverified_listed`.
**Check:** linha I12 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.
**Limite declarado:** as duas palavras (`aberto`, `open`); outro idioma, ou "PR 7 em aberto",
passa sem ser listado.

### I13 — O `sdd run` não grita que commita na base quando a TICKET vai cortar o branch (item 13)

**O quê:** um predicado novo, `ticket_will_cut_branch`: verdadeiro quando `JIRA_ENABLED` é `true`,
o `mission_branch_declared` está vazio (o placeholder) e a missão não tem `10-ticket.md`. No
`cmd_run` e no `cmd_retry`, o `warn_if_on_base_branch` só é chamado quando o predicado é falso. O
`cmd_approve` e o `cmd_kaizen` ficam como estão (lá o aviso é verdadeiro). O `MISSION_DIR` já está
resolvido nos dois pontos (confira a ordem: `resolve_mission` vem antes do aviso; se não vier no
`cmd_retry`, mova o aviso para depois dele).
**Onde:** `bin/sdd` (`cmd_run`, `cmd_retry`, o predicado), `tests/check-gates.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** na seção `base branch warning`: `JIRA_ENABLED=true`, `branch:` no placeholder, sem
`10-ticket.md`, na base → `sdd run --dry-run` sem a frase `commits straight into it`; o mesmo com
o `10-ticket.md` presente → com a frase; e com `branch: main` declarado → com a frase. Use o
`--dry-run` como as asserções vizinhas usam.
**As frases:**
- `sdd run on the base branch is silent about committing into it while the branch field is the placeholder and the TICKET is still to run`
- `sdd run on the base branch still warns once 10-ticket.md exists, and when the mission declares the base itself`
**Mutante:** `RUN_base_warning_before_ticket`.
**Check:** linha I13 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções e o mutante.
**Reversível por:** `git revert` do commit.

### I14 — O lembrete do `sdd kaizen` diz o backlog e o custo (item 15)

**O quê:** as duas linhas `dim` do `kaizen_reminder` ganham o mesmo fim:
`— the kit backlog holds <N> open finding(s); 'sdd kaizen' is one paid session, two when its gate
fails, each capped at US$ <teto>`. `<N>` sai de
`bash "$SDD_HOME/tests/check-todo.sh" --count "$SDD_HOME/<TODO_FILE do kit>"` e o teto de
`config_read_key "$SDD_HOME/.sdd/config.sh" BUDGET_PER_PHASE_USD` (o `TODO_FILE` do kit pela mesma
leitura, com `TODO.md` de recuo). Capturas guardadas: sem a contagem, a oração do backlog some e o
resto fica; sem o teto, a oração do teto diz só "one paid session, two when its gate fails".
**Onde:** `bin/sdd` (`kaizen_reminder`), `tests/check-kaizen.sh`, `tests/check-mutation.sh`.
**Como (TDD):** nas seções `reminder: …` do `tests/check-kaizen.sh`, o kit é o **kit de fixture**
`$FIX`, uma cópia de `bin/`, `templates/`, `config/` e `agents/`
(`grep -n 'cp -r "$ROOT/bin"' tests/check-kaizen.sh` → `:1025`), **sem `tests/`**: do jeito que
está, ele é o mundo em que o backlog não se conta. Para o mundo da contagem, copie para
`$FIX/tests/` o `check-todo.sh` e o `isolate-git.sh` (o primeiro carrega o segundo), e dê ao kit de
fixture um `TODO.md` com os dois marcadores e três achados abertos e um `.sdd/config.sh` com
`BUDGET_PER_PHASE_USD=40`: a linha diz `3 open finding(s)` e `US$ 40`. Sem o `tests/` na cópia, a
linha continua e não diz `open finding`.
**As frases:**
- `the reminder says how many open findings the kit backlog holds and what one judge session may cost`
- `the reminder still prints, without the count, when the kit backlog cannot be counted`
**Mutantes:** `KAIZEN_reminder_backlog_unsaid`, `KAIZEN_reminder_cost_unsaid`.
**Check:** linha I14 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções e os dois mutantes.
**Reversível por:** `git revert` do commit.

### I15 — O `sdd install` troca a semente intocada de outro idioma (item 4, decisão 7)

**O quê:** no braço do `cmd_install` em que o `TODO_FILE` já existe: se o arquivo é **byte a byte**
(`git hash-object --no-filters`, como o precedente logo abaixo) igual a um `templates/todo*.md` do
kit que **não** é a semente do `OUTPUT_LANG` de agora, ele é trocado pela semente de agora, com um
`ok` que diz de qual para qual. Um byte diferente e o arquivo é preservado, como hoje. Na primeira
instalação, quando o `inst_lang` está vazio, o `ok` da semente diz que ela veio em inglês porque o
`OUTPUT_LANG` está vazio, e que basta declarar a chave e rodar `sdd install` de novo enquanto o
arquivo estiver intocado. No `cmd_preflight`, um `warn` (nunca `_fail`) quando o `TODO_FILE` é
byte a byte a semente de outro idioma, nomeando o `sdd install`. Uma função só responde "este
arquivo é a semente intocada de qual template" e é lida pelos dois.
**Onde:** `bin/sdd` (`cmd_install`, `cmd_preflight`, a função), `tests/check-preflight.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** ao lado do `seed_lang` do `tests/check-preflight.sh`: instale sem idioma (a
semente em inglês e a frase nova na saída); declare `pt-BR` e reinstale → o arquivo passa a ser
igual ao `templates/todo.pt-BR.md` (`cmp`); repita com um byte acrescentado antes do segundo
install → preservado, `cmp` com o inglês mais o byte; e o preflight do primeiro mundo, com a chave
já em `pt-BR` e antes do reinstall → o `warn`.
**As frases:**
- `the first install with no OUTPUT_LANG says the TODO was seeded in English and how to reseed it`
- `install replaces a TODO that is still the untouched seed of another language with the seed of OUTPUT_LANG`
- `install preserves a TODO one byte away from a seed`
- `preflight warns that the TODO is still the untouched seed of another language, naming sdd install`
**Mutantes:** `INSTALL_seed_other_lang_kept`, `INSTALL_seed_edited_replaced`,
`PRE_seed_other_lang_silent`.
**Check:** linha I15 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções e os três mutantes.
**Reversível por:** `git revert` do commit.
**Limite declarado:** só as sementes de hoje são reconhecidas; a de uma revisão antiga do template
é o mecanismo do I5 do L4. Leia "Onde o L5 toca os mesmos arquivos que o L4" antes de começar.

### I16 — A prosa diz a regra 2 e o teto de largura como os sensores medem (item 2)

**O quê:** cinco frases, sem mudar regra nenhuma. Leia antes os dois cabeçalhos
(`sed -n 38,50p tests/check-checkpoint.sh` e `sed -n 26,31p tests/check-todo.sh`).
(a) `templates/checkpoint.md` (o aviso "Check que lê a saída de um sensor ancora em…") e
`agents/sdd-planner.md` § 4 (o `⚠️` do `^  ok    `): além do prefixo `^  ok    `, a marca de
aprovação de um test runner no começo do padrão (`'^ *✓ '`) ancora do mesmo jeito; a âncora é
devida pelo grep que lê a saída mesclada, em qualquer grafia de mescla; e o grep de contagem cujo
esperado é só zeros não deve âncora.
(b) `templates/todo.md:26`, `templates/todo.pt-BR.md:26` e `agents/sdd-executor.md:178`: o teto
de 120 isenta a `RECURRED` bem formada **e a linha que, depois do recuo, carrega só a âncora**.
Espelhe os dois chapéus com `./bin/sdd install --force`.
**Onde:** `templates/checkpoint.md`, `templates/todo.md`, `templates/todo.pt-BR.md`,
`agents/sdd-planner.md`, `agents/sdd-executor.md`, os dois espelhos, `tests/check-templates.sh`,
`tests/check-hat.sh`.
**Como (TDD):** três `check` no `tests/check-templates.sh` (a regex do `checkpoint.md` exige `✓` e
a palavra dos zeros no aviso; a de cada `todo*.md` exige a isenção da linha da âncora no parágrafo
do teto) e uma família no `tests/check-hat.sh` que lê as duas frases dos chapéus.
**As frases:**
- `checkpoint.md: the anchor rule names the pass mark of a test runner and the count that expects only zeros`
- `todo.md: the width cap exempts the line that carries only the anchor`
- `todo.pt-BR.md: the width cap exempts the line that carries only the anchor`
- `prose: the planner and the executor state the anchor rule and the width cap as the sensors measure them`
**Mutantes:** nenhum; lote de prosa, sem passada de sabotagem (régua A).
**Check:** linha I16 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções.
**Reversível por:** `git revert` do commit.
**Cuidado:** o `tests/check-templates.sh` cobra que as duas variantes do `todo` tenham o mesmo
esqueleto linha por linha: se uma ganhar uma linha, a outra ganha a mesma.

### I17 — A citação de ADR do kit nomeia o kit (item 7)

**O quê:** as 11 citações do gemba passam a nomear o kit: em inglês, `ADR 0018 §3 of the sdd kit`;
em português (o `templates/missao.md`), `ADR 0018 §3 do kit sdd`. Sem link (o molde com link do
`todo.md:27` fica para quem quiser; o que o item cobra é o nome do kit). O `agents/sdd-kaizen.md`
fica de fora: só roda no kit. No `tests/check-hat.sh`, uma família nova varre `agents/*.md` (menos
o `sdd-kaizen.md`), `templates/*.md` e `commands/*.md` e recusa todo `ADR NNNN` (com ou sem `§N`)
que não é seguido, na mesma linha, por ` of the sdd kit` ou ` do kit sdd`, nem está dentro de um
link `[ADR NNNN of the sdd kit](…)`. O controle negativo: a mesma varredura sobre um chapéu de
fixture com `(ADR 0018 §3).` tem de recusar, nomeando o arquivo e a linha. Espelhe os chapéus com
`./bin/sdd install --force`.
**Onde:** `templates/missao.md`, `agents/sdd-planner.md`, `agents/sdd-docs.md`,
`agents/sdd-publisher.md`, `agents/sdd-reviewer.md`, os quatro espelhos, `commands/sdd-plan.md`,
`commands/sdd-worker.md`, `tests/check-hat.sh`.
**Como (TDD):** escreva a varredura primeiro e veja-a vermelha com as 11 linhas nomeadas; conserte
uma a uma. Quando a citação quebra de linha entre o número e "of the sdd kit", reflua a frase.
**As frases:**
- `adr citation: no hat, template or command cites a kit ADR by its bare number`
- `adr citation: a bare ADR number in a fixture hat is refused by name`
**Mutantes:** nenhum; lote de prosa, com o controle negativo acima.
**Check:** linha I17 → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções.
**Reversível por:** `git revert` do commit.
**Cuidado:** o `00-missao.md` e o `checkpoint.md` desta missão foram instanciados do template de
antes e trazem `(ADR 0018 §3)` no parágrafo do gate PLAN-AUTO: a varredura não lê `docs/handoffs/`,
e você não os edita.

### I18 — Fecho

**O quê:** `RESOLVED by <hash>` nos 17 itens do `TODO.md`, cada um com o hash do incremento que o
fechou (a coluna Incremento da tabela do `00-missao.md` diz qual, e o hash sai da coluna Commit do
`checkpoint.md`). O item 6 leva o hash do I5; a metade dele que o PR #391 já tinha fechado vai dita
no corpo do commit, não no item. O `20-handoff-exec.md` é do chapéu do executor, que o escreve no
incremento que não deixa linha `pending`.
**Onde:** `TODO.md`, `docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/20-handoff-exec.md`.
**Como (TDD):** o Check conta os `RESOLVED by` contra o `TODO.md` do merge-base com a
`origin/main`; antes ele imprime `0`. Depois: `bash tests/check-todo.sh --check TODO.md` (rc 0,
nenhum item acima de 8 linhas), `--anchors` (`0 off target`) e
`bash tests/check-todo.sh --resolved TODO.md` (as 17 linhas, mais as que a base já trouxer). Não
toque em `tests/health-baseline.txt`.
**Check:** linha I18 → `17`. Antes: `0`.
**Sensor durável:** `tests/check-todo.sh` (forma e âncoras), que a suíte roda. A contagem em si é
checagem desta missão: o chore de depois do merge apaga os itens.
**Reversível por:** `git revert` do commit.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A base anda entre o plano e a corrida (o merge do L4 e do #460), nos mesmos trechos do `cmd_install`, do `cmd_preflight`, do `cmd_run` e do `check-todo.sh` | certa | Pendência 1 do `00-missao.md`: merge da `origin/main`, `--anchors`, `--check` e `--red` de novo, antes do `sdd run`. A seção "Onde o L5 toca os mesmos arquivos" diz o que reler |
| Uma linha nova na saída (o `after the merge`, o `CHECKOUT-BUSY`, o lembrete) quebra uma asserção que compara a saída inteira | média | Nenhum sensor foi rodado contra a mudança (ela não existe ainda), então o risco fica aberto: a suíte inteira antes do commit do I7, do I9 e do I14 é quem responde. As asserções vizinhas leem por `grep` de uma frase (`grep -n 'only the merge is left' tests/*.sh` → nada), o que é evidência, não prova |
| A leitura dos refs no I1 fica lenta num clone com milhares de refs | baixa | 0,44 s para 158 refs aqui (um `ls-tree` por ref). Se um alvo medir segundos, o conserto é um `for-each-ref` só com `%(objectname)` e um `ls-tree` por árvore distinta; não se antecipa |
| O probe do índice (I4) é verde por o git não reescrever o índice naquele mundo | média | A testemunha obrigatória: o `git status` puro tem de trocar o inode no mesmo mundo, senão o probe morre alto. Medido no planejamento: `29338` → `29341` com o status puro, `29338` → `29338` com a variável |
| Um probe novo do preflight (I2, I15) depende da home real desta máquina, onde `~/.claude/commands/sdd-plan.md` existe | alta, se o plano não for seguido | Todo probe fixa `HOME` num diretório de fixture, como os probes de skill (`tests/check-preflight.sh:1515`) |
| Um mutante novo não é pego, e a asserção é decoração | média | `--only <slug> <sensor>` antes de cada commit, anotado nas notas; mutante vivo = incremento não fecha |
| O probe do I1 ou do I11 depende do git do kit real e falha na sandbox de mutação, que copia o kit sem git | alta, se o plano não for seguido | Os dois montam repositórios de fixture próprios (`fixture` do `check-adr.sh`; o fixture do close) |
| O `sdd close` lista como "pode sair" um item cujo conserto não chegou à base | baixa | A lista exige **todo** hash do item numa das duas provas, e a segunda só vale com o `MERGED` lido do `gh` naquele close; ela só lista, e quem apaga revê. O mutante `CLOSE_resolved_lists_unproven` segura a regra |
| A segunda prova contradiz o `CLAUDE.md:152` enquanto o dono não aplica o `⛔` | certa | Pendência 4 do `00-missao.md`, destacada no corpo do PR; o ADR registra a mudança; o texto do `CLAUDE.md` só muda pelo dono |
| A skill `todo-to-github-issues` e o template divergem calados | certa, até o retrofit | Pendência 3; a divergência é para o lado seguro (a skill deixa de apagar, nunca apaga a mais) |

**Não-feitos, por decisão:** o catálogo de mutação inteiro (`./bin/sdd health`); `sdd run
--detach`; `sdd adr new --after`; a troca do token `RESOLVED by`; apagar itens pelo `sdd close`; a
porta do `app-down` antes da sessão; as citações de ADR do `boot_prompt` e do `sdd-kaizen.md`; a
edição do `CLAUDE.md` e da rule da anatomia (linhas `⛔` na DOCS); `tests/health-baseline.txt`; a
skill do espelho.

## Verificação end-to-end

Quando todos os incrementos estiverem `done`, no worktree da missão:

1. `tests/run-all.sh` → `suite green`, rc 0, e `grep -cE '^  FAIL' <saída>` → `0`.
2. As 46 frases, cada uma com `  ok    ` no seu sensor (os Checks I1 a I17 do `checkpoint.md`,
   todos com o valor esperado).
3. `grep -cE '^mut_(ADR_alloc_refs_unread|ADR_alloc_worktrees_unread|ADR_alloc_source_unnamed|LINK_commands_unlinked|LINK_commands_gitignore_dropped|PRE_sdd_plan_missing_silent|PRE_sdd_plan_kit_names_link_agents|HELP_run_detached_form_dropped|STATUS_leftovers_rewrites_index|WORKER_pr_ready_rewrites_index|RUN_mission_dash_unrefused|KAIZEN_remedy_tracks_the_base|COORD_busy_no_gates_unnamed|STATUS_app_down_names_run|STATUS_app_down_closed_unsaid|RUN_complete_close_unnamed|STATUS_complete_close_unnamed|CLOSE_resolved_unlisted|CLOSE_resolved_squash_proof_unread|CLOSE_resolved_lists_unproven|CLOSE_open_pr_lines_unlisted|CLOSE_open_pr_lines_unverified_listed|RUN_base_warning_before_ticket|KAIZEN_reminder_backlog_unsaid|KAIZEN_reminder_cost_unsaid|INSTALL_seed_other_lang_kept|INSTALL_seed_edited_replaced|PRE_seed_other_lang_silent)\(\)' tests/check-mutation.sh`
   → `28`, e `bash tests/check-mutation.sh --anchors` → rc 0.
4. Os espelhos: para cada um de `sdd-kaizen`, `sdd-planner`, `sdd-executor`, `sdd-docs`,
   `sdd-publisher` e `sdd-reviewer`, `cmp -s agents/<h>.md .claude/agents/<h>.md; echo $?` → `0`.
5. `bash tests/check-todo.sh --check TODO.md` → rc 0, `bash tests/check-todo.sh --anchors TODO.md`
   → `0 off target`, e o Check I18 → `17`.
6. `./bin/sdd adr check --mission 20261121-l5-saida-humana-e-contrato-do-runner --phase plan` →
   rc 0.
7. Para a QA, de mão, num repo de rascunho fora do worktree e com o `./bin/sdd` deste worktree
   pelo caminho absoluto: `sdd install` sem idioma e de novo com `OUTPUT_LANG="pt-BR"` (a semente
   troca); `sdd-link-agents` (os dois links em `.claude/commands/`); `sdd why -l` (a recusa);
   `sdd help` (a forma destacada); e, com duas pastas de ADR em dois branches, `sdd adr new --slug
   x --dry-run` (o número seguinte ao maior dos dois).

## O vermelho medido

Medido pelo planner em `86e16c0`, em 2026-11-21, com o `tests/check-checkpoint.sh` do worktree e
as suítes do L4 rodando na mesma máquina:

- `bash tests/check-checkpoint.sh --check docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/checkpoint.md`
  → `ok    checkpoint.md: 18 row(s), 17 under the anchor rule, none blind`, rc 0.
- `bash tests/check-checkpoint.sh --red <o mesmo checkpoint>` (18:26:39 a 18:47:35, 21 min) → rc 0,
  `18 pending Check(s), every one red at HEAD`. As dezoito linhas `is red at HEAD`:
  I1 `prints '0 0 0 0', wants '1 1 1 1'`; I2 `'0 0 0 0 0'`/`'1 1 1 1 1'`; I3 `'0 0'`/`'1 1'`;
  I4 `'0 0'`/`'1 1'`; I5 `'0 0'`/`'1 1'`; I6 `'0 0'`/`'1 2'`; I7 `'0'`/`'1'`;
  I8 `'0 0 0'`/`'1 1 1'`; I9 `'0 0 0'`/`'1 1 1'`; I10 `'0 0 0 0'`/`'1 1 1 1'`;
  I11 `'0 0 0 0'`/`'1 1 1 1'`; I12 `'0 0'`/`'1 1'`; I13 `'0 0'`/`'1 1'`; I14 `'0 0'`/`'1 1'`;
  I15 `'0 0 0 0'`/`'1 1 1 1'`; I16 `'0 0 0 0'`/`'1 1 1 1'`; I17 `'0 0'`/`'1 1'`; I18 `'0'`/`'17'`.
- A quarta frase do I1 foi trocada depois dessa corrida (a de antes falava de um repositório que
  não é git, um mundo em que o `sdd adr new` não roda); a linha foi medida de novo:
  `--red … --only I1` (18:47:56 a 18:48:07) → rc 0, `I1 is red at HEAD (prints '0 0 0 0', wants
  '1 1 1 1')`.

O `--red` prova "não verde no HEAD", não "vermelho pelo motivo certo": todas as frases são novas,
então cada contagem é `0` porque a frase ainda não existe. O vermelho pelo motivo certo é o passo 1
de cada incremento. Depois do merge da `main` (pendência 1 do `00-missao.md`) a corrida se repete;
ela leva cerca de 20 min e não cabe numa chamada `Bash` só: rode-a destacada, com a saída num
arquivo, ou em duas metades com `--only`.

## Teste de autocontenção

Lido incremento a incremento com a pergunta "uma sessão nova executa isto só com os três
arquivos?". O que saiu como "só se souber X" e está escrito acima: o `sdd` do PATH é o runner
velho e o `./bin/sdd` é o novo; não escrever no worktree com um sensor dele rodando; o ADR já está
alocado e não se roda `sdd adr new`; a linha da origem do I1 vai na stderr, porque o `--dry-run` é
lido por linha inteira, e o `adr_next_id` passa a ser chamado; o `-z` do `worktree list` (I1); a
home de fixture dos probes do preflight (I2, I15); o `link-agents` recusa o próprio kit (I2); a
testemunha obrigatória do índice (I4); a metade do `--help` já fechada (I5); as duas citações numa
linha física (I6); o `frontmatter` do handoff de QA (I8); a oração do I9 que só fica verdade no
I11; o formato do `--resolved` e quem o lê (I10, I11); os três sítios do `close_return_home` e o
stub do `gh` da seção (I11); o kit de fixture sem `tests/` (I14); a sobreposição com o I5 do L4
(I15); o esqueleto linha a linha das duas variantes do `todo` (I10, I16); os espelhos dos chapéus
(I10, I16, I17); o catálogo que não alcança o I10, o I16 e o I17; o `RULES_FLOOR`; a re-ancoragem
do `TODO.md` em todo commit; a sandbox de mutação sem git; e que a base terá andado.
