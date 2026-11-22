---
missao: 20261121-l4-preflight-health-e-sensores
data: 2026-11-21
---

# Plano — L4: preflight, health e sensores

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-21, no commit `a0004df`, no worktree `/home/joruge/repos/sdd_agents-l4`. **A base
vai ter andado quando você ler isto** (pendência 1 do `00-missao.md`: o L3 mergeia antes, e a
`main` entra neste branch). Todo número de linha abaixo é pista, nunca instrução: ache cada trecho
pelo `grep` do nome da função ou da frase que o incremento dá. Ao lado de cada contagem está o
comando que a mediu.

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit (`git rev-parse --git-dir --git-common-dir` →
  `/home/joruge/repos/sdd_agents/.git/worktrees/sdd_agents-l4` e `/home/joruge/repos/sdd_agents/.git`).
  O `sdd` do PATH é o do checkout principal (`/home/joruge/repos/sdd_agents`), com o runner de
  **antes** deste lote: é ele que julga os gates desta corrida. O `./bin/sdd` é o deste worktree,
  com o que você escreveu. **Nunca escreva, commite ou entre no checkout principal**: a guarda de
  kit de toda corrida da máquina compara o `HEAD` e o `git status` dele.
- Quem espelha um chapéu é **`./bin/sdd install --force`**, com o `./`. `.claude/agents/` é
  rastreado aqui, então o espelho entra no mesmo commit do chapéu (só o I9 edita um chapéu). Nunca
  `cp`, nunca `Edit`/`Write` em `.claude/`. Se o comando responder `CHECKOUT-BUSY` (rc 75), não
  contorne: anote o comando, o rc e a saída nas notas, marque `blocked` e pare.
- Config (`grep -v '^#' .sdd/config.sh`): `DEFAULT_BRANCH="main"`, `TEST_CMD="tests/run-all.sh"`,
  `HANDOFF_DIR="docs/handoffs"`, `TODO_FILE="TODO.md"`, `JIRA_ENABLED=false`, `OUTPUT_LANG="pt-BR"`,
  `ADR_CHECK="block"`, `READ_EXTRA` com a entrada do `codereview`. A linha
  `EFFORT_EXEC="${EFFORT_EXEC:-medium}"` não é sua: não mexa nela.
- Não há ADR nesta missão (`adr: none`, decisão 8). Não rode `sdd adr new`.

**A suíte, os sensores e os mutantes**

- `TEST_CMD` é `tests/run-all.sh` (8 a 15 min). A chamada `Bash` do harness para de esperar aos
  120 s por padrão e 600 s no máximo: rode a suíte com o `timeout` da chamada em 600000 ms, ou
  destacada com a saída num arquivo. Use o sensor sozinho para o Red e o Green; a suíte inteira
  fica para antes do commit.
- Tempo de cada sensor sozinho em `a0004df`, com outra suíte rodando na máquina
  (`/usr/bin/time -f '%es' bash tests/<sensor>.sh`): `check-preflight.sh` 55 s, `check-checkpoint.sh`
  20 s, `check-todo.sh` 5 s, `check-hat.sh` 5 s. `check-kaizen.sh`, `check-dry-run.sh` e
  `check-health.sh` não foram medidos sozinhos: os oito Checks de I6 a I13, que os rodam uma vez
  cada e o `check-preflight.sh` três vezes, levaram 5 min 7 s juntos ("O vermelho medido", no fim).
- Todo sensor imprime `  ok    <frase>` na stdout e `  FAIL  <frase>` na stderr. Os ajudantes de
  cada um (`grep -n '^pass()\|^fail()\|^assert_[a-z_]*()' tests/<sensor>.sh`):
  - `tests/check-preflight.sh` (2 652 linhas): `pass "<frase>"`, `fail "<frase>" "<esperado>" "<obtido>"`,
    `assert_eq "<frase>" "<esperado>" "<obtido>"`, `assert_has`, `assert_lacks`. O `claude` é um
    stub; o stream saudável da sonda do `Bash` é o **stub A** (`grep -n 'stub A' tests/check-preflight.sh`
    → `:442`, `:923`), e as linhas reais de resultado moram em `$FIX/.stub/result-real.jsonl`
    (`:313`). Mundos que você reusa: `kp_world` (`:859`, uma **cópia do kit** num diretório próprio,
    rodada pelo `bin/sdd` da cópia), `rx_skill`/`rx_run`/`rx_where`/`rx_broken` (`:1513` a `:1824`,
    as skills sob um `SDD_SKILLS_ROOT` de fixture, com e sem `READ_EXTRA`), `todo_lint_case`
    (`:1383`, o `TODO.md` do fixture com um achado malformado), `seed_lang` (`:2122`, o `install`
    sobre `OUTPUT_LANG`), `failed_count` (`:1024`).
  - `tests/check-kaizen.sh`: `pass`, `fail`, `assert_eq`. Os stubs de sessão do juiz que **escrevem
    artefato** estão em `grep -n 'stub/claude' tests/check-kaizen.sh` (`:1156`, `:1186`, `:1817`);
    `dead_stub` e `loud_stub` em `:1046`. O ledger da corrida é `$LEDGER`/`SDD_STATE_DIR`.
  - `tests/check-autonomy.sh`: o molde das portas do chapéu está em
    `grep -n 'hat: door\|hat_rows()' tests/check-autonomy.sh` (`:5660`, `:5736`, `:5832`): roda o
    `sdd run` com um stub que escreve fora do `writes:`, e lê o rc e
    `jq -r -s '[.[] | select(.event == "blocked") | .kind] | join(",")' "$LEDGER"`.
  - `tests/check-checkpoint.sh`: regra nova imprime por `rule_ok "<texto>"` → `  ok    rule: <texto>`
    (`:1795`; `RULE_FLOOR=10` conta essas linhas e sobe com a regra nova,
    `grep -n 'RULE_FLOOR=' tests/check-checkpoint.sh`), e os probes são `probe <desc> <rc> <texto|-> <alvo> [modo]` (`:1797`), com
    `cp_head`/`cp_row` para montar um checkpoint (`:1848`, `:1855`). A varredura de um arquivo é
    `scan_file` (`:1295`), o `--check` é `check_one` (`:1573`), os contadores são `V_ANCHOR`,
    `V_COLS`, `V_IGNORED`, `V_ORDER` (`reset_counters`, `:1290`).
  - `tests/check-todo.sh`: uma linha `  ok    rule: <texto> (N probe(s))` por regra, entre
    `rule_begin` e `rule_end <piso> <texto>` (`:873`, `:874`); `RULES_FLOOR=14` conta as regras
    reportadas (`grep -n 'RULES_FLOOR=' tests/check-todo.sh`) e sobe a 15 com a regra nova. Os
    probes de `--baseline` usam `baseline_says <rc> <substring> <label> <args>` sobre o repositório
    `$box/baselinerepo` (`:2216` a `:2277`). A regra 7 (o `#N` solto) mora no `todo_awk`
    (`grep -n 'a bare #' tests/check-todo.sh` → `:807`) e está descrita no cabeçalho (`:60` a `:70`).
  - `tests/check-hat.sh`: `pass`/`fail` levam **um** argumento. As famílias são funções
    `*_probes()` chamadas numa lista no fim do arquivo; família nova entra nessa lista.
  - `tests/check-templates.sh`: `check <arquivo> <regex> <descrição>` imprime
    `  ok    <arquivo>: <descrição>`. É o único sensor em que um literal em português pode morar.
  - `tests/check-dry-run.sh`: `pass "<frase>"` (`:51`).
- **Toda frase que uma asserção lê cabe numa linha física.** As 41 frases dos incrementos abaixo
  são **exatas**: os Checks do `checkpoint.md` as leem byte a byte. Não as reescreva, nem para
  corrigir estilo.
- **Mutante novo são duas coisas** em `tests/check-mutation.sh` (`grep -c '^mut_' tests/check-mutation.sh`
  → `926` em `a0004df`): a função `mut_<slug>() { … }`, que aplica um `sed -i` em `"$1"` (a cópia do
  `bin/sdd`), endereçado à função alvo (`sed -i '/^cmd_preflight() {/,/^}/ s|…|…|' "$1"`; veja
  `mut_PRE_template_outcome_default_green`, `:2833`), e o `<slug>` na lista do catálogo
  (`grep -n '^  PRE_template_outcome_default_green$' tests/check-mutation.sh` → `:7962`). Prove
  cada um antes do commit: `bash tests/check-mutation.sh --only <slug> tests/<sensor>.sh` → rc 0
  (pego). **Mutante que o `--only` não pega significa que a asserção não mede**: conserte a
  asserção, nunca o mutante. O `--anchors` (`bash tests/check-mutation.sh --anchors`, segundos)
  roda na suíte e reprova o mutante que não se aplica. O catálogo inteiro (`./bin/sdd health`)
  **não roda** nesta missão.
