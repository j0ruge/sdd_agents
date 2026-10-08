---
missao: 20261008-lote-6-as-quatro-que-faltam
data: 2026-10-08
---

# Plano — Lote 6: as quatro que faltam

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Passo 0 — antes do I1 (não é incremento)

⚠️ **Esta missão mora num worktree ligado, e é aí que ela é executada** (ADR 0016 §2):

```
/home/joruge/repos/sdd_agents-lote-6     ← AQUI: branch fix/lote-6-as-quatro-que-faltam
/home/joruge/repos/sdd_agents            ← checkout principal: fica na `main`, NUNCA tocado
```

O `sdd` do `PATH` é o checkout **principal** (`readlink -f "$(command -v sdd)"` →
`/home/joruge/repos/sdd_agents/bin/sdd`), e todo `sdd run` de repo-alvo desta máquina executa o
código de lá. Por isso, quatro regras valem para a missão inteira:

1. **Toda sessão trabalha com `cwd` no worktree** e roda o runner como **`./bin/sdd`**, nunca como
   `sdd` nu (o `sdd` nu executa o código da `main`, e o `SDD_HOME` dele é o checkout principal).
   `preflight` e `install` vão com `env -u CLAUDECODE` quando rodados de dentro do Claude Code.
2. **Nada é escrito, commitado, `checkout`-ado nem `stash`-ado em `/home/joruge/repos/sdd_agents`.**
   Um arquivo não rastreado ali faz o `sdd run` de um alvo em voo parar como `kit-touched`
   (reproduzido na ADR 0016 §2). **Nunca `sdd run` sobre esta missão:** ela é executada
   interativamente, incremento a incremento.
3. **Ajudantes de `~/.claude/plans/2026-10-03-helpers/`:** o `remap.py` aceita `--root <dir>` (use
   `--root /home/joruge/repos/sdd_agents-lote-6`); o `sab.sh`, o `sab.py` e o `trymut.sh` têm o
   checkout principal fixo no código (medido) e **não** servem sem cópia editada. Sem eles, tudo se
   faz à mão (§ Mecânica da casa).
4. **Não edite o worktree enquanto a suíte, um `--only` ou um `sdd health` rodam nele:** a medição
   lê a árvore (um `kit-touched` falso no `check-autonomy.sh`, ou um carimbo de conteúdo errado).

O que o relay já fez antes do I1, com o humano presente:

- criou o worktree (`git worktree add ../sdd_agents-lote-6 -b fix/lote-6-as-quatro-que-faltam
  origin/main`, `origin/main` = `fc32329`) e copiou o mapa de assassinos de 676 linhas para
  `/home/joruge/repos/sdd_agents-lote-6/.sdd/cache/mutation-killers.tsv`;
- commitou o plano (esta pasta e a ADR 0017,
  `docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md`) e rodou `./bin/sdd approve`
  depois da pergunta YES/NO ao humano.

Confira antes do I1, no worktree:

1. `pwd -P` → `/home/joruge/repos/sdd_agents-lote-6`; `git branch --show-current` →
   `fix/lote-6-as-quatro-que-faltam`; `git status --short` → vazio.
2. `git -C /home/joruge/repos/sdd_agents branch --show-current` → `main` (só leitura).
3. `bash tests/check-todo.sh` → última linha `  ok    4 finding(s), all within 8 lines, carrying
   anchor + date, every anchor on target`.
4. `./bin/sdd why 20261008-lote-6-as-quatro-que-faltam PLAN` → `plan approved (humano-…)`. Se não
   disser isso, **pare** e peça ao humano: a aprovação é dele, e nenhuma sessão escreve `aprovacao:`.

**O fluxo de cada incremento** é o da casa (lotes 3–5, e o `agents/sdd-executor.md` desde o #243):

1. **Red pelo motivo certo.** Rode o Check da tabela **antes** do conserto e anote a saída. Escreva o
   probe novo e veja a linha `FAIL` dele (ou o `SENSOR-BROKEN`, no I1) no código de antes, com o
   texto do ramo certo, não de outro.
2. **Conserto.** Depois o refactor, se houver.
3. **Sabotagem DEPOIS do refactor, sobre o diff final** (#243): toda linha que o diff final
   acrescenta ou muda é degradada uma a uma, e toda linha que ele apaga é posta de volta; o sensor
   tem de ficar vermelho em cada uma. Em `bin/`: `tests/check-mutation.sh --only <SLUG> <sensor>`
   no mutante novo e nos vizinhos da mesma função. Em `tests/` e `agents/` (o catálogo não alcança):
   passada de sabotagem numa cópia (§ Mecânica). Prove que a sabotagem **aplicou** antes de concluir.
4. Sensores tocados inteiros, `shellcheck -S warning` nos arquivos tocados de `bin/` e `tests/`,
   `bash -n bin/sdd`, e `tests/check-mutation.sh --anchors` quando `bin/` ou `tests/check-mutation.sh`
   mudaram.
5. **Re-âncora do `TODO.md`:** `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`
   (§ Âncoras do `TODO.md` por incremento).
6. O commit do incremento.
7. Por último, um commit SEPARADO `chore(checkpoint): I<n> done (<hash>)`, com a linha do
   `checkpoint.md` (Status `done` e o hash curto **nu** do commit do passo 6) e uma nota appendada ao
   `checkpoint-notas.md` (`>>`, nunca reescrever): o Red medido, os desvios, as sabotagens e os
   mutantes reancorados.

**A anatomia do agente muda no MESMO commit do incremento que toca o componente** (regra do
`CLAUDE.md`, "Os sete componentes de um agente têm rule própria"). A edição é interativa.

| Incremento | Seção da `.claude/rules/anatomia-do-agente.md` |
|---|---|
| I3 | §6 "Dívida declarada", o parágrafo "A exceção é a **missão do próprio kit**": o `sdd kaizen` recusa o checkout que os alvos executam e manda para o worktree (ADR 0017) |
| I6 | §6 "Onde mora hoje", a frase da guarda de kit: a árvore suja chega ao `awk` por arquivo, NUL até lá, com o nome codificado |

O I1, o I2, o I4 e o I5 não tocam a anatomia (o I5 só troca o transporte; o I6 descreve o resultado
dos dois). O I7 só confere.

## Contexto verificado (não re-descobrir)

### Estado e números de partida (medidos em 2026-10-08, worktree em `fc32329`)

- **Suíte verde no HEAD do worktree:** `tests/run-all.sh` → `suite green`, rc 0, **548 s** de relógio
  com carga ~0,5. `catalogue anchors: …` → `  ok    anchors: all 676 mutants still apply and leave
  valid code`; `  ok    the catalogue lists 676 mutants (floor 420)`.
- **Catálogo:** `grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh` → **676**.
- **Backlog:** `bash tests/check-todo.sh` → `  ok    4 finding(s), … every anchor on target`;
  `bash tests/check-todo.sh --anchors TODO.md` → `  ok    anchors: 4 measured, 0 off target`.
  Catraca `tests/health-baseline.txt`: `todo-findings 4`.
- **Sensores:** 16 (`ls tests/check-*.sh`), mais `tests/run-all.sh` e `tests/isolate-git.sh`.
- **`tests/check-health.sh` sozinho:** 52 s, rc 0, 54 linhas `ok`.
- **Prazos por passo** (`step_timeout` de `tests/run-all.sh:172`): `gate state machine` 600 s,
  `autonomy ledger` 720 s, `kaizen series and gate` 120 s, `sdd health discriminates` 180 s,
  `every hat declares its boundary` 60 s. Os regimes novos do I5/I6 e os probes do I3 cabem com folga;
  se um passo crescer mais de 50% no relógio, re-meça antes de mexer no número (que só se move num
  commit com autor).
- **Ferramentas:** git 2.43.0, GNU coreutils 9.4 (`md5sum`), mawk 1.3.4 20240123 (o `awk` da
  máquina), bash. Shell interativo é **zsh**.
- **ADR 0017** alocada por `./bin/sdd adr new` (`docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md`,
  `Status: proposed`). `./bin/sdd adr check --mission 20261008-lote-6-as-quatro-que-faltam --phase
  plan` → `ok … and that ADR points back`, rc 0. O corpo (contexto, decisão, descartadas,
  consequências) já está escrito; o I7 só a aceita.

### Fatos medidos por item

- **#240, o limite:** uma variável de ambiente aceita **131 063 B** de valor
  (`KG_SUMS="$(head -c 131063 …)" awk 'BEGIN{}'` passa; 131 064 dá `Argument list too long`). É o
  `MAX_ARG_STRLEN` (131 072) menos `KG_SUMS=` e o NUL. Vale igual para argumento de linha de comando.
- **#240, reproduzido** sobre as funções extraídas (`sed -n '/^hat_status_lines() {/,/^}/p;/^kit_guard_tree() {/,/^}/p' bin/sdd`
  num script com `set -euo pipefail` e `SDD_HOME` apontando para um repo de rascunho): **1800**
  caminhos não rastreados `bulk/a-dirty-path-with-a-name-long-enough-to-count-NNNNN.md` (60 B cada,
  ~95 B por linha do `KG_SUMS`) → `/usr/bin/awk: Lista de argumentos muito longa`, **rc 126**; **801**
  caminhos → rc 0. Sob `set -e` a atribuição `KIT_GUARD_TREE="$( … awk … )"` mata o processo, então
  o `sdd run` do alvo morre no `kit_guard_arm`, **antes da sessão**.
- **#240, o nome com `\n`, reproduzido** do mesmo jeito: um kit com o não rastreado
  `notes<LF>draft.md` dá a árvore `?? notes<TAB>-` + `draft.md<TAB>-`, e depois de um `>>` no arquivo
  a árvore é **a mesma**: a guarda não vê a edição.
- **#240, o `mawk`:** aceita `RS="\0"` e mantém o `\n` dentro do registro (`printf 'a\nx\0b\0' |
  mawk 'BEGIN{RS="\0"} …'` → registros `a<LF>x` e `b`). Aceita também **atribuição entre operandos**
  (`mawk '…' RS="\\0" <(…) RS="\n" <(…)`): o `RS` muda por arquivo, e as atribuições contam em
  `ARGV`, então o 1º arquivo é `ARGV[2]` nesse exemplo (medido: `FILENAME == ARGV[2]` e
  `FILENAME == ARGV[4]`). Um process substitution vazio não gera registro, por isso
  `FILENAME == ARGV[n]` e nunca `NR == FNR`.
- **#240, o `md5sum`:** GNU 9.4 escreve um nome com `\`, LF ou CR como `\<md5>  <nome>` com `\\`,
  `\n` e `\r` dentro (medido: `\9dd4…  n\nl.md`, `\4152…  b\\s.md`). **Nunca `md5sum -z`**: só
  existe a partir do coreutils 8.30, e a retro de 2026-10-07 o recusou por isso.
- **#240, yokoten:** os `ENVIRON[...]` do runner são `ADR_KEY_RE`, `KG_BEFORE`, `KG_EXECS`,
  `KG_LINKS`, `KG_SUMS`, `SDD_FM_KEY`, `SDD_FM_VALUE`, `SDD_GATE_FIELD`, `SDD_PLACEHOLDER_TEXT`,
  `SDD_PROSE_CRITERIA`, `SDD_PROSE_MIN_GRADE`. Só os quatro `KG_*` carregam dado sem teto.
- **#239, o terceiro leitor:** o `gate_DOCS` (`bin/sdd:2194–2212`: o comentário em `:2194–2197`, o
  awk em `:2198–2212`, a regra final `is_fence { … }` em `:2211`) já lê a cerca como o CommonMark
  (abre em ```` ``` ````/`~~~` de 3+; fecha só com o mesmo caractere, comprimento ≥ e nada depois),
  e é seguro pelos mutantes `DOCS_fence_closes_on_other_char`, `_on_shorter` e `_with_info`
  (`tests/check-mutation.sh:611–619`), mortos pelo laço `for docs_fence_rule in tilde shorter info`
  de `tests/check-gates.sh:2765–2775`. Os dois leitores de bug: `bin/sdd:1560` (`{ infence =
  !infence; next }`) e `bin/sdd:1708` (`{ fenced = !fenced; next }`). Yokoten: `tests/check-todo.sh:561`
  recusa qualquer linha de cerca na seção de achados (não alterna), `tests/check-templates.sh:475`
  lê forma. Nenhum dos dois é da classe.
