---
missao: 20261119-l1b-a-rodada-delta
data: 2026-11-19
---

# Plano — L1b: a rodada delta

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-11-19, no branch `feat/l1b-a-rodada-delta` cortado de `origin/main` em `cc8509a`.
Os números de linha são desse commit: ache cada lugar pelo **símbolo** (`grep -n '^nome()' bin/sdd`),
porque a `main` pode entrar no branch antes do EXEC (pendência no `00-missao.md`).

**Onde você está e com que `sdd`**

- A missão roda num **worktree ligado** do kit (`/home/joruge/repos/sdd_agents-lote-aceleracao`). O
  `sdd` do PATH é o do checkout principal (`/home/joruge/repos/sdd_agents`), com o runner e os
  chapéus de **antes** desta missão. O `./bin/sdd` é o deste worktree. **Nunca escreva, commite ou
  entre no checkout principal**: a guarda de kit de toda corrida da máquina compara o `HEAD` e o
  `git status` dele.
- Para testar o que você escreveu, use sempre `./bin/sdd` (ou os sensores de `tests/`, que já usam
  `$ROOT/bin/sdd`). O `sdd review-base` do PATH não existe.
- Quem espelha um chapéu é **`./bin/sdd install --force`**, com o `./`. `.claude/agents/` é
  **rastreado** neste repo (`git ls-files .claude/agents` lista os oito), então o espelho entra no
  mesmo commit do chapéu. Nunca `cp`, nunca `Edit`/`Write` em `.claude/`: a sessão headless leva
  negativa. Se o `./bin/sdd install --force` responder `CHECKOUT-BUSY` (rc 75) dentro da corrida,
  não contorne: anote o comando, o rc e a saída em `checkpoint-notas.md`, marque o incremento
  `blocked` e pare.
- O **frontmatter** dos chapéus (`disallowedTools:`, `permissionsDeny:`, `writes:`, `mcp:`) não é
  tocado. Só o corpo do `agents/sdd-reviewer.md` muda.

**A suíte e os sensores (tempos medidos no HEAD)**

- `TEST_CMD` é `tests/run-all.sh` (8 a 11 min). O `gate_EXEC` a roda a cada volta.
- `bash tests/check-gates.sh`: 122 s, 490 linhas `  ok    `, rc 0. `bash tests/check-dry-run.sh`:
  10 s, 92. `bash tests/check-hat.sh`: 6 s, 105. `bash tests/check-worker.sh`: 63 s, 69.
  `bash tests/check-templates.sh`: < 1 s, 119. `bash tests/check-coordination.sh`: 35 s, 193.
  `bash tests/check-mutation.sh --anchors`: 7 s,
  `  ok    anchors: all 904 mutants still apply and leave valid code`.
  `bash tests/check-todo.sh --anchors TODO.md`: < 1 s, `  ok    anchors: 103 measured, 0 off target`.
- Todo sensor imprime `  ok    <frase>` na stdout e `  FAIL  <frase>` na stderr. Os Checks do
  `checkpoint.md` contam linhas `^  ok    <frase exata>`: **a frase de cada asserção nova está
  escrita neste plano, palavra por palavra, e tem de caber numa linha física** do sensor.
- `tests/check-lang.sh` cobra inglês em `bin/`, `agents/`, `commands/`, `docs/` e `tests/`. Frase de
  asserção, mensagem do runner e prosa do chapéu: inglês. `templates/` e `docs/handoffs/` são pt-BR.
- Antes de **cada** commit que toca `bin/` ou `tests/`: `shellcheck -S warning <arquivos tocados>`,
  `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`, e
  `bash tests/check-mutation.sh --anchors` → `all <N> mutants still apply`. Antes de commitar o
  incremento, a suíte `tests/run-all.sh` inteira.
- Um mutante novo se prova com `bash tests/check-mutation.sh --only <slug> <sensor.sh>`
  (~2 min contra o `check-gates.sh`; a saída diz que é dica). Mutante = função
  `mut_<slug>() { sed -i '/^<função>()/,/^}/ s|<código>|<sabotagem>|' "$1"; }` mais o `<slug>` no
  array `CATALOG=(` de `tests/check-mutation.sh` (linha 7474). Ancore o `sed` em **código** que só
  existe no sítio sabotado; o `--anchors` acusa o mutante que não se aplica.
  ⚠️ Defina as funções `mut_*` novas **logo acima** de `CATALOG=(`, não junto das `mut_REVIEW_*`
  antigas (linha ~1430): o `TODO.md` ancora um item em `tests/check-mutation.sh:7167`, e inserir
  linhas antes dela o tira do alvo.
- Um teste novo para o `bin/sdd` vive num sensor que já está na suíte; nenhum sensor novo nasce nesta
  missão, então nada muda em `run-all.sh`, `LINT_FLOOR`, pisos ou `step_timeout`.

**O `bin/sdd` hoje**