- **O catálogo só sabota o `bin/sdd`.** Três incrementos mudam sensores que ele não alcança
  (I10 `check-checkpoint.sh`, I11 `check-health.sh`, I12 `check-todo.sh`): ali a prova é a
  **sabotagem à mão**, anotada nas notas. Degrade a regra nova para uma versão frouxa numa cópia do
  sensor fora do worktree, rode o selftest da cópia e exija vermelho; o probe prova primeiro que
  sabotou o que dizia sabotar (ancore em código, e morra alto se o trecho não mudou). Devolva o
  arquivo com `cp` do original, nunca com `mv`.
- Antes de cada commit em `bin/` ou `tests/`: `bash -n bin/sdd`, `shellcheck -S warning` nos
  arquivos tocados (`shellcheck --version` → `0.10.0`, em `~/.local/bin`; a superfície sai limpa em
  `a0004df`: `shellcheck -S warning bin/sdd bin/sdd-worker bin/sdd-link-agents tests/*.sh` → rc 0,
  nenhuma linha) e `bash tests/check-lang.sh` (a superfície do kit é inglês).
- **Nenhum sensor novo nasce neste lote.** Não mexa em `LINT_FLOOR`, no piso do `check-pipefail.sh`
  nem no `CALIBRATE_FLOOR`.

**Armadilhas do `bin/sdd` que este lote pisa**

- O arquivo roda sob `set -euo pipefail`: `x="$(cmd)"` mata o processo na atribuição quando `cmd`
  devolve não-zero. Toda captura nova leva `|| true`, `|| rc=$?` ou `if x="$(…)"; then`. O
  `tests/check-health.sh` cobra isso na região do `sdd health` (regra `guard:`).
- Função lida como `x="$(f)"` roda num subshell: atribuição a global dentro dela morre. Função que
  **publica** global é **chamada**, nunca substituída. Um `die` dentro de `$( )` só encerra o
  subshell.
- `printf … | grep -q` devolve 141 sob `pipefail` quando o grep acha: use herestring.
- O `awk` é o `mawk`, orientado a byte: classe negada só com ASCII; para literal use `index()`.
- Comentário `#` dentro de um bloco continuado por `\` quebra o comando em silêncio.
- `cd` com operando relativo dentro de `$( )` leva `CDPATH=''`.
- A lista que pode ser vazia chega a um comando por `${lista[@]+"${lista[@]}"}` (bash 4.0 a 4.3).
- `_fail`, `ok`, `warn`, `dim`, `bad` e `die` são as vozes do runner; dentro do `cmd_preflight`,
  `_fail` soma em `fails` e `warn` não.

**O `cmd_preflight` de hoje** (`grep -n '^cmd_preflight()' bin/sdd` → `:6547`)

- A sonda do `Bash` (`grep -n 'sdd-preflight-ok' bin/sdd` → `:6670`, `:6690`) roda com
  `--setting-sources "user,project,local"`, o chapéu do executor, e guarda o stream em
  `probe_stream`. Lê a linha `init` (`probe_init`, `.tools`), a resposta (`probe_answer`, o
  `.result`) e a linha `result` (`probe_result`). O braço `ok` é
  `grep -q 'sdd-preflight-ok' <<< "$probe_answer"`, e a mensagem dele afirma "Bash in the tool
  list" mesmo com `probe_init` vazio.
- **Um stream real dessa sonda, capturado no planejamento** (Claude Code 2.1.327, o mesmo comando
  do runner com `--agent sdd-executor`, rc 0, 15 linhas, US$ 0,018). A ordem dos tipos de linha
  (`jq -r '.type + " " + (.subtype // "")' <stream>`): 3 `system hook_started`, 3 `system
  hook_response`, `system init`, 2 `system thinking_tokens`, `assistant` (thinking), `assistant`
  (tool_use), `rate_limit_event`, `user` (tool_result), `assistant` (text), `result success`. As
  duas linhas que o I2 lê, dentro de `.message.content[]`, com o id trocado:
  `{"type":"tool_use","id":"toolu_X","name":"Bash","input":{"command":"bash -c 'echo sdd-preflight-ok'","description":"…"}}`
  na linha `assistant`, e
  `{"type":"tool_result","tool_use_id":"toolu_X","content":"sdd-preflight-ok","is_error":false}`
  na linha `user` (o `content` é string aqui; a sonda dos templates já trata string e lista, em
  `grep -n 'tool_result' bin/sdd` → `:6742` a `:6824`: copie de lá o casamento por `tool_use_id`).
  A linha `result` trouxe `"result":"sdd-preflight-ok"`, `"num_turns":2` e `permission_denials` vazio.
- **Os hooks no mesmo stream** (`jq -c 'select(.subtype=="hook_response") | {hook_event, hook_name, exit_code, outcome, out:(.output|length)}' <stream>`):
  três linhas `{"hook_event":"SessionStart","hook_name":"SessionStart:startup","exit_code":0,"outcome":"success","out":N}`,
  com `N` igual a 3604, 0 e 0. As chaves de uma `hook_response`: `exit_code, hook_event, hook_id,
  hook_name, outcome, output, session_id, stderr, stdout, subtype, type, uuid`. O `hook_name` é o
  mesmo nos três: para nomear o que falhou, use o `hook_name` e a primeira linha do `stderr`.
- **As skills na linha `init`** (`jq -c 'select(.subtype=="init") | [.skills[] | select(test("codereview|ticket|qa-"))]' <stream>`):
  `["qa-execution","qa-report","ticket","codereview:coderabbit-pr","codereview:codereview"]`, de
  134 nomes. É a grafia em que as fases chamam, a mesma da lista `wanted` do preflight
  (`grep -n 'local -a wanted=' bin/sdd` → `:7003`).
- **Fixture que imita o harness é copiado da fonte.** As formas acima são a fonte: o comentário de
  proveniência do stub novo cita "captured at PLAN, 2026-11-21, Claude Code 2.1.327, mission
  20261121-l4-preflight-health-e-sensores". O stream inteiro **não** entra no repositório: ele
  carrega caminhos, plugins e a saída de um hook da máquina do dono, e o repositório é público.
- O bloco das skills (`grep -n 'third-party skills the phases boot' bin/sdd` → `:6988`): monta
  `wanted`, chama `skill_findable` (`:5830`, publica `SKILL_FOUND_DIR` e `SKILL_BROKEN_WHY`),
  `read_rules_cover` (`:5877`), `read_extra_dir_ok` (`:5453`) e `skill_read_entry` (`:5894`), e
  imprime quatro avisos e o `ok "third-party skills present (…)"`. `skills_root` é
  `${SDD_SKILLS_ROOT:-$HOME/.claude}` (`:6993` e `:5831`).
- O `TEST_CMD` roda por `run_check_cmd "$TEST_CMD" "preflight-test"` (`:6936`; a função em `:893`,
  que executa `( cd "$REPO_ROOT" && eval "$cmd" ) </dev/null >"$logfile" 2>&1`).
- A árvore suja (`grep -n 'working tree dirty — the pipeline' bin/sdd` → `:7166`): um
  `git status --porcelain` e uma frase, sem caminho nenhum.

**Reproduções feitas no planejamento**

- **O pipe quebrado (item 12).** As funções reais (`read_extra_each`, `read_extra_dir_ok`,
  `kit_template_rules`, `dir_read_rules`, `kit_read_rules`, `read_rules_cover`), extraídas do
  `bin/sdd` por `awk` e avaliadas num `bash` com `trap '' PIPE` e uma `READ_EXTRA` de 400 entradas:
  20 chamadas de `read_rules_cover "$SDD_HOME/templates/x"` deixaram 102 linhas
  `printf: erro de escrita: Pipe quebrado` na stderr. A causa: `read_rules_cover` sai do `while`
  no primeiro casamento (`return 0`) e o `kit_read_rules`, do outro lado de `< <(…)`, segue
  escrevendo. Com poucas entradas a corrida quase nunca perde; com 400, sempre. A mensagem sai no
  idioma do locale: o probe conta linhas com `printf: ` sob `LC_ALL=C`, nunca o texto traduzido.
- **A marca de ambiente (item 3).** `( SDD_CHECK_TAG=l4probe bash -c 'sleep 20 & disown' )` e,
  depois, `grep -lsa "SDD_CHECK_TAG=l4probe" /proc/[0-9]*/environ` → um arquivo, o do `sleep`, e
  `cat /proc/<pid>/comm` → `sleep`. O processo que sobra herda o ambiente do comando, e o
  `/proc/<pid>/environ` de um processo do mesmo usuário se lê.
- **O preâmbulo (item 10).** `git log --oneline --follow -- templates/todo.pt-BR.md` → 10 revisões
  (9 para `templates/todo.md`). O trecho até o marcador
  (`git show "<rev>:templates/todo.pt-BR.md"`, cortado por `sed '/^<!-- sdd:open -->/q'`, por
  `git hash-object --stdin`) dá 10 hashes distintos. No zsh, escreva `"${rev}:templates/…"` com as
  chaves: `$rev:t…` vira o modificador `:t`. O `TODO.md` do próprio kit tem preâmbulo de autor:
  o `diff` do trecho dele contra o do `templates/todo.pt-BR.md` de hoje dá 13 linhas de um lado e
  61 do outro, e ele **não** deve avisar.
- **O `PR #N` (item 9).** Os 9 números distintos citados como `PR #N` solto na seção aberta do
  `TODO.md` têm todos um commit com `#N` no assunto (`git log --format=%s origin/main` contra cada
  número → 0 sem rastro). `git rev-parse --is-shallow-repository` → `false`.