- **#238:** a regex do censo está em `tests/check-health.sh:1741` (a `:1740` é o `$0 == want`); o
  controle negativo, em `:1828–1841` (mundo de 5 arquivos, `broken` com rc 90 se o censo erra), com o
  comentário em `:1828–1832` ("Four sensors and a suite"); a asserção sobre a suíte real, em
  `:1842–1851`. O cabeçalho do bloco (`~:1696–1700`) também descreve o mundo de 5 ("five known
  answers", "`git` as a word"). O bloco inteiro roda **fora** de mutante (`if [ -z "${SDD_MUTANT:-}" ]`,
  `:1756`): o catálogo sabota só `bin/` e não o alcança. Nos 17 pontos de entrada, a única linha que
  não é comentário acima do `source` é o `set … pipefail` (medido).
- **#236:** o `cmd_kaizen` (`bin/sdd:10917`) tem, nesta ordem: o laço de opções (`--series`,
  `--dry-run`, `--all-repos`), o retorno do `--series` (antes do `load_config`), o `load_config`, a
  recusa de kit sem git, a recusa de identidade (`die "sdd kaizen plans the KIT's next mission — run
  it in the kit repo ($SDD_HOME)"`, por diretório git comum), o aviso de árvore suja, o
  `warn_if_on_base_branch`, a pseudo-missão, as notas, o gate e o `run_phase KAIZEN`. O
  `tests/check-kaizen.sh` monta o kit-fixture em `$FIX` (`FIX="$OUTSIDE/fix"`, e o `$OUTSIDE` é
  `mktemp -d`; o kit é montado em `:1018–1040`; `KSDD="$FIX/bin/sdd"`, com
  `bin templates config agents` copiados e commitados), põe `$OUTSIDE/stub` no PATH (`:1061`;
  `loud_stub`/`dead_stub` escrevem `$OUTSIDE/stub/claude`), e prova o worktree ligado em
  `:1878–1893` (`kz_door`, que roda `"$KSDD" kaizen --dry-run`). O PATH do processo de teste não tem
  `sdd` resolvendo dentro de `$FIX`, então nenhuma asserção de hoje muda com a recusa nova. A recusa
  de identidade está em `bin/sdd:10970–10977`. ⚠️ No ponto do bloco do issue 121 o `SDD_STATE_DIR`
  exportado (`$OUTSIDE/state`) já guarda um veredito para `aaa1111` (a corrida real responderia
  "already judged" sem abrir sessão, também no código de antes) e o stub ativo é o do approve
  (`:1817`), que commita em `$FIX`.
- **#236, o lembrete:** o `kaizen_reminder` (`bin/sdd:10695`) termina as duas frases com "run 'sdd
  kaizen' in the kit repo ($SDD_HOME)" — de um alvo, o `$SDD_HOME` é o checkout que o I3 passa a
  recusar. `tests/check-kaizen.sh:1243` lê o trecho "run 'sdd kaizen' in the kit repo", e
  `:1258–1261` leem "for the next kit mission plan" e "The kaizen judge counts them". Os mutantes
  `KAIZEN_reminder_dead`, `_wrong_repo` e `_per_worktree` (`tests/check-mutation.sh:3835–3851`)
  moram ali.
- **Bash:** 5.2.21; `mapfile -d ''` lê um fluxo NUL num array (medido: `a<LF>b` e `c` saem como dois
  elementos). Uma variável do bash **não** guarda NUL: `x="$(… -z …)"` descarta os NULs.
- **F8:** `grep -n 'designat' agents/sdd-planner.md` → nada. O § 4 do chapéu vai de `:78` a `:130`
  (`## 4. Slice into increments with sensors` até `## 5.`). Os probes de texto de chapéu moram em
  `tests/check-hat.sh` (`executor_agent_probes`, `hat_promise_probes`), e a lista de topo está em
  `:607–616`.

### Mecânica da casa que todo incremento usa

- **Ambiente de todo comando:** `mkdir -p /tmp/l6-exec`, depois `env -u CLAUDECODE TMPDIR=/tmp/l6-exec …`.
  O `TMPDIR` tem de ser curto: com um `TMPDIR` de ~100 caracteres (o do harness ou o do scratchpad),
  uma asserção do kit-guard em `check-autonomy.sh` reprova (declarado no sensor desde `0c0e13a`). O
  nome não começa com `sdd-`: o hook de limpeza apaga `/tmp/sdd-*` com mais de 10 min. Desde o #226
  a suíte, o catálogo e cada sensor limpam sozinhos as variáveis de repositório do git
  (`tests/isolate-git.sh`).
- **Suíte:** `bash tests/run-all.sh` → `suite green` (rc 0), ~9 min. Rode-a inteira depois do I2, do
  I3, do I6 e no I7. Entre elas, antes de cada commit, rode os sensores que o incremento toca, mais
  `bash tests/check-todo.sh`, `bash tests/check-lang.sh` e `bash tests/check-pipefail.sh` sempre que
  `tests/` ou `bin/` mudarem.