- `gate_REVIEW()` começa em `bin/sdd:1943`. A rodada é
  `last="$(latest_matching "$MISSION_DIR/40-review-r*.md")"` (versão, `sort -V`). Depois da tabela de
  notas, o `case "$offending"` e o `if [ -n "$offending" ]` (~`bin/sdd:2102-2104`) vêm
  `run_check_cmd "$TEST_CMD" "gate-review-test"` (a suíte) e a recusa da árvore suja. Toda recusa
  publica `GATE_WHY` e devolve 1, e **todo `GATE_WHY` de rodada começa por `$(basename "$last"): `**:
  o leitor `historic_rounds` (`bin/sdd:4136`) casa `^40-review-r[0-9]+\.md`.
- `phase_extra()` em `bin/sdd:3173`: `case "$1" in REVIEW) cat <<'EOF' … EOF ;;`. É chamado dentro do
  `boot_prompt` como `$(phase_extra "$step")` (`bin/sdd:3516`), então roda num subshell e só pode
  imprimir. `MISSION_DIR`, `MISSION`, `REPO_ROOT` e `HANDOFF_DIR` já estão definidos ali.
- `frontmatter <arquivo> <chave>` (`bin/sdd:376`) imprime o valor (vazio quando ausente);
  `frontmatter_has <arquivo> <chave>` (`bin/sdd:410`) responde pela presença. Use os dois: uma chave
  ausente e uma vazia têm vereditos diferentes (decisão 4).
- `latest_matching` em `bin/sdd:969`; `review_rounds_on_disk` em `bin/sdd:6057`.
- O `writes:` efetivo do revisor: `hat_writes REVIEW` (`bin/sdd:3125`) soma `HAT_WRITES_BASE`
  (`bin/sdd:2972`, `'$TODO_FILE, tests/health-baseline.txt'`) ao `writes:` do chapéu
  (`$HANDOFF_DIR/$MISSION/**`), já expandidos e separados por vírgula. O `.sdd/config.sh` do kit não
  tem `HAT_WRITES_EXTRA`. `hat_path_allowed <caminho> <globs>` (`bin/sdd:4688`) responde rc 0 quando o
  caminho (relativo à raiz, como o `git diff --name-only` imprime) está dentro.
- `cmd_boot` (`bin/sdd:10624`) chama `derive_phase`, que roda os gates e o `TEST_CMD`. Num repo real
  isso custa a suíte (8 a 11 min); no fixture do `check-gates.sh` o `TEST_CMD` é `true`.
- `main()` em `bin/sdd:12540` despacha `boot)      cmd_boot "$@" ;;` (`bin/sdd:12573`).
  `cmd_help()` em `bin/sdd:12290`; a entrada do `sdd boot` está em `bin/sdd:12329`.
- `coordination_enter()` em `bin/sdd:12471`. ⚠️ **O `review-base` não precisa de linha ali.** O
  último braço do `case`, `*) { COORDINATION_ADMITTED=1; return 0; } ;;` (`bin/sdd:12483`), já admite
  **sem lock** todo subcomando que o `case` não nomeia. Os que pegam o lock estão nomeados no braço de
  cima, `boot|note-manual|install|preflight|health|approve|phase|why|link-agents) : ;;`
  (`bin/sdd:12482`). Uma linha nova para o `review-base` não mudaria nada, e o mutante que a apagasse
  sobreviveria. Então: **não edite o `coordination_enter`**. O mutante `COORD_review_base_locked`
  põe o `review-base` no braço que pega o lock (ver I1). Não mexa também na linha
  `help|…|census|autonomy)` (`bin/sdd:12475`): o `mut_COORD_boot_unlocked`
  (`tests/check-mutation.sh:6609`) faz `sed` sobre esse texto exato.
- A última linha do arquivo é `{ main "$@"; exit $?; }` (12993 linhas no HEAD), e a forma é contrato
  (`tests/check-entrypoint.sh`). Logo acima dela há um bloco de comentário de 7 linhas
  (`bin/sdd:12986-12992`, `# The braces and the \`exit\` are load-bearing…`), que é dela. Há funções
  definidas depois do `main()` (ex. `close_return_home`).
- **Onde escrever o código novo:** as funções novas (`review_base_line`, `review_head_ok`,
  `cmd_review_base`) vão **juntas, no fim do arquivo, acima daquele bloco de comentário**: logo depois
  do `}` da última função (`bin/sdd:12983`), antes das duas linhas em branco e do comentário. No meio
  do arquivo, cada linha nova desloca
  as âncoras do `TODO.md` que apontam para depois dela: são ao menos 17 depois da linha 3173, e quem
  decide é o `--anchors`. Nos sítios existentes, só o mínimo: uma linha no `gate_REVIEW`, poucas no
  `phase_extra`, uma no `main()`, duas no `cmd_help()`.
- `sdd why <missão> <FASE>` imprime `<FASE>: <GATE_WHY>` (`printf '%s: %s\n' "$ph" "$GATE_WHY"`,
  `bin/sdd:8314`). Então a saída que o `assert_why` lê começa por `REVIEW: `, e as regexes das
  asserções **não** levam `^`. As que existem também não levam (ex. `tests/check-gates.sh:2353`).
- O boot já nomeia o handoff mais recente (item 4 do `boot_prompt`, `mission_latest_handoff`). No
  fixture do I1, depois de `rm … "$MDIR/45-docs.md"` (`tests/check-gates.sh:2363`), esse handoff é
  o `40-review-r12.md`. Então "o prompt contém `40-review-r12.md`" não prova nada sobre a linha
  nova; a asserção do I2 lê um literal que só a linha do delta tem.

