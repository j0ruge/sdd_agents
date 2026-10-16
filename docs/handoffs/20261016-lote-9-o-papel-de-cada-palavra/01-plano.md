---
missao: 20261016-lote-9-o-papel-de-cada-palavra
data: 2026-10-16
---

# Plano — o lote 9: o papel de cada palavra

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

### Onde e como se executa

- **Raiz de TODA leitura e escrita:** o worktree ligado `/home/joruge/repos/sdd_agents-lote-9`, na
  branch `fix/lote-9-o-papel-de-cada-palavra`, cortada da `origin/main` `9c13855` com `--no-track` e
  **sem upstream** (`git rev-parse --abbrev-ref @{u}` → `fatal: no upstream configured`). O
  `.sdd/config.sh` e o `.sdd/cache/mutation-killers.tsv` foram copiados do checkout principal. A
  catraca `tests/health-baseline.txt` está em `todo-findings 14`.
- **Missão do kit = execução INTERATIVA no worktree**, um incremento por vez, no contrato do
  `sdd-executor`: Red → Green → commit → checkpoint como último ato. **Nunca** `sdd run` a partir do
  checkout principal (ADR 0016 §2). Dentro do worktree, `health`, `preflight` e `install` rodam como
  `./bin/sdd`.
- **Nada se escreve no checkout principal `/home/joruge/repos/sdd_agents`**, nem arquivo não
  rastreado: a guarda de kit de todo `sdd run` de alvo compara o `HEAD` e o `status --porcelain` dele.
- **Congelamento (decisão 1):** o eixo do juiz é o último commit em `KIT_BEHAVIOR_PATHS=(bin agents
  templates config)`. Esta missão toca **só** `tests/check-checkpoint.sh`, `TODO.md`,
  `tests/health-baseline.txt` (se um achado novo nascer), `KAIZEN_LOG.md`,
  `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` e a pasta da missão. Um diff em `bin/`,
  `agents/`, `templates/` ou `config/` parte a janela: se um incremento parecer exigir um desses, pare e
  registre no `checkpoint-notas.md`.
- **Sem carimbo:** o `./bin/sdd health` **não** roda nesta missão (decisão do humano no PR #267: o
  carimbo só quando a catraca das issues zerar). Não o rode "para conferir".
- **O shell da ferramenta Bash desta máquina é o zsh.** No zsh, `grep` é o ugrep (recusa abreviação de
  opção longa, por exemplo) e `$var` não se divide em palavras. Todo comportamento de grep se mede com
  `/usr/bin/grep` (GNU grep 3.11) dentro de `bash -c '…'` ou de um script `bash`. O sensor roda sob
  `bash`, então o que ele faz não depende disso.
- **`tests/` é superfície inglesa** (`tests/check-lang.sh`): comentários, mensagens, descrições de
  probe e textos de linha `ok` em inglês, sem stopword de pt-BR.
- **Antes de cada commit em `tests/`:** `shellcheck -S warning tests/check-checkpoint.sh` (o lint só
  roda na suíte inteira; no lote 3 um SC1010 apareceu tarde e custou um commit) e
  `bash tests/check-todo.sh --anchors TODO.md` (ver § O `TODO.md`).
- **Toda edição no `TODO.md` (decisão 7):** antes, invoque a skill `todo-to-github-issues` (ferramenta
  `Skill`) e siga o formato dela; depois da edição,
  `SDD_HOME=/home/joruge/repos/sdd_agents-lote-9 python3 ~/.claude/skills/todo-to-github-issues/scripts/todo_issues.py --audit`
  tem de dizer `summary auto=0 manual=0` (medido no HEAD: `sensor: before clean → after the AUTO fixes
  clean`; só lê). **Nunca** `--apply` a partir da branch, e **nunca** mude o título de um item: a chave
  do espelho é o título, e um título novo vira issue nova com a antiga órfã.

### `tests/check-checkpoint.sh` — 1811 linhas, roda em ~9,3 s (prazo da suíte: 60 s)

Linhas do HEAD `9c13855`; os incrementos as deslocam.

- **Constantes:** `OK_ANCHOR='^  ok    '` (`:210`), `PASS_MARK='✓ '` (`:217`), `pass`/`fail` (`:228`,
  `:231`), `count_occ` (`:235`). O cabeçalho avisa: regex do leitor mora em variável
  (`R2_VAR_RE`, `R2_BRACED_RE`, `R2_NAME_RE`, `R2_INDIRECT_RE`, `:264-267`), porque escrita inline no
  `[[ =~ ]]` cada caractere entre aspas vira uma barra a mais. O leitor roda sob `local LC_ALL=C`.
- **O leitor da regra 2** (`:243-555`):
  - `r2_close` (`:270`) fecha um `$(`;
  - `r2_grep_at <text> <i>` (`:307`) lê o grep que começa em `i` e publica `R2_END` (o primeiro `;`,
    `&`, `|`, newline ou crase fora de aspas e parênteses, ou o `)` que fecha), `R2_LITS` (os literais
    entre aspas fora do operando do herestring), `R2_BARE` (as palavras com cada parte entre aspas
    trocada por um branco), `R2_ANSI` (há `$'…'` numa palavra) e `R2_HS` (o nome da variável do
    herestring, `?` quando não é exatamente uma variável, vazio sem herestring);
  - `r2_refs` (`:362`), `r2_bounded` (`:378`: o `grep`/`egrep`/`fgrep` em `i` é palavra de comando),
    `r2_anchored <literal>` (`:391`: começa por `OK_ANCHOR`, ou por `^`, brancos com ou sem `*` e
    `PASS_MARK`);
  - `r2_grep_anchored` (`:412`): o grep que `r2_grep_at` acabou de ler está ancorado — `R2_ANSI` recusa;
    `a` = literais de `R2_LITS` ancorados; nas palavras de `R2_BARE`, `--x` recusa quando `x` é prefixo
    de `fixed-strings`, `invert-match` ou `file`, e conta um `-e` quando é prefixo de `regexp`; `-*[fFv]*`
    recusa; `-*e` conta um `-e`; `-*e*` recusa; vale `a >= 1 && a >= e`;
  - `rule2 <cell>` (`:438`) publica `R2_STRICT`, `R2_G`, `R2_A`, `R2_AA`, `R2_HSREFS`, `R2_TAINTED`;
    `r2_captures` (`:461`) é a passada 1; `r2_greps` (`:512`) é a passada 2 e **não pula** as palavras
    do grep que leu (continua o laço no caractere seguinte ao `grep`).
