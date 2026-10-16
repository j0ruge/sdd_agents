---
missao: 20261016-lote-10-as-cinco-livres
data: 2026-10-16
---

# Plano — o lote 10: as cinco livres

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido pelo planner em 2026-10-16, 18:16–18:44, no worktree, HEAD `3208161`.

### Onde e como se trabalha

- **Raiz da missão:** o worktree ligado `/home/joruge/repos/sdd_agents-lote-10`, branch
  `fix/lote-10-as-cinco-livres` (renomeada de `fix/lote-10`; cortada de `origin/main` `3208161` com
  `--no-track`; `git rev-parse @{u}` → `no upstream configured`). O checkout principal
  `/home/joruge/repos/sdd_agents` está em `3208161`, limpo (`git -C … status --porcelain` vazio).
- **Todo comando roda como `cd /home/joruge/repos/sdd_agents-lote-10 && …`.** A sessão herda o cwd do
  checkout principal, e nada se escreve lá: um `2>e` relativo do lote 9 criou `?? e` ali (o #281). Rascunho,
  fixture e saída de medição vão para caminho **absoluto** num scratchpad (`mktemp -d` sob o scratchpad da
  sessão, ou o diretório que o relay der), nunca para caminho relativo. Antes de devolver, rode
  `git -C /home/joruge/repos/sdd_agents status --porcelain` → vazio.
- `.sdd/config.sh` do worktree: `HANDOFF_DIR=docs/handoffs`, `OUTPUT_LANG=pt-BR`, `DEFAULT_BRANCH=main`,
  `TODO_FILE=TODO.md`, `JIRA_ENABLED=false`, `ADR_CHECK=block`, `TEST_CMD=tests/run-all.sh`.
- **Execução interativa**, um subagente `sdd-executor` por incremento, nunca `sdd run` do kit. Dentro do
  worktree, `health`, `preflight` e `install` rodam como `./bin/sdd`. Sem `./bin/sdd health` nesta missão
  (decisão do humano no PR #267: só com a catraca zerada).
- **Congelamento D11:** `git diff fec0cca..HEAD -- bin agents templates config` está vazio e tem de seguir
  vazio em todo commit. Esta missão só toca `tests/`, `commands/`, `TODO.md`, `tests/health-baseline.txt`,
  `KAIZEN_LOG.md`, `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` e a pasta da missão.
- **Ferramentas:** `/usr/bin/bash` é o GNU bash 5.2.21; `/usr/bin/grep` é o GNU grep 3.11. O `grep` do zsh é
  o ugrep: meça comportamento de grep sempre no bash ou com `/usr/bin/grep`. No zsh, `echo ====` falha
  (expansão `=`): use `echo '----'`. `shellcheck` está em `/home/joruge/.local/bin/shellcheck`.
- **Antes de cada commit em `tests/`:** `shellcheck -S warning <arquivos tocados>`, `bash tests/check-todo.sh`
  (as âncoras do `TODO.md`: o símbolo designado tem de estar a até 10 linhas da linha ancorada),
  `bash tests/check-lang.sh` (superfície inglesa: prosa nova em `tests/` e `commands/`) e
  `bash tests/check-pipefail.sh`. Nenhum commit com `tests/run-all.sh` vivo.
- **Antes de mexer em item ou seção do `TODO.md`** (mover para decidido, `RESOLVED by`, reancorar), invoque a
  skill `todo-to-github-issues` (ferramenta `Skill`) e siga a forma dela; depois da edição, rode o `--audit`
  dela, que só lê (`python3 ~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py --audit`). Nunca
  `--apply` da branch da missão e nunca mude o título de um item: o título é a chave do espelho.

### `tests/check-checkpoint.sh` (3254 linhas no HEAD)

- `R2_STDOUT_RE` em `:444`: `'[^0-9]2(>>|>[|]|<>|>)[[:blank:]]*(/dev/stdout|/dev/fd/1|/proc/[^[:space:]]+/fd/1)([[:space:];&)|`]|$)'`.
- `r2_merges` em `:463`. O filtro barato em `:467` (`case "$t" in *'>&'* | *'<&'* | *'&>'* | *'2>'* | *'2<>'*)`,
  então todo `2> >(` já passa por ele); o teste da stdout em `:468`
  (`[[ "${t//[\"\']/}" =~ $R2_STDOUT_RE ]] && return 0`, aspas removidas do texto inteiro). O comentário que
  lista as grafias da mescla fica logo acima (`:451–462`). O `t` é `" $1"`: o branco inicial deixa o
  `[^0-9]` ler o índice 0.