- **O censo das portas** (`CLAUDE.md`, princípio 5): `grep -cE '^[a-z_]+_escalation\(\) \{' bin/sdd`
  → `5`; `grep -cE '^ +if [a-z_]+_escalation "\$phase"; then' bin/sdd` → `13`;
  `grep -cE '^ *kit_guard_check "' bin/sdd` → `4`; `grep -cE '^ *hat_guard_check "' bin/sdd` → `4`.
  O I9 leva o segundo a `15` e o quarto a `6`.
- **O kit não tem `origin/HEAD`** no checkout principal
  (`git -C /home/joruge/repos/sdd_agents symbolic-ref refs/remotes/origin/HEAD` → `fatal: ref
  refs/remotes/origin/HEAD is not a symbolic ref`). O `cmd_install` já tem o recuo para
  `origin/main` e `origin/master` (`grep -n 'origin/HEAD' bin/sdd` → `:6169` a `:6235`).
- **Nenhum sensor afirma hoje a frase do chapéu não instalado**
  (`grep -ln 'is not installed in' tests/*.sh` → nada). As duas mensagens estão em
  `grep -n "is not installed in" bin/sdd` → `:5521` (projeção) e `:5523` (`die`).
- **Nenhuma asserção conta linhas `warn` genéricas de um `sdd run`**
  (`grep -n "grep -c[A-Za-z]* *-*[A-Za-z]* *['\"]\(  \)\?warn\b" tests/*.sh` → 4 linhas, todas em
  `tests/check-preflight.sh`, todas com o texto inteiro do aviso). É evidência fraca, não prova:
  veja a tabela de riscos.

**O que a skill do espelho diz** (regra do dono: consultar a `todo-to-github-issues` antes de mexer
na estrutura do `TODO.md`; lida em 2026-11-21)

- `~/.claude/skills/todo-to-github-issues/SKILL.md:204-209`: na issue, o GitHub liga todo `#N`
  **fora de crase** ao `#N` deste repo, queira o texto o item N ou o PR de outro repo; o conserto é
  na fonte, com `dono/repo#N` ou "item N". É a saída que a decisão 5 nomeia.
- `~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py:312-316` (`bare_refs`): não são
  soltos o `#N` dentro de crase ou de bloco cercado, `owner/repo#N`, `repo#N`, `&#N;` e `file#L12`.
  Por isso a regra nova **isenta o `PR #N` dentro de crase**. A regra 7, que lê a crase "como
  qualquer outra", fica como está.
- O título do item é a chave do espelho, a âncora é medida, o `RESOLVED by` e o teto de 8 linhas
  são o que o espelho lê. Este lote não muda nenhum dos quatro: só acrescenta uma regra ao sensor e
  uma frase aos dois templates.

**O `TODO.md`**

- `bash tests/check-todo.sh --count TODO.md` → `91` em `a0004df`. **Não toque em
  `tests/health-baseline.txt`.**
- O título de um item (o texto entre `**`) é a chave do espelho de issues: **nunca mude um título.**
  Os 15 estão na tabela do `00-missao.md`.
- A âncora de cada item é medida: `` `arquivo:linha` (`símbolo`) ``, e o símbolo tem de ocorrer no
  arquivo a até 10 linhas da linha. Antes de **todo** commit:
  `bash tests/check-todo.sh --anchors TODO.md` → `0 off target` (em `a0004df`:
  `anchors: 91 measured, 0 off target`). Âncora que saiu do alvo se conserta no mesmo commit,
  mudando o número da linha (ou o símbolo, quando o conserto o apagou), nunca o título.
- O `bin/sdd` é o arquivo mais ancorado: 41 itens abertos ancoram nele
  (a primeira âncora de cada item, por `grep -oE` de `` `arquivo:linha` `` na seção aberta). I1 a
  I9 editam o `bin/sdd`, quase sempre **acima** de âncoras de outros lotes: espere re-ancorar
  vários itens em cada commit. Outros arquivos ancorados que o lote edita:
  `tests/check-checkpoint.sh` (2 itens, o I10), `tests/check-todo.sh` (1, o I12),
  `tests/run-all.sh` (1), `docs/failure-modes.md` (2, o I7).
- **Símbolos que o conserto pode apagar**, e o que fazer: item 6, `sdd-preflight-ok` (o marcador
  continua no prompt da sonda: fica); item 11, `git status --porcelain` (continua: fica); item 14,
  `Run 'sdd install --force'` (a frase continua no ramo do checkout principal: fica); item 12,
  `kit_read_rules` (fica). Se um símbolo sumir mesmo assim, troque-o pelo nome da função nova no
  mesmo commit.
- `RESOLVED by <hash>` vai no fim da última linha do corpo, **antes** do `— descoberto por` (ou do
  `Fonte:`), nunca numa linha própria, nunca na linha `RECURRED`; nenhum item passa de 8 linhas
  (`bash tests/check-todo.sh --check TODO.md` → rc 0). É o I13 que as escreve.
- Achado fora de escopo que você encontrar vira item novo no `TODO.md` (formato em
  `templates/todo.pt-BR.md`), ou entrada na linha `RECURRED` de um item aberto equivalente.

**Para a fase DOCS**

- A entrada do `KAIZEN_LOG.md` cita o id inteiro `20261121-l4-preflight-health-e-sensores` sob um
  título `## ` novo, com o antes e o depois: 41 asserções e 31 mutantes novos, a contagem de
  `^mut_` antes (`926` em `a0004df`; meça de novo no merge-base) e depois, e a tabela por sessão de
  EXEC (minutos e US$ das linhas `"event":"session"` com `"phase":"EXEC"` desta missão em
  `~/.sdd/autonomy-log.jsonl`; some com `jq`, ou com `LC_ALL=C awk`).
- `docs/adr/0019-the-session-reads-what-the-boot-names.md` ganha **uma linha datada** apontando esta missão: o `sdd run` e o
  `sdd retry` param na skill achada e não coberta (decisão 3), e o preflight reprova a skill fora
  do `.skills` da `init` (decisão 6). É a decisão 8.
- As linhas `⛔` da pendência 3 do `00-missao.md` (o censo do `CLAUDE.md` e as §2, §4, §6 e §7 da
  rule da anatomia): proponha o texto, não edite.
- `config/schema.md` (a seção do opt-in do `TODO.md`, `:63`) e `docs/failure-modes.md` mudam nos
  incrementos que os tocam (I4, I7, I12), em inglês, não na DOCS.

## Arquitetura da mudança

Nada de arquitetura nova. São quinze consertos em quatro lugares:

1. **`cmd_preflight`** (`bin/sdd`) ganha leituras do que ele já tem em mãos: o stream da sonda do
   `Bash` (o `tool_result`, os hooks, o `.skills`), o `TODO_FILE` (a forma, pelo `check-todo.sh` do
   próprio kit, e o preâmbulo, pelo git do kit), o `git status` (os caminhos) e o ambiente do
   `TEST_CMD` (a marca).
2. **O lançamento do `sdd run` e do `sdd retry`** ganha duas conferências sem sessão: as skills das
   fases (para, decisão 3) e o estado do clone do kit (avisa). A busca das skills sai do
   `cmd_preflight` para **uma função**, chamada dos três lugares. A mensagem do chapéu não
   instalado passa a saber se está num worktree ligado.
3. **`cmd_kaizen`** ganha a guarda do chapéu que as outras quatro portas já têm.
4. **Três sensores** ganham uma regra cada: `check-checkpoint.sh` (o relógio), `check-todo.sh` (o
   `PR #N`), `check-health.sh` (a sonda de interrupção lê o grupo na hora certa). E
   `tests/isolate-git.sh` passa a fixar a raiz das skills para a suíte inteira (decisão 9).