**A skill e o worker**

- A `codereview` instalada é a 2.30.1
  (`~/.claude/plugins/cache/chewiesoft-marketplace/codereview/2.30.1/skills/codereview/SKILL.md`): o
  passo 4 usa `git merge-base {BASE_BRANCH} HEAD`, "or the base commit the user names
  (`base=<sha>`, even in prose)", e revisa `base..HEAD`.
- O worker lê a mesma chave: `rh="$(fm_value "$round" reviewed_head)"` (`bin/sdd-worker:1258`), aceita
  `^[0-9a-f]{7,40}$` que resolve como commit, e exige que todo commit de `<reviewed_head>..<head>`
  toque só a pasta da missão. Uma rodada do runner feita antes da DOCS raramente passa nisso, porque
  a DOCS escreve fora da pasta: o worker continua fazendo a rodada dele depois da corrida.
- `fm_value` (`bin/sdd-worker:78`) devolve a **primeira** ocorrência da chave. O fixture `round()` de
  `tests/check-worker.sh:1748` copia o `templates/review.md` e **insere** `reviewed_head: <sha>` logo
  abaixo do `gate:` (`sed … s@^gate: .*@gate: …\nreviewed_head: $2@`); com `-`, apaga toda linha
  `reviewed_head:`. Quando o template ganhar a chave (I3), o fixture passaria a ter duas: troque o
  `round()` para **substituir** a linha `reviewed_head:` do template (e apagá-la com `-`), no mesmo
  commit.
- O ato `review` do worker está em `commands/sdd-worker.md`, seção `` ### `review` `` (~linha 193): ele
  mergeia a base (`git merge origin/<base>`), roda a suíte e faz a rodada por subagente com
  `reviewed_head:`. A frase "The rounds the runner's REVIEW phase writes carry no `reviewed_head:`, so
  `pr-ready` waits for this one." (`commands/sdd-worker.md:203`) fica falsa nesta missão. O parágrafo
  "**`reviewed_head:` is the worker's key, on purpose.**" (`docs/pipeline.md:2078`) também, e os
  comentários de `bin/sdd-worker:1221` e `bin/sdd-worker:1286` dizem o mesmo.
- As probes do `commands/sdd-worker.md` moram em `tests/check-worker.sh` (`COMMAND="$ROOT/commands/sdd-worker.md"`,
  linha ~2082), na família `command:`.

**Os fixtures**

- `tests/check-gates.sh`: `SDD="$ROOT/bin/sdd"`, `FIX` (o repo do fixture, cwd das probes),
  `MISSION="20260101-fixture"`, `MDIR` (a pasta da missão). O `TEST_CMD="true"` não é variável do
  sensor: está no heredoc do `.sdd/config.sh` do fixture. Helpers: `pass <frase>` (imprime
  `  ok    <frase>`), `fail <frase> <esperado> <obtido>`, `assert_phase <frase> <fase>` e
  `assert_why <frase> <fase> <regex>` (lê `sdd why`, `grep -E` sem âncora). ⚠️ O `assert_phase`
  imprime `pass "<frase> → <fase>"` (`tests/check-gates.sh:47-51`), e o `assert_why` imprime
  `pass "<frase>"`. **Duas chamadas com a mesma frase dão duas linhas `ok`**: os Checks contam linhas.
- No bloco REVIEW o fixture está no branch `main` (`git checkout -q main` em
  `tests/check-gates.sh:1804`). O idioma do merge está em `:1718-1724`: `git checkout -q -b <lado>`,
  um commit, `git checkout -q <volta>`, `git merge -q --no-edit <lado> >/dev/null`. Para o I1, use
  `--no-ff`, para o merge sempre existir. A tabela toda A a copiar para o r12 é a do r10
  (`tests/check-gates.sh:2327-2351`, Rationale `clean`). O `gate:` do frontmatter tem de carregar
  evidência real, nunca placeholder: o modelo é
  `tests/run-all.sh: suite green, 559 assertions, tree clean` (`:2611`). A forma do frontmatter é a
  do `write_r11` (`:2522`): `printf -- '---\nfase: REVIEW\nrodada: 11\ngate: %s\n---\n\n'`.
  A seção REVIEW vai de `echo "== REVIEW phase =="` (linha 2109) a `# --- DOCS` (linha ~2785). Logo
  antes do `# --- DOCS`, o bloco do r11 termina com `rm -f "$MDIR/40-review-r11.md"`, um commit e
  `assert_phase "with the Rationale fixture gone the mission is back at DOCS" "DOCS"`: nesse ponto o
  `40-review-r10.md` é a rodada mais nova, toda A, **sem frontmatter**, e a fase derivada é DOCS.
  **É ali que entra o bloco novo desta missão** (I1, I2 e I3 o estendem), e ele termina do mesmo jeito:
  apaga as rodadas que escreveu, commita e afirma DOCS. O molde de uma rodada com frontmatter é o
  `write_r11` (linha ~2522).
- `tests/check-dry-run.sh`: `prompt_of REVIEW` (linha ~538) devolve o bloco do prompt de boot da
  REVIEW que a projeção imprime. A missão do fixture não tem rodada nenhuma.