- **Mutante novo** = função `mut_<SLUG>() { sed -i '…' "$1"; }` em `tests/check-mutation.sh`, **mais**
  o `<SLUG>` no array `CATALOG=(` (`tests/check-mutation.sh:5973`).
  - O sed usa faixa `/^<função>() {/,/^}/` e âncora em CÓDIGO, nunca em número de linha nem em
    comentário. Modelos: `mut_QA_bug_deferred_decision_fenced` (`:1039`) e
    `mut_RUN_kit_guard_tree_no_mode` (`:4153`).
  - Prove com `tests/check-mutation.sh --only <SLUG> <sensor>`, com o sensor como **nome nu**
    (`check-gates.sh`); a linha verde é `  ok    <SLUG> — check-gates.sh dies (rc 1)`.
  - Depois `tests/check-mutation.sh --anchors` (segundos): todo mutante tem de **aplicar**. Um conserto
    que reescreve a linha que um mutante ancora faz o `--anchors` nomeá-lo; re-ancore no texto novo
    com a MESMA propriedade, ou aposente-o com o motivo escrito no comentário do catálogo e na nota.
- **Sensor que a mutação não alcança** (tudo em `tests/`, mais probe de texto de chapéu): a regra nova
  ganha probe, e o executor faz a **passada de sabotagem** numa cópia — `cp -a` do worktree para
  `/tmp/l6-exec/sab/kit` (dois níveis abaixo), `sed`/`perl` lá, o sensor rodado lá. Prove que a
  sabotagem aplicou (`cmp`/`grep` antes de rodar).
- **Shell é zsh:** nunca `path` como nome de variável; `"${r}:arquivo"`, nunca `$r:arquivo`;
  `echo ====` falha (aspas); laços e pipelines em `bash -c '…'`; mensagem de commit sempre por
  arquivo (`git commit -F <arquivo>`).