Contrato de artefato: nenhum muda. As chaves de config, os tokens de status e a forma do
`TODO.md` ficam como estão.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

**Em todo incremento, nesta ordem:** (1) escreva a asserção e veja-a vermelha no sensor sozinho,
pelo motivo certo; (2) implemente; (3) veja-a verde; (4) escreva o mutante e prove-o com `--only`
(anote nas notas `<slug> caught by <sensor>`), ou faça a sabotagem à mão onde o catálogo não
alcança; (5) `bash -n bin/sdd`, `shellcheck -S warning` nos arquivos tocados,
`bash tests/check-lang.sh`, `bash tests/check-todo.sh --anchors TODO.md` (`0 off target`), e, se
editou um chapéu, `./bin/sdd install --force` e o `cmp` do espelho; (6) a suíte inteira; (7) o
commit, com o porquê no corpo; (8) o checkpoint e a nota, como último ato, com a hora de
`date '+%Y-%m-%d %H:%M'` rodado no mesmo lote de comandos.

Todo aviso, falha e frase de asserção é em **inglês** (superfície do kit).

### I1 — O preflight sem ruído de pipe, e a árvore suja com os caminhos (itens 12 e 11)

**O quê:** (a) `read_rules_cover` lê a lista inteira do `kit_read_rules` antes de casar
(`mapfile -t`), para o produtor nunca escrever num pipe sem leitor; confira os outros leitores do
mesmo par que saem cedo (`grep -n 'done < <(kit_read_rules)\|done < <(read_extra_each)' bin/sdd`).
(b) A falha da árvore suja lista os caminhos do `git status --porcelain` (até 10, e "… and N more"),
e, quando **todos** são `??`, acrescenta que são só não versionados e nomeia o `.git/info/exclude`
como saída para dado que o app grava fora do git. Continua `_fail`.
**Onde:** `bin/sdd` (`read_rules_cover`, o bloco `git state` do `cmd_preflight`),
`tests/check-preflight.sh`, `tests/check-mutation.sh`.
**Como (TDD):** para (a), um mundo com `READ_EXTRA` de 400 entradas (diretórios que não precisam
existir) e uma skill coberta, o preflight rodado por `( trap '' PIPE; LC_ALL=C "$SDD" preflight )`;
conte as linhas com `printf: ` na saída. O probe prova primeiro que o veneno está armado (um
`bash -c 'kill -PIPE $$; echo alive'` sob o mesmo `trap` imprime `alive`). No HEAD a contagem é
maior que 0. Para (b), três mundos: um arquivo rastreado modificado e um `??`; só `??`; 12 `??`.
**As frases:**
- `preflight prints no write error with READ_EXTRA filled under a caller that ignores SIGPIPE`
- `preflight names the dirty paths, and the exclude file only when every one of them is untracked`
**Mutantes:** `PRE_read_rules_cover_stream_read` (volta a ler do `< <(kit_read_rules)` com saída
no primeiro casamento), `PRE_dirty_paths_unnamed`, `PRE_dirty_exclude_always_named`.
**Check:** linha I1 do `checkpoint.md` → `1 1`. Antes: `0 0`.
**Sensor durável:** as duas asserções em `tests/check-preflight.sh` e os três mutantes.
**Reversível por:** `git revert` do commit.

### I2 — A sonda do `Bash` dá `ok` pelo comando rodado (item 6)

**O quê:** o braço `ok` da sonda deixa de ler o `.result` e passa a ler o artefato: um
`tool_result` sem `is_error`, cujo `tool_use_id` é o de um `tool_use` de nome `Bash`, e cujo
conteúdo (string ou lista de blocos `text`) traz `sdd-preflight-ok`. Resposta com o marcador e sem
esse `tool_result` é `_fail`, dizendo que o modelo repetiu o texto sem rodar o comando. A frase
"Bash in the tool list" só é impressa com `probe_init` não vazio; sem `init` e com o `tool_result`
certo, o `ok` diz só o que leu. Molde: o veredito da sonda dos templates (um `jq` que imprime um
desfecho, um `case` com default que reprova).
**Onde:** `bin/sdd` (`cmd_preflight`), `tests/check-preflight.sh` (o **stub A** muda), `tests/check-mutation.sh`.
**Como (TDD):** o stub A de hoje responde sem `tool_use`. Ele passa a emitir as duas linhas reais
de "O `cmd_preflight` de hoje" (a `assistant` com o `tool_use` e a `user` com o `tool_result`),
com o comentário de proveniência. Todo probe que herda o stub A continua verde. Mundos novos: o
stub antigo (marcador só no `.result`) → `_fail`; o marcador num `tool_result` de **outra**
ferramenta, ou com `is_error: true` → `_fail`; o stream certo sem a linha `init` → `ok` sem
"tool list".
**As frases:**
- `preflight says the Bash probe executes only when a Bash tool_result of the stream carries the marker`
- `preflight fails a Bash probe whose answer repeats the marker with no Bash call behind it`
- `preflight claims Bash in the tool list only over an init line`
**Mutantes:** `PRE_bash_probe_reads_answer`, `PRE_bash_probe_any_tool_result`,
`PRE_bash_probe_tool_list_blind`.
**Check:** linha I2 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e os três mutantes.
**Reversível por:** `git revert` do commit.

### I3 — Os hooks que toda fase carrega, e a skill pelo `.skills` da `init` (item 15)

**O quê:** logo depois do veredito da sonda do `Bash`, sobre o mesmo `probe_stream`:
(a) uma linha por `hook_event` das linhas `hook_response`: quantos hooks, os rc, e a soma dos
bytes de `output` ("bytes into the context of every session"); sem `hook_response`, uma linha
`dim` dizendo que a sonda não viu hook nenhum; (b) `warn`, com o `hook_name` e a primeira linha do
`stderr`, para cada hook com `exit_code` diferente de 0 ou `outcome` diferente de `success`, e só
para ele; (c) com `init` cujo `.skills` é uma lista, cada skill de `wanted` que **não** está nela
é `_fail` (a fase vai rodar e o harness não a carregou), nomeando a skill e a fase. Predicado
escrito positivamente: `(.skills | type) == "array"`; `init` sem a chave, ou sem `init`, não
afirma nada sobre skills nem sobre hooks. A lista `wanted` sobe para antes da sonda, uma definição
só para os dois blocos. A busca em diretórios do bloco "third-party skills" fica, para a cobertura
do `READ_EXTRA`; o `warn` "skills not found" dela continua, porque sem `init` é tudo o que há.
**Onde:** `bin/sdd` (`cmd_preflight`), `tests/check-preflight.sh`, `tests/check-mutation.sh`.
**Como (TDD):** o stub ganha, por mundo, as linhas `hook_response` da forma real e um `.skills`
na `init`. Mundos: 3 hooks verdes de `SessionStart` (3604, 0 e 0 bytes) → uma linha com `3` e
`3604`; um deles com `exit_code: 2` e `outcome: "error"` → um `warn`, e nenhum para os outros
dois; `.skills` sem `codereview:codereview` → `_fail` e a contagem de falhas sobe 1; stream sem
`init` → nenhuma linha de hook, nenhuma de skill da `init`. A asserção que já existe "a repo with
no interface never sees `qa-report`" tem de continuar verde.
**As frases:**
- `preflight lists the hooks the probe session ran, one line per event, with the count, the exit codes and the bytes`
- `preflight warns by name about a hook that exits non-zero or does not report success, and only about it`
- `preflight fails a skill a phase will invoke when the init line of the probe does not list it`
- `preflight says nothing about hooks or the skills list without an init line`
**Mutantes:** `PRE_hooks_unlisted`, `PRE_hook_failure_silent`,
`PRE_skill_absent_from_init_warned`, `PRE_skill_init_blind` (afirma sem `init`).
**Check:** linha I3 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções e os quatro mutantes.
**Reversível por:** `git revert` do commit.

### I4 — O preflight mede a forma do `TODO_FILE` (item 1, decisão 2)