- `tests/check-hat.sh`: as famílias são funções `*_probes()` chamadas numa lista no fim do arquivo
  (`grep -n '_probes$' tests/check-hat.sh`, a última é `release_stamps_probes`, linha 1155). O `fail`
  dali leva **um** argumento (`tests/check-hat.sh:48`). Leitura por seção, com
  `local agent="$ROOT/agents/sdd-reviewer.md" sec`:
  `sec="$(awk '/^## 2\. /{s=1; next} s && /^## /{s=0} s' "$agent")"`, depois
  `grep -qF '<literal>' <<< "$sec"`. Sempre herestring, nunca `printf … | grep -q` (o arquivo roda
  sob `pipefail`).
- `tests/check-worker.sh`: o `section()` (`:2089`) lê só seções `## `. A subseção
  `` ### `review` `` do `commands/sdd-worker.md` pede `awk` próprio, por exemplo
  ``awk '/^### `review`/{s=1; next} s && /^##+ /{s=0} s' "$COMMAND"``.
- `tests/check-coordination.sh:683`: a lista Python de consultas que não podem responder
  `CHECKOUT-BUSY` com outro dono no checkout, `("census", "20260101-one"), ("autonomy",), …`.

**O `agents/sdd-reviewer.md` hoje**

- Seções: `## 1. Load the state` (linha 34), `## 2. Run the review` (44), `## 3. Findings become
  increments` (76), `## 4. Write the round report` (158), `## 5.` (220).
- A linha 46 é ``Invoke `/codereview:codereview` over the mission diff. The skill routes the model by severity``.
  ⚠️ O item #436 do `TODO.md` ancora ali: `` `agents/sdd-reviewer.md:46` (`over the mission diff`) ``.
  **Mantenha o literal `over the mission diff` intacto, numa linha.** O I3 acrescenta linhas ao
  `## 1.` e o empurra para baixo. A âncora tolera 10 linhas: se o `--anchors` disser `nearest … at
  line <N>`, troque o `:46` por `:<N>` no mesmo commit.
- A REVIEW **desta** missão vai rodar com o runner de antes (o `sdd` do PATH), que não imprime linha
  de delta. Então o chapéu tem de dizer o que fazer quando o prompt não traz `base=`: a rodada é
  inteira.

**O `TODO.md`**

- O título de um item (o texto entre `**`) é a chave do espelho de issues: **nunca mude um título**.
- A âncora `` `arquivo:linha` (`símbolo`) `` é medida: o símbolo tem de estar a até 10 linhas. Antes de
  todo commit, `bash tests/check-todo.sh --anchors TODO.md` → `0 off target`; a saída do que saiu do
  alvo diz `nearest <símbolo> is at line <N>`, e o conserto é trocar o número no mesmo commit.
  Itens ancorados nos arquivos que esta missão edita (linha do `- [ ]` no `TODO.md` de `cc8509a`):
  `agents/sdd-reviewer.md` 273→`:62`, 736→`:95`, 746→`:46`, 755→`:144`, 763→`:87`; no `bin/sdd`, ao
  menos 17 âncoras depois da linha 3173 (de `:4003` a `:12729`); `tests/check-mutation.sh` 209→`:7167`; `tests/check-worker.sh`
  217→`:1904`; `commands/sdd-worker.md` 552→`:77`, 174→`:216`, 560→`:226`, 568→`:239`;
  `docs/pipeline.md` 252→`:99`; `bin/sdd-worker` 165→`:1229`, 201→`:1095`.
- O item #436 está nas linhas 745 a 752: **oito linhas, o teto**. Linhas 751 e 752:
  `  Fonte: `…`/checkpoint-notas.md` — descoberto pela sessão` (100 caracteres, 103 bytes; o
  `check-todo.sh` conta caracteres, `WIDTH_CAP=120`) e
  `  orquestradora na missão `20261117-o-worker-orquestrador` (2026-11-18)`. O `RESOLVED by <hash>`
  vai no fim da linha `Fonte:`, **antes** do `— descoberto por`; nenhuma linha passa de 120
  caracteres, e o item não passa de 8 linhas (`templates/todo.pt-BR.md`, "Onde vai o `RESOLVED by`").
  Com um hash de 7 a linha 751 chegaria a 120 exatos, no limite. Reflua o "pela sessão" para a linha
  752 do mesmo jeito. O item **fica** no arquivo, e a
  catraca (`tests/health-baseline.txt`) **não muda** nesta missão.

## Arquitetura da mudança

Uma definição do juízo, três leitores:

```
40-review-r<N>.md (reviewed_head:)  ──►  review_base_line   ──►  phase_extra REVIEW  (prompt da sessão)
                                     │                      └─►  sdd review-base      (ato review do worker)
                                     └►  review_head_ok     ──►  gate_REVIEW          (recusa a chave errada)