- **Armadilhas de bash da casa** (`CLAUDE.md`): `printf … | grep -q` sob `pipefail` inverte em
  entrada grande — use herestring; `grep -m<N>` sem `-q` é a mesma família; comentário `#` dentro de
  bloco continuado por `\` quebra o comando calado; função lida por `$( )` perde a atribuição a
  global (as funções desta missão são **chamadas** e publicam em global); `cd` relativo dentro de
  `$( )` leva `CDPATH=''`; o `mawk` é orientado a byte — classe negada só com ASCII, e
  `index()`/`substr()` para separador literal; dentro de regex de awk prefira classe (`[*]`, `[$]`,
  `[{]`) a escape.
- **Espelho dos agentes:** `agents/sdd-*.md` → `.claude/agents/` só por
  `env -u CLAUDECODE ./bin/sdd install --force` rodado **no worktree**. Nunca `cp`, nunca Edit. Confira
  com `git status --short` que só o espelho do chapéu mudou, e com `env -u CLAUDECODE ./bin/sdd
  preflight` que não há `agent <nome> stale`.
- **Idioma:** `bin/`, `agents/`, `commands/`, `docs/` (fora de `docs/handoffs/`, `docs/qa/` e
  `docs/superpowers/`), `README.md`, `config/schema.md` e `tests/` são superfície **inglesa** (inclui
  `docs/adr/` e `docs/failure-modes.md`). `TODO.md`, `CONTEXT.md`, `CLAUDE.md`, `KAIZEN_LOG.md`,
  `templates/`, `.claude/rules/` e os handoffs falam pt-BR. O sensor é `tests/check-lang.sh`.
- **Checks** (`templates/checkpoint.md`; `tests/check-checkpoint.sh --check` escaneia ESTE
  checkpoint): todo `grep` de saída de sensor ancora em `^  ok    `; nunca `|` cru; forma estrita
  `` `cmd` → `esperado` ``.
- **Formato do `TODO.md`:** item aberto com teto de 8 linhas físicas e 120 caracteres por linha.
  Consertado por commit: o corpo ganha ` RESOLVED by <hash>` (I7), e o item só sai no chore
  pós-merge (`templates/todo.pt-BR.md` § Ciclo de vida). **O título do item não muda** — é a chave
  do espelho de issues. Achado novo: item com âncora `path:N` (`símbolo`), data, e a catraca
  `tests/health-baseline.txt` +1 no MESMO commit.
- **Commits:** `<tipo>(<escopo>): <o quê>`, com o porquê no corpo (pt-BR), um por item.

### Âncoras do `TODO.md` por incremento (F8, aplicado a este plano)

As quatro âncoras abertas, em `fc32329`, e o que cada incremento faz com elas. O `check-todo.sh` está
no `TEST_CMD` e reprova âncora cujo símbolo designado sumiu ou ficou a mais de 10 linhas. Re-ancore
**no commit do incremento que desloca**, editando só o número (ou o símbolo, onde dito), nunca o
título.

| Item (issue) | Âncora em `fc32329` | I1 | I2 | I3 | I5 | I6 |
|---|---|---|---|---|---|---|
| #238 | `tests/check-health.sh:1733` (`gitenv_census`) | edita a função e o controle abaixo dela; desloca só se crescer comentário **acima** da `:1733` | — | — | — | — |
| #239 | `bin/sdd:1560` (`bug_decision_recorded`) | — | o `FENCE_AWK` entra acima (depois do `placeholder()`, `:1529`): desloca pelo tamanho do fragmento | — | — | — |
| #236 | `bin/sdd:10917` (`cmd_kaizen`) | — | desloca: + fragmento − linhas que saem do `gate_DOCS` | o helper novo entra logo acima: desloca pelo tamanho dele | desloca pelo saldo do `kit_guard_*` | desloca pelo saldo |
| #240 | `bin/sdd:4017` (`KG_SUMS`) | — | desloca: + fragmento − linhas do `gate_DOCS` | — | **apaga o símbolo**: re-designe para `` (`kit_guard_tree`) `` na linha da definição da função | desloca pelo saldo |

**Números de prosa que um incremento anterior muda** (re-meça no estado depois dele, nunca copie
daqui): o tamanho do catálogo (676 → 679 no I2 → 683 no I3 → + os do I5/I6 − aposentados), o mundo do
controle do censo (5 → 8 arquivos, I1), as linhas citadas deste plano (todas de `fc32329`; ache
pelo símbolo).

## Arquitetura da mudança

Cinco frentes, nenhuma infraestrutura nova (princípio 6). Uma muda um contrato com o humano (o
`sdd kaizen`), uma funde três cópias numa definição, as outras apertam sensores e o canal da guarda.

| Frente | Incrementos | Arquivos | Contrato / ADR |
|---|---|---|---|
| Censo do `GIT_DIR` | I1 | `tests/check-health.sh` (`gitenv_census`, o controle negativo) | nenhum |
| Cerca CommonMark única | I2 | `bin/sdd` (`FENCE_AWK` novo, `bug_decision_recorded`, extrator do gênero no `gate_QA`, leitor de proposta do `gate_DOCS`), `tests/check-gates.sh`, `tests/check-mutation.sh` | uma definição para três leitores (decisão 3) |
| Onde o juiz roda | I3 | `bin/sdd` (`cmd_kaizen` + um helper, `kaizen_reminder`), `tests/check-kaizen.sh`, `tests/check-mutation.sh`, `README.md`, `docs/pipeline.md`, `docs/failure-modes.md`, `CONTEXT.md`, `.claude/rules/anatomia-do-agente.md` | ADR 0017 (emenda a 0016 §2) |
| O plano mede contra o disco | I4 | `agents/sdd-planner.md` § 4 (+ espelho), `tests/check-hat.sh`, a gaveta (índice e § F8) | nenhum |
| O canal da guarda de kit | I5, I6 | `bin/sdd` (`kit_guard_tree`, `kit_guard_changes`, `hat_status_lines`), `tests/check-autonomy.sh`, `tests/check-mutation.sh`, `docs/failure-modes.md` | um parser, dois modos (decisão 5) |

## Incrementos

A tabela executável vive em `checkpoint.md`. A ordem: I1 (só `tests/`, o mais barato), I2 e I3 (os
dois consertos de `bin/` independentes), I4 (o chapéu), I5 e I6 (a #240, por último — decisão 2), I7
(o fecho). Os "antes" de cada Check foram medidos pelo `tests/check-checkpoint.sh --red` sobre este
checkpoint, no worktree em `fc32329` + o plano.

### I1 — #238: o censo do `GIT_DIR` conta o git chamado por caminho e pela variável `GIT`

**O quê:** o `gitenv_census` passa a contar como "git" uma linha que chama o binário por caminho
terminado em `/git` (`/usr/bin/git init`, `"$ROOT/bin/git" log`) e uma que o chama pela variável
`GIT` exata (`$GIT`, `${GIT}`, `"$GIT"`). `$GIT_DIR`, `$GIT_WORK_TREE` e afins **não** contam
(decisão P2 do planner).

**Onde:** `tests/check-health.sh` — a regex do awk do censo (`:1741`), o comentário do censo, o
controle negativo (`:1828–1841`) e o comentário dele (`:1828–1832`), o cabeçalho do bloco
(`~:1696–1700`, que fala em cinco respostas e em "`git` as a word"), e uma asserção `pass` nova logo
depois do controle. Se o cabeçalho crescer, a âncora do #238 (`:1733`) desloca.

**Como (TDD):**
1. **Red.** O mundo do controle ganha três arquivos, escritos como os de hoje (`printf '%s\n' …`):
   - `check-abspath.sh`: `#!/usr/bin/env bash`, `set -uo pipefail`, `/usr/bin/git init -q "$box"`, e
     só então `"$GITENV_SOURCE"`;
   - `check-var.sh`: o mesmo com `"$GIT" init -q "$box"` antes do `source`;
   - `check-gitdir.sh`: `[ -z "${GIT_DIR:-}" ] || echo "$GIT_DIR" "$b/.git" /usr/lib/git-core/x`
     antes do `source` e nenhum git — o censo **não** pode nomeá-lo. A linha é escolhida para que cada
     afrouxamento a nomeie: a variável alargada (`$GIT_DIR`), o caminho sem o `/` à esquerda (`.git"`)
     e o caminho sem a classe da direita (`/git-core`). Medido em mawk pelo teste de autocontenção: o
     censo consertado dá 0 nela, e cada sabotagem dá 1.

   O controle passa a exigir `GITENV_MISSING = 'check-abspath.sh check-late.sh check-none.sh
   check-var.sh'` e `GITENV_SEEN = 8` (a ordem é a do glob: `check-abspath`, `check-gitdir`,
   `check-good`, `check-late`, `check-nogit`, `check-none`, `check-var`, depois de `run-all.sh`), e
   o texto do `broken` passa a descrever o mundo de 8. Logo depois do `broken`, antes de
   `gitenv_census "$ROOT/tests"`, entra
   `pass 'surface: the gitenv census names a git run by path or by variable before the source'`.

   No código de antes o censo responde `check-late.sh check-none.sh` e o sensor sai **rc 90** com
   `SENSOR-BROKEN  gitenv census: a world with …` — é o Red (o controle é `broken`, não `fail`, por
   desenho: censo errado é sensor quebrado).
2. **Conserto.** Mais duas alternativas na condição do `first`, mantendo a da palavra como está. A
   forma sugerida, com classes em vez de escapes (mawk):
   `$0 ~ /\/git([^[:alnum:]_.-]|$)/` (caminho terminado em `/git`; o `.` à direita exclui
   `/git.sh`, o `-` exclui `/git-lfs`) e `$0 ~ /[$]([{]GIT[}]|GIT([^[:alnum:]_]|$))/` (a variável
   `GIT` exata). Confira que a própria linha do `source`
   (`. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"`) **não** casa nenhuma das três — ela tem
   `-git.` e não `/git` — e que `$b/.git` também não.
3. **Comentário do censo:** o que conta como git, e o **limite declarado**: variável de nome
   arbitrário (`"$g" init`) é indecidível numa regex de linha, como o operando variável do `cd` na
   RULE 2 do `check-pipefail.sh`.

**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    surface: the gitenv census names a git run by path or by variable' <<< "$o"` → `1`
**Antes:** `0` (a asserção não existe).

**Sabotagem (passada manual, o catálogo não alcança `tests/`):** (a) tirar a alternativa do caminho
→ `check-abspath.sh` some do resultado → `broken`; (b) tirar a da variável → `check-var.sh` some →
`broken`; (c) alargar a variável para `GIT[A-Z_]*` → `check-gitdir.sh` aparece → `broken`;
(d) tirar o `/` da alternativa do caminho → `check-gitdir.sh` aparece (`.git"`) → `broken`;
(e) tirar a classe da direita do caminho → `check-gitdir.sh` aparece (`/git-core`) → `broken`;
(f) tirar o `[}]` da variável → conferir; (g) tirar a linha `pass` → Check `0`. Cada uma anotada na
nota do I1; a que sobreviver vira probe ou limite declarado no comentário do censo.

**Sensor durável:** o controle negativo do censo, que roda no `TEST_CMD` em todo gate. Sem mutante:
o bloco roda fora de `SDD_MUTANT` e o catálogo só sabota `bin/` — a prova é a passada de sabotagem,
como nas outras regras de `tests/`.

**Âncoras / mutantes tocados:** a do #238 (`gitenv_census`), só se crescer comentário acima da
`:1733`. Nenhum mutante. O `GITENV_FLOOR=17` não muda (a suíte real não muda).

**Reversível por:** `git revert` do commit.

### I2 — #239: uma cerca CommonMark para os três leitores (`FENCE_AWK`)

**O quê:** um fragmento de awk numa variável, `FENCE_AWK`, define a cerca **uma vez**. Os três
leitores de cerca do runner o concatenam no seu programa, no molde do `PLACEHOLDER_AWK`
(`bin/sdd:1495`, usado em `:1529` e `:1896`): `awk "$FENCE_AWK"' … '`.

**Onde:** `bin/sdd` — o fragmento logo depois do `placeholder()` (`:1529`). ⚠️ O fragmento é uma
string bash entre **aspas simples**: nem o código nem o comentário dele podem conter apóstrofo (o
`PLACEHOLDER_AWK` evita pelo mesmo motivo); `bug_decision_recorded`
(`:1558–1567`, e o comentário `:1531–1557`, cujo parágrafo sobre `infence` deixa de valer); o
extrator do gênero no `gate_QA` (`:1704–1712`); o leitor da proposta no `gate_DOCS` (`:2194–2212`,
cujo comentário de cerca, `:2194–2197`, muda para o fragmento). `tests/check-gates.sh`: quatro asserções novas.
`tests/check-mutation.sh`: cinco mutantes reancorados e três novos.

**O contrato do fragmento** (a forma é do executor; a regra é esta, e é a do `gate_DOCS` de hoje):

```awk
# fence_line(l) — 1 when l opens or closes a fence, updating the state `fence`; 0 otherwise
function fence_line(l,   run, ch, len) {
  if (!match(l, /^[ \t]*(```+|~~~+)/)) return 0
  run = substr(l, RSTART, RLENGTH); sub(/^[ \t]+/, "", run)
  ch = substr(run, 1, 1); len = length(run)
  if (!fence) { fence = 1; fch = ch; flen = len; return 1 }
  if (ch == fch && len >= flen && l ~ /^[ \t]*(`+|~+)[ \t]*$/) { fence = 0; return 1 }
  return 0
}
```

E os leitores:
- `bug_decision_recorded`: `fence_line($0) { next }` e `fence { next }` no lugar de
  `/^[[:space:]]*(```|~~~)/ { infence = !infence; next }` e `infence { next }`;
- o extrator do gênero: a mesma troca, **depois** da primeira regra
  (`!/^-[[:space:]]+[*][*][^*]+:[*][*]/ { if (inheader) exit }`), que fica onde está;
- o `gate_DOCS`: uma regra `{ fence_line($0) }` no topo do programa no lugar do bloco que calcula
  `is_fence`, e a última regra (`is_fence { … }`) sai. A ordem não muda o resultado: a linha de cerca
  nunca é a do marcador nem um `## `, e o `on { print }` a imprime nos dois casos. As linhas
  `!fence && /^[[:space:]]*<!-- sdd:proposed -->[[:space:]]*$/ { on = 1; next }` e
  `on && !fence && /^## / { on = 0 }` ficam **byte a byte** como estão: cinco mutantes do `gate_DOCS`
  as ancoram (`DOCS_proposal_fence_blind`, `DOCS_marker_in_fence`, `DOCS_proposal_runs_past_heading`,
  `DOCS_proposal_first_section_only`, e o `DOCS_marker_unanchored` na do marcador).

Os limites que o comentário do fragmento declara (não mudam o comportamento de hoje do `gate_DOCS`):
indentação de 4+ espaços abre cerca aqui (no CommonMark é bloco indentado); uma crase dentro da info
string de uma cerca de crases não é recusada; uma cerca sem fecho vai até o fim do arquivo (como no
CommonMark).

**Como (TDD):**
1. **Red.** Quatro asserções novas em `tests/check-gates.sh`, todas com o prefixo `fence: `:
   - perto das da decisão (depois da `a '## Decision' heading inside a fence is not the decision`,
     `:1127`), dois mundos de `write_genre_bug '- **Closable by:** deferred <!-- agent | human |
     deferred -->' "<corpo>"` comparados com o controle `$genre_decided` (`REVIEW`):
     - `fence: a ~~~ inside a backtick fence does not close it — a quoted dated decision does not count`
       — corpo `"$(printf '\nThe template reads:\n\n```md\n~~~\n## Decision\n\n2026-01-02, the repo owner.\n```')"`,
       esperado `REVIEW|QA`;
     - `fence: a shorter run does not close a longer fence — a quoted dated decision does not count`
       — corpo com ```` ````md ```` na abertura, uma linha ```` ``` ```` antes do `## Decision`
       datado, e ```` ```` ```` no fecho; esperado `REVIEW|QA`;
   - perto do `a whole header quoted inside a fence above the real one` (`:927–941`), dois mundos
     com o cabeçalho inteiro citado numa cerca **acima** do real (`Closable by: human` citado,
     `Closable by: agent` real), comparados com `$genre_exact`:
     - `fence: a ~~~ inside a backtick fence does not close it — a quoted header does not become the genre`
       — a cerca abre com ```` ```md ````, a linha seguinte é `~~~`, depois o `Status:` e o
       `Closable by: human` citados, e ```` ``` ```` fecha; esperado `REVIEW|QA`;
     - `fence: a shorter run does not close a longer fence — a quoted header does not become the genre`
       — ```` ````md ````, uma linha ```` ``` ````, o cabeçalho citado, ```` ```` ````; esperado `REVIEW|QA`.

   No código de antes, nos quatro, a linha interna (`~~~` ou ```` ``` ````) **fecha** a cerca: o
   `## Decision` datado conta (a QA passa: `REVIEW|REVIEW`) e o `Closable by: human` citado vira o
   gênero (não barra: `REVIEW|REVIEW`). Veja os quatro `FAIL` com esse `got`.

   **E três mundos positivos, um por leitor, também com o prefixo `fence: `** — sem eles, uma cerca
   que **nunca fecha** (`{ fence = 0; return 1 }` → `{ return 1 }`, ou o `fch = ch` apagado) sobrevive
   à sabotagem, porque todo mundo cercado de hoje (`check-gates.sh` `:868`, `:887`, `:927`, `:983`,
   `:1065`, `:1078`, `:1125`, `:2744`, `:2758`, `:2765`) e os quatro novos esperam um bloqueio
   (achado do teste de autocontenção):
   - `fence: after a closed example fence the real dated decision counts — the bug passes` — corpo com
     uma cerca de exemplo **fechada** (sem `## Decision` dentro) e depois o `$GENRE_DECIDED` real;
     esperado `REVIEW`;
   - `fence: after a closed fence quoting an agent header the real human header is the genre` — uma
     cerca fechada citando `Status:` + `Closable by: agent`, e o cabeçalho real com `Closable by:
     human` abaixo; esperado `REVIEW` (o gênero humano não barra);
   - `fence: after a closed example fence the real proposal counts` — no `gate_DOCS`, uma cerca de
     exemplo fechada e depois a seção `<!-- sdd:proposed -->` real que nomeia o documento ⛔;
     esperado o mesmo do mundo de proposta válida que o `check-gates.sh` já tem (a fase sai do DOCS).

   No código de antes os três passam (são controles); com a cerca que nunca fecha, os três reprovam.