**O quê:** um bloco novo no `cmd_preflight`, perto do `config`: roda
`bash "$SDD_HOME/tests/check-todo.sh" --check "$TODO_FILE" --allow-empty` a partir do
`REPO_ROOT` (as âncoras resolvem contra o repo), com captura guardada. rc 0 → `ok` com a linha de
resumo do sensor; rc 1 → `warn` com a contagem de violações e as três primeiras linhas, e, **só**
quando o `TEST_CMD` não contém `check-todo.sh`, a linha do opt-in com `--baseline` (a de
`config/schema.md`); qualquer outro rc, o arquivo ausente, ou o kit sem `tests/check-todo.sh` →
`warn` dizendo que a forma **não foi medida** e por quê. Nunca `_fail`. `config/schema.md` (seção
do opt-in) passa a dizer que o preflight mede sozinho e que o opt-in é o que **para** a linha.
**Onde:** `bin/sdd`, `tests/check-preflight.sh`, `tests/check-mutation.sh`, `config/schema.md`.
**Como (TDD):** no molde do `todo_lint_case`: o `TODO.md` semeado limpo → `ok`; com
`- [ ] **a finding with no anchor and no date**` sob o marcador → `warn` com `1`, e
`failed_count` igual ao do mundo limpo; o mesmo com o `TEST_CMD` carregando `check-todo.sh` → o
`warn` sem a linha do opt-in; `TODO_FILE` apagado → o `warn` de "not measured".
**As frases:**
- `preflight measures the shape of TODO_FILE by itself: ok when clean, a warning with the count when not, never a failure`
- `preflight names the opt-in line with --baseline only when TEST_CMD does not carry check-todo.sh`
- `preflight says the shape of TODO_FILE was not measured when the file or the sensor is missing`
**Mutantes:** `PRE_todo_shape_unmeasured`, `PRE_todo_shape_fails` (o `warn` vira `_fail`),
`PRE_todo_optin_always_named`.
**Check:** linha I4 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e os três mutantes.
**Reversível por:** `git revert` do commit.

### I5 — O preâmbulo do `TODO_FILE` contra as revisões do template (item 10, decisão 4)

**O quê:** uma função, `todo_preamble_verdict <arquivo> <idioma>`, que **publica** o veredito num
global (é chamada, nunca lida por `$( )`): o preâmbulo é o arquivo da linha 1 até a primeira linha
`^<!-- sdd:open -->[[:space:]]*$`, inclusive, com `git hash-object --no-filters --stdin`. O
template é `templates/todo.<idioma>.md` quando existe, senão `templates/todo.md` (a escolha do
`cmd_install`). Compara com o preâmbulo do template em disco (`current`) e, senão, com o de cada
revisão de `git -C "$SDD_HOME" log --format='%H %ad' --date=short -- <template>` (`stale <rev>
<data>`); igual a nenhum é `author`; arquivo sem marcador, ou `SDD_HOME` que não é checkout git,
é `unknown`. Chamadores: o `cmd_preflight` (ao lado do bloco do I4) e o braço
`already exists (preserved)` do `cmd_install`. `current` → `ok`; `stale` → `warn` com a revisão
curta, a data e o comando `diff` a rodar (o preâmbulo do arquivo contra o do template de hoje), e
**o arquivo não é reescrito**; `author` → uma linha `dim`; `unknown` → nada.
**Onde:** `bin/sdd` (`cmd_install`, `cmd_preflight`, a função nova), `tests/check-preflight.sh`,
`tests/check-mutation.sh`.
**Como (TDD):** a sandbox de mutação copia o kit **sem git**, então o probe não pode depender do
git do kit real: monte uma **cópia do kit** como o `kp_world`, com um repositório próprio de dois
commits (o `templates/todo.md` com um preâmbulo antigo, depois o de hoje), e rode o `bin/sdd` da
cópia. Mundos: `TODO.md` semeado hoje → `ok`; semeado no primeiro commit → `warn` com a revisão e
a data desse commit, e o `md5sum` do `TODO.md` igual antes e depois; preâmbulo com uma linha
trocada → a linha neutra, nenhum `warn`; a cópia sem `.git` → nenhuma das três frases. Os mesmos
dois primeiros mundos pelo `install`.
**As frases:**
- `the TODO preamble equal to the template of today is ok, in preflight and in install`
- `the TODO preamble equal to an older revision of the template is a warning with the revision, its date and the diff to run, and the file is not rewritten`
- `the TODO preamble equal to no revision of the template is an author preamble, said in one neutral line`
- `a kit that is not a git checkout answers nothing about the TODO preamble`
**Mutantes:** `PRE_todo_preamble_stale_silent`, `PRE_todo_preamble_author_warned`,
`INSTALL_todo_preamble_unchecked`.
**Check:** linha I5 → `1 1 1 1`. Antes: `0 0 0 0`.
**Sensor durável:** as quatro asserções e os três mutantes.
**Reversível por:** `git revert` do commit.

### I6 — O `sdd run` para antes da sessão que será negada (item 7, decisões 3 e 9)

**O quê:** (a) a busca das skills sai do `cmd_preflight` para uma função,
`phase_skills_check <voz>`, que percorre `wanted` e classifica cada skill em: coberta, `missing`
(não achada), `broken` (o registro grava o plugin e a instalação não tem a skill), `uncovered`
(achada, nenhuma regra cobre, e uma entrada do `READ_EXTRA` a alcança) e `unreachable` (o alvo que
a gramática recusa). As frases de cada classe são as de hoje, numa definição só. (b) O
`cmd_preflight` a chama com a voz de sempre (tudo `warn`). (c) O `cmd_run` e o `cmd_retry` a
chamam **depois** do `load_config` e **antes** de qualquer sessão e de qualquer gate que rode o
`TEST_CMD`: `uncovered` e `broken` são `die`, com a frase do aviso mais a entrada a acrescentar;
`missing` e `unreachable` são `warn`. Sob `--dry-run`, tudo é `warn`. O `die` fica fora de
qualquer `$( )`. (d) `tests/isolate-git.sh` passa a exportar um `SDD_SKILLS_ROOT` que aponta para
um diretório vazio (decisão 9), e o cabeçalho dele diz as duas coisas que o arquivo limpa: sem
isso, numa máquina com o plugin `codereview`, todo `sdd run` de fixture da suíte morreria. Os
mundos do `check-preflight.sh` que já passam um `SDD_SKILLS_ROOT` próprio continuam passando o
deles. (e) `docs/failure-modes.md` ganha o verbete da parada, com a saída e o remédio.
**Onde:** `bin/sdd` (`cmd_preflight`, `cmd_run`, `cmd_retry`, a função nova),
`tests/isolate-git.sh`, `tests/check-preflight.sh`, `tests/check-mutation.sh`,
`docs/failure-modes.md`.
**Como (TDD):** no mundo `rx_*` (skill `codereview:codereview` instalada num `SDD_SKILLS_ROOT` de
fixture, `READ_EXTRA` vazio), com uma pasta de missão mínima e o `claude` como `loud_stub` (a
testemunha de "nenhuma sessão" é o argv do stub vazio): `sdd run <missão>` → rc diferente de 0, a
frase com `READ_EXTRA entry to add:`, nenhuma sessão; `sdd retry <missão> <FASE>` → o mesmo; o
registro apontando uma instalação sem a skill → para com a frase do `broken`; `--dry-run` → rc 0,
o aviso, a projeção impressa; skill ausente do root → `warn` e a corrida segue; o alvo de nome
recusado → `warn` e segue. A sexta asserção é **diferencial**: a frase que o preflight imprime e a
que o `sdd run` imprime sobre a mesma skill, comparadas entre si (a do `run` sem o prefixo da voz).
Depois, a suíte inteira: é ela que diz se algum sensor dependia da raiz real das skills.
**As frases:**
- `sdd run stops before any session when a skill a phase invokes is found where no read rule covers it, naming the READ_EXTRA entry to add`
- `sdd retry stops before any session on the same uncovered skill`
- `sdd run stops before any session on a plugin install that does not hold the skill`
- `sdd run --dry-run only warns about an uncovered skill, and still projects`
- `sdd run only warns about a skill it does not find, and about one whose target the grammar refuses`
- `preflight and sdd run say the same sentence about the same uncovered skill`
**Mutantes:** `RUN_skill_uncovered_not_stopped`, `RETRY_skill_uncovered_not_stopped`,
`RUN_skill_broken_not_stopped`, `RUN_skill_dry_run_stops`, `RUN_skill_missing_stops`.
**Check:** linha I6 → `1 1 1 1 1 1`. Antes: `0 0 0 0 0 0`.
**Sensor durável:** as seis asserções e os cinco mutantes (um por porta: `run` e `retry`).
**Reversível por:** `git revert` do commit (a linha do `isolate-git.sh` sai junto).

### I7 — O `TEST_CMD` que deixa processo vivo, e a suíte sem o linter (itens 3 e 13)