```

- **`review_base_line`** (sem argumento, lê `MISSION_DIR` e o git em `REPO_ROOT`) imprime **uma linha**,
  pela primeira regra que casar, nesta ordem:
  1. nenhuma `40-review-r*.md` → `full — no earlier round`;
  2. a mais nova não tem a chave → `full — 40-review-r<N>.md has no reviewed_head:`;
  3. o valor não casa `^[0-9a-f]{7,40}$` ou não resolve como commit (`git rev-parse -q --verify "<v>^{commit}"`)
     → `full — the reviewed_head: of 40-review-r<N>.md is no commit ('<v>')`;
  4. não é ancestral do `HEAD` (`git merge-base --is-ancestor`) →
     `full — the reviewed_head: of 40-review-r<N>.md (<sha curto>) is not an ancestor of HEAD`;
  5. `git rev-list --merges -n 1 <v>..HEAD` não vazio →
     `full — merge <sha curto do merge> entered after 40-review-r<N>.md`;
  6. senão → `base=<sha de 40 hex, o rev-parse do valor> — 40-review-r<N>.md reviewed this head; its findings are the open ones`.

  O primeiro campo é o contrato (`base=<sha>` ou `full`); o resto é para o humano. Na linha `base=`,
  o nome da rodada é a **terceira palavra** (`awk '{print $3}'`); numa linha `full`, o motivo é tudo
  depois de `full — `. Todo "sha curto" desta missão, no código e nos testes, sai de
  `git rev-parse --short <sha>`, para os dois concordarem no comprimento. Sob `set -euo pipefail`,
  toda captura de `git` é guardada (`|| true`, `|| rc=$?` ou `if …; then`). Função pura: só imprime,
  não publica global, e pode ser lida por `$( )`.
- **`sdd review-base <missão>`** (`cmd_review_base`): `load_config`, `resolve_mission "${1:-}"`,
  `review_base_line`; rc 0 com a linha (`full` é resposta, não erro), e o rc do `resolve_mission` sem
  missão. Não chama `derive_phase` nem gate nenhum: não roda a suíte. Não precisa de linha no
  `coordination_enter` (o braço `*)` já admite sem lock; ver o contexto verificado). Entra no
  `cmd_help`, abaixo do `sdd boot`.
- **`phase_extra REVIEW`**: depois do heredoc que existe, `line="$(review_base_line)"`, e imprime a
  linha do delta conforme `${line%% *}`:
  - `base=…` → `This is a DELTA round. Invoke /codereview:codereview base=<sha> — the argument, not this sentence, limits the skill to the delta — and read <round> for the findings it left open. A finding in code the delta did not touch goes to the TODO_FILE, never to an R<n>; the one read outside the delta is a grep for the old spelling of an interface the delta changed.`
  - `full …` → `This is a FULL round (<o motivo, o texto depois de "full — ">): invoke /codereview:codereview over the mission diff.`
  As duas frases podem ser quebradas em mais de uma linha do prompt, mas os literais que as probes
  leem (abaixo) ficam inteiros numa linha.
- **`review_head_ok <rodada>`**: rc 0 quando a chave está ausente (legado, decisão 4); senão recusa
  com `GATE_WHY` e rc 1, nesta ordem:
  1. valor fora de `^[0-9a-f]{7,40}$` ou que não resolve como commit →
     `<basename>: reviewed_head '<v>' is no commit — write the git rev-parse HEAD the round read, or leave the key out`;
  2. não ancestral do `HEAD` → `<basename>: reviewed_head <curto> is not an ancestor of HEAD — the branch does not carry the commit the round read`;
  3. o commit da rodada é `git log -1 --format=%H -- <rodada>` (vazio = rodada não commitada: rc 0,
     a recusa da árvore suja logo abaixo cobre); todo caminho de
     `git diff --name-only <v> <commit da rodada>` tem de passar em `hat_path_allowed` com os globs de
     `hat_writes REVIEW`; o primeiro que não passa →
     `<basename>: <caminho> changed between reviewed_head <curto> and the round's commit — the round did not read that code`.
  O `gate_REVIEW` a chama numa linha só, `review_head_ok "$last" || return 1`, logo depois do
  `if [ -n "$offending" ]` e **antes** do `run_check_cmd` (recusa barata antes da suíte).
- **O chapéu** grava a chave: no `## 1. Load the state`, antes de ler qualquer coisa, `git rev-parse HEAD`;
  esse sha vai no `reviewed_head:` do frontmatter da rodada. No `## 2. Run the review`, a rodada segue
  a linha do delta do prompt; sem ela (um runner mais velho), a rodada é inteira.
- **O template** `templates/review.md` ganha `reviewed_head:` como **última** chave do frontmatter,
  logo abaixo do `gate:`.
- **O worker**: o ato `review` roda `sdd review-base <missão>` **depois** do merge da base e passa a
  linha ao subagente; os docs e comentários que diziam que a rodada do runner não tem a chave são
  reescritos.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — o juízo do delta e o verbo `sdd review-base`