2. **Conserto:** o fragmento e os três leitores, como acima.
3. **Mutantes** (`tests/check-mutation.sh`):
   - **reancorar** `DOCS_fence_closes_on_other_char`, `DOCS_fence_closes_on_shorter` e
     `DOCS_fence_closes_with_info` (`:611–619`) da faixa `/^gate_DOCS() {/,/^}/` para o texto do
     fragmento (faixa `/^FENCE_AWK='/,/^'/`, ou sed sem faixa sobre uma string única dele). Eles
     passam a sabotar os **três** leitores, então o nome `DOCS_` mente: renomeie para
     `FENCE_closes_on_other_char`, `FENCE_closes_on_shorter`, `FENCE_closes_with_info` (no `CATALOG`
     também; o mapa de assassinos só perde a dica de ordem desses três);
   - **reancorar** `QA_bug_genre_fenced` (`:972`, hoje um sed **sem faixa** sobre
     `{ fenced = !fenced; next }`) para a faixa `/^gate_QA() {/,/^}/`, apagando a linha
     `fence { next }` do extrator (o conteúdo da cerca volta a ser lido) — morre em `a whole header
     quoted inside a fence above the real one`;
   - **reancorar** `QA_bug_deferred_decision_fenced` (`:1039`; ele **já** usa a faixa
     `/^bug_decision_recorded() {/,/^}/`, só o texto substituído muda): passa a apagar a linha
     `fence { next }` dela — morre em `a '## Decision' heading inside a fence is not the decision`;
   - **novos, um por leitor** (decisão 3), cada um devolvendo ao leitor a cerca frouxa de hoje
     (`fence_line($0) { next }` → `/^[[:space:]]*(```|~~~)/ { fence = !fence; next }`, e no
     `gate_DOCS` a regra `{ fence_line($0) }` → a mesma alternância):
     `QA_bug_deferred_decision_fence_loose` (morre nos dois `fence: … decision`),
     `QA_bug_genre_fence_loose` (morre nos dois `fence: … genre`), `DOCS_fence_loose` (morre no laço
     `tilde|shorter|info` de `:2765`).
   - Catálogo: 676 → **679**. Prove cada um com `--only <SLUG> check-gates.sh`, e rode `--only` também
     nos vizinhos: os 16 com faixa `gate_DOCS`, os 6 com faixa `bug_decision_recorded`, e os do
     extrator, que são **sem faixa** — `QA_bug_genre_outside_header`, `QA_bug_genre_header_unbounded`,
     `QA_bug_genre_prefix`, `QA_bug_genre_anywhere` (não "os 6 do `gate_QA`").

**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    fence: ' <<< "$o"` → `7`
**Antes:** `0`.

**Sensor durável:** as sete asserções `fence: ` e os três mundos do laço `docs_fence_rule` do
`gate_DOCS`, mais os oito mutantes acima.

**Âncoras / mutantes tocados:** o fragmento desloca as âncoras do #239, #236 e #240 (tabela F8
acima). Mutantes: os 5 reancorados e os 3 novos, listados acima; o `--anchors` diz se algum outro
do `gate_DOCS` deixou de aplicar.

**Reversível por:** `git revert` do commit.

### I3 — #236: o `sdd kaizen` recusa o checkout que os alvos executam (ADR 0017)

**O quê:** decisão 1, P1 e ADR 0017. Um helper, chamado e nunca `$( )`-capturado:

```bash
# rc 0 when REPO_ROOT is the checkout the `sdd` on the PATH resolves into — the test of step 2 of
# /sdd-plan, trailing slash included, so a sibling such as <root>-kaizen is never taken for it.
kit_checkout_targets_run() {
  local p
  p="$(command -v sdd 2>/dev/null)" || return 1
  p="$(readlink -f -- "$p" 2>/dev/null)" || return 1
  case "$p" in "$REPO_ROOT"/*) return 0 ;; esac
  return 1
}
```

No `cmd_kaizen`, **logo depois** da recusa de identidade e **antes** do aviso de árvore suja:
- sem `--dry-run`: `die` com a frase da ADR 0017 — por que (todo `sdd run` de alvo executa este
  checkout; uma sessão KAIZEN que commita aqui os para com `KIT-TOUCHED`, ADR 0017) e o remédio
  inteiro, **o mesmo texto da ADR 0017 § Decision**: `git -C <root> fetch && git -C <root> worktree
  add ../<repo>-kaizen -b kaizen/<YYYYMMDD> origin/<DEFAULT_BRANCH>` (`<repo>` = o basename do root),
  depois `sdd kaizen` de lá — fetch, nunca pull. Rc 1, nenhuma sessão, nenhuma linha de ledger,
  nenhum hook;
- com `--dry-run`: `warn "a real run here would refuse: <a mesma frase>"` e a projeção segue (P1);
- `--series` não chega aqui (retorna antes); `sdd` fora do PATH ou resolvendo fora do root: nada muda.

A frase é **uma** definição (uma variável ou função local), lida pelo `die` e pelo `warn`.

**O lembrete muda junto (P6):** as duas frases do `kaizen_reminder` (`bin/sdd:10695`) que terminam em
"run 'sdd kaizen' in the kit repo ($SDD_HOME)" passam a dizer que o juiz roda de um worktree ligado
do kit (ADR 0017), mantendo o trecho "run 'sdd kaizen' in the kit repo" — por exemplo "run 'sdd
kaizen' in the kit repo, from a linked worktree of it (ADR 0017; the kit is $SDD_HOME)". A asserção
`pointing at sdd kaizen` (`tests/check-kaizen.sh:1243`) ganha o termo `linked worktree` no `grep`.
Sem mutante novo para a frase (é prosa de um lembrete; a porta que ela descreve tem os quatro); os
três `KAIZEN_reminder_*` (`tests/check-mutation.sh:3835–3851`) têm de continuar aplicando.

**Onde:** `bin/sdd` (`cmd_kaizen`, `:10917`, recusa de identidade em `:10970–10977`; o helper logo
acima dele; `kaizen_reminder`, `:10695`); `tests/check-kaizen.sh` (a asserção de `:1243`, e os probes
novos depois do bloco do issue 121, que termina em `:1893`, antes de
`echo "== the base branch warning reaches the kaizen door =="`, `:1895`); `tests/check-mutation.sh`.
No mesmo commit (contrato com o humano mudou): `README.md:96` (o comentário do `sdd kaizen`),
`docs/pipeline.md` § The kaizen loop (`:1431`), `docs/failure-modes.md` (verbete novo, ao lado de
"The line stopped with `kit-touched`", `:596`: sintoma = a frase do `die`; o que fazer = o
`git worktree add` e `sdd kaizen` de lá), `CONTEXT.md` (verbete **Janela de medição**: a frase
"Rodado da `main` durante uma janela, ele commita na `main` e move o eixo. Durante a janela use
`sdd kaizen --dry-run`…" passa a dizer que a corrida real recusa o checkout dos alvos e que a
projeção avisa e segue) e a anatomia §6 (tabela do Passo 0).