- `r2_anchored` em `:753`; em `r2_grep_anchored` (`:917`) a linha `:925` é `lit | dq) r2_anchored "${R2_PV[k]}" || return 1 ;;`.
- `PROBE_FLOOR=398` em `:1659`, `RULE_FLOOR=8` em `:1671`, `rule_ok()` em `:1672`
  (`pass "rule: $1"; RULE_LINES=…`). Os dois pisos são **exatos**, não mínimos: o piso tem de ser igual à
  contagem real. Para ler a contagem real, suba o piso temporariamente e leia a mensagem de piso do
  `--selftest` (`%d probes … expected at least %d`), depois grave o número real.
- `probe <desc> <want_rc> <want_text|-> <fixture>` (roda `--check` no fixture e confere rc e texto),
  `cp_head <f>` e `cp_row <f> <ID> <célula>` montam um checkpoint de uma linha; `mg_merges <0|1> '<texto>'`
  (`:1705`) chama `r2_merges` em processo (0 = mescla) e conta como probe.
- O grupo de probes da mescla (#269) ocupa `:2167–2275` e fecha com
  `rule_ok "every spelling that merges stderr into stdout puts the cell under the anchor rule ($((PROBES - mg_p0)) probe(s))"`.
  O padrão de fixture de captura é
  `cp_row "$mg" I1 "\`o=\$(bash t.sh $mg_g); grep -c 'alpha' <<< \"\$o\"\` → \`1\`"` com
  `probe "…" 1 '0 of 1 pattern(s) anchored' "$mg"`; o de controle espera `0 '0 under the anchor rule'`.
- Saídas no HEAD: `bash tests/check-checkpoint.sh --selftest` → rc 0 e **8** linhas `^  ok    rule:` (o laço
  completo, sem `--selftest`, imprime 9: a do `|` também abre assim); `bash tests/check-checkpoint.sh` leva
  ~13 s e diz `ok    no checkpoint Check reads a red assertion as green (197 cell(s) under the rule, 262 row(s)
  in 31 file(s))` (antes do checkpoint desta missão); com ele, medido às 18:50: `199 cell(s) under the rule,
  266 row(s) in 32 file(s)`.
- Cabeçalho: a frase do `dq` em `:152–156` ("DECLARED, lote 9: …, although the expansion could carry a
  newline or a `\|`."); o parágrafo "DECLARED LIMITS of the merge" em `:166–183`, cuja frase em `:179` termina
  com "The TODO.md item of round 3 lists them with the rest."
- **Reprodução no HEAD** (fixtures no scratchpad, `--check`): a célula
  `` `o=$(bash tests/check-a.sh 2> >(cat)); grep -c 'caso' <<< "$o"` → `1` `` sai
  `ok    ps.md: 1 row(s), 0 under the anchor rule, none blind` (rc 0); a mesma com `2>&1` sai
  `FAIL … 0 of 1 pattern(s) anchored`; a de `grep -c "^  ok    caso$alt"` sai `1 under the anchor rule, none blind`.
- **Bash 5.2.21, medido** (`o=$( { echo OUT; echo ERR >&2; } <grafia> )`): `2> >(cat)`, `2>> >(cat)`,
  `2>| >(cat)`, `2<> >(cat)` e `2>  >(tee /dev/null)` põem `ERR` na captura; `> >(cat)`, `1> >(cat)`,
  `12> >(cat)`, `2> >(cat >/dev/null)` e `2> >(cat >&2)` não; `2>>(cat)` (sem branco) e `"2"> >(cat)` são erro
  de sintaxe (captura vazia).

### `tests/check-hat.sh` (797 linhas) e `commands/sdd-plan.md` (195 linhas)

- O `check-hat.sh` é o único sensor do `commands/sdd-plan.md` (o catálogo de mutação nunca muta
  `commands/*.md`). `pass`/`fail` em `:47–48` (`  ok    ` na stdout, `  FAIL  ` na stderr; sob `SDD_MUTANT` o
  `fail` sai). As funções lêem o arquivo **por seção** com
  `awk '/^## <Título>/{s=1; next} s && /^## /{s=0} s'`: `command_relay_probes` (`:438`, seção "Relaying the
  grill to the human"), `command_worktree_probes` (`:552`, "Before anything else") e
  `command_worktree_return_probes` (`:583`). A lista de chamadas de topo está em `:781–791`.
- `command_worktree_probes` exige, em `:570`, o literal
  `git worktree add ../<repo>-<slug> --no-track -b <branch> origin/<DEFAULT_BRANCH>` (o par "cuts the mission
  branch with --no-track"). O I3 troca `<branch>` por `<provisional>` **nos dois arquivos, no mesmo commit**.
- No HEAD, `bash tests/check-hat.sh` → rc 0, ~2,4 s, **11** linhas `^  ok    command:`.
- **Sabotagem numa cópia, medida:** `git archive HEAD | tar -x -C <dir>` e `bash <dir>/tests/check-hat.sh` → rc 0
  e as 11 linhas; tirar o `--no-track` do `commands/sdd-plan.md` da cópia → rc 1 e
  `FAIL  command: /sdd-plan cuts the mission branch without --no-track, and it tracks the base`. Para sabotar
  o trabalho ainda não commitado, copie a árvore com
  `tar --exclude=./.git -cf - . | tar -xf - -C <dir>` (da raiz do worktree).
- `commands/sdd-plan.md`: passo 2 em `:25–54` (o primeiro sub-item, o do `git worktree add`, em `:33–40`); a
  seção `## Then` em `:70–83` (o primeiro parágrafo, "Delegate to the `sdd-planner` subagent…", em `:72–75`).
  Nenhum outro documento do kit copia o texto do passo 2 (grep em `docs/*.md`, `README.md`, `CLAUDE.md`,
  `CONTEXT.md`, `agents/sdd-planner.md`).
- `ensure_mission_branch` (`bin/sdd:6068`): com a branch de `branch:` inexistente, faz `git checkout -b` a partir
  da atual. Por isso o rename é o que evita sobrar a provisória, não o que faz a missão andar.

### `TODO.md`, catraca e espelho

- `bash tests/check-todo.sh --count TODO.md` → `17`; `tests/health-baseline.txt` traz `todo-findings 17`.
- Os cinco itens: #277 em `:42` ("A regra 2 do check-checkpoint deixa abertos os casos que só o runtime
  decide", âncora `tests/check-checkpoint.sh:444` (`R2_STDOUT_RE`)), #278 em `:50` ("A regra 2 não lê a
  substituição de processo da stderr como mescla", `:463` (`r2_merges`)), #279 em `:57` ("A regra 2 aceita a
  âncora seguida de uma expansão no padrão", `:925` (`r2_anchored`)), #280 em `:118` (`commands/sdd-plan.md:35`
  (`git worktree add`)), #281 em `:126` (`commands/sdd-plan.md:72` (`sdd-planner`)).
- **Registro decidido** (`templates/todo.pt-BR.md`; regra em `tests/check-todo.sh:540–565`): uma linha física,
  sem caixa, `- **<título>** — <o que se decidiu e por quê> — `<ponteiro>` (YYYY-MM-DD)`; o título não leva `*`;
  um span de código depois do título; a data no fim. A largura de 120 vale só para a seção aberta.
- **`RESOLVED by <hash>`:** no fim da última linha do corpo, ou dentro da linha `Fonte:` antes do
  `— descoberto por`; nunca numa linha própria nem depois do descoberto-por. Sem espaço nos 120 caracteres,
  quebre a linha de cima sem mudar palavra (o item tem teto de 8 linhas).
- Item que sai por decisão (sem `RESOLVED by`) vira `ORPHAN … no RESOLVED by` no plano do espelho, e o
  `--close-orphans` o pula: o humano o fecha à mão como `not planned` (Pendências do `00-missao.md`).
- **Corpus da regra 2** (67 checkpoints: 30 do kit e 37 dos alvos — 6 do `lighthouse_project` em `3794fc9`, 31
  do `sales_quote` em `a1ad4b74`): 0 linhas de tabela escrevem `>(` ou qualquer grafia aberta do #277; a forma
  do #279 está só nas Checks da I10 de `20261002-onde-o-comando-do-humano-escreve` e da I20 de
  `20261003-lote-3-a-catraca-desce`.
- **O comando de medição dos alvos** (leitura só; rode em `bash`, da raiz do worktree):

  ```bash
  for f in /home/joruge/repos/lighthouse_project/docs/handoffs/*/checkpoint.md \
           /home/joruge/repos/sales_quote/docs/handoffs/*/checkpoint.md; do
    bash tests/check-checkpoint.sh --check "$f" 2>&1
  done | grep -c 'pattern(s) anchored'
  ```

  Hoje (18:42, sensor do HEAD `3208161`): **106** recusas. O antes se remede no fecho com o sensor da base,
  porque os alvos ganham checkpoints: `d=$(mktemp -d); mkdir -p "$d/tests"; git show
  3208161:tests/check-checkpoint.sh > "$d/tests/check-checkpoint.sh"; cp tests/isolate-git.sh "$d/tests/"` e o
  mesmo laço com `bash "$d/tests/check-checkpoint.sh"` (o sensor precisa do `isolate-git.sh` ao lado).
- **Janela do juiz:** `./bin/sdd kaizen --series` (só lê) às 18:41 → `kit_sha: bad6168`, `missions: 1`.

### Fecho

- `KAIZEN_LOG.md`: a entrada mais nova é a do lote 9, em `:7` (`## 2026-10-16 — Lote 9: o papel de cada
  palavra`), logo abaixo do `---` da `:5`. A nova entra acima dela, com o mesmo molde (**Missão**, **Antes**,
  **Depois**).
- Gaveta (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): a linha F3 do índice (`:18`) termina com
  "os 11 congelados esperam a triagem"; o parágrafo "**Hoje (2026-10-16).**" de § F3 está em `:208–215`.
  "Frente que anda, fecha ou nasce atualiza o índice no mesmo commit" (`CLAUDE.md`).
- `20-handoff-exec.md` sai do `templates/handoff.md`.

## Arquitetura da mudança

Três peças independentes, nenhuma em `bin agents templates config`:

1. **A família da regra 2 fecha (decisão 1).** O `TODO.md` move #277 e #279 para a seção decidida, cada um com
   o evento que o reabre; o cabeçalho do sensor troca o ponteiro "The TODO.md item of round 3" pelo registro
   decidido. Nenhum código do sensor muda.
2. **A substituição de processo é mescla (#278).** Um teste a mais no `r2_merges`, ao lado do
   `R2_STDOUT_RE` e com a mesma leitura (aspas removidas, o `2` depois de nenhum dígito): `2>`, `2>>`, `2>|` ou
   `2<>`, brancos opcionais, e então `>(`. Como o `r2_merges` é a definição única, os três sítios que o chamam
   ganham a grafia juntos. Lado fechado: todo `>(…)` conta, inclusive `>(cat >/dev/null)`, que não mescla.
3. **O `/sdd-plan` (#280, #281).** O passo 2 corta a branch provisória; o `## Then` ganha as duas ordens do
   relay (o rename na decisão do id; o `cd <worktree> &&` e a conferência do checkout principal a cada
   devolução). Os probes ficam no `tests/check-hat.sh`, lidos por seção, como os vizinhos.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia. O "antes" de cada
Check é o que o `tests/check-checkpoint.sh --red` imprimiu no HEAD `3208161`.

### I1 — #277 e #279 para a seção decidida (decisão 1)

**O quê:**
1. Skill `todo-to-github-issues` antes. No `TODO.md`, apague os dois itens abertos (#277, o bloco que abre na
   `:42`; #279, o que abre na `:57`, cada um até a linha em branco) e acrescente ao fim da seção decidida (o fim
   do arquivo) estas duas linhas, **cada uma numa linha física só**, com a data da decisão (2026-10-16), não a
   da sessão:

   ```md
   - **A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide** — decidido sem conserto (decisão 1 do lote 10): um leitor de texto não decide o terceiro descritor, o alvo de runtime (`2>$f`), a grafia da stdout que o sistema resolve, a palavra que abre com expansão lida como operando, o `POSIXLY_CORRECT` ou outro grep, nem o nome que substitui o grep; a peça que mediria a Check em execução não tem dono (no PLAN a asserção ainda não existe, e gate não executa texto de modelo); 0 de 67 checkpoints escrevem uma dessas grafias, e o cabeçalho do sensor as declara; reabre quando uma Check real escrever uma delas — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
   - **A regra 2 aceita a âncora seguida de uma expansão no padrão** — decidido sem conserto (decisão 1 do lote 10), confirmando a decisão 8(a) do lote 9: o padrão `dq` ancora pelo prefixo literal antes da 1ª expansão, limite declarado no cabeçalho do sensor; recusá-lo deixaria vermelha a varredura do kit em 2 checkpoints fechados (a I10 de 20261002-onde-o-comando-do-humano-escreve e a I20 de 20261003-lote-3-a-catraca-desce, cuja expansão é uma contagem da catraca), e nenhum texto prova que a expansão não acrescenta padrão nem alternância; reabre quando uma Check real escrever, depois da âncora, uma expansão que possa trazê-los — `docs/handoffs/20261016-lote-10-as-cinco-livres/00-missao.md` (2026-10-16)
   ```

2. `tests/health-baseline.txt`: `todo-findings 17` → `todo-findings 15`, no mesmo commit.
3. Cabeçalho do `tests/check-checkpoint.sh` (inglês, `check-lang.sh` verde; não cite o slug pt-BR fora de span
   de código — escreva "lote 10"):
   - na `:179`, troque "The TODO.md item of round 3 lists them with the rest." por uma frase com este sentido:
     "They and the rest of round 3's list are DECIDED, not open (lote 10): only the run time decides them, no
     Check of the 67 checkpoints measured writes one, and the decided record of TODO.md reopens them when a
     real Check does.";
   - depois da frase do `dq` que termina na `:155` ("…could carry a newline or a `\|`."), acrescente: "Decided,
     not open (lote 10; Codex on PR #274, round 5): refusing it would redden two closed checkpoints of the kit
     whose expansion is a count, and no text proves an expansion harmless; the decided record of TODO.md
     reopens it when a real Check writes one that could add a pattern."
   Quebre as linhas na largura do cabeçalho (~100 colunas), com `# ` no começo.
4. `bash tests/check-todo.sh` verde (o cabeçalho cresce poucas linhas: o #278 em `:463` (`r2_merges`) tem de
   seguir a até 10 linhas; se sair, reancore-o neste commit). `--audit` da skill sem violação. Commit
   `docs(todo): …` com o porquê no corpo.

**Onde:** `TODO.md`, `tests/health-baseline.txt`, `tests/check-checkpoint.sh` (só comentário).
**Como (TDD):** o Check abaixo roda antes e sai `0 0 17 0`; depois, `1 1 15 1`.
**Check:** `a=$(awk '/<!-- sdd:decided -->/{d=1} d && /^- \*\*A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide\*\* — /{c++} END{print c+0}' TODO.md); b=$(awk '/<!-- sdd:decided -->/{d=1} d && /^- \*\*A regra 2 aceita a âncora seguida de uma expansão no padrão\*\* — /{c++} END{print c+0}' TODO.md); n=$(bash tests/check-todo.sh --count TODO.md 2>/dev/null); k=$(grep -cx 'todo-findings 15' tests/health-baseline.txt); echo "$a $b $n $k"` → `1 1 15 1`
(antes, medido pelo `--red`: `0 0 17 0`).
**Sensor durável:** o `tests/check-todo.sh` (no `TEST_CMD`) mede a forma do registro decidido e a contagem; a
catraca do `sdd health` cobra a baseline. Nenhum probe novo: a mudança é de registro, não de regra.
**Reversível por:** `git revert` do commit (os dois itens voltam abertos e a catraca a 17).

### I2 — a substituição de processo da stderr é mescla (#278)

**O quê:**
1. No `r2_merges`, ao lado do teste do `R2_STDOUT_RE` (`:468`) e sobre o mesmo texto sem aspas, leia como mescla
   `2>`, `2>>`, `2>|` ou `2<>` (o `2` depois de nenhum dígito) seguidos de brancos opcionais e de `>(`. Uma forma
   que basta: uma regex nova junto às vizinhas, `R2_PROCSUB_RE='[^0-9]2(>>|>[|]|<>|>)[[:blank:]]*>[(]'`, e
   `[[ "${t//[\"\']/}" =~ $R2_PROCSUB_RE ]] && return 0`. Acrescente a grafia à lista do comentário do
   `r2_merges` (`:451–462`) e ao parágrafo "DECLARED LIMITS of the merge" do cabeçalho: `2> >(…)` mescla
   porque o processo escreve onde a stdout do shell estava, a captura inclusive (Codex no PR #274, rodada 5,
   medido no bash 5.2.21), e todo `>(…)` conta, mesmo o que não mescla (`>(cat >/dev/null)`, `>(cat >&2)`):
   lado FECHADO.
2. Um grupo de probes novo no `selftest`, logo depois do `rule_ok` da mescla (`:2275`), com contador próprio
   (`ps_p0="$PROBES"`, `ps_f0="$FAILS"`), no molde do grupo da mescla:
   - **mesclam** (captura, `probe … 1 '0 of 1 pattern(s) anchored'`): `2> >(cat)`, `2>> >(cat)`, `2<> >(cat)`,
     `2>  >(tee x)` e, do lado fechado, `2> >(cat >/dev/null)` e `2>>(cat)`;
   - **a célula vai à regra da célula** (`bash t.sh 2> >(cat); grep -c 'alpha' f` → `1`): rc 1;
   - **a âncora segura** (`o=$(bash t.sh 2> >(cat)); grep -c '^  ok    alpha' <<< "$o"` → `1`): rc 0 e
     `1 under the anchor rule` (use `${OK_ANCHOR}` como os vizinhos);
   - **em processo** (o `|` parte a linha na regra 1): `mg_merges 0 'o=$(bash t.sh 2>| >(cat))'`;
   - **controles** (`probe … 0 '0 under the anchor rule'`): `> >(cat)`, `1> >(cat)`, `12> >(cat)` e
     `2>/dev/null >(cat)` (aqui o `>(cat)` é argumento, e a stderr vai para o null).
   Feche com `[ "$FAILS" -eq "$ps_f0" ] && rule_ok "a process substitution that takes stderr counts as a merge ($((PROBES - ps_p0)) probe(s))"`.
   A frase depois de `rule: ` fica numa linha física só.
3. `RULE_FLOOR` 8 → 9; `PROBE_FLOOR` 398 → a contagem real (exata).
4. Sabotagem antes do commit, numa cópia no scratchpad (`tar --exclude=./.git …`, § Contexto), cada degradação
   ancorada em código e com a contagem de ocorrências conferida antes (o probe de sabotagem prova primeiro que
   sabotou o que dizia sabotar): sem o `>>`, sem o `>[|]`, sem o `<>`, sem o `[[:blank:]]*`, `[^0-9]` → nada,
   `>[(]` → `[(]`, o teste novo apagado, o `rule_ok` apagado, o piso baixado. Cada uma tem de deixar o
   `bash <cópia>/tests/check-checkpoint.sh --selftest` vermelho (rc 90/91/92). Sobrevivente vira probe.
   Anote o placar no `checkpoint-notas.md`.
5. Regressão: o comando de medição dos alvos segue em **106** (§ Contexto; anote a hora e os shas dos alvos), e a
   varredura do kit segue limpa.
6. `bash tests/check-todo.sh`: o `r2_merges` foi editado, então confira a âncora do #278 (`:463` (`r2_merges`));
   reancore neste commit se ela saiu dos 10. `shellcheck -S warning tests/check-checkpoint.sh`. Commit
   `fix(tests): …`.

**Onde:** `tests/check-checkpoint.sh` (e `TODO.md` só se a âncora do #278 precisar).
**Como (TDD):** os probes primeiro; no HEAD os seis "mesclam" e o da regra da célula falham (rc 0 com `0 under`),
os controles e o da âncora passam. Depois, o teste no `r2_merges`.
**Check:** `o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: a process substitution that takes stderr counts as a merge' <<< "$o"` → `1`
(antes, medido pelo `--red`: `0`).
**Sensor durável:** os probes no `selftest` do próprio sensor, que roda no `TEST_CMD`; `RULE_FLOOR` e
`PROBE_FLOOR` exatos seguram a remoção de um probe ou do `rule_ok`.
**Reversível por:** `git revert` do commit.

### I3 — o `/sdd-plan` corta uma branch provisória e mantém o planner fora do checkout principal (#280, #281)

**O quê:**
1. `commands/sdd-plan.md`, passo 2, primeiro sub-item (`:33–40`): o worktree nasce **numa branch
   provisória** cortada da `origin/<DEFAULT_BRANCH>`, e o comando passa a ser
   `git worktree add ../<repo>-<slug> --no-track -b <provisional> origin/<DEFAULT_BRANCH>`. Diga por quê (o id da
   missão, e com ele o nome que `branch:` declara, sai do grill, e o worktree tem de existir antes de o grill
   escrever qualquer coisa), que o diretório mantém o nome provisório, e que o planner renomeia a branch na
   decisão do id (ver *Then*). "or reuse it, when it already exists on that branch" passa a "…when it already
   exists for this mission". O resto do sub-item (o `git pull`, o `--no-track` medido) fica.
2. `## Then`, depois do primeiro parágrafo (`:72–75`): quando o passo 2 moveu a sessão, o relay passa ao planner
   duas ordens e o segura nelas:
   - **a branch:** na decisão do id o planner renomeia a branch no worktree com
     `git branch -m <provisional> <branch>`, enquanto a branch não tem upstream, e escreve esse nome em
     `branch:` (medido nos lotes 9 e 10: `fix/lote-N` renomeada sem atrito; o `sdd approve` encontra a branch
     que lê);
   - **o diretório de trabalho:** o planner herda o cwd desta sessão, que é o checkout principal; ele roda todo
     comando como `cd <worktree> && …` e escreve rascunho só em caminho absoluto fora do checkout principal.
     Antes de delegar, o relay registra `git -C <main checkout> status --porcelain` e
     `git -C <main checkout> rev-parse HEAD`; a cada devolução roda os dois de novo, antes de repassar a
     pergunta; se algum mudou, para, mostra ao humano os caminhos e o HEAD que mudaram, e nunca apaga nem
     reseta nada ali por conta própria (um caminho daquele checkout pode ser de outro escritor). Medido no
     lote 9: um `2>e` relativo do planner deixou `?? e` no checkout principal às 08:02, e um `sdd run` de alvo
     em voo teria parado com `KIT-TOUCHED` (rc 3).
   Prosa em inglês (`check-lang.sh`). **Cada um destes literais fica numa linha física só**, porque o probe os lê
   com `grep -F`: no passo 2, `on a provisional branch`, `the directory keeps its provisional name` e
   `git worktree add ../<repo>-<slug> --no-track -b <provisional> origin/<DEFAULT_BRANCH>`; no *Then*,
   `git branch -m <provisional> <branch>`, `while the branch has no upstream`, `cd <worktree> &&`,
   `git -C <main checkout> status --porcelain`, `git -C <main checkout> rev-parse HEAD`, `at every hand-back` e
   `never delete or reset anything there yourself`.
3. `tests/check-hat.sh`:
   - em `:570`, o literal do par `--no-track` passa a
     `git worktree add ../<repo>-<slug> --no-track -b <provisional> origin/<DEFAULT_BRANCH>`;
   - uma função nova (por exemplo `command_branch_cwd_probes`), com comentário que nomeia o #280, o #281 e a
     medida do lote 9, lendo a seção "Before anything else" e a seção "Then" pelo `awk` dos vizinhos (variáveis
     com nome que não seja palavra reservada: nada de `then=`), com **dois** pares `pass`/`fail`:
     - #280: `on a provisional branch` e `the directory keeps its provisional name` em "Before anything else", e
       `git branch -m <provisional> <branch>` e `while the branch has no upstream` em "Then" →
       `pass "command: /sdd-plan cuts a provisional branch and has the planner rename it when the grill decides the id"`;
     - #281: `cd <worktree> &&`, `git -C <main checkout> status --porcelain`,
       `git -C <main checkout> rev-parse HEAD`, `at every hand-back` e
       `never delete or reset anything there yourself` em "Then" →
       `pass "command: /sdd-plan keeps the planner out of the main checkout and compares that checkout at every hand-back"`;
     cada `fail` diz o que falta, no molde dos vizinhos;
   - a chamada da função nova na lista de topo (`:781–791`), depois de `command_worktree_return_probes`.
4. Sabotagem antes do commit, numa cópia (`tar --exclude=./.git …`): apagar cada um dos nove literais acima do
   `commands/sdd-plan.md` da cópia (um por vez) e mover o parágrafo do *Then* para outra seção; cada uma tem de
   dar rc 1 com o `FAIL` do par certo. Anote o placar no `checkpoint-notas.md`.
5. `bash tests/check-todo.sh`: as âncoras do #280 (`commands/sdd-plan.md:35` (`git worktree add`)) e do #281
   (`:72` (`sdd-planner`)) seguem a até 10 linhas, ou são reancoradas neste commit. `bash tests/check-lang.sh`,
   `shellcheck -S warning tests/check-hat.sh`. Commit `docs(sdd-plan): …`.

**Onde:** `commands/sdd-plan.md`, `tests/check-hat.sh` (e `TODO.md` só para reancorar).
**Como (TDD):** a função de probes primeiro, com os literais novos: o `check-hat.sh` sai rc 1 nos dois pares (e no
par `--no-track`, que passou a ler `<provisional>`); depois a prosa.
**Check:** `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    command: /sdd-plan cuts a provisional branch and has the planner rename it' <<< "$o"); b=$(grep -c '^  ok    command: /sdd-plan keeps the planner out of the main checkout' <<< "$o"); echo "$a $b"` → `1 1`
(antes, medido pelo `--red`: `0 0`).
**Sensor durável:** os dois pares no `tests/check-hat.sh`, que roda no `TEST_CMD` e lê por seção. O catálogo de
mutação não alcança `commands/*.md`, então os probes são o sensor inteiro (limite já declarado nos vizinhos).
**Reversível por:** `git revert` do commit.

### I4 — fecho: `RESOLVED by`, `KAIZEN_LOG.md`, gaveta, handoff e a suíte

**O quê:**
1. Skill `todo-to-github-issues` antes. `RESOLVED by <hash>` no #278 (o hash do commit do I2) e no #280 e no #281
   (o do I3), no lugar que a skill manda; `--audit` sem violação; `bash tests/check-todo.sh` verde. A contagem
   segue **15** (item com `RESOLVED by` continua aberto até o chore).
2. A medida final, com o sensor da base (`3208161`) e o do HEAD sobre o mesmo corpus, na mesma hora (§ Contexto):
   a previsão é **106 → 106**; anote os shas dos alvos e a hora. A varredura do kit (`bash
   tests/check-checkpoint.sh`) segue limpa, agora com o checkpoint desta missão. Conte as linhas
   `^  ok    command:` do `check-hat.sh` (11 → 13) e as `^  ok    rule:` do `check-checkpoint.sh --selftest`
   (8 → 9).
3. `KAIZEN_LOG.md`: entrada nova no topo (acima da do lote 9), título `## <data de date> — Lote 10: as cinco livres`,
   citando o id inteiro `20261016-lote-10-as-cinco-livres`, no molde **Missão / Antes / Depois**: a família da
   regra 2 (6 rodadas do Codex no PR #267 segundo o K3 do lote 9, 5 rodadas e 7 P2 no PR #274; o sensor de 1811
   para 3254 linhas e de 128 para 398 probes no lote 9; 0 de 67 checkpoints com uma grafia aberta), o critério
   que a fecha (uma Check real no corpus; decisões 1 e 5), o #278 (0 de 5 → 5 de 5 grafias, 106 → 106 nos alvos),
   o `/sdd-plan` (11 → 13 linhas `command:`), e a catraca (17 → 15 na branch, 12 depois do chore). Todo número
   remedido no fecho, nunca copiado daqui.
4. Gaveta, no mesmo commit: a linha F3 do índice (`:18`) diz que o lote 10 levou as cinco livres sem partir a
   janela e que 12 congelados esperam a triagem; o § F3 ganha um parágrafo "**Hoje (<data>).**" com a leitura do
   `./bin/sdd kaizen --series` do dia (`kit_sha`, `missions`) e o mesmo resumo.
5. `docs/handoffs/20261016-lote-10-as-cinco-livres/20-handoff-exec.md` a partir do `templates/handoff.md`: o que cada
   incremento fez, os números, o que ficou para o humano (as Pendências do `00-missao.md`).
6. A suíte inteira: `tests/run-all.sh` em background, esperando a última linha (≈10 min), verde; anote a linha
   final. `git diff fec0cca..HEAD -- bin agents templates config` vazio. Commits `docs(todo): …` e
   `docs(kaizen): …` (ou um só), com o porquê.

**Onde:** `TODO.md`, `KAIZEN_LOG.md`, a gaveta, a pasta da missão.
**Como (TDD):** o Check abaixo sai `0 1 0 1` no HEAD e `1 0 3 0` depois.
**Check:** `a=$(grep -c '^## [0-9-]* — Lote 10: as cinco livres$' KAIZEN_LOG.md); b=$(grep -q '20261016-lote-10-as-cinco-livres' KAIZEN_LOG.md; echo $?); c=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/{n++} END{print n+0}' TODO.md); d=$(test -f docs/handoffs/20261016-lote-10-as-cinco-livres/20-handoff-exec.md; echo $?); echo "$a $b $c $d"` → `1 0 3 0`
(antes, medido pelo `--red`: `0 1 0 1`).
**Sensor durável:** o `tests/check-todo.sh` mede a forma do `RESOLVED by`; a suíte inteira no fecho; o espelho e a
catraca no chore pós-merge.
**Reversível por:** `git revert` dos commits do fecho.

### O `TODO.md` — as âncoras que os incrementos movem

O `tests/check-todo.sh` (no `TEST_CMD`) reprova a âncora cujo símbolo designado sai a mais de 10 linhas. Nesta
missão:

| Incremento | Edita ou desloca | Item que pode precisar reancorar |
|---|---|---|
| I1 | o cabeçalho do `check-checkpoint.sh` (+2 a +4 linhas) e o próprio `TODO.md` | #278 (`:463` (`r2_merges`)); os outros dois do arquivo saem do aberto |
| I2 | `r2_merges` (editado), uma regex nova perto da `:444`, o comentário e os probes | #278, que designa o `r2_merges` editado: reancore no commit do I2 se sair dos 10 |
| I3 | o passo 2 e o *Then* do `commands/sdd-plan.md` | #280 (`:35` (`git worktree add`)) e #281 (`:72` (`sdd-planner`)) |
| I4 | só o `TODO.md` (o `RESOLVED by`) | nenhum |

Nenhum outro item aberto ancora em `tests/check-checkpoint.sh`, `tests/check-hat.sh` ou `commands/sdd-plan.md`
(os congelados ancoram em `bin/`, `templates/`, `agents/` e `docs/pipeline.md`).

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A revisão do PR acha outra grafia da regra 2 | alta (toda rodada do lote 9 achou) | decisão 5: no modelo do #278 conserta; fora dele vai ao cabeçalho, sem item; da 4ª rodada em diante, `TODO.md` e o humano decide |
| A regex nova recusa células reais dos alvos | baixa (0 de 67 checkpoints escrevem `>(`) | a medida de regressão (106 → 106) no I2 e no fecho |
| O planner de um alvo segue o passo 2 velho até o pull | média | Pendência 3: o pull ocioso do checkout principal depois do merge |
| Um literal do probe quebra em duas linhas físicas | média | o I3 lista os nove literais; o `check-hat.sh` fica vermelho e nomeia o par |
| O executor escreve no checkout principal | baixa | todo comando com `cd /home/joruge/repos/sdd_agents-lote-10 &&`; o relay confere `git -C /home/joruge/repos/sdd_agents status --porcelain` a cada devolução |

## Verificação end-to-end

Com I1–I4 `done`, na raiz do worktree:

1. `bash tests/check-checkpoint.sh --check docs/handoffs/20261016-lote-10-as-cinco-livres/checkpoint.md` → rc 0.
2. Os quatro Checks do `checkpoint.md` dão o esperado (`1 1 15 1`, `1`, `1 1`, `1 0 3 0`).
3. `tests/run-all.sh` verde (a última linha), `git diff fec0cca..HEAD -- bin agents templates config` vazio,
   `git -C /home/joruge/repos/sdd_agents status --porcelain` vazio.
4. O comando de medição dos alvos dá 106 com o sensor da base e com o do HEAD, na mesma hora.
5. `./bin/sdd kaizen --series` segue em `bad6168` (o PR não parte a janela).

## Teste de autocontenção

Uma sessão nova lendo só os três arquivos executa o I1: sabe onde rodar (o worktree, com `cd … &&`), que tem de
consultar a skill antes de tocar o `TODO.md`, quais blocos apagar (linhas 42 e 57, pelos títulos), o texto exato
das duas linhas decididas, a troca da baseline, as duas frases do cabeçalho (linhas 155 e 179), os sensores a rodar
antes do commit e o Check com o seu "antes". O I2 traz a regex sugerida, os probes com os textos de rc, os pisos e a
sabotagem; o I3, os nove literais e o literal que muda no probe vizinho; o I4, os números a remedir e onde
escrevê-los.