**O quê:** `review_base_line` e `cmd_review_base`, como em "Arquitetura"; o despacho
`review-base) cmd_review_base "$@" ;;` no `main()`; a entrada no `cmd_help()`
(`sdd review-base <mission>` — o que imprime, que não roda gate nem suíte);
`("review-base", "20260101-one")` na lista de consultas de `tests/check-coordination.sh:683`.
O `coordination_enter()` **não** muda (o braço `*)` já admite o verbo sem lock).
**Onde:** `bin/sdd` (fim do arquivo, `main`, `cmd_help`), `tests/check-gates.sh`,
`tests/check-coordination.sh`, `tests/check-mutation.sh`, `TODO.md` (âncoras, se saírem do alvo).
**Como (TDD):** primeiro o bloco novo do `tests/check-gates.sh`, no ponto descrito em "Os fixtures"
(logo antes do `# --- DOCS`, no branch `main`). Cada mundo escreve `"$MDIR/40-review-r12.md"`: o
frontmatter na forma do `write_r11`, com `fase: REVIEW`, `rodada: 12`, um `gate:` com evidência real
e, conforme o mundo, `reviewed_head: <v>` (sempre a última chave). Depois vem a tabela toda A do
r10. O mundo commita (`git add -A && git commit -qm "…" >/dev/null`) e lê
`out="$( cd "$FIX" && "$SDD" review-base "$MISSION" 2>&1 )"`. Cada asserção é **um** `pass`/`fail`
com a frase abaixo, palavra por palavra:
1. `review-base: a round with reviewed_head: answers base=<that sha>` — chave = `git rev-parse HEAD`
   antes do commit da rodada; a saída começa por `base=<o sha de 40 hex>` e contém `40-review-r12.md`;
2. `review-base: a round without reviewed_head: answers full and names it` — sem a chave; começa por
   `full` e contém `40-review-r12.md has no reviewed_head:`;
3. `review-base: a reviewed_head: that is no commit answers full` — chave `zzz`; começa por `full`
   **e contém `is no commit`** (sem isso, o mutante da regra 3 sobrevive, porque o `zzz` cai na
   regra 4 e também diz `full`);
4. `review-base: a reviewed_head: the HEAD does not carry answers full` — chave = um commit órfão
   (`git commit-tree "$(git hash-object -t tree /dev/null)" -m orphan`); começa por `full` e contém
   `not an ancestor of HEAD`;
5. `review-base: a merge after the reviewed head answers full and names the merge` — chave =
   `git rev-parse HEAD`, commit do r12. Depois `git checkout -q -b l1b-side`, um commit num arquivo
   novo, `git checkout -q main`, `git merge -q --no-edit --no-ff l1b-side >/dev/null` e
   `git branch -q -D l1b-side`. A saída começa por `full` e contém `git rev-parse --short HEAD` (o
   merge). O merge fica na história. Os mundos seguintes gravam `reviewed_head:` depois dele, então
   ele não entra no intervalo deles.

Rode o `check-gates.sh` e veja as cinco vermelhas (o verbo não existe: `unknown command`), depois
implemente. O bloco termina apagando o r12, commitando e afirmando DOCS
(`assert_phase "with the r12 fixture gone the mission is back at DOCS" "DOCS"`). Os mutantes e quem
mata cada um (prove com `bash tests/check-mutation.sh --only <slug> <sensor.sh>`):
- `RUN_review_base_absent_as_base` (a regra 2 deixa passar) → asserção 2, contra `check-gates.sh`;
- `RUN_review_base_commit_unchecked` (sem a regra 3) → asserção 3 (`is no commit`), contra
  `check-gates.sh`;
- `RUN_review_base_ancestry_unchecked` (sem a regra 4) → asserção 4, contra `check-gates.sh`;
- `RUN_review_base_merge_ignored` (sem a regra 5) → asserção 5, contra `check-gates.sh`;
- `COORD_review_base_locked` → a consulta nova do `check-coordination.sh` (que responde
  `CHECKOUT-BUSY` com outro dono). Põe o `review-base` no braço que pega o lock:
  `sed -i '/^coordination_enter()/,/^}/ s/^    boot|note-manual|/    review-base|boot|note-manual|/' "$1"`.
**Check:** ver `checkpoint.md` — as cinco linhas `review-base: ` do `check-gates.sh`. Antes: 0.
**Sensor durável:** as cinco asserções no `check-gates.sh`, a consulta no `check-coordination.sh` e
os cinco mutantes no catálogo, todos na suíte.
**Reversível por:** `git revert`.

### I2 — o prompt da REVIEW diz qual rodada é, e a regra do achado fora do delta

**O quê:** o `phase_extra REVIEW` imprime a linha do delta (ver "Arquitetura"); o `## 2. Run the review`
do `agents/sdd-reviewer.md` diz que a rodada segue a linha do prompt, que sem ela (runner mais velho) a
rodada é inteira, e a regra da decisão 9; espelho por `./bin/sdd install --force`.
**Onde:** `bin/sdd` (`phase_extra`), `agents/sdd-reviewer.md`, `.claude/agents/sdd-reviewer.md` (pelo
`install --force`), `tests/check-dry-run.sh`, `tests/check-gates.sh`, `tests/check-hat.sh`,
`tests/check-mutation.sh`, `TODO.md` (âncoras).
**Como (TDD):** três asserções, palavra por palavra, vermelhas antes:
1. em `tests/check-dry-run.sh`, logo abaixo do bloco `== the REVIEW boot prompt carries the contract of the phase ==`:
   `the REVIEW boot prompt of a first round orders a full review and says why` — o `prompt_of REVIEW`
   contém o literal `FULL round (no earlier round)`;