**Como (TDD):**
1. **Red.** Seis asserções `kaizen door: …` em `tests/check-kaizen.sh`. O mundo:
   `KPATH="$OUTSIDE/kaizen-pathbin"` com `ln -s "$KSDD" "$KPATH/sdd"`; um worktree ligado **irmão de
   nome mais longo**, `KWT2="${FIX}-kaizen"` (`git -C "$FIX" worktree add -q -b kaizen/shared-fixture
   "$KWT2"`; o `bin/sdd` vem junto, porque o fixture o commitou); um segundo
   `KPATH2="$OUTSIDE/kaizen-pathbin2"` com `ln -s "$KWT2/bin/sdd" "$KPATH2/sdd"`. Cada corrida com
   `PATH="$KPATH:$PATH"` (ou `KPATH2`) e um `SDD_STATE_DIR` **novo e vazio** por corrida
   (`mkdir -p "$OUTSIDE/shared-<x>"`): com ele a série tem `latest: null`, o gate fica pendente, o
   código de antes abre a sessão e a projeção nova sai rc 0. Não use o `$OUTSIDE/state` exportado: ele
   guarda o veredito de `aaa1111` e a corrida real responderia "already judged" sem sessão já no código
   de antes (Red falso). **Chame `loud_stub` antes** (o stub ativo naquele ponto é o do approve,
   `:1817`, que commita em `$FIX`). A testemunha de "nenhuma sessão" é a contagem de linhas
   `"event":"session"` no `autonomy-log.jsonl` daquele diretório, guardada porque o arquivo não existe
   depois do conserto: `n=$(grep -c '"event":"session"' "$d/autonomy-log.jsonl" 2>/dev/null || true)`
   e `${n:-0}`.
   - `kaizen door: the checkout the PATH's sdd runs from is refused before any session, naming git worktree add`
     — corrida real de `$FIX` com `KPATH`: esperado `rc:1 named:1 sessions:0` (`named` = `grep -c
     'git -C .* worktree add'` na saída);
   - `kaizen door: the projection there warns with the same sentence and still projects` —
     `--dry-run` de `$FIX` com `KPATH`: esperado `rc:0 warned:1` (`warned` = a frase do aviso);
   - `kaizen door: a linked worktree of that checkout is admitted under the same PATH` —
     `--dry-run` de `$KWT2` com `KPATH`: esperado `rc:0 warned:0`;
   - `kaizen door: a sibling whose name extends this one is not taken for it` — `--dry-run` de
     `$FIX` com `KPATH2` (o `sdd` resolve em `${FIX}-kaizen/bin/sdd`): esperado `rc:0 warned:0`;
   - `kaizen door: --series still reads from that checkout` — `--series` de `$FIX` com `KPATH`:
     esperado `rc:0 json:1` (`jq -e .guard` responde);
   - `kaizen door: with no sdd on the PATH nothing is refused` — `--dry-run` de `$FIX` com
     `PATH="$OUTSIDE/stub:/usr/local/bin:/usr/bin:/bin"`: esperado `armed:1 rc:0 warned:0`, onde
     `armed` prova que o veneno está armado (`command -v sdd` falha sob esse PATH; sem isso a
     asserção não mede nada). É o mundo do ramo `|| return 1` do `command -v` do helper.

   O ramo `|| return 1` do `readlink -f` não tem mundo (o `readlink -f` de um caminho que o
   `command -v` achou não falha nesta máquina): fica declarado no comentário do helper e na ADR 0017.

   No código de antes, a 1ª e a 2ª reprovam (a corrida real abre a sessão do `loud_stub`, e a
   projeção não avisa) e as outras quatro passam — são os controles; o par 1/3 é o diferencial (mesmo
   PATH, dois checkouts) e o par 3/4 prova a barra final. Limpe no fim:
   `git -C "$FIX" worktree remove --force "$KWT2"` e `git -C "$FIX" branch -q -D kaizen/shared-fixture`.
2. **Conserto:** o helper e as duas chamadas.
3. **Mutantes** (+4; catálogo 679 → **683**): `KAIZEN_shared_checkout_admitted` (a recusa vira
   no-op), `KAIZEN_shared_checkout_projection_silent` (o `warn` da projeção some),
   `KAIZEN_shared_checkout_prefix` (`"$REPO_ROOT"/*` → `"$REPO_ROOT"*`, morre no mundo do irmão),
   `KAIZEN_shared_checkout_no_sdd` (o `|| return 1` do `command -v` → `|| return 0`, morre no mundo
   sem `sdd` no PATH).
   Faixas `/^cmd_kaizen() {/,/^}/` e `/^kit_checkout_targets_run() {/,/^}/`. Vizinhos com `--only`:
   os 3 de hoje no `cmd_kaizen`.
4. **Docs** no mesmo commit (lista em "Onde"), em inglês na superfície e em pt-BR no `CONTEXT.md` e na
   anatomia.

**Check:** `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    kaizen door: ' <<< "$o"` → `6`
**Antes:** `0`.

**Sensor durável:** as seis asserções, a de `:1243` com o termo novo, e os quatro mutantes.

**Âncoras / mutantes tocados:** a do #236 (`cmd_kaizen`) desloca pelo tamanho do helper. Mutantes: os
3 de hoje do `cmd_kaizen` e os 3 `KAIZEN_reminder_*` continuam aplicando (o `--anchors` confirma).

**Reversível por:** `git revert` do commit (a ADR 0017 fica `proposed` até o I7).

### I4 — F8: o `sdd-planner` mede cada incremento contra o disco que os anteriores deixam