**O quê:** (a) `run_check_cmd` exporta, só para o comando que avalia, uma marca única
(`SDD_CHECK_TAG=<rótulo>-<aleatório>`) e a publica num global (`LAST_CHECK_TAG`). Depois do
`run_check_cmd` do `TEST_CMD`, o `cmd_preflight` procura a marca em `/proc/[0-9]*/environ`
(`grep -lsa -F`, captura guardada) e, para cada processo achado, dá **um** `warn`, antes do
veredito final: o pid e o `comm` do kernel (`/proc/<pid>/comm`), **nunca os argumentos** (podem
levar credencial; é a regra do `name_stragglers` do `bin/sdd-coordination.py`), dizendo que o
comando deixou processo vivo, que todo comando do kit que roda o `TEST_CMD` espera por ele, e
apontando o verbete de `docs/failure-modes.md`. Sem `/proc`, ou sem processo, não diz nada. (b)
Num repo que carrega o catálogo (`has_mutation_catalogue "$REPO_ROOT"`, a árvore do kit) e sem
`shellcheck` no PATH, o preflight dá `warn`: o passo de lint da suíte será pulado, e a suíte verde
não terá medido os avisos. (c) `docs/failure-modes.md` ganha o verbete do servidor de build que
sobra, com as duas saídas **medidas** no `dotp-remake` (`dotnet build-server shutdown` e
`--disable-build-servers`); outras toolchains não foram medidas e não entram.
**Onde:** `bin/sdd` (`run_check_cmd`, `cmd_preflight`), `tests/check-preflight.sh`,
`tests/check-mutation.sh`, `docs/failure-modes.md`.
**Como (TDD):** um `TEST_CMD` de fixture que faz `sleep 5 300 >/dev/null 2>&1 &` e sai 0 (o
preflight espera o processo sumir: mantenha o sono curto, e use um segundo argumento reconhecível,
`300`, só para provar que argumento não é impresso). O `warn` aparece antes da linha do veredito,
traz o pid e `sleep`, e a saída não contém `300`. Um `TEST_CMD` que não deixa nada → nenhuma linha
dessas. Para (b): um PATH sem `shellcheck` numa cópia do kit (`kp_world`) → o `warn`; o mesmo PATH
num repo-alvo de fixture → nada.
⚠️ O L3 também mexe em `run_check_cmd` (o I1 dele). Quando você ler a função, ela já terá a
mudança do L3: acrescente a marca sem desfazer o que ele pôs.
**As frases:**
- `preflight warns before its verdict, by pid and executable and never by arguments, about a process TEST_CMD left running`
- `preflight says nothing of the kind when TEST_CMD leaves nothing behind`
- `preflight warns that the lint step of the suite will be skipped when shellcheck is absent, only in a tree that carries the suite`
**Mutantes:** `PRE_test_cmd_stragglers_unnamed`, `PRE_test_cmd_stragglers_print_args`,
`PRE_lint_absent_silent`.
**Check:** linha I7 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e os três mutantes.
**Reversível por:** `git revert` do commit.

### I8 — O clone velho do kit, e o worktree sem o espelho dos chapéus (itens 2 e 14)

**O quê:** (a) uma função, `kit_stale_check`, chamada uma vez por processo (guarda num global, e
por isso **chamada**, nunca lida por `$( )`) no lançamento do `sdd run` e do `sdd retry` e numa
linha do `sdd preflight`. Ela só fala quando o `SDD_HOME` é checkout git, é o **worktree
principal** (`--git-dir` igual ao `--git-common-dir`, os dois por
`git -C "$SDD_HOME" rev-parse --path-format=absolute`) e o `HEAD` está num branch. O branch padrão
do kit é o `origin/HEAD` **do kit** (`git -C "$SDD_HOME" symbolic-ref --quiet --short
refs/remotes/origin/HEAD`), com recuo para `origin/main` e depois `origin/master` quando ele não
existe, e **nunca** o `DEFAULT_BRANCH` do alvo. Fora do branch padrão: `warn` com o branch em que
está. No branch padrão e atrás do upstream **já buscado** (`rev-list --count HEAD..origin/<b>`,
sem `fetch`): `warn` com a contagem. Sem remoto, em worktree ligado, com `HEAD` destacado, ou kit
que não é git: nada. Sob `--dry-run`, nada (a projeção não herda aviso de estado do kit). (b) As
duas mensagens do chapéu não instalado (`grep -n 'is not installed in' bin/sdd`): quando o
`REPO_ROOT` é um worktree ligado (`--git-dir` diferente do `--git-common-dir`), nomeiam o
`sdd link-agents` e dizem por quê (os espelhos são links ignorados de cada checkout); no checkout
principal, continuam nomeando o `sdd install --force`.
**Onde:** `bin/sdd` (`cmd_run`, `cmd_retry`, `cmd_preflight`, `run_phase`, a função nova),
`tests/check-preflight.sh`, `tests/check-dry-run.sh`, `tests/check-mutation.sh`.
**Como (TDD):** para (a), cópias do kit como o `kp_world`, cada uma um repositório próprio com um
remoto `bare` local: no branch padrão e em dia → silêncio; num branch `side` → o `warn` com
`side`; no padrão, 2 commits atrás do `origin/main` já buscado → o `warn` com `2`; o alvo com
`DEFAULT_BRANCH="develop"` e o kit em `main` em dia → silêncio (é a testemunha de que o branch do
alvo não é lido); a cópia sem `.git` → silêncio. "Uma vez por processo": num `sdd run` que abre
duas sessões de stub, a frase aparece 1 vez. Para (b), em `tests/check-dry-run.sh`: um repo de
fixture instalado, um `git worktree add` dele, os espelhos `.claude/agents/sdd-*.md` ausentes no
worktree; `sdd run --dry-run` e `sdd run` de lá nomeiam `sdd link-agents`; do checkout principal
com o espelho apagado, `sdd install --force`.
**As frases:**
- `a kit checkout off its default branch is named once per process, with the branch it is on`
- `a kit checkout behind its fetched upstream is named with the count of commits`
- `a kit on its default branch and level with it says nothing, and so does a linked worktree, a detached HEAD and a kit that is not a git checkout`
- `the default branch of the kit is its own remote HEAD, never the DEFAULT_BRANCH of the target`
- `sdd run in a linked worktree with no agent mirror names sdd link-agents, in the stop and in the projection`
- `sdd run in a main checkout with no agent mirror still names sdd install --force`
**Mutantes:** `RUN_kit_off_branch_silent`, `RUN_kit_behind_silent`,
`RUN_kit_reads_target_branch`, `RUN_agent_missing_worktree_names_install`.
**Check:** linha I8 → `1 1 1 1 1 1`. Antes: `0 0 0 0 0 0`.
**Sensor durável:** as seis asserções e os quatro mutantes.
**Reversível por:** `git revert` do commit.

### I9 — O juiz passa pela guarda do chapéu (item 4, decisão 7)

**O quê:** no `cmd_kaizen`, em volta de **cada** `run_phase KAIZEN` (são dois,
`grep -n 'run_phase KAIZEN' bin/sdd`): `hat_guard_arm` antes, e depois da sessão
`hat_guard_check "$phase" "${before%%|*}"` (o `before` é o `state_fingerprint` que a função já
tira; para a segunda sessão, o `after` da primeira), e a porta
`if hat_crossed_escalation "$phase"; then return 3; fi` **depois** da linha de sessão do ledger
(`autonomy_session_row`). Declare `local phase="KAIZEN"` e escreva a porta com `"$phase"`: é a
grafia que o censo do `CLAUDE.md` conta. A guarda de **kit** não entra (`kit_guard_arm`/`_check`
ficam fora): o juiz roda no kit. Sob `--dry-run` nada arma (a projeção já sai antes). O comentário
da porta diz por que só a metade do chapéu, e o chapéu `agents/sdd-kaizen.md` passa a dizer, numa
frase ao lado do que ele escreve, que a base de todo chapéu soma o arquivo de achados
(`$TODO_FILE`) e a catraca (`tests/health-baseline.txt`). Depois: `./bin/sdd install --force` e o
espelho no mesmo commit.
**Onde:** `bin/sdd` (`cmd_kaizen`), `agents/sdd-kaizen.md`, `.claude/agents/sdd-kaizen.md` (pelo
`install`), `tests/check-kaizen.sh`, `tests/check-hat.sh`, `tests/check-mutation.sh`.
**Como (TDD):** em `tests/check-kaizen.sh`, um stub de sessão do juiz no molde dos que já escrevem
artefato (`:1156`, `:1186`): um que escreve o veredito na pasta da missão **e** um arquivo fora do
`writes:` (por exemplo `README.md` do fixture) → rc 3, e as linhas do ledger daquela corrida são
`session` e depois `blocked` com `kind: hat-crossed`; um que só cruza na **segunda** sessão (a
primeira não satisfaz o gate) → rc 3, com duas linhas `session` antes do `blocked`; um que escreve
só a pasta da missão, o `KAIZEN_LOG.md` e o `TODO.md` → nenhum `hat-crossed`; `--dry-run` → nenhum
`HAT-CROSSED` no journal. Em `tests/check-hat.sh`, uma asserção lê a frase da base no chapéu.
**As frases:**
- `kaizen: a judge session that writes outside its hat stops the line as hat-crossed, after its session row`
- `kaizen: the retry session that crosses stops too, by its own read`
- `kaizen: a judge session that writes only the mission folder, KAIZEN_LOG.md and the findings file is not accused`
- `kaizen: the projection arms no hat guard`
- `hat: the judge names the base every hat may write, the findings file and the ratchet`
**Mutantes:** `KAIZEN_hat_guard_first_door_dropped`, `KAIZEN_hat_guard_retry_door_dropped`,
`KAIZEN_hat_guard_unarmed`.
**Check:** linha I9 → `1 1 1 1 1 0` (o último é o rc do `cmp` do espelho). Antes: `0 0 0 0 0 0`.
**Sensor durável:** as cinco asserções e os três mutantes, um por porta.
**Reversível por:** `git revert` do commit, e `./bin/sdd install --force` de novo.