2. no bloco do I1 em `tests/check-gates.sh`, com o r12 de chave válida commitado:
   `the REVIEW boot prompt of a delta round carries base= and names the round` — a saída de
   `"$SDD" boot "$MISSION" REVIEW` contém `/codereview:codereview base=<o sha de 40 hex>` **e** o
   literal `read 40-review-r12.md for the findings it left open`. Só o nome do arquivo não basta: o
   item 4 do boot já nomeia o `40-review-r12.md` como o handoff mais recente. Os dois literais ficam
   inteiros numa linha do prompt;
3. em `tests/check-hat.sh`, uma família nova `reviewer_delta_probes`, acrescentada à lista do fim:
   `reviewer hat: a delta round sends a finding outside the delta to the TODO_FILE` — a seção `## 2.`
   do `agents/sdd-reviewer.md` contém os literais `base=` e `never to an R<n>`.
Mutante: `RUN_review_prompt_delta_dropped` (o `phase_extra` deixa de imprimir a linha do delta),
provado contra `check-dry-run.sh`.
**Check:** ver `checkpoint.md` — `1 1 1`. Antes: `0 0 0`.
**Sensor durável:** as três asserções e o mutante.
**Reversível por:** `git revert`.

### I3 — a rodada grava o head, e o gate confere

**O quê:** `reviewed_head:` no `templates/review.md` (última chave, abaixo do `gate:`, com um
placeholder em pt-BR que diga "o `git rev-parse HEAD` que a rodada leu antes de revisar, 40 hex");
o chapéu manda gravá-la (`## 1.`, e o frontmatter em `## 4.`); `review_head_ok` e a sua linha no
`gate_REVIEW`; o `round()` de `tests/check-worker.sh` passa a substituir a linha do template.
**Onde:** `templates/review.md`, `agents/sdd-reviewer.md` (+ espelho), `bin/sdd` (fim do arquivo e uma
linha no `gate_REVIEW`), `tests/check-gates.sh`, `tests/check-worker.sh`, `tests/check-mutation.sh`,
`TODO.md` (âncoras).
**Como (TDD):** cinco mundos no bloco do I1. ⚠️ **Cada mundo dá exatamente uma linha `ok` que
começa por `gate_REVIEW: reviewed_head`**, porque o Check conta 5. Nas três recusas, a frase vai no
`assert_why` (fase `REVIEW`, regex sem `^`). A fase derivada vai num `assert_phase` cuja frase
**não** começa por esse prefixo, por exemplo `r12 with a wrong reviewed_head (zzz): the mission stays at REVIEW`.
Nas duas aprovações, a frase vai no `assert_phase` (→ DOCS, que imprime uma linha). As frases,
palavra por palavra:
1. `gate_REVIEW: reviewed_head that is no sha is refused, naming the round` — chave `zzz`; regex
   `40-review-r12\.md: reviewed_head 'zzz' is no commit`;
2. `gate_REVIEW: reviewed_head the HEAD does not carry is refused` — commit órfão; regex
   `40-review-r12\.md: reviewed_head [0-9a-f]+ is not an ancestor of HEAD`;
3. `gate_REVIEW: reviewed_head with code changed before the round commit is refused` — chave = HEAD,
   depois um commit num arquivo fora da pasta da missão (`l1b-outside.txt` na raiz do fixture),
   depois o commit do r12. Regex `40-review-r12\.md: l1b-outside\.txt changed between reviewed_head`;
4. `gate_REVIEW: reviewed_head absent still passes, as the rounds before the key` — sem a chave → DOCS;
5. `gate_REVIEW: reviewed_head the round read, with only its own files after it, passes` — chave =
   HEAD, o commit do r12 só com a pasta da missão → DOCS.
Os mutantes e quem mata cada um, todos contra `check-gates.sh`:
- `REVIEW_head_sha_unchecked` (sem a regra 1) → o mundo 1, porque o `zzz` cai na regra 2, e
  `is no commit` não casa;
- `REVIEW_head_ancestry_unchecked` (sem a regra 2) → o mundo 2. A árvore do órfão é vazia, então a
  regra 3 ainda recusa, mas com `changed between`, e `not an ancestor` não casa;
- `REVIEW_head_range_unchecked` (sem a regra 3) → o mundo 3, que vira DOCS;
- `REVIEW_head_absent_refused` (a ausência passa a recusar) → o mundo 4. Rode também `bash tests/check-worker.sh` e `bash tests/check-templates.sh`:
os dois leem o `templates/review.md`.
**Check:** ver `checkpoint.md` — `5 1`: as cinco linhas e a chave no template. Antes: `0 0`.
**Sensor durável:** as cinco asserções e os quatro mutantes.
**Reversível por:** `git revert`.

### I4 — o ato `review` do worker usa o delta, e os docs param de dizer o contrário