- **Os três testes de `2>&1` (o #269):**
  - `:490` — `[ "${inner#*2>&1}" != "$inner" ]` (a captura nomeada contamina o nome);
  - `:502` — `[ "${res#*2>&1}" != "$res" ]` (sobrou mescla fora das capturas limpas → `R2_STRICT=1`);
  - `:672` — `case "$chk" in *'2>&1'*) ;; *) continue ;; esac` (a pré-condição em `scan_file`).
- **`scan_file`** (`:615`), regra 2 em `:670-689`: depois da pré-condição, `g="$(count_occ 'grep' "$chk")"`;
  no caminho estrito `a=R2_AA` contra esse `g` (contagem de substring, que conta o `grep` de dentro de
  `egrep` e de `$(…)`); no caminho da variável `g=R2_G`, `a=R2_A`. A mensagem de FAIL (`:686`) é
  `… greps a sensor's merged output with $a of $g pattern(s) anchored on the ok prefix or on a pass mark
  ('^ *✓ ') — FAIL prints the same text as ok, …`. **Mantenha o trecho `pattern(s) anchored`**: os probes
  e o comando de medição nos alvos contam por ele. O `ok` de `check_one` (`:902`) é
  `<arquivo>: N row(s), M under the anchor rule, none blind`.
- **`red_cell`** (`:939`) separa a forma estrita `` `comando` → `esperado` `` em `RED_CMD`/`RED_EXP`.
- **O selftest** (`:1108`):
  - `probe <desc> <want_rc> <want_text|-> <target> [mode]` (`:1032`), modo padrão `--check`, roda o
    sensor num processo filho; `cp_head <file>` (`:1049`) e `cp_row <file> <id> <célula> [status]`
    (`:1056`) montam o fixture. Nas células, `$` e `"` são escapados como em `:1167`:
    `cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"`;
  - os probes de controle leem `0 '0 under the anchor rule'` (fora da regra) ou `0 '1 under the anchor
    rule'` (dentro, ancorado); os de recusa, `1 '0 of 1 pattern(s) anchored'` (ou `'1 of 2 …'`);
  - o grupo da regra 2 vai de `:1160` a `:1342` (48 probes) e fecha com
    `[ "$FAILS" -eq "$r2_f0" ] && rule_ok "the anchor rule reads the variable … ($((PROBES - r2_p0)) probe(s))"`;
    o da marca de "passou", de `:1344` a `:1407` (15 probes);
  - **pisos apertados:** `PROBE_FLOOR=128` (`:1017`) e `RULE_FLOOR=4` (`:1029`) são **iguais** às
    contagens reais, medidas com uma cópia descartável que imprime `PROBES` e `RULE_LINES` antes do teste
    dos pisos (`PROBES=128 RULE_LINES=4`). Todo probe novo sobe `PROBE_FLOOR` para a contagem nova
    exata; todo grupo novo com `rule_ok` sobe `RULE_FLOOR` em 1. Para medir, copie o sensor para
    `tests/.probecount.sh`, acrescente `printf "PROBES=%d RULE_LINES=%d\n" "$PROBES" "$RULE_LINES" >&2`
    logo depois do `rm -rf "$box"` do fim do `selftest`, rode `bash tests/.probecount.sh --selftest` e
    **apague a cópia** (ela fica fora do commit).
- **A corrida padrão** (o `case` de `:1797`, ramo vazio): `selftest || exit $?`, `calibrate`, `scan`. Hoje: `ok    no checkpoint
  Check reads a red assertion as green (193 cell(s) under the rule, 257 row(s) in 30 file(s))`, e quatro
  linhas `ok    rule:`. A varredura lê `docs/handoffs/*/checkpoint.md` do disco, então o checkpoint
  desta missão entra nela (as Checks dele estão ancoradas).
- **O cabeçalho:** a regra 2 em `:38-44`; os limites do leitor em `:111-135` (a linha
  `FAIL-OPEN, in TODO.md` em `:134` é o #270 e sai quando ele fecha); o histórico de sabotagens em
  `:164-191`; os códigos de saída em `:193`.
- **O sensor mede markdown**, então o catálogo de mutação não o alcança. Quem o guarda é o `selftest()`
  (rc 90/91/92), e regra nova exige a **passada de sabotagem adversarial** do `CLAUDE.md`: degradar cada
  regra e exigir o selftest vermelho em cada degradação. **Antes de concluir "sobreviveu", prove que a
  sabotagem mudou o trecho que dizia mudar** (ancore em código, não em número de linha; um `perl -0pe`
  sem `/g` muda a primeira ocorrência do arquivo). A trava do Bash recusa `sed` com `rm` no texto:
  sabote com um script Python sobre uma cópia de backup.

### As grafias de mescla (#269) — medidas no bash 5.2.21

`t.sh` imprime `  ok    alpha` na stdout e `  FAIL  beta` na stderr; `o=$(eval "bash t.sh <grafia>")`:

| Grafia | A stderr vai para | Mescla? |
|---|---|---|
| `2>&1`, `2>& 1`, `2>&1-`, `2<&1`, `2>&01`, `2>&"1"`, `2>&$one` (com `one=1`) | onde está a stdout (capturada) | sim |
| `&>f`, `&> f`, `&>>f`, `>&f`, `>& f`, `1>&f` | o arquivo `f`, junto com a stdout | sim |
| `>&2`, `1>&2` | a stdout vai para a stderr; nada mescla na stdout | não |
| `2>&-` | fechada | não |
| `2>\|f` (escrito sem a barra) | só o arquivo `f` | não |
| `2>&1 >/dev/null` | a capturada (a stdout foi para o null depois) | sim |

`&>/dev/null`, `&>>/dev/null` e `>&/dev/null` mandam as duas para o null: nenhum grep as lê. **O
`lighthouse_project` usa essa forma** dentro de capturas
(`q=$(npm run lint -w packages/frontend &>/dev/null && npm run typecheck &>/dev/null && echo GATES-OK)`,
em `20260921-amep-backend-0-1-0` e nas missões AMEP seguintes), ao lado de greps sem âncora de capturas
com `2>/dev/null`. Hoje essas células ficam fora da regra; lidas como mescla, viram recusas novas. Nenhum
checkpoint do kit nem do `sales_quote` usa outra grafia além de `2>&1` (`grep -E '&>|[^0-9]>&[^0-9 -]|2<&'`).

### O argv do GNU grep 3.11 (#270) — medido no `/usr/bin/grep`

- **Opções curtas** (cada letra testada isolada): sem argumento `a b c E F G h H i I l L n o P q r R s T u
  U v V w x y z Z` e os dígitos `0-9` (contexto, `-5` = `--context=5`); **com argumento obrigatório**
  `A B C d D e f m X`. Num aglomerado (`-ce`), a letra que leva argumento toma o resto da palavra ou,
  vazio o resto, a palavra seguinte: `-ce '^a'` é `-c -e '^a'`; `-ec '^a'` é `-e c` com o FILE `'^a'`.
- **As 50 opções longas** (enumeradas pelas mensagens de ambiguidade de `--a` … `--z`):
  - argumento obrigatório (15): `after-context before-context binary-files context devices directories
    exclude exclude-dir exclude-from file group-separator include label max-count regexp`;
  - argumento opcional (2): `color colour` — só com `=` (`--color never` faz de `never` um operando);
  - sem argumento (33): `basic-regexp binary byte-offset count dereference-recursive extended-regexp
    files-with-matches files-without-match fixed-regexp fixed-strings help ignore-case initial-tab
    invert-match line-buffered line-number line-regexp no-filename no-group-separator no-ignore-case
    no-messages null null-data only-matching perl-regexp quiet recursive silent text unix-byte-offsets
    version with-filename word-regexp`.
- **Prefixo (getopt_long):** um prefixo que casa só uma opção é ela; um que casa várias é ambíguo e o
  grep sai 2 — **exceto** quando todas as candidatas são a mesma opção curta: `--fixed` (`fixed-regexp` e
  `fixed-strings`, ambas `-F`) e `--colo`/`--col` (`color`, `colour`) resolvem. Medido: `--fi`, `--nu`,
  `--line`, `--in`, `--e`, `--re` ambíguos; `--fixed`, `--colo`, `--null` (exato), `--no-i`, `--quie`,
  `--sil`, `--reg` resolvem. Um prefixo que exige argumento sem `=` toma a palavra seguinte: `--reg -c y`
  usa `-c` como padrão.
- **`--fixed-regexp` é um sinônimo escondido de `-F`** (`grep --fixed-regexp -c '^a' <<< a` → `0`).
- **`-X <matcher>`** aceita só os nomes exatos `grep egrep fgrep awk gawk posixawk perl`; `-X fgrep` lê
  o `^` como literal (`0`), os outros o leem como âncora (`1`); nome inválido sai 2.
- **Matchers em conflito** (`-E -F`, `-F -E`, `-X fgrep -E`) saem 2 com `conflicting matchers specified`.
- **`-z`/`--null-data`:** o registro é a entrada inteira; o `^` só casa no começo dela e o `.` atravessa a
  quebra de linha: `printf '  ok    a\n  FAIL  b\n' | grep -cz '^  ok    a.*b'` → `1` (sem `-z`, `0`).
- **FILE ao lado do herestring:** o grep lê o arquivo e ignora a stdin
  (`grep -c -e caso '^  ok    x' <<< "$o"` → `grep: ^  ok    x: No such file or directory`, rc 2).
- **`--` encerra as opções; `-` sozinho é operando (a stdin).** O GNU grep permuta: opção vale em qualquer
  posição antes do `--`.

### Os defeitos reproduzidos no HEAD (fixture de uma linha, `--check`)

| Célula (notação de shell) | Hoje | Depois | Incremento |
|---|---|---|---|
| `bash tests/check-a.sh &> out.log; grep -c 'alpha holds' out.log` | rc 0 | rc 1 | I1 |
| idem com `>&` e `&>>` | rc 0 | rc 1 | I1 |
| `o=$(bash t.sh 2>&1); grep '-v' -c '^  ok    x' <<< "$o"` | rc 0 | rc 1 | I2 |
| `o=$(npm test 2>&1); grep "-F" -c '^ ✓ caso' <<< "$o"` | rc 0 | rc 1 | I2 |
| `o=$(bash t.sh 2>&1); grep --label='^  ok    x' -H -c 'caso' <<< "$o"` | rc 0 | rc 1 | I2 |
| `o=$(bash t.sh 2>&1); grep -c ^\ \ ok\ \ \ \ x <<< "$o"` | rc 1 | rc 0 | I2 |
| `o=$(bash t.sh 2>&1); grep -c -e 'caso' '^  ok    x' <<< "$o"` | rc 0 | rc 1 | I3 |
| `o=$(npm test 2>&1); grep --fixed-regexp -c '^ ✓ caso' <<< "$o"` | rc 0 | rc 1 | I3 |
| `o=$(bash t.sh 2>&1); grep -cz '^  ok    a.*b' <<< "$o"` | rc 0 | rc 1 | I3 |
| `o=$(bash t.sh 2>&1); grep -c -- '^  ok    x' grep <<< "$o"` (FILE chamado `grep`) | rc 1 (`1 of 2`) | rc 0 | I3 |
| `b=$(npm run build 2>&1); grep -ci 'chunks larger than' <<< "$b"` → `0` | rc 1 | rc 0 | I4 |
| `o=$(bash t.sh 2>&1); grep -c 'caso' <<< "$o"` (o controle cego) | rc 1 | rc 1 | todos |

Duas observações que corrigem o que o grill supôs: `grep -c -m '1' '^  ok    x' <<< "$o"` **passa** hoje (a
regra `a >= 1 && a >= e` só soma literais ancorados), então o argumento de opção entre aspas nunca causou
falso positivo, só os fail-opens; e `grep -X fgrep -c '^ ✓ caso'` é recusado hoje **por acidente** (o
`r2_greps` lê o `fgrep` do argumento como um segundo grep).

### Os padrões com expansão que o kit já escreve (não podem regredir)

Dois checkpoints do kit grepam a saída mesclada com um padrão cuja âncora é literal e o resto vem de uma
variável, e hoje passam:

- `docs/handoffs/20261003-lote-3-a-catraca-desce/checkpoint.md:59` (I20): `grep -c "^  ok    $k finding(s)" <<< "$o"`;
- `docs/handoffs/20261002-onde-o-comando-do-humano-escreve/checkpoint.md:49` (I10):
  `grep -c "^  ok    $n finding(s), all within 8 lines" …`.

Por isso "padrão vindo de variável" (decisão 2, lida pela decisão 8 (a)) quer dizer **padrão cujo começo é uma expansão**
(`"$p"`, `$p`): esse é recusado. Um padrão entre aspas duplas cujo prefixo literal, antes da primeira
expansão, já satisfaz `r2_anchored` continua ancorado, com o limite declarado no cabeçalho (a expansão
poderia carregar uma quebra de linha ou um `\|`).

### Os alvos (#272 e a regressão do #269)

- **O comando de medição** (leitura só, rode em `bash`, da raiz do worktree):

  ```bash
  for f in /home/joruge/repos/lighthouse_project/docs/handoffs/*/checkpoint.md \
           /home/joruge/repos/sales_quote/docs/handoffs/*/checkpoint.md; do
    bash tests/check-checkpoint.sh --check "$f" 2>&1
  done | grep -c 'pattern(s) anchored'
  ```

  Hoje (2026-10-16 08:00, `lighthouse_project` em `b39ab0d`, `sales_quote` em `a1ad4b74`): **114**, em 36
  checkpoints (16 + 98). Só a LH-4
  (`/home/joruge/repos/lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md`):
  **2** (a I8 do zero e a I9, que lê `^Total:` e fica).
- **O antes se remede no fecho** com o sensor da base, porque os alvos ganham checkpoints entre hoje e lá:
  `d=$(mktemp -d); mkdir -p "$d/tests"; git show 9c13855:tests/check-checkpoint.sh > "$d/tests/check-checkpoint.sh"; cp tests/isolate-git.sh "$d/tests/"`
  e o mesmo laço com `bash "$d/tests/check-checkpoint.sh"`. O sensor precisa do `isolate-git.sh` ao lado.
- **O protótipo descartável do planner** (Python, fora do repo, regex sobre as 114 células recusadas):
  25 têm um grep contador sem âncora, no nível de topo do comando, num par de esperado só zeros; em 11
  todos os greps cegos são desse tipo (10 do `sales_quote` e a I8 da LH-4). Previsão: 114 → **103** e LH-4
  2 → **1**. Em formato estrito (`` `cmd` → `0` `` sozinho na célula) há **0** das 114: o ganho vem dos pares.

### O `TODO.md` — as âncoras que os incrementos movem

`tests/check-todo.sh` está no `TEST_CMD` e **reprova** a âncora cujo símbolo designado sai a mais de 10
linhas da linha citada (`ANCHOR_REACH`). Todo incremento roda `bash tests/check-todo.sh --anchors TODO.md`
(hoje `14 measured, 0 off target`) e reancora, **no mesmo commit**, o item que moveu, consultando antes a
skill (decisão 7). No lote 8, a 5ª rodada do Codex foi exatamente três âncoras deste sensor a 22 linhas
do alvo.

| Item | Linha no `TODO.md` | Âncora de hoje | Movida por |
|---|---|---|---|
| #269 (mescla `2>&1`) | 42 | `tests/check-checkpoint.sh:672` (`2>&1`) | I1 (a linha muda); reancore em `r2_merges` |
| #270 (papel das palavras) | 49 | `tests/check-checkpoint.sh:412` (`r2_grep_anchored`) | I1–I3 (o cabeçalho e o leitor crescem) |
| #272 (esperado `0`) | 73 | `tests/check-checkpoint.sh:677` (`rule2`) | I1–I4 |
| #271 (prosa congelada) | 66 | `templates/checkpoint.md:27` (`check-x.sh`) | não se move (`templates/` não muda) |

**Onde vai o `RESOLVED by`** (`templates/todo.pt-BR.md:38-41`): no fim da última linha do corpo, ou na
linha `Fonte:` antes do `— descoberto por`; nunca numa linha própria, nunca depois do descoberto-por. A
largura (bytes de continuação UTF-8 descontados) da última linha do corpo hoje: #269 `:46` = 72 (cabe),
#270 `:54` = 51 (cabe), #272 `:78` = 103 (**não cabe** `RESOLVED by <7 hex>`: encurte o corpo, sem mudar o
título). O #271 tem 7 linhas (`:66-72`), teto 8: a linha nova entra antes do `— descoberto por`.

### O fecho (I5)

- **`KAIZEN_LOG.md`:** a entrada mais nova vai no topo (hoje `:7` é
  `## 2026-10-15 — Lote 8: a leva que não parte a janela`), com `**Missão:**`, `**Antes**`, `**Depois**` e,
  se houver, `**Achados:**`, separadas por `---`. Como `kaizen_log:` está vazio, o título `## ` e uma linha
  que cita o id inteiro da missão têm de ser novos no diff (ADR 0018 §4).
- **Gaveta:** a linha F3 da tabela (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:18`) e um
  parágrafo `**Hoje (<data>).**` depois do de `2026-10-15` (`:201-207`), antes de `## F4` (`:209`). "Frente
  que anda, fecha ou nasce atualiza o índice no mesmo commit" (`CLAUDE.md`).
- **`20-handoff-exec.md`:** do `templates/handoff.md` (`## TL;DR` de até 20 linhas, `## Estado do repo`,
  `## O que foi feito`, `## Artefatos`, `## Boot da próxima fase`, `## Pendências / Decisions for a Human`,
  `## Riscos e não-feitos`, `## Achados fora de escopo`).
- **A suíte inteira:** `bash tests/run-all.sh` leva ~10 min. A ferramenta Bash corta em 2 min por padrão e
  10 no máximo: rode em background e espere a última linha.

## Arquitetura da mudança

Um sensor de markdown, nenhum toque no runner. A regra 2 do `check-checkpoint.sh` ganha quatro camadas,
uma por incremento, cada uma com o seu grupo de probes e a sua linha `ok    rule:`:

1. **A mescla (I1, #269).** Uma definição, `r2_merges`, responde "este texto manda a stderr para onde a
   stdout vai?" para os três sítios que hoje testam o literal `2>&1`.
2. **A palavra (I2, #270).** O `r2_grep_at` deixa de guardar literais soltos (`R2_LITS`) e palavras com as
   aspas apagadas (`R2_BARE`) e passa a guardar **palavras**: o valor de cada uma, com aspas e escapes
   removidos, e de que tipo são as partes dela. Redirecionamentos deixam de ser palavras. A regra do
   `r2_grep_anchored` continua a de hoje, agora sobre valores.
3. **O papel (I3, #270).** Sobre as palavras, o argv é lido como o getopt_long do GNU grep 3.11 o lê, com a
   tabela do contexto verificado: cada palavra é opção, argumento de opção ou operando, e os padrões são os
   argumentos de `-e`/`--regexp` ou o primeiro operando. Só o padrão deve a âncora; toda opção que desarma
   o `^` desarma. O `r2_greps` pula as palavras do grep que leu.
4. **O par (I4, #272).** A célula é lida como pares `` `cmd` → `esperado` ``; um grep contador, no topo do
   comando de um par cujo esperado é só zeros, e que passa numa lista positiva de condições, conta como
   ancorado.

Nenhuma camada muda o que a regra 2 já recusa: os 128 probes de hoje mantêm o veredito (quatro fixtures
mudam o **esperado** no I4, ver lá). A prosa congelada (`templates/checkpoint.md`, `agents/sdd-planner.md`)
**não** se edita: o #271 ganha uma linha no fecho (decisão 6).

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o **porquê** de cada fatia e o detalhe que não
cabe numa célula.

### I1 — toda grafia de mescla põe a célula sob a regra (#269)

**O quê:**

1. Uma função `r2_merges <text>`, **chamada** (`if r2_merges "$x"; then`), nunca lida por `$(…)`. rc 0
   quando o texto mescla a stderr na stdout. Lê o texto cru, sem honrar aspas, como o `2>&1` de hoje (o
   lado fechado: `grep -c '&>' f` numa célula com grep passa a pôr a célula sob a regra). Mescla é:
   - **a forma do descritor:** um `2` não precedido de dígito, seguido de `>&` ou `<&`, brancos opcionais e
     um alvo que é `1` com zeros à esquerda (`1`, `01`, `1-`) **ou** que não começa por dígito, `-` nem
     branco (`"1"`, `$one`, `$(…)`: indecidível, lido como mescla). `2>&-` e `2>&3` não mesclam;
   - **a forma das duas:** `&>` ou `&>>`, ou `>&`/`1>&` não precedidos de outro dígito, seguidos de
     brancos opcionais e de um alvo que não começa por dígito nem `-`. **Exceção:** o alvo exatamente
     `/dev/null` (seguido de fim, branco, `;`, `&`, `)` ou crase) não mescla, porque nenhum grep o lê.
2. Troque os três testes do literal: `:490` → `r2_merges "$inner"`; `:502` → `r2_merges "$res"`;
   `:672` → `r2_merges "$chk" || continue`.
3. Os comentários que dizem `2>&1` como "a mescla" (`:246`, `:253`, `:460` e a regra 2 do cabeçalho em
   `:38`) passam a dizer "uma mescla (qualquer grafia)". Declare no cabeçalho, como limites: a mescla por
   um terceiro descritor (`3>&1 2>&3`) não é seguida; `>/dev/null 2>&1` continua lido como mescla (fechado);
   `&>`/`>&` entre aspas contam (fechado); a exceção do null é só o texto exato `/dev/null`.

**Como (TDD):** um grupo novo de probes logo depois do grupo da marca de "passou" (`:1407`), com
`local mg_p0="$PROBES" mg_f0="$FAILS" mg`. Cada fixture é uma célula num `cp_head`/`cp_row` próprio.

| # | Célula (notação de shell; escape `$` e `"` no `cp_row`) | Quer |
|---|---|---|
| M1–M6 | `o=$(bash t.sh <g>); grep -c 'alpha' <<< "$o"` com `<g>` = `2>& 1`, `2>&1-`, `2<&1`, `2>&01`, `2>&"1"`, `2>&$one` | rc 1, `0 of 1 pattern(s) anchored` |
| M7–M12 | `bash t.sh <g>; grep -c 'alpha' f` com `<g>` = `&>f`, `&> f`, `&>>f`, `>&f`, `>& f`, `1>&f` | rc 1, `0 of 1 pattern(s) anchored` |
| M13 | `o=$(bash t.sh 2<&1); grep -c '^  ok    alpha' <<< "$o"` (a grafia nova contamina e a âncora vale) | rc 0, `1 under the anchor rule` |
| C1–C6 | `bash t.sh <g>; grep -c 'alpha' f` com `<g>` = `&>/dev/null`, `&>>/dev/null`, `>&/dev/null`, `>&2`, `1>&2`, `2>&-` | rc 0, `0 under the anchor rule` |
| C7 | `bash t.sh 2>&3; grep -c 'alpha' f` (outro descritor) | rc 0, `0 under the anchor rule` |
| C8 | `q=$(npm run lint &>/dev/null && echo OK); o=$(npm test 2>/dev/null); grep -c 'caso' <<< "$o"` (a forma do `lighthouse_project`) | rc 0, `0 under the anchor rule` |

M1 e M3–M12 são vermelhos no HEAD do jeito certo (hoje rc 0, `0 under the anchor rule`); o M2 (`2>&1-`) já é
recusado hoje, porque contém o literal, e fica como guarda; o M13 é vermelho (hoje fora da regra, quer `1 under`). C1–C8 são controles verdes hoje que têm de continuar verdes. No `cp_row`, `$one`
vira `\$one` e `"1"` vira `\"1\"`, como os escapes de `:1167`.
No fim do grupo:

```bash
[ "$FAILS" -eq "$mg_f0" ] && rule_ok "every spelling that merges stderr into stdout puts the cell under the anchor rule ($((PROBES - mg_p0)) probe(s))"
```

`RULE_FLOOR` 4 → 5 e `PROBE_FLOOR` para a contagem nova exata (128 + os do grupo). Todo probe de hoje
mantém o rc; um que mudar é decisão, anotada no `checkpoint-notas.md` com o porquê.

**Passada de sabotagem** (cada uma deixa o selftest vermelho; resultado no `checkpoint-notas.md`):
a forma do descritor sem o ramo "alvo 1"; sem o ramo "alvo indecidível"; sem o `<&`; a forma das duas
sem `&>>`; sem `1>&`; sem a exceção do `/dev/null`; a exceção valendo para qualquer alvo que **contém**
`/dev/null`; cada um dos três sítios de volta ao literal `2>&1`; a linha `rule_ok` apagada; o piso baixado.

**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: every spelling that merges stderr into stdout puts the cell under the anchor rule' <<< "$o" `` → `1`
(vermelho no HEAD: imprime `0`).
**Sensor durável:** o grupo M1–M13/C1–C8 no `selftest()`, que roda no `tests/run-all.sh`.
**Medida de regressão:** o comando de medição dos alvos continua em **114** depois do I1 (anote no
`checkpoint-notas.md`). Se subir, uma grafia do `lighthouse_project` entrou na regra: pare e leia a célula.
**Reancorar:** #269 em `tests/check-checkpoint.sh:<linha da chamada na pré-condição>` (`r2_merges`), e os
outros dois se o `--anchors` acusar.
**Reversível por:** `git revert` do commit do I1.

### I2 — cada palavra do grep é lida pelo valor (#270, metade 1)

**O quê:** o `r2_grep_at` passa a publicar **palavras** no lugar de `R2_LITS`/`R2_BARE`:

1. **Tokenizador**, sobre o trecho do grep (do fim da palavra `grep` até `R2_END`, os mesmos
   terminadores de hoje). Um branco fora de aspas e de `$(…)` separa palavras. Cada palavra é a
   concatenação de partes, e cada parte tem um tipo:
   - **literal:** texto sem aspas (com `\x` → `x`), `'…'` (verbatim) e o texto de `"…"` (com `\$`, `` \` ``,
     `\"` e `\\` desescapados);
   - **expansão entre aspas duplas:** `$nome`, `${…}`, `$(…)` ou crase dentro de `"…"` — vira uma palavra
     só, de valor desconhecido;
   - **expansão sem aspas:** `$nome`, `${…}`, `$(…)`, crase, `*`, `?`, `[`, um `{` com `,` ou `..` antes do
     `}`, e o `~` no começo — pode virar várias palavras ou nomes de arquivo;
   - **ANSI-C:** `$'…'`.

   Publique, por palavra, o valor (as partes literais, com um marcador no lugar de cada expansão), o
   **prefixo literal** (o valor até a primeira parte não literal) e a classe: `lit` (só partes literais),
   `dq` (literal e expansões entre aspas duplas, nada mais), `ansi` (tem ANSI-C) ou `raw` (o resto). Arrays
   globais (`R2_WV`, `R2_WP`, `R2_WK`, por exemplo), nunca por `$(…)`.
2. **Redirecionamentos não são palavras.** Um operador fora de aspas — dígitos opcionais e `<<<`, `<<`,
   `<>`, `<&`, `>&`, `>>`, `>|`, `<` ou `>`, ou `&>`/`&>>` — e o alvo dele (o resto da palavra ou a palavra
   seguinte) saem da lista. Guarde se algum deles manda a **stdout** do grep para outro lugar (`>`, `>>`,
   `>|`, `1>…`, `&>`, `&>>`, `>&…`): o I4 lê isso. O alvo do `<<<` é o operando do herestring, e o `R2_HS`
   continua com o sentido de hoje.
3. **O `r2_grep_anchored` mantém a regra de hoje, sobre valores** (o papel é o I3):
   - uma palavra cujo valor começa por `-` e tem mais de um caractere é opção, lida pelas mesmas regras de
     hoje (`-*[fFv]*` recusa, `-*e` conta um `-e`, `-*e*` recusa, os prefixos longos de `fixed-strings`,
     `invert-match`, `file` e `regexp`), **pelo valor**: `'-v'` e `"-F"` passam a ser as opções que são, e
     `--label='^  ok    x'` é uma opção, não um padrão;
   - as outras palavras são candidatas a padrão: `a` conta as ancoradas, e uma palavra é ancorada quando é
     `lit` e `r2_anchored(valor)`, ou `dq` e `r2_anchored(prefixo literal)` (os dois checkpoints do kit em
     § Os padrões com expansão); `ansi` e `raw` nunca ancoram;
   - uma palavra `ansi` em qualquer posição recusa o grep, como o `R2_ANSI` de hoje;
   - vale `a >= 1 && a >= e`, como hoje.
4. Cabeçalho: os limites do leitor (`:111-135`) passam a descrever palavras; declare que uma palavra
   `dq` ancorada pelo prefixo é limite (a expansão poderia trazer uma quebra de linha ou um `\|`) e que o
   escape `\$'` deixou de ser recusado (é um `$` literal seguido de um `'…'`, e o bash o lê assim).

**Como (TDD):** grupo novo depois do do I1, `local wd_p0 wd_f0 wd`:

| # | Grep do fixture (célula `o=$(bash t.sh 2>&1); <grep>` ou `o=$(npm test 2>&1); <grep>`) | Quer |
|---|---|---|
| W1 | `grep '-v' -c '^  ok    x' <<< "$o"` | rc 1 |
| W2 | `grep "-F" -c '^ ✓ caso' <<< "$o"` (esperado `1`, não `0`: ver I4) | rc 1 |
| W3 | `grep '--inv' -c '^  ok    x' <<< "$o"` | rc 1 |
| W4 | `grep --label='^  ok    x' -H -c 'caso' <<< "$o"` | rc 1 |
| W5 | `grep -c ^\ \ ok\ \ \ \ x <<< "$o"` (âncora escrita com escape; no `cp_row`, cada `\` vira `\\`) | rc 0 |
| W6 | `grep -c '^  ok'"    x" <<< "$o"` (partes coladas) | rc 0 |
| W7 | `grep -c '^  ok    x' 2>/dev/null <<< "$o"` e `grep -c '^  ok    x' 2> /dev/null <<< "$o"` | rc 0 |
| W8 | `grep -c "^  ok    $k x" <<< "$o"` (âncora literal, resto expandido: o molde do kit) | rc 0 |
| W9 | `grep -c "$p" <<< "$o"` e `grep -c $p <<< "$o"` (começo expandido) | rc 1 |
| W10 | `grep -c '^  ok    '* <<< "$o"` (glob sem aspas: `raw`) | rc 1 |

W1–W5 e W9–W10 descrevem o defeito ou a recusa; W5 é vermelho no HEAD (hoje rc 1). Todo probe dos grupos
de hoje mantém o rc. Linha do grupo:
`rule_ok "each word of a grep is read by its value, quotes and escapes removed ($((PROBES - wd_p0)) probe(s))"`;
`RULE_FLOOR` +1, `PROBE_FLOOR` exato.

**Passada de sabotagem:** o valor das partes entre aspas simples apagado (a regra de hoje); as aspas
duplas não desescapadas; o `\x` sem aspas não desescapado; a expansão entre aspas duplas lida como `lit`;
a sem aspas lida como `dq`; o `ansi` deixando de recusar; os redirecionamentos voltando a ser palavras; a
opção lida pelo texto cru (com aspas) em vez do valor; a linha `rule_ok` apagada; o piso baixado.

**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: each word of a grep is read by its value, quotes and escapes removed' <<< "$o" `` → `1`
(vermelho no HEAD: imprime `0`).
**Sensor durável:** o grupo W1–W10 no `selftest()`.
**Reancorar:** #270 se `r2_grep_anchored` andar mais de 10 linhas (mantenha o nome da função); os outros
dois se o `--anchors` acusar.
**Reversível por:** `git revert` do commit do I2.

### I3 — o argv do grep é lido como o getopt_long o lê (#270, metade 2)

**O quê:**

1. **A tabela**, numa definição só, copiada do § O argv do GNU grep 3.11, com a proveniência no comentário
   (`/usr/bin/grep --help` e as mensagens de ambiguidade, GNU grep 3.11, medidos em 2026-10-16): as letras
   curtas, quais levam argumento, as 50 longas com o tipo de argumento (`required`, `optional`, `none`) e,
   para cada longa, a identidade que decide a ambiguidade (a letra curta equivalente quando há: `F` para
   `fixed-regexp` e `fixed-strings`; a própria longa quando não há; `color` e `colour` a mesma).
2. **O laço do getopt sobre as palavras do I2**, permutando:
   - `--` → toda palavra seguinte é operando; `-` sozinho é operando;
   - `--nome` ou `--nome=valor`: o nome exato ou um prefixo cujas candidatas têm todas a mesma identidade;
     prefixo ambíguo ou nome desconhecido **recusa o grep**; `required` sem `=` toma a palavra seguinte
     (seja ela qual for); `optional` só com `=`; `none` com `=` recusa;
   - `-abc`: cada letra tem de existir (desconhecida recusa); a letra que leva argumento toma o resto da
     palavra, ou a palavra seguinte quando o resto é vazio (sem palavra seguinte, recusa); dígitos são o
     número de contexto;
   - uma palavra cujo prefixo literal é vazio (começa por expansão) é **operando** (limite declarado: se
     o valor dela for uma opção, o grep a lê como tal; o controle `grep -c '^  ok    x' "$l"` do kit tem
     de continuar aceito, F1 de 2026-08-16);
   - os **padrões** são os argumentos de `-e`/`--regexp`; sem nenhum deles e sem `-f`/`--file`, o
     primeiro operando; os outros operandos são arquivos.
3. **O grep está ancorado** quando nada recusou, nenhuma opção desarma o `^` e todo padrão ancora pela
   regra do I2 (`lit` pelo valor, `dq` pelo prefixo literal; `ansi`/`raw` nunca). **Desarmam:** `-F`,
   `--fixed-strings`, `--fixed-regexp` (e os prefixos que resolvem para eles), `-X fgrep`, `-v`,
   `--invert-match`, `-z`, `--null-data`, `-f`, `--file`; o comando `fgrep` como hoje. `-X` com um nome fora
   da lista de matchers, ou com valor não literal, recusa. A recusa por `ansi` passa a valer só para
   padrões (no herestring já não valia; num FILE ou num argumento de opção ela não muda o que o grep lê).
4. **O `r2_greps` pula as palavras do grep que leu** (continua o laço em `R2_END`), para que o `fgrep` de
   `-X fgrep`, ou um FILE chamado `grep`, não seja lido como outro grep.
5. Publique o que o I4 vai ler, em globais: se `-c`/`--count` está presente, o conjunto de opções
   resolvidas (pela identidade), se todos os padrões são `lit`, e o redirecionamento da stdout do I2.
6. Cabeçalho: a linha `FAIL-OPEN, in TODO.md` (`:134`) sai; os limites do leitor descrevem o modelo; o
   `-z`, o `--fixed-regexp` e o `-X fgrep` entram no histórico como membros da família achados no
   planejamento.

**Como (TDD):** grupo novo depois do do I2, `local gt_p0 gt_f0 gt`:

| # | Grep do fixture (célula com `o=$(… 2>&1)` e herestring `<<< "$o"`) | Quer |
|---|---|---|
| G1 | `grep --label '^  ok    x' -H -c 'caso'` (argumento em palavra separada) | rc 1 |
| G2 | `grep -c -e 'caso' '^  ok    x'` (FILE com nome de âncora) | rc 1 |
| G3 | `grep --fixed-regexp -c '^ ✓ caso'` e `grep --fixed-r -c '^ ✓ caso'` | rc 1 |
| G4 | `grep -cz '^  ok    a.*b'` e `grep --null-data -c '^  ok    a.*b'` | rc 1 |
| G5 | `grep -X fgrep -c '^ ✓ caso'` e `grep -Xfgrep -c '^ ✓ caso'` | rc 1 |
| G6 | `grep -X egrep -c '^ ✓ a'` | rc 0 |
| G7 | `grep -X nope -c '^ ✓ a'` (matcher inválido) | rc 1 |
| G8 | `grep -c -- '^  ok    x' grep` (FILE chamado `grep`) | rc 0, `1 under the anchor rule` |
| G9 | `grep --e '^  ok    x'` (prefixo ambíguo) e `grep -K -c '^  ok    x'` (letra desconhecida) | rc 1 |
| G10 | `grep -c --colo=never '^  ok    x'` (prefixo de `color`/`colour`) | rc 0 |
| G11 | `grep -c --color never '^  ok    x'` (opcional sem `=`: `never` vira o padrão) | rc 1 |
| G12 | `grep -ce '^  ok    x'` | rc 0 |
| G13 | `grep -ec '^  ok    x'` (o padrão é `c`) | rc 1 |
| G14 | `grep -c --regexp '^  ok    x'` e `grep -c --reg '^  ok    x'` | rc 0 |
| G15 | `grep -c -5 '^  ok    x'` e `grep -c -m 1 '^  ok    x'` | rc 0 |
| G16 | `grep -c -- -e` (depois do `--`, `-e` é o padrão) | rc 1 |
| G17 | `grep -c "$p" '^  ok    x'` (o padrão começa por expansão; o FILE não salva) | rc 1 |
| G18 | `grep -c --count '^  ok    x'` e `grep --fixed -c '^ ✓ caso'` (a ambiguidade de mesma identidade resolve) | rc 0 e rc 1 |

G1–G5, G7, G9, G11 e G13 são os fail-opens e as recusas; G8 é vermelho no HEAD do jeito certo (hoje
`1 of 2`). Os probes de hoje que mexem em opção (`-F`, `-v`, `-f`, `--fixed`, `--inv`, `--file=`, `--reg=`,
`--count`, `--`, `egrep`, `fgrep`, `-e` colado, `-e` depois do herestring) mantêm o rc. Linha do grupo:
`rule_ok "grep's argv is read as getopt_long reads it, and only a pattern owes the anchor ($((PROBES - gt_p0)) probe(s))"`;
`RULE_FLOOR` +1, `PROBE_FLOOR` exato.

**Passada de sabotagem:** `required` ignorado (o argumento vira operando); `optional` tomando a palavra
seguinte; prefixo só exato; a regra da mesma identidade removida (todo prefixo múltiplo ambíguo); `--`
ignorado; "todo operando é padrão"; cada desarmador removido da lista (`F`, `fixed-regexp`, `-X fgrep`,
`v`, `z`, `f`), um por vez; o `r2_greps` sem o pulo; a letra desconhecida aceita; a linha `rule_ok` apagada;
o piso baixado.

**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c "^  ok    rule: grep's argv is read as getopt_long reads it, and only a pattern owes the anchor" <<< "$o" `` → `1`
(vermelho no HEAD: imprime `0`).
**Sensor durável:** o grupo G1–G18 no `selftest()`.
**Reancorar:** #270 em `r2_grep_anchored` (mantenha o nome) ou na função nova que decide o padrão, com o
`--anchors` limpo; os outros dois se ele acusar.
**Reversível por:** `git revert` do commit do I3 (o I2 continua de pé sozinho).

### I4 — o grep contador de um par que espera só zeros não deve âncora (#272)

**O quê:**

1. **Os pares.** Uma passada sobre a célula acha os code spans na ordem (crase a crase; um span nunca tem
   crase dentro). Um span seguido, depois de brancos opcionais, de `→`, brancos e outro span é o
   **comando** de um par, e o seguinte é o **esperado**. O esperado é "só zeros" quando, dividido em
   brancos, tem pelo menos uma palavra e toda palavra é exatamente `0`. Publique os intervalos dos
   comandos e a marca de zero em arrays globais. A forma estrita é o caso de um par só; a célula da I8 da
   LH-4 tem cinco.
2. **A isenção** (decisão 3, lida pela decisão 8 (b)), decidida no `r2_greps` para cada grep, admitida **positivamente** (predicado escrito pelo
   que entra, regra do `CLAUDE.md`): o grep conta como ancorado, nos dois caminhos (`R2_AA` e `R2_A`),
   quando **todas** valem:
   - está dentro do comando de um par cujo esperado é só zeros;
   - está no topo daquele comando: fora de `$(…)`, de crase e de `(…)` (pilha `st` vazia), então a
     contagem dele chega à stdout do par;
   - nenhum redirecionamento do I2 manda a stdout dele para outro lugar;
   - tem `-c`/`--count`, e toda opção resolvida está na lista: `c`, `i`, `y`, `no-ignore-case`, `E`, `G`,
     `P`, `w`, `x`, `e`/`regexp`, `s`, `a`, `h`, `H`, `n`, `b`, `o`, `T`, `U`, `u`, `Z`, `label`,
     `color`/`colour`, `line-buffered`. Fica fora, por omissão, todo o resto: `v` (conta o resto das
     linhas), `q`/`quiet`/`silent` (não imprime), `m` (`-m 0` imprime `0` sempre), `F` e afins, `-X`, `f`,
     `z`, `l`, `L`, `r`, `R`, `I`, `binary-files`, contexto e filtros de arquivo;
   - todo padrão é `lit` (valor conhecido; nem `dq`, nem `ansi`).
3. **O esperado misto** (`3 0`) continua recusado (decisão 3): declare no cabeçalho, junto com a contagem
   capturada e reimpressa (`echo "$(grep -c a <<< "$o")"` → `0`), que também fica de fora (não está no
   topo), e com o comando de um par que imprime outra coisa além da contagem (a Check nunca fica verde;
   isentar é inofensivo).
4. **A mensagem de FAIL** ganha, no fim, a saída: por exemplo `; a counting grep in a pair that expects only
   zeros owes none`. O trecho `pattern(s) anchored on the ok prefix or on a pass mark` não muda.
5. **Quatro fixtures de hoje têm esperado `0` por acaso** e passariam a ser isentos, deixando de medir o que
   nomeiam. Troque o **esperado** deles por um valor não-zero, sem tocar no comando nem no rc que o probe
   quer, e anote no `checkpoint-notas.md`:
   - `:1171` (`r2-blind`, `grep -c 'beta' <<< "$o"; grep -c '^  ok    x' f`) → `1 1`;
   - `:1334` (`r2-loose-echo`) → `1`;
   - `:1373` (as marcas de falha `^ × caso` e `^  ✘ caso`) → `1 1`;
   - `:1404` (`^  ok   a` com três espaços e `^ x ✓ b`) → `1 1`.

   Os fixtures de `-F`/`--fixed-strings`/`--fixed`/`fgrep` (`:1253`, `:1256`, `:1267`, `:1295`) e de ANSI-C
   (`:1303`, `:1306`, `:1317`) também têm esperado `0` e **continuam recusados** pela lista e pela regra do
   `lit`; não os mude, eles são o controle de que a lista é positiva.

**Como (TDD):** grupo novo depois do do I3, `local zr_p0 zr_f0 zr`. Na tabela, `…` abrevia
`o=$(bash t.sh 2>&1)`:

| # | Célula do fixture (notação de shell) | Quer |
|---|---|---|
| Z1 | `` `b=$(npm run build 2>&1); grep -ci 'chunks larger than' <<< "$b"` → `0` `` (a I8 da LH-4) | rc 0, `1 under the anchor rule` |
| Z2 | `` `o=$(npm test 2>&1); grep -c '^ ✓ a' <<< "$o"` → `3`; `b=$(npm run build 2>&1); grep -ci 'chunks' <<< "$b"` → `0` `` (dois pares) | rc 0 |
| Z3 | `` `o=$(bash t.sh 2>&1); grep -c 'a' <<< "$o"; grep -c 'b' <<< "$o"` → `0 0` `` | rc 0 |
| Z4 | idem → `3 0` (misto) | rc 1 |
| Z5 | `` `…; grep -vc 'caso' <<< "$o"` → `0` `` | rc 1 |
| Z6 | `` `…; grep -qc 'caso' <<< "$o"; echo 0` → `0` `` | rc 1 |
| Z7 | `` `…; grep -c -m 0 'caso' <<< "$o"` → `0` `` | rc 1 |
| Z8 | `` `…; n=$(grep -c 'caso' <<< "$o"); [ "$n" -gt 0 ]; echo $?` → `0` `` (contagem capturada) | rc 1 |
| Z9 | `` `…; grep -c 'caso' <<< "$o" > /dev/null; echo 0` → `0` `` (stdout redirecionada) | rc 1 |
| Z10 | `` `…; grep 'caso' <<< "$o"` → `0` `` (sem `-c`) | rc 1 |
| Z11 | `` `…; grep -c 'caso' <<< "$o"` → `1`; `true; echo $?` → `0` `` (o zero é de outro par) | rc 1 |
| Z12 | `` `…; grep -c 'caso' <<< "$o"` → 0 linhas `` (esperado fora de crase) | rc 1 |
| Z13 | `` `bash t.sh > out 2>&1; grep -c 'caso' out` → `0` `` (caminho estrito) | rc 0 |
| Z14 | `` `…; grep -c "$p" <<< "$o"` → `0` `` (padrão não `lit`) | rc 1 |

Z1–Z3 e Z13 são vermelhos no HEAD do jeito certo (hoje rc 1). Linha do grupo:
`rule_ok "a counting grep whose pair expects only zeros owes no anchor ($((PROBES - zr_p0)) probe(s))"`;
`RULE_FLOOR` +1 (8 no fim da missão), `PROBE_FLOOR` exato.

**Passada de sabotagem:** a isenção sem o par (a célula inteira); "só zeros" virando "algum zero"; sem o
teste de topo; sem o teste da stdout redirecionada; a lista positiva virando "qualquer opção menos `v`"
(a forma negativa que o `CLAUDE.md` recusa); sem a exigência de `-c`; sem a exigência de `lit`; a isenção só
num dos dois caminhos; a linha `rule_ok` apagada; o piso baixado.

**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: a counting grep whose pair expects only zeros owes no anchor' <<< "$o" `` → `1`
(vermelho no HEAD: imprime `0`).
**Sensor durável:** o grupo Z1–Z14 no `selftest()`.
**Medida:** o comando de medição dos alvos depois do I4 (anote no `checkpoint-notas.md`): a previsão é 103,
com a LH-4 em 1. Um número diferente não é falha; é o número, explicado na nota.
**Reancorar:** #272 em `rule2` ou na chamada nova, com o `--anchors` limpo.
**Reversível por:** `git revert` do commit do I4.

### I5 — o fecho

**O quê**, nesta ordem:

1. **A medida final**, com o sensor da base e o do HEAD sobre o mesmo corpus, na mesma hora (§ Os alvos):
   total e LH-4, antes e depois.
2. **O `TODO.md`**, consultando antes a skill (decisão 7): `RESOLVED by <hash>` nos três itens (#269 com o
   hash do I1; #270 com o do I3; #272 com o do I4), no lugar que o template manda (§ O `TODO.md`); a linha
   nova do #271, antes do `— descoberto por`, nomeando as regras do lote 9 que a prosa congelada não sabe
   (as grafias de mescla e o par de zeros, com a missão), dentro dos 120 caracteres e sem mudar o título;
   `bash tests/check-todo.sh` verde e o `--audit` da skill em `auto=0 manual=0`. A catraca
   `tests/health-baseline.txt` só se move se um achado novo nasceu (princípio 5), no mesmo diff.
3. **O `KAIZEN_LOG.md`**: a entrada `## <data> — Lote 9: o papel de cada palavra` no topo, com
   `**Missão:** \`20261016-lote-9-o-papel-de-cada-palavra\``, o antes e o depois medidos no passo 1, as
   linhas `ok` novas, os probes e as sabotagens (com as que sobreviveram primeiro e viraram probe).
4. **A gaveta** (F3): a linha da tabela e um parágrafo `**Hoje (<data>).**` dizendo que o lote 9 levou os
   três itens de `tests/` sem partir a janela, e que os 11 congelados esperam a triagem.
5. **O `20-handoff-exec.md`** do `templates/handoff.md`, com o `## Boot da próxima fase` dizendo as
   pendências 1 a 4 do `00-missao.md` (PR, sem carimbo, pull ocioso, chore pós-merge com a skill).
6. **A suíte inteira** (`bash tests/run-all.sh`, em background) verde, e só então o commit do fecho.

**Check:** `` a=$(grep -c '^## [0-9-]* — Lote 9: o papel de cada palavra$' KAIZEN_LOG.md); b=$(grep -q '20261016-lote-9-o-papel-de-cada-palavra' KAIZEN_LOG.md; echo $?); c=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/{n++} END{print n+0}' TODO.md); n=$(bash tests/check-todo.sh --count TODO.md 2>/dev/null); d=$(grep -cx "todo-findings $n" tests/health-baseline.txt); e=$(test -f docs/handoffs/20261016-lote-9-o-papel-de-cada-palavra/20-handoff-exec.md; echo $?); echo "$a $b $c $d $e" `` → `1 0 3 1 0`
(vermelho no HEAD: imprime `0 1 0 1 1`). O `awk` desta máquina é o mawk: sem `{7}`, as sete classes
escritas por extenso.
**Sensor durável:** os quatro grupos do selftest; o fecho não cria sensor.
**Reversível por:** `git revert` do commit do fecho.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A reescrita do I2/I3 muda o veredito de um probe de hoje | média | os 128 probes rodam a cada mudança; probe que muda de rc é decisão anotada, nunca ajuste silencioso do fixture (a única troca prevista é a do esperado, no I4) |
| A varredura do kit fica vermelha (um checkpoint antigo passa a ser recusado) | média | `bash tests/check-checkpoint.sh` depois de cada incremento; os dois checkpoints com padrão `dq` estão nomeados e têm o W8 como probe |
| O I1 cria recusas novas nos alvos | baixa | a exceção do `/dev/null` e o C8; a medida de regressão (114 → 114) roda logo depois do I1 |
| A tabela do grep fica incompleta | baixa | ela foi enumerada pelas mensagens de ambiguidade de `--a` … `--z`; opção ausente da tabela é recusada (lado fechado) |
| A revisão do PR entra em laço de novo | média | decisão 4: escopo fechado, parada na rodada limpa, válvula na 4ª |
| Um "sobreviveu" falso na passada de sabotagem | média | prove que a sabotagem mudou o trecho antes de concluir; ancore em código, não em linha |
| O protótipo errou o número do I4 | média | o número é o do sensor real no fecho; o protótipo é previsão, não meta |

Não-feitos, por decisão: os 11 itens congelados; o esperado misto; a mescla por um terceiro descritor; a
ordem do `>/dev/null 2>&1`; o carimbo.

## Verificação end-to-end

Com todos os incrementos `done`:

```bash
o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: ' <<< "$o"      # 9: 8 rule_ok + a linha de doc (rule: the ban on '|')
grep -c '^  ok    no checkpoint Check reads a red assertion as green' <<< "$o"      # 1
bash tests/check-checkpoint.sh --check /home/joruge/repos/lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md 2>&1 | grep -c 'pattern(s) anchored'   # 1
bash tests/check-todo.sh --anchors TODO.md                                        # 0 off target
bash tests/run-all.sh                                                             # verde
```

e o comando de medição dos alvos com o sensor da base e o do HEAD, os dois números no `KAIZEN_LOG.md`.

## Teste de autocontenção

Rodado sobre o I1 por uma leitura fria destes três arquivos: o arquivo, as três linhas a trocar (`:490`,
`:502`, `:672`), a semântica exata de "mescla" com as grafias medidas, os 20 fixtures com o rc e o texto
que cada probe quer, onde o grupo entra (`:1407`), a forma da linha `rule_ok` e dos pisos, como medir o
`PROBE_FLOOR` real, a passada de sabotagem, a medida de regressão nos alvos, o item a reancorar e o shell
em que medir grep estão escritos aqui. O I2–I4 dependem só do incremento anterior e do contexto acima
(a tabela do grep está transcrita inteira). O que não está aqui e a sessão vai precisar descobrir: os
números de linha depois de cada incremento, que o `grep -n` dá em segundos.