### I10 — O `atualizado:` no futuro é recusado (item 5)

**O quê:** `tests/check-checkpoint.sh` lê o `atualizado:` do frontmatter de cada checkpoint, no
`scan_file` (então vale no `--check` e na varredura que a suíte roda). A forma
`YYYY-MM-DD HH:MM` posterior ao relógio (`date '+%Y-%m-%d %H:%M'`; as duas strings nessa forma se
comparam como texto) é violação, com contador próprio (`V_CLOCK`) somado ao veredito do
`check_one` e do `scan`, e a mensagem traz o campo, o valor e a hora do relógio. Passam: a hora
igual ou anterior, o placeholder do template (`<YYYY-MM-DD HH:MM>`), o arquivo sem o campo e o
valor em outra forma (limite declarado no cabeçalho: a regra só lê a forma que o template dá). O
cabeçalho do sensor ganha a regra e o limite: uma hora inventada **no passado** não é medível.
**Onde:** `tests/check-checkpoint.sh`.
**Como (TDD):** probes do selftest com `cp_head`/`cp_row`: `atualizado:` de amanhã
(`date -d tomorrow '+%Y-%m-%d %H:%M'`) → rc 1 pelo `--check`, com o campo na mensagem; de agora e
de ontem → rc 0; o placeholder → rc 0; sem o campo → rc 0; uma árvore com um checkpoint no futuro
→ a varredura reprova. O probe roda o **caminho** (`--check <arquivo>`), não só a função.
**A frase:**
- `rule: an atualizado later than the clock is refused, in --check and in the scan, and one at or before it passes`
**Sabotagem à mão** (o catálogo não alcança este sensor): numa cópia fora do worktree, troque a
comparação para aceitar tudo e exija o selftest vermelho; depois tire o `V_CLOCK` da soma do
`check_one` e exija vermelho de novo. Anote os dois nas notas.
**Check:** linha I10 → `1`. Antes: `0`.
**Sensor durável:** a regra e os probes do selftest, que a suíte roda.
**Reversível por:** `git revert` do commit.
⚠️ O `checkpoint.md` desta missão passa por essa regra daqui em diante: a hora sai sempre do
`date`.

### I11 — A sonda de interrupção lê o grupo depois que a suíte roda (item 8)

**O quê:** em `tests/check-health.sh` (`grep -n 'INTR_PID' tests/check-health.sh`), a leitura
`ps -o pgid= -p "$INTR_PID"` sai de logo depois do `setsid … &` e vai para **depois** da espera
pelo passo lento (o laço que lê `$WORK/intr.log`): nessa hora o filho já chamou o `setsid()`. A
pergunta "é líder do próprio grupo?" vira uma função pequena (`intr_leader <pid>`), e ganha um
**controle negativo**: o mesmo mundo lançado **sem** o `setsid` tem de responder "não é líder"
(e é derrubado em seguida pelo pid, com `kill`, sem sinal ao grupo, que seria o do sensor). Sem o
controle, a função que respondesse sempre "líder" passaria.
**Onde:** `tests/check-health.sh`.
**Como (TDD):** a frase nova não existe no HEAD. O probe com `setsid` responde líder, o sem
`setsid` responde não-líder, e só então a asserção passa. A asserção que já existe
(`surface: an interrupt still stops the suite while a step runs`) continua verde.
**A frase:**
- `surface: the interrupt probe tells a suite in its own process group from one left in the caller group`
**Sabotagem à mão:** numa cópia, faça `intr_leader` devolver sempre 0 e exija a frase vermelha.
Rode o sensor 5 vezes seguidas depois do conserto e anote os 5 rc nas notas (a corrida caía 1 vez
em 4).
**Check:** linha I11 → `1`. Antes: `0`.
**Sensor durável:** a asserção com o controle negativo, na suíte.
**Reversível por:** `git revert` do commit.

### I12 — O `PR #N` sem rastro no histórico (item 9, decisão 5)