**O quê:** na seção `` ### `review` `` do `commands/sdd-worker.md`, depois do merge da base e da
suíte, rodar `sdd review-base <mission>` e passar a linha ao subagente (`base=<sha>` → ele invoca
`/codereview:codereview base=<sha>` e lê a rodada nomeada para os achados abertos; `full — …` → a
rodada é inteira); reescrever a frase da linha 203 (a rodada do runner tem a chave agora, e o
`pr-ready` segue esperando a do worker quando um commit depois dela sai da pasta da missão, como os
da DOCS). Em `docs/pipeline.md`, reescrever o parágrafo de `:2078` pelo mesmo fato e dizer o delta na
seção `### REVIEW` (`:389`), citando `sdd review-base`. Nos comentários de `bin/sdd-worker:1221` e
`:1286`, o mesmo fato, sem mudar o número de linhas (âncoras em `:1229` e `:1095`). Também os dois
comentários de `tests/check-worker.sh` que dizem "a round with reviewed_head: is the worker's own"
(`:150-151` e `:2526-2527`), sem mudar o número de linhas (âncora em `:1904`).
**Onde:** `commands/sdd-worker.md`, `docs/pipeline.md`, `bin/sdd-worker` (comentários),
`tests/check-worker.sh`, `TODO.md` (âncoras).
**Como (TDD):** uma asserção na família `command:` de `tests/check-worker.sh`, vermelha antes:
`command: the review act passes the line of sdd review-base to its subagent` — a seção `` ### `review` ``
do `commands/sdd-worker.md` contém `sdd review-base` **e não contém** `carry no `reviewed_head:``.
**Check:** ver `checkpoint.md` — `1 0`: a asserção e o `grep -q 'sdd review-base' docs/pipeline.md`.
Antes: `0 1`.
**Sensor durável:** a asserção. Os docs são prosa: quem os lê de novo é a DOCS desta missão e o
`check-lang.sh`.
**Reversível por:** `git revert`.

### I5 — o fecho: `RESOLVED by` no #436 e o `20-handoff-exec.md`

**O quê:** o item #436 do `TODO.md` ganha `RESOLVED by <hash curto do commit do I4>` (a coluna Commit
do `checkpoint.md`), onde e como diz "O `TODO.md`" acima. Por ser o último incremento, o `§6` do seu
chapéu vale: escreva e commite o `20-handoff-exec.md` (o que no diff chega a quem usa o kit: o verbo
novo e a sua ajuda, o prompt da REVIEW, a chave no template, o ato do worker; e a jornada de
"Verificação end-to-end").
**Onde:** `TODO.md`, `docs/handoffs/20261119-l1b-a-rodada-delta/20-handoff-exec.md`.
**Como (TDD):** rode o Check antes (`0 1`), escreva, rode depois (`1 0`); em seguida
`bash tests/check-todo.sh --check TODO.md` rc 0 e `--anchors TODO.md` → `0 off target`. O título não
muda, o item fica, a catraca não muda.
**Check:** ver `checkpoint.md`.
**Sensor durável:** `tests/check-todo.sh` (a forma do `RESOLVED by`, o teto de 8 linhas e as 120
colunas), na suíte. O item sai do arquivo no chore de depois do merge.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| A `main` entra no branch antes do EXEC (o L1 mergeado) e muda os números de linha deste plano | alta | os lugares estão nomeados por símbolo; rode `tests/check-checkpoint.sh --red` de novo depois do merge (pendência no `00-missao.md`) |
| O L1 também edita o `agents/sdd-reviewer.md` (§3 e a linha 144) e o `TODO.md` | média | hunks diferentes dos desta missão; com a `main` mergeada antes do EXEC, o conflito, se houver, aparece antes de pagar sessão |
| O `./bin/sdd install --force` responde `CHECKOUT-BUSY` dentro da corrida | média | não contorne: nota, `blocked`, pare |
| A frase de uma asserção quebrada em duas linhas do sensor nunca casa | média | cada frase está neste plano numa linha só; copie-a inteira |
| Código novo no meio do `bin/sdd` tira do alvo as âncoras do `TODO.md` (ao menos 17 depois da linha 3173) | alta se ignorado | funções novas no fim do arquivo; `check-todo.sh --anchors` antes de todo commit |
| Uma linha nova no `coordination_enter` para o `review-base` não muda nada (o braço `*)` já admite), e o mutante que a apaga sobrevive | alta se ignorado | o `coordination_enter` não muda; o `COORD_review_base_locked` põe o verbo no braço que pega o lock; `check-mutation.sh --anchors` antes do commit |
| Uma asserção que lê só o prefixo comum de dois ramos deixa um mutante vivo | alta se ignorado | cada asserção do I1 e do I3 lê o texto do ramo dela (`is no commit`, `not an ancestor`, `changed between`); a tabela de quem mata cada mutante está no I1 e no I3 |
| A REVIEW desta missão roda com o runner de antes e não mede o delta | certa | é a decisão 7: o número vem do L2 |

## Verificação end-to-end

Com os cinco incrementos `done`, na raiz do worktree:

```bash
o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    review-base: ' <<< "$o"          # 5
grep -c '^  ok    gate_REVIEW: reviewed_head' <<< "$o"                                # 5
grep -c '^  ok    the REVIEW boot prompt of a delta round carries base= and names the round' <<< "$o"   # 1
./bin/sdd review-base 20261119-l1b-a-rodada-delta     # full — no earlier round (a missão ainda não tem rodada)
bash tests/run-all.sh                                 # rc 0
```

A métrica em dinheiro é a pendência do L2 no `00-missao.md`.