**O quê:** decisão 4. Um parágrafo `⚠️` no § 4 do `agents/sdd-planner.md` (depois do bullet "**the
size of one session.**"), em inglês, com estas três frases-chave **literais** (o probe as lê):

> ⚠️ **Measure each increment against the disk the earlier ones leave, not against the base.** For
> every increment, grep the symbols the open items of `TODO.md` designate (`` `path:N` (`symbol`) ``)
> against the lines it will edit, move or delete: an increment that edits a designated symbol, or
> moves it more than 10 lines, re-anchors that item in its own commit (`tests/check-todo.sh
> --anchors <TODO_FILE>`), and the plan says which increment re-anchors which item. A number the plan
> writes in prose that an earlier increment changes — a count of mutants, sensors or rows — is
> re-measured in the state after that increment, never copied from the base.

**Onde:** `agents/sdd-planner.md` § 4 (`:78–130`); `.claude/agents/sdd-planner.md` por
`env -u CLAUDECODE ./bin/sdd install --force`; `tests/check-hat.sh` (função nova
`planner_agent_probes`, na lista de topo `:607–616`); a gaveta
(`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): a linha F8 do índice → "fechada pelo I4 de
`20261008-lote-6-as-quatro-que-faltam`", e o § F8 ganha a mesma nota (regra do `CLAUDE.md`: frente
que fecha atualiza o índice no mesmo commit).

**Como (TDD):**
1. **Red.** `planner_agent_probes` lê o § 4 como **seção** (`awk '/^## 4\. /{s=1; next} s && /^## /{s=0} s'`,
   no molde do `command_worktree_probes`), e exige as três: `against the disk the earlier ones leave`,
   `tests/check-todo.sh --anchors` e `re-measured in the state after that increment`. Verde:
   `pass "hat: the planner measures each increment against the disk the earlier ones leave (TODO.md anchors and prose numbers)"`;
   vermelho: `fail "hat: sdd-planner no longer measures each increment against the disk the earlier ones leave"`.
   No chapéu de antes → `FAIL`.
2. **Conserto:** o parágrafo; o espelho por `install --force` (confira com `git status --short` que só
   `agents/sdd-planner.md` e `.claude/agents/sdd-planner.md` mudaram, e `preflight` sem `stale`).
3. **Sabotagem** (o catálogo não alcança `agents/`): apagar cada uma das três frases → `FAIL`; mover o
   parágrafo para o § 5 → `FAIL` (prova que a leitura é por seção); tirar `planner_agent_probes` da
   lista de topo → Check `0`.

**Check:** `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: the planner measures each increment against the disk the earlier ones leave' <<< "$o"` → `1`
**Antes:** `0`.

**Sensor durável:** o probe `hat:` no `TEST_CMD`. O `tests/check-lang.sh` lê o `agents/` como
inglês: rode-o.

**Âncoras / mutantes tocados:** nenhum.

**Reversível por:** `git revert` do commit (e `./bin/sdd install --force` de novo).

### I5 — #240, fatia 1: o canal da guarda de kit sai do ambiente

**O quê:** decisão 2 e P3. Nenhum dado da árvore passa mais por variável de ambiente nem por argumento.
- `kit_guard_tree` (`bin/sdd:3984–4033`): `KG_SUMS`, `KG_EXECS` e `KG_LINKS` deixam de existir. Os
  três fluxos chegam ao `awk` como **arquivos** por process substitution (`<(printf '%s' "$sums")`,
  `printf` é builtin, sem `exec` e sem limite), cada um lido sob `FILENAME == ARGV[n]` com `next`, ao
  lado do índice (que já é `ARGV[1]`) e antes do status (o `-` do stdin, último). O que hoje é o laço
  do `BEGIN` vira a regra do arquivo correspondente, com a **mesma** lógica (o registro escapado do
  md5sum, o `l` do link, o `+x`).
- `kit_guard_changes` (`:4047–4064`): `KG_BEFORE` deixa de existir; a árvore anterior chega como o
  `ARGV[1]` (`<(printf '%s\n' "$1")`), e o laço do `BEGIN` vira a regra desse arquivo (o `ord[]` na
  ordem do arquivo, como hoje). A árvore de depois continua no stdin.
- A semântica não muda: as mesmas linhas publicadas, os mesmos motivos. Só o transporte.

**Onde:** `bin/sdd` (as duas funções e o comentário de `ENVIRON and not -v` em `:4005`, que passa a
dizer "arquivo, e nunca ambiente nem `-v`: o ambiente tem teto de 131 063 B por variável — #240");
`tests/check-autonomy.sh` (regime novo); `tests/check-mutation.sh` (re-âncoras).

**Como (TDD):**
1. **Red.** Regime **2k**, logo depois do 2j (`tests/check-autonomy.sh:6143–6174`), no molde do 2b
   (`kitguard_dirty_run`, `:5905`), com diretórios de alvo **novos** (`$OUTSIDE/kitguard-bulk-edit` e
   `$OUTSIDE/kitguard-bulk-alone`). Antes das duas corridas, o kit falso ganha em `$FAKEKIT/bulk/`
   (não está no `.gitignore` do kit, conferido) sujeira que estoura **os quatro** canais, cada um
   acima de 131 063 B — senão devolver um deles ao ambiente sobrevive à sabotagem (achado do teste de
   autocontenção):
   - **1000 arquivos regulares executáveis** (`chmod +x`) com nomes de ~200 B (componente < 255 B):
     `KG_SUMS` ≈ 1000 × 235 B, `KG_EXECS` ≈ 1000 × 201 B, e as linhas da árvore (`KG_BEFORE`) ≈
     1000 × 240 B;
   - **700 symlinks** com nomes de ~200 B (`ln -s` para um arquivo qualquer do bulk): `KG_LINKS` ≈
     700 × 235 B. O laço dos links abre um subshell por symlink por chamada; 700 × 4 chamadas fica em
     segundos — meça o relógio do passo antes e depois.

   O `kitguard_reset` **não** limpa o `$FAKEKIT`: no fim, `rm -rf "$FAKEKIT/bulk"`. Pode ser uma
   variante `kitguard_dirty_run_bulk` ou um parâmetro do `kitguard_dirty_run`. Asserção:
   `kit-guard: a kit with thousands of dirty paths still opens the session, sees the edit, and stays silent left alone`,
   esperado o mesmo do 2b: `sessions:1 lines:1 rc:3 kind:kit-touched same:1 named:1|sessions:2 lines:0 rc:3 kind:no-progress same:0 named:0`.
   No código de antes as duas corridas morrem no `kit_guard_arm` antes da sessão (`sessions:0`, o rc do
   `Argument list too long`, 126 nas funções extraídas): veja o `FAIL` com esse `got`.
2. **Conserto:** as duas funções, como acima.
3. **Mutantes:** os 9 ancorados em `/^kit_guard_tree() {/` e os 6 em `/^kit_guard_changes() {/`
   (`tests/check-mutation.sh:4120–4207`: `RUN_kit_guard_tree_no_content`, `_tree_no_mode`,
   `_tree_no_index`, `_index_no_mode`, `_md5_options`, `_md5_escape_kept`, `_md5_escape_prefix`,
   `_link_unhashed`, `_link_followed`, `_no_longer_dirty_silent`, `_no_longer_dirty_hash_order`,
   `_key_first_tab`, `_mode_reads_as_content`, `_index_reads_as_mode`, `_index_reads_as_content`).
   Os que ancoram texto do `BEGIN` reescrito (`--anchors` os nomeia) são **reancorados** no texto
   novo com a mesma propriedade, e provados com `--only <SLUG> check-autonomy.sh`. Mutante novo só
   onde a sabotagem do diff final achar regra sem probe — por exemplo, o `FILENAME == ARGV[n]` de um
   arquivo trocado por `NR == FNR`; se nenhum probe o pegar, escreva o probe (um mundo com índice
   vazio) ou declare no cabeçalho da função, pela régua D15.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    kit-guard: a kit with thousands of dirty paths' <<< "$o"` → `1`
**Antes:** `0`.

**Sensor durável:** o regime 2k, diferencial (edita × deixa em paz), e os 15 mutantes da guarda,
reancorados.

**Âncoras / mutantes tocados:** a do #240 **perde o símbolo**: re-designe para `` (`kit_guard_tree`) ``
na linha da definição (`kit_guard_tree() {`), no commit do I5; o título não muda. A do #236 desloca
pelo saldo.

**Reversível por:** `git revert` do commit.

### I6 — #240, fatia 2: o nome com `\n` atravessa a guarda de kit inteiro

**O quê:** decisão 5. Um parser, dois modos, e o nome codificado na árvore publicada.
- `hat_status_lines` (`bin/sdd:4357`) aceita `-z` como 1º argumento: `hat_status_lines [-z] [root]`.
  Com `-z`, cada registro sai terminado por NUL em vez de `\n`; a dobra do ORIG_PATH continua no
  mesmo laço. As duas chamadas do chapéu (`:4261`, `:4409`) não mudam e continuam no modo `\n`.
- `kit_guard_tree` lê o status com `-z`. ⚠️ Uma variável do bash não guarda NUL
  (`status="$(hat_status_lines -z …)"` descartaria os NULs calado): leia o fluxo **uma vez** num
  array, `mapfile -d '' st < <(GIT_OPTIONAL_LOCKS=0 hat_status_lines -z "$SDD_HOME")` (bash 5.2.21,
  medido), e o retorno cedo vira `[ "${#st[@]}" -gt 0 ] || return 0`. Os laços de `sums`, `execs` e
  `links` andam pelo array; o status e o índice (`git ls-files -s -z`, **sem** o `tr '\0' '\n'` de hoje) chegam ao `awk`
  NUL-terminados, com `RS="\0"` por atribuição entre operandos para esses arquivos (fato medido no
  § Contexto).
- **A linha publicada leva o nome codificado:** `\` → `\\`, LF → `\n`, CR → `\r` — o mesmo escape do
  `md5sum`. Assim o nome do registro escapado do md5sum já é a chave (sem decodificar), e um nome sem
  esses bytes fica igual. `XY <nome codificado><TAB><digest>[+x][@<modo>:<blob>[,…]]`. O
  `kit_guard_changes` não muda de lógica (corta no ÚLTIMO TAB, e o nome codificado não tem LF), e o
  motivo do `kit-touched` passa a dizer `notes\ndraft.md`.
- Nunca `md5sum -z`.
- O limite declarado do cabeçalho do `kit_guard_tree` (`:3975–3979`, "a newline in a name splits its
  status line…") sai, e no lugar entra o contrato da codificação. O comentário do `hat_status_lines`
  (`:4350–4356`, "A newline inside a name is the one residue left") passa a dizer que o modo `-z` é o
  da guarda de kit e que o chapéu fica no modo `\n` (decisão 5). O limite da guarda do chapéu
  (`:4205–4211`) **fica**.

**Onde:** `bin/sdd` (as duas funções e os comentários citados); `tests/check-autonomy.sh` (regime
novo); `tests/check-mutation.sh`; `docs/failure-modes.md` (o verbete `kit-touched`, `:596`: um nome
com quebra de linha aparece como `\n`); anatomia §6.

**Como (TDD):**
1. **Red.** Regime **2l**, depois do 2k, no molde do 2j (`:6143–6174`): o kit falso ganha o **não
   rastreado** `notes<LF>draft.md` (`kg_nl_name="notes"$'\n'"draft.md"`, conteúdo `scratch`); a
   sessão do stub faz `>>` nele; a corrida benigna não toca. Asserção:
   `kit-guard: a dirty name holding a newline is one path — edited again it stops the line and is named, left alone it is silent`,
   esperado `sessions:1 rc:3 kind:kit-touched named:1|sessions:2 rc:3 kind:no-progress`, com
   `named` = `grep -cF '?? notes\ndraft.md (content changed)'` (barra e `n` literais) no stderr da
   corrida que edita. Limpe com `rm -f "$FAKEKIT/$kg_nl_name"`. No código de antes, as duas corridas
   terminam em `no-progress` (a árvore é a mesma antes e depois, reproduzido): veja o `FAIL`.
2. **Conserto:** como acima.
3. **Mutantes:** novos `RUN_kit_guard_name_unencoded` (a codificação some → o nome parte a linha → 2l
   vermelho) e `RUN_hat_status_z_newline` (o modo `-z` volta a imprimir `\n` → 2l vermelho). Os
   `RUN_kit_guard_md5_escape_kept` e `_md5_escape_prefix` ancoram o decode do registro escapado
   (`unesc`): se o desenho novo usa o nome escapado como chave e o `unesc` deixa de existir,
   reancore-os na regra que os substitui (o `\` inicial do registro tirado; o nome escapado como
   chave) ou aposente-os com o motivo escrito — o regime 2j (`back\slash.md`) continua medindo o
   registro escapado. O `RUN_hat_status_not_nul` (`:2215`, o `-z` do `git status` tirado) continua
   aplicando. Prove com `--only <SLUG> check-autonomy.sh`.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    kit-guard: a dirty name holding a newline' <<< "$o"` → `1`
**Antes:** `0`.

**Sensor durável:** o regime 2l e os mutantes novos; o 2j (`back\slash.md`) e o 2i (`-dash.md`)
continuam verdes.

**Âncoras / mutantes tocados:** a do #240 (já em `kit_guard_tree` desde o I5) e a do #236 deslocam
pelo saldo.

**Reversível por:** `git revert` do commit (o I5 fica de pé sozinho).

### I7 — Fecho: `RESOLVED by`, a ADR aceita, o congelamento escrito, KAIZEN_LOG, handoff da EXEC e a suíte inteira

1. **`RESOLVED by <hash>.`** no fim do corpo dos quatro itens do `TODO.md` (seção aberta, antes da
   linha do `— descoberto por`), cada um com o hash do commit que o consertou: #238 → I1, #239 → I2,
   #236 → I3, #240 → I6. O título não muda. Medido em `fc32329` (caracteres por linha física, teto
   120): a última linha do corpo do #238 tem 61, a do #239 94, a do #236 78 — o token (~21) cabe; a
   do #240 tem **106** e o item já tem as 8 linhas do teto, então o corpo do #240 é **reescrito mais
   curto** para o token caber (o I5 já trocou o símbolo da âncora para `kit_guard_tree`).
2. **ADR 0017:** `Status: accepted (—, <data>)`. A ADR 0016 ganha `- **Amended by**: 0017 (§2: the
   kit's own judge runs in a linked worktree; the runner refuses the shared checkout)` no cabeçalho.
   `./bin/sdd adr check --mission 20261008-lote-6-as-quatro-que-faltam --phase plan` → rc 0.
3. **O congelamento (decisão 6), escrito onde o próximo leitor o procura:** a gaveta — a linha F3 do
   índice e o § F3 ("Hoje"): o kit congela no merge do lote 6; a janela seguinte abre no primeiro
   carimbo de alvo depois dele; nada em `bin agents templates config` até o veredito; o `sdd kaizen`
   roda de um worktree ligado (ADR 0017); a frente F1-P1 espera. O verbete **Janela de medição** do
   `CONTEXT.md` ganha a mesma frase.
4. **`KAIZEN_LOG.md`:** entrada `## <data> — Lote 6: as quatro que faltam`, no molde da do lote 5
   (Problema, Medição antes/depois em tabela, Padronizado em). Os números saem de comando, nunca
   daqui: o catálogo (`grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh`), a catraca, o 1800
   → rc 126 contra o regime 2k verde, o `\n` calado contra `kit-touched`, o `sdd kaizen` que abria
   sessão contra o rc 1.
5. **`20-handoff-exec.md`** a partir de `templates/handoff.md`, com `## TL;DR` de no máximo 20 linhas
   (`handoff_tldr_ok`).
6. **`bash tests/run-all.sh` → `suite green`**, com `anchors: all <N> mutants still apply`.
7. Achados nascidos na leva: cada um já está no `TODO.md` com a catraca movida no commit que o
   registrou (régua D15); o I7 só confere `bash tests/check-todo.sh`.

**Check:** `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by/{n++} END{print n+0}' TODO.md); b=$(awk '/^## .* — Lote 6: as quatro que faltam/{c++} END{print c+0}' KAIZEN_LOG.md); c=$(awk '/^- [*][*]Status[*][*]: accepted/{n++} END{print n+0}' docs/adr/0017-kaizen-refuses-the-checkout-the-targets-run.md); d=$(awk '/Amended by.*0017/{n++} END{print n+0}' docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261008-lote-6-as-quatro-que-faltam/20-handoff-exec.md 2>/dev/null); echo "$a $b $c $d ${f:-0}"` → `4 1 1 1 1`
**Antes:** `0 0 0 0 0`.

## Depois do checkpoint (sem incremento)

Na ordem que economiza um carimbo (`CLAUDE.md`, "`sdd health` ran three times for one branch"):

1. Empurrar a branch e abrir o PR para a `main` (corpo em pt-BR, com a evidência de cada incremento,
   as decisões 1–6, a P1, e as **mudanças de comportamento a declarar**: I2 — um exemplo cercado com
   `~~~` ou fecho mais curto não vira mais decisão nem gênero; I3 — o `sdd kaizen` recusa o checkout
   que os alvos executam, e a projeção avisa; I5/I6 — a guarda de kit aguenta milhares de caminhos
   sujos e vê o nome com `\n`).
2. Esperar **todos** os revisores (Codex, CodeRabbit; o Copilot está sem cota). `Review rate limited`
   do CodeRabbit = não revisou: depois da janela, `@coderabbitai review`.
3. Uma leva de consertos; o laço de revisão para numa rodada que não acha nada.
4. `./bin/sdd health` **uma vez**, no worktree (pendência do humano no `00-missao.md`).
5. O resto é do humano (§ Pendências do `00-missao.md`): merge, chore, re-sync, congelamento, yokoten,
   remoção do worktree.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A sabotagem do I5/I6 acha regra sem probe na guarda de kit (o PR #237 levou 6 rodadas do Codex na mesma função) | média | A sabotagem de cada linha do diff final (#243) roda antes do commit; regra sem probe ganha probe ou vira limite declarado no cabeçalho. A #240 vem por último (decisão 2): ela não segura as outras três. |
| Reancorar os 15 mutantes da guarda troca a propriedade sem querer | média | Cada reancorado é provado com `--only` contra o `check-autonomy.sh` e a nota diz qual propriedade ele sabota antes e depois. |
| O fragmento `FENCE_AWK` muda o resultado do `gate_DOCS` em algum mundo | baixa | Os três mundos do laço `docs_fence_rule` (`tilde`, `shorter`, `info`), o `DOCS_marker_in_fence` e o `DOCS_proposal_fence_blind` continuam no `check-gates.sh`; o `--only` nos 16 vizinhos do `gate_DOCS`. |
| O `command -v sdd` do `cmd_kaizen` lê um PATH diferente do dos alvos | baixa | Declarado na ADR 0017 (Consequences); é o mesmo teste do `/sdd-plan`. |
| O regime 2k deixa o `check-autonomy.sh` lento | baixa | 2600 arquivos pequenos: `md5sum` e `git status` em milissegundos. Compare o relógio do passo `autonomy ledger` antes e depois (prazo 720 s). |
| Âncora do `TODO.md` fora do alvo num commit | alta, por construção | A tabela F8 do Contexto diz quem desloca o quê; `bash tests/check-todo.sh --anchors TODO.md` antes de cada commit. |

**Não-feitos, por decisão:** o `\n` na guarda do chapéu (decisão 5); o runner criar worktree (decisão
1, ADR 0017); o congelamento em si (decisão 6, no merge); as outras sutilezas do CommonMark (limite
declarado no `FENCE_AWK`).

## Verificação end-to-end

Com o I7 `done`, no worktree:

1. `bash tests/run-all.sh` → `suite green`, rc 0; a linha `anchors: all <N> mutants still apply and
   leave valid code`, com `N` = `grep -cE '^mut_[A-Za-z0-9_]+\(\)' tests/check-mutation.sh` (676 + 3
   do I2 + 4 do I3 + os do I5/I6 − aposentados).
2. Os seis Checks I1–I6 da tabela de novo, todos no esperado, e o do I7 → `4 1 1 1 1`.
3. `./bin/sdd adr check --mission 20261008-lote-6-as-quatro-que-faltam --phase plan` → rc 0.
4. `bash tests/check-todo.sh` → `4 finding(s)` (mais os nascidos) e `every anchor on target`;
   `grep '^todo-findings' tests/health-baseline.txt` bate com a contagem.
5. `env -u CLAUDECODE ./bin/sdd preflight` sem `agent sdd-planner stale`.
6. Depois dos revisores: `./bin/sdd health` → o carimbo (pendência do humano).