**O quê:** uma regra nova no `tests/check-todo.sh`, **só sob `--baseline <ref>`** e só para item
que a base não tinha: um `PR #N` (ou `PRs #N`) solto, fora de crase e de bloco cercado, só passa
se algum assunto de `git log --format=%s HEAD <ref>` cita `#N` (o `#N` sem dígito logo depois).
Sem rastro: violação, e a mensagem nomeia a linha em que o item abre e a saída
`owner/repo#N`, "also for a pull request of this repository that has not merged". `owner/repo#N`,
`issue #N` e o `PR #N` dentro de crase passam. Repositório raso
(`git rev-parse --is-shallow-repository` → `true`) ou sem histórico legível: a regra não recusa
nada e diz isso numa linha. O cabeçalho do sensor ganha a regra (a 8) e os limites declarados:
`issue #N` fora; um `#N` de outro repositório que coincide com um PR local passa; sem
`--baseline` nada é lido. Os dois templates (`templates/todo.md`, `templates/todo.pt-BR.md`), no
parágrafo do `#N` solto, passam a dizer que `PR #N` é o PR **deste repositório, já mergeado**, e
que o resto vai como `dono/repo#N`. `config/schema.md` (os limites do opt-in) ganha uma linha.
Releia "O que a skill do espelho diz" antes de escrever a frase dos templates.
**Onde:** `tests/check-todo.sh`, `templates/todo.md`, `templates/todo.pt-BR.md`,
`tests/check-templates.sh`, `config/schema.md`.
**Como (TDD):** no `$box/baselinerepo` do selftest, com um commit de assunto `Merge pull request
#7 from x/y`: item novo com `PR #7` → 0 novas; com `PR #9` → 1 nova, e a mensagem traz
`owner/repo#9`; com `` `PR #9` `` em crase, `x/y#9` e `issue #9` → 0 novas; o `PR #9` num item que
a base já tinha → herdado; o mesmo arquivo sem `--baseline` → rc 0. `RULES_FLOOR` sobe de 14 para
15. Em `tests/check-templates.sh`, uma asserção por template lê a frase nova (regex com o literal
de cada idioma).
**As frases:**
- `rule: under --baseline a bare PR number in a new item passes only when a commit subject of the local history cites it`
- `todo.md: a bare PR number is said to be a merged pull request of this repository`
- `todo.pt-BR.md: a bare PR number is said to be a merged pull request of this repository`
**Sabotagem à mão:** numa cópia, faça a regra aceitar todo número e exija o selftest vermelho;
depois faça-a ler também sem `--baseline` e exija vermelho. Anote nas notas.
**Check:** linha I12 → `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** a regra com os probes do selftest, e as duas asserções dos templates.
**Reversível por:** `git revert` do commit.
⚠️ A suíte roda o `check-todo.sh` sobre o `TODO.md` do kit **sem** `--baseline`: a regra nova não
o lê, e nenhum item daqui muda.

### I13 — Fecho

**O quê:** `RESOLVED by <hash>` nos 15 itens do `TODO.md`, cada um com o hash do incremento que o
fechou (a coluna Incremento da tabela do `00-missao.md` diz qual, e o hash sai da coluna Commit do
`checkpoint.md`). O item 13 leva o hash do I7; a metade dele que `3f96448` já tinha fechado vai
dita no corpo do commit, não no item. O `20-handoff-exec.md` é do chapéu do executor, que o
escreve no incremento que não deixa linha `pending`.
**Onde:** `TODO.md`, `docs/handoffs/20261121-l4-preflight-health-e-sensores/20-handoff-exec.md`.
**Como (TDD):** o Check conta os `RESOLVED by` contra o `TODO.md` do merge-base com a
`origin/main`; antes ele imprime `0`. Depois: `bash tests/check-todo.sh --check TODO.md` (rc 0,
nenhum item acima de 8 linhas) e `--anchors` (`0 off target`). Não toque em
`tests/health-baseline.txt`.
**Check:** linha I13 → `15`. Antes: `0`.
**Sensor durável:** `tests/check-todo.sh` (forma e âncoras), que a suíte roda. A contagem em si é
checagem desta missão: o chore de depois do merge apaga os itens.
**Reversível por:** `git revert` do commit.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A parada do I6 mata os `sdd run` de fixture dos outros sensores numa máquina com o plugin instalado | certa, sem a decisão 9 | `tests/isolate-git.sh` exporta um `SDD_SKILLS_ROOT` vazio no mesmo commit. O sensor que cobre é a suíte inteira antes do commit do I6; **não foi rodada no planejamento contra a mudança** (ela não existe ainda), então o risco fica aberto até lá |
| Um aviso novo no lançamento do `sdd run` (skill não achada, kit velho) quebra uma asserção que conta linhas | baixa | `grep -n "grep -c[A-Za-z]* *-*[A-Za-z]* *['\"]\(  \)\?warn\b" tests/*.sh` → 4 linhas, todas com o texto inteiro de um aviso. É evidência, não prova: a suíte antes do commit do I6 e do I8 é quem responde. O aviso do kit velho cala em worktree ligado e em `HEAD` destacado, que são os mundos em que a suíte roda numa missão do kit e num CI |
| O stub A novo (I2) muda o stream que dezenas de probes herdam | média | O stub novo é o de hoje **mais** duas linhas; rode `bash tests/check-preflight.sh` inteiro antes de seguir, e a contagem de `^  ok    ` não pode cair (anote antes e depois nas notas) |
| A base anda entre o plano e a corrida (o merge do L3) | certa | Pendência 1 do `00-missao.md`: merge da `origin/main`, `--anchors`, `--check` e `--red` de novo, antes do `sdd run` |
| Um mutante novo não é pego, e a asserção é decoração | média | `--only <slug> <sensor>` antes de cada commit, anotado nas notas; mutante vivo = incremento não fecha |
| O probe do preâmbulo (I5) ou do kit velho (I8) depende do git do kit real e falha na sandbox de mutação, que copia o kit sem git | alta, se o plano não for seguido | Os dois probes montam uma **cópia do kit** com repositório próprio (`kp_world`); a asserção "kit que não é git não responde" é a que roda no mundo sem git |
| O processo que o probe do I7 deixa vivo segura o preflight do próprio teste | média | O `TEST_CMD` de fixture deixa um `sleep 5`: o supervisor espera 5 s e libera. Nunca um sono longo |
| A guarda do chapéu para um `sdd kaizen` saudável (o juiz que commita o plano nascido) | baixa | O `writes:` do juiz cobre `$HANDOFF_DIR/**` e o `KAIZEN_LOG.md`, e a base cobre o `TODO.md` e a catraca; a terceira asserção do I9 é esse mundo. O custo de um falso é um `sdd kaizen` do humano |
| Alvo sem a entrada do `codereview` para no primeiro `sdd run` depois do merge | certa | É o desenho (decisão 3). A mensagem traz a linha a acrescentar; a pendência 4 lista os alvos |

**Não-feitos, por decisão:** o catálogo de mutação inteiro (`./bin/sdd health`); a parada da skill
no `sdd close` e no `sdd kaizen`; a duração dos hooks; `issue #N` de outro repositório; a edição
do `CLAUDE.md` e da rule da anatomia (linhas `⛔` na DOCS); `tests/health-baseline.txt`.

## Verificação end-to-end

Quando todos os incrementos estiverem `done`, no worktree da missão:

1. `tests/run-all.sh` → `suite green`, rc 0, e `grep -cE '^  FAIL' <saída>` → `0`.
2. As 41 frases, cada uma com `  ok    ` no seu sensor (os Checks I1 a I12 do `checkpoint.md`,
   todos com o valor esperado).
3. `grep -cE '^mut_(PRE_read_rules_cover_stream_read|PRE_dirty_paths_unnamed|PRE_dirty_exclude_always_named|PRE_bash_probe_reads_answer|PRE_bash_probe_any_tool_result|PRE_bash_probe_tool_list_blind|PRE_hooks_unlisted|PRE_hook_failure_silent|PRE_skill_absent_from_init_warned|PRE_skill_init_blind|PRE_todo_shape_unmeasured|PRE_todo_shape_fails|PRE_todo_optin_always_named|PRE_todo_preamble_stale_silent|PRE_todo_preamble_author_warned|INSTALL_todo_preamble_unchecked|RUN_skill_uncovered_not_stopped|RETRY_skill_uncovered_not_stopped|RUN_skill_broken_not_stopped|RUN_skill_dry_run_stops|RUN_skill_missing_stops|PRE_test_cmd_stragglers_unnamed|PRE_test_cmd_stragglers_print_args|PRE_lint_absent_silent|RUN_kit_off_branch_silent|RUN_kit_behind_silent|RUN_kit_reads_target_branch|RUN_agent_missing_worktree_names_install|KAIZEN_hat_guard_first_door_dropped|KAIZEN_hat_guard_retry_door_dropped|KAIZEN_hat_guard_unarmed)\(\)' tests/check-mutation.sh`
   → `31`, e `bash tests/check-mutation.sh --anchors` → rc 0.
4. `cmp -s agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md; echo $?` → `0`.
5. O censo das portas: `grep -cE '^ +if [a-z_]+_escalation "\$phase"; then' bin/sdd` → `15`
   (mais o que o L3 tiver somado: compare com o valor do merge-base mais 2), e
   `grep -cE '^ *hat_guard_check "' bin/sdd` → o do merge-base mais 2.
6. `bash tests/check-todo.sh --check TODO.md` → rc 0, `bash tests/check-todo.sh --anchors TODO.md`
   → `0 off target`, e o Check I13 → `15`.
7. Para a QA, de mão: `./bin/sdd preflight` neste worktree (roda o `TEST_CMD` inteiro, 8 a 15 min,
   e duas sessões haiku). A saída traz a linha dos hooks, a da forma do `TODO_FILE`, a do
   preâmbulo (neutra: o do kit é de autor) e a sonda do `Bash` verde. Dentro de uma sessão do
   Claude Code, rode-o com `env -u CLAUDECODE`.

## O vermelho medido

Medido pelo planner em `a0004df`, em 2026-11-21, com o `tests/check-checkpoint.sh` do worktree:

- `bash tests/check-checkpoint.sh --check docs/handoffs/20261121-l4-preflight-health-e-sensores/checkpoint.md`
  → `ok    checkpoint.md: 13 row(s), 12 under the anchor rule, none blind`, rc 0.
- `--red … --only I1,I2,I3,I4,I5` (04:29:23 a 04:34:15) → rc 0, as cinco `is red at HEAD`:
  I1 `prints '0 0', wants '1 1'`; I2 `'0 0 0'`/`'1 1 1'`; I3 `'0 0 0 0'`/`'1 1 1 1'`;
  I4 `'0 0 0'`/`'1 1 1'`; I5 `'0 0 0 0'`/`'1 1 1 1'`.
- `--red … --only I6,I7,I8,I9,I10,I11,I12,I13` (04:34:21 a 04:39:28) → rc 0, as oito
  `is red at HEAD`: I6 `'0 0 0 0 0 0'`/`'1 1 1 1 1 1'`; I7 `'0 0 0'`/`'1 1 1'`;
  I8 `'0 0 0 0 0 0'`/`'1 1 1 1 1 1'`; I9 `'0 0 0 0 0 0'`/`'1 1 1 1 1 0'`; I10 `'0'`/`'1'`;
  I11 `'0'`/`'1'`; I12 `'0 0 0'`/`'1 1 1'`; I13 `'0'`/`'15'`.

As duas corridas são parciais por construção (`--only`), e juntas cobrem as 13 linhas: a chamada
`Bash` do harness não espera os 10 min de uma corrida só. Depois do merge da `main` (pendência 1
do `00-missao.md`) as duas se repetem.

## Teste de autocontenção

Lido incremento a incremento com a pergunta "uma sessão nova executa isto só com os três
arquivos?". O que saiu como "só se souber X" e está escrito acima: o `sdd` do PATH é o runner
velho e o `./bin/sdd` é o novo; o stub A e a forma real do stream (I2, I3); o `kp_world` e a
sandbox de mutação sem git (I5, I8); a raiz das skills da suíte (I6); o sono curto do processo que
sobra (I7); a grafia `"$phase"` que o censo conta (I9); o catálogo que não alcança três sensores e
a sabotagem à mão (I10 a I12); o `RULES_FLOOR` (I12); a re-ancoragem do `TODO.md` em todo commit;
o `$rev:t` do zsh; a mensagem de pipe no idioma do locale.
