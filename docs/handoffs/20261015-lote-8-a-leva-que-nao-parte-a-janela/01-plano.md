---
missao: 20261015-lote-8-a-leva-que-nao-parte-a-janela
data: 2026-10-15
---

# Plano — o lote 8: a leva que não parte a janela

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

### Onde e como se executa

- **Raiz de TODA leitura e escrita:** o worktree ligado `/home/joruge/repos/sdd_agents-lote-8`, na
  branch `fix/lote-8-a-leva-que-nao-parte-a-janela`, cortada da `origin/main` `fec0cca` e **sem
  upstream** (`git rev-parse --abbrev-ref @{u}` → `fatal: no upstream configured`). Os dois commits
  do planner já estão nela: `ed78ff5` (o achado do `--no-track`) e `42b1a35` (o gêmeo congelado
  dele). A catraca `tests/health-baseline.txt` está em `todo-findings 15`.
- **Missão do kit = execução INTERATIVA no worktree**, um incremento por vez, no contrato do
  `sdd-executor`: Red → Green → commit → checkpoint como último ato. **Nunca** `sdd run` a partir
  do checkout principal (ADR 0016 §2). Dentro do worktree, `health`, `preflight` e `install` rodam
  como `./bin/sdd`.
- **Nada se escreve no checkout principal `/home/joruge/repos/sdd_agents`**, nem arquivo não
  rastreado. A guarda de kit de todo `sdd run` de alvo compara o `HEAD` e o
  `status --porcelain` dele. Às 15:03 havia um `sdd run` vivo no `lighthouse_project`
  (`ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'`).
- **Congelamento:** o eixo do juiz é o último commit em `KIT_BEHAVIOR_PATHS=(bin agents templates
  config)` (`bin/sdd:4075`). Esta leva toca **só** `tests/`, `commands/`, `docs/`, `TODO.md`,
  `KAIZEN_LOG.md` e a catraca. Um diff em `bin/`, `agents/`, `templates/` ou `config/` é **fora de
  escopo** e parte a janela: se um incremento parecer exigir um desses, pare e registre no
  `checkpoint-notas.md`.
- **O carimbo:** `MUTATION_STAMP_PATHS=(bin tests templates config agents)` (`bin/sdd:2417`), menos
  a catraca. `tests/` está na chave, `commands/` não está.

### `tests/check-checkpoint.sh` (I1, I2) — 1178 linhas, roda em 5,6 s

- `OK_ANCHOR='^  ok    '`, `ANCHOR_SQ="'${OK_ANCHOR}"` e `ANCHOR_DQ="\"${OK_ANCHOR}"` em `:162-164`,
  uma definição, lida pela regra da célula, pelas asserções de doc e pelos probes.
  `count_occ <needle> <hay>` em `:182` (só expansão de parâmetro).
- **A regra 2 de hoje** (`scan_file`, `:307-319`):
  - pré-condição: a célula contém `2>&1` (`case "$chk" in *'2>&1'*`) **e** `grep`
    (`g="$(count_occ 'grep' "$chk")"`, `> 0`);
  - então `N_RULED++` e `a = count_occ(ANCHOR_SQ) + count_occ(ANCHOR_DQ)` na **célula inteira**;
  - recusa quando `a < g`, com
    `fail "$label: the Check of $id greps a sensor's merged output with $a of $g pattern(s) anchored on the ok prefix — FAIL prints the same text as ok, so this cell answers 'the assertion exists', never 'the assertion passed'"`
    e `V_ANCHOR++`.
- **Os probes da regra 2 no `selftest()`** (`:729`):
  - os fixtures `anchored`, `blind`, `nocaret`, `thin`, `nogrep`, `nomerge`, `piped`, `two` e
    `onlyone`, montados em `:734-767` com `cp_head` (`:670`) e `cp_row` (`:677`, `cp_row <file> <id> <check cell> [status]`);
  - as chamadas `probe` em `:770-778`;
  - a assinatura é `probe <desc> <want_rc> <want_text|-> <target> [mode]` (`:653`), e o `mode`
    padrão é `--check`.
- **Pisos:** `PROBE_FLOOR=64` (`:646`) é **apertado**, igual à contagem real ("A floor one below the
  truth measures nothing it claims to"). Todo probe novo sobe o piso para a contagem nova exata.
  `RULED_FLOOR=4` vale para a varredura do kit.
- **Forma de linha `ok` por grupo:** `local red_p0="$PROBES" red_f0="$FAILS"` (`:1073`) e, no fim
  do grupo, `[ "$FAILS" -eq "$red_f0" ] && pass "rule: … ($((PROBES - red_p0)) probe(s))"`
  (`:1128-1129`).
- **A corrida padrão** (`:1172-1176`): `selftest || exit $?`, depois `calibrate`, depois `scan`. Na
  varredura do kit de hoje: `no checkpoint Check reads a red assertion as green (188 cell(s) under the rule, 251 row(s) in 29 file(s))`.
- **O sensor mede markdown**, então o catálogo de mutação não o alcança. Quem o guarda é o
  `selftest()`, com rc 90/91/92, e regra nova exige a **passada de sabotagem adversarial** do
  `CLAUDE.md`: degradar cada regra e exigir o selftest vermelho em cada degradação.
- **Os dois defeitos reproduzidos no HEAD** (fixture, `--check`):
  - #258: `` `o=$(bash t.sh 2>&1); a=$(grep -c '^  ok    x' <<< "$o"); b=$(grep -c foo f); echo "$a $b"` ``
    → `the Check of I1 greps a sensor's merged output with 1 of 2 pattern(s) anchored on the ok prefix`;
  - #249: `` `o=$(npm test 2>&1); grep -c '^ ✓ src/a.test.ts > caso' <<< "$o"` `` → `0 of 1 pattern(s)`;
  - o controle cego `` `o=$(npm test 2>&1); grep -c 'caso' <<< "$o"` `` → `0 of 1`, e tem de
    **continuar** recusado.
- **A marca de "passou" é U+2713 (`✓`, bytes `e2 9c 93`)** nos dois runners medidos:
  - vitest 3.2.7 (`/home/joruge/repos/lighthouse_project/node_modules/vitest/package.json`): ` ✓ `
    para o caso que passou e ` × ` para o que reprovou, na stdout
    (`lighthouse_project/docs/handoffs/20261014-amep-entrada-em-dois-niveis/01-plano.md:36-37`);
  - list do Playwright: `  ✓   1 [chromium] › …` e `  ✘   8 [chromium] › …` nos logs de gate de
    `lighthouse_project/.sdd/logs/`;
  - as Checks da LH-4 escrevem `'^ ✓ src/test/… > '` (codepoint conferido: `0x2713`).
- **O alcance nos alvos (antes):** o `--check` sobre os 36 checkpoints dos dois alvos recusa **122**
  células, em 19 missões (14 em `lighthouse_project/…/20260921-amep-backend-0-1-0`, 10 na LH-4
  `20260927-idioma-da-spa-pelo-idp`, o resto no `sales_quote`). O comando, de leitura só, que o I6
  repete:

  ```bash
  for f in /home/joruge/repos/lighthouse_project/docs/handoffs/*/checkpoint.md \
           /home/joruge/repos/sales_quote/docs/handoffs/*/checkpoint.md; do
    bash tests/check-checkpoint.sh --check "$f" 2>&1
  done | grep -c 'pattern(s) anchored'
  ```

  O protótipo descartável do planner (Python, fora do repo) previu a LH-4 em 1–2 e o total em ~113.
  O 2 da LH-4 era um artefato do protótipo: ele partia o `grep` no `;` de dentro de um padrão entre
  aspas (`'const PENDENTES: readonly string\[\] = \[\];'`). O conserto real tem de ler aspas (I1).
  A recusa que sobra (I9 da LH-4) lê `grep -c '^Total: 1 test in 1 file' <<< "$o"` de um
  `playwright --list` com `2>&1`, e continua recusada pela regra.

### `tests/check-todo.sh` (I3) — roda em 5,2 s

- `WIDTH_CAP=120` em `:211`, sem botão de ambiente de propósito.
- **A regra da largura** é um bloco `awk` sob `LC_ALL=C` (`:572-576`):

  ```awk
  sect == 1 && mode == "lint" {
    w = $0; gsub(/[\200-\277]/, "", w)
    if (length(w) > wcap)
      print "  line " NR ": " length(w) " characters on one physical line, cap is " wcap " — the long analysis lives in the handoff"
  }
  ```

  ⚠️ O `awk` desta máquina é o **mawk**, orientado a byte: classe negada **só com ASCII** (`[^` ]`
  serve), nunca com caractere multibyte (`CLAUDE.md`, verbete do mawk).
- **Os probes da largura** estão em `:1769-1809`, entre `rule_begin` e
  `rule_end 7 'a physical line of the open section holds at most 120 characters'`. Os ajudantes são
  `long_item`, `assert_says <file> <cap> <text> <label>`, `assert_rc <rc> <label> <cmd…>` e
  `with_decided`.
- `rule_end <floor> <text>` (`:684-695`) imprime `  ok    rule: <text> (N probe(s))` só se o grupo
  não ganhou `FAILS`, e conta `RULES_REPORTED`. **Pisos:** `RULES_FLOOR=11` (`:682`; um grupo novo
  sobe para 12) e o piso total `-lt 168` (`:2076`, "The number moves only on purpose").
- **O defeito, reproduzido num repo de rascunho** com o caminho real do `sales_quote`
  (`packages/backend/src/modules/sales-quote/infrastructure/__tests__/prisma-cotacao-repository-query.integration.test.ts`,
  117 caracteres, mais `:420`):

  ```
  - [ ] **Item longo** —
    `<o caminho>:420`
    (`sanity_perf_case`) — teto de 1 s.
    — descoberto por `x` na missão `y` (2026-10-15)
  ```

  responde `line 7: 125 characters on one physical line, cap is 120`, e é a **única** violação. O
  parser de âncora já aceita o `` (`símbolo`) `` na linha física seguinte.
- **A prosa congelada que fica mais estrita que o sensor** (não editar, decisão 7):
  `templates/todo.pt-BR.md:24` ("Nenhuma linha física da seção aberta passa de 120 caracteres"),
  `templates/todo.md:24` e `agents/sdd-executor.md:127`.

### `tests/check-hat.sh` (I4, I5) — roda em 4,1 s, 88 linhas `ok`

- **`command_relay_probes`** (`:438`) lê a seção pelo nome:
  `relay="$(awk '/^## Relaying the grill to the human/{s=1; next} s && /^## /{s=0} s' "$cmd")"`.
  O par de hoje exige `by the option's text, never by its position` e
  `Nothing else resumes the planner while a question is pending` (`:454-455`).
- **`command_worktree_probes`** (`:544`) lê `## Before anything else` e exige, entre outros, o
  literal `git worktree add ../<repo>-<slug>` (`:550`). **Esse literal não pode quebrar.**
- A lista de topo (`:767-777`) chama cada `*_probes`. Um par `pass`/`fail` novo **dentro** de
  uma função existente não muda a lista.

### `commands/sdd-plan.md` (I4, I5) — 185 linhas

- `:35` diz `` `git worktree add ../<repo>-<slug> -b <branch> origin/<DEFAULT_BRANCH>` — or reuse it, when ``.
  Medido com git 2.43.0 num repo de rascunho: sem a flag, a branch nasce com upstream
  `origin/main`. `git worktree add ../w3 --no-track -b t3 origin/main` (flag **depois** do caminho)
  e `git worktree add --no-track ../w2 -b t2 origin/main` deixam as duas `no upstream configured`.
  **Use a forma com a flag depois do caminho**: ela preserva o literal que o `check-hat.sh:550` exige.
- A seção `## Relaying the grill to the human` vai de `:82` a `:114`. Âncoras dos itens:
  `SendMessage` em `:94`, e o bullet `- **Nothing else resumes the planner while a question is pending.**`
  em `:97-104`.
- Sobre o retorno da `SendMessage` (descrição da ferramenta, lida no planejamento): o nome de um
  agente continua valendo depois que ele termina, e "a send resumes it from its transcript"; com
  o agente ocupado, "messages enqueue and drain at the receiver's next tool round". A string
  `Resuming agent` vem do achado (#264, relay do grill da 0.4.0 do `lighthouse_project`,
  2026-10-14). A fonte que o item cita (`lighthouse_project/docs/handoffs/2026-10-14-planejar-0-4-0.md`)
  **não** a contém. Escreva a regra pelo comportamento e cite a string como medida, sem fazer a
  regra depender dela.
- O `tests/check-lang.sh` lê `commands/*.md` como superfície **inglesa**: prosa nova em inglês,
  sem stopword de pt-BR.

### O `TODO.md` — as âncoras que os incrementos movem

`tests/check-todo.sh` está no `TEST_CMD` e **reprova** a âncora cujo símbolo designado sai a mais
de 10 linhas da linha citada. Todo incremento roda `bash tests/check-todo.sh --anchors TODO.md` e
reancora, **no mesmo commit**, o item que moveu (ver `agents/sdd-planner.md` § 4). Linhas de hoje:

| Item | Linha no `TODO.md` | Âncora | Movida por |
|---|---|---|---|
| #257 (âncora longa) | 51 | `tests/check-todo.sh:211` (`WIDTH_CAP`) | I3, se o cabeçalho crescer acima de `:211` |
| #258 (regra 2 por célula) | 58 | `tests/check-checkpoint.sh:310` (`count_occ`) | I1 (reescreve `:307-319`) |
| #264 (recado ao planner) | 88 | `commands/sdd-plan.md:97` (`SendMessage`) | I4/I5, se `:94` andar mais de 10 linhas |
| relay `--no-track` | 96 | `commands/sdd-plan.md:35` (`git worktree add`) | I5 (a própria linha) |
| #249 (`✓` do vitest) | 150 | `tests/check-checkpoint.sh:313` (`ANCHOR_SQ`) | I1/I2 (reescrevem `:307-319`) |

**Onde vai o `RESOLVED by`** (`templates/todo.pt-BR.md:38-41`): no fim da última linha do corpo, ou
na linha `Fonte:` antes do `— descoberto por`. Nunca numa linha própria (vira a 9ª linha num item
no teto) e nunca depois do descoberto-por. Sem espaço nos 120 caracteres, encurte o corpo.

### O fecho (I6)

- **`KAIZEN_LOG.md`:** a entrada mais nova vai no topo. Hoje a `:7` é
  `## 2026-10-14 — Lote 7: a rota da QA e o aceite que lê o plano`, com `**Missão:**`, `**Antes**`
  e `**Depois**` e `---` entre as entradas. O `gate_DOCS` exige, no diff da branch, um bloco `## `
  cujo título e uma linha que cita o id inteiro da missão sejam novos (ADR 0018 §4), porque
  `kaizen_log:` está vazio.
- **Gaveta:** a seção `## F3` de `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` termina no
  parágrafo `**Hoje (2026-10-14).**` (`:193-199`), logo antes de `## F4` (`:201`). "Frente que anda, fecha ou
  nasce atualiza o índice no mesmo commit" (`CLAUDE.md`).
- **O `gate_EXEC`** (`bin/sdd`, corpo do `gate_EXEC`) exige todo incremento `done`, `TEST_CMD`
  (`tests/run-all.sh`) verde e `20-handoff-exec.md` com `## TL;DR` de até 20 linhas
  (`handoff_tldr_ok`). O template é `templates/handoff.md`.
- **Antes de cada commit em `tests/`, rode `shellcheck -S warning` nos arquivos tocados.** O lint só
  roda na suíte inteira, e medido no lote 3 o SC1010 apareceu tarde e custou um commit.

## Arquitetura da mudança

Duas famílias, nenhuma tocando o runner:

1. **Dois sensores de markdown.** A regra 2 do `check-checkpoint.sh` passa de uma pergunta sobre a
   **célula** ("tem `2>&1` e `grep`? então todo `grep` ancora") para uma pergunta sobre a
   **leitura** ("este `grep` lê a variável onde a saída misturada caiu? então ancora em `^  ok    `
   ou numa marca de passou `^ *✓ `"). Toda forma que o leitor não reconhece cai na regra de hoje,
   que é fechada. O teto de largura do `check-todo.sh` ganha uma isenção estreita: a linha que é
   só a âncora.
2. **O texto do `/sdd-plan`.** Uma regra nova ao relay (devolução superada não se mostra) e uma
   flag na receita do worktree (`--no-track`), cada uma com o seu par `pass`/`fail` no
   `check-hat.sh`, porque o catálogo de mutação não muta `commands/*.md`.

A prosa congelada que descreve as duas regras (`templates/checkpoint.md`, `agents/sdd-planner.md`,
`templates/todo*.md`, `agents/sdd-executor.md`) **não** se edita: fica mais estrita que o sensor,
e a dívida vira um item no `TODO.md` no fecho (decisão 7).

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — a regra 2 lê a variável, não a célula (#258)

**O quê:** reescrever a regra 2 do `scan_file` (`tests/check-checkpoint.sh:307-319`) por
**leitura**:

1. A pré-condição fica a mesma: a célula contém `2>&1` **e** `grep`. Sem as duas, a regra não se
   aplica.
2. **Capturas.** Toda atribuição `NOME=$(…)` da célula, com os parênteses casados **fora de aspas**
   (`'…'` e `"…"`). Uma captura é **limpa** quando o texto dela contém `2>&1` e nenhum `grep`. Os
   nomes das capturas limpas são as variáveis **contaminadas**.
3. **Volta à regra de hoje (todo `grep` da célula ancorado)** quando:
   - a célula, sem as capturas limpas, ainda contém `2>&1` (a saída misturada caiu num arquivo,
     num `<(…)` ou numa captura que também tem `grep`);
   - uma variável contaminada aparece em qualquer lugar que não seja o herestring de um `grep`
     (`<<< "$NOME"`, `<<<"$NOME"`, `<<< $NOME`, `<<< "${NOME}"`), por exemplo
     `echo "$o" > f; grep -c x f`;
   - o leitor não fecha uma captura ou uma aspa.
4. **Fora dessas três situações**, `g` é o número de `grep` cujo herestring lê uma variável
   contaminada, e `a` é o número desses que estão ancorados (padrão literal começando por
   `'^  ok    ` ou `"^  ok    `, por `grep`, não pela célula). Recusa quando `a < g`. Um `grep`
   que lê outra coisa fica fora da regra. `N_RULED` conta a célula com `g > 0`.
5. **Separe os `grep` por `;`, `&&`, `||` e quebra de linha fora de aspas.** Um `;` dentro de
   `'…'` não parte nada: foi o que errou o protótipo do planner.
6. **Implementação:** uma função que **publica globais** (por exemplo `R2_G`, `R2_A`,
   `R2_STRICT`) e é **chamada**, nunca lida por `x="$(f)"`, porque a atribuição a global morre no
   subshell (`CLAUDE.md`). Só expansão de parâmetro e laço em bash, sem `awk`, e as aspas e os
   parênteses são ASCII.
7. **A mensagem de FAIL mantém o trecho `pattern(s) anchored`.** O comando de medição do I6 conta
   esse trecho.
8. **Atualize o cabeçalho** (regra 2 em `:37-40`) e declare os limites:
   - a variável contaminada reatribuída depois na mesma célula continua contaminada (falha fechada);
   - o herestring de uma concatenação (`<<< "$o$p"`) cai na regra de hoje.

**Como (TDD):** antes de mexer no `scan_file`, crie um grupo novo de probes logo depois de `:778`,
com `local r2_p0="$PROBES" r2_f0="$FAILS"`, e fixtures `cp_head`/`cp_row`. Os fixtures abaixo estão
em notação de shell; na célula real, `$` e as aspas duplas são escapados como em `:734-767`.

| # | célula do fixture | quer |
|---|---|---|
| P1 | `o=$(bash t.sh 2>&1); a=$(grep -c '^  ok    x' <<< "$o"); b=$(grep -c foo f)` (o #258) | rc 0 |
| P2 | `o=$(bash t.sh 2>&1); grep -c 'beta' <<< "$o"; grep -c foo f` | rc 1, `0 of 1 pattern(s)` |
| P3 | `bash t.sh > out.log 2>&1; grep -c 'alpha' out.log` (`2>&1` fora de captura) | rc 1 |
| P4 | `o=$(bash t.sh 2>&1); echo "$o" > f; grep -c x f` (vazou para arquivo) | rc 1 |
| P5 | `n=$(grep -c x <<< "$(bash t.sh 2>&1)")` (captura com `grep`) | rc 1 |
| P6 | `o=$(bash t.sh 2>&1); grep -c '^  ok    a (b); c' <<< "$o"; grep -c 'x;y' f` (`;` e parêntese entre aspas) | rc 0 |
| P7 | `o=$(bash t.sh 2>&1); p=$(cat f); grep -c '^  ok    a' <<< "$o"; grep -c x <<< "$p"` (variável limpa) | rc 0 |
| P8 | `o=$(bash t.sh 2>&1; grep -c x <<< "$o"` (captura que não fecha) | rc 1 |

Todos têm de ficar vermelhos contra o `scan_file` de hoje onde querem rc 0 (P1, P6, P7) e verdes
onde querem rc 1. No fim do grupo:

```bash
[ "$FAILS" -eq "$r2_f0" ] && pass "rule: the anchor rule reads the variable the merged output went into, not the whole cell ($((PROBES - r2_p0)) probe(s))"
```

Suba o `PROBE_FLOOR` para a contagem nova **exata**. Os probes de `:770-778` (`blind`, `nocaret`,
`thin`, `onlyone`…) têm de continuar com o rc de hoje. Probe antigo que mudar de veredito é decisão:
anote no `checkpoint-notas.md` com o porquê.

**Passada de sabotagem** (resultado no `checkpoint-notas.md`). Cada degradação abaixo tem de deixar
o selftest vermelho:
- "nenhuma captura contamina";
- "pular a volta por `2>&1` fora de captura";
- "pular a volta por variável vazada";
- "ignorar aspas";
- "contar `a` pela célula";
- apagar a linha `pass`;
- baixar o piso.

Prove primeiro que cada sabotagem mudou o trecho que dizia mudar (`CLAUDE.md`: "o probe de
sabotagem prova primeiro que sabotou o que dizia sabotar").

**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: the anchor rule reads the variable the merged output went into, not the whole cell' <<< "$o" `` → `1`
(vermelho no HEAD: imprime `0`).
**Sensor durável:** o grupo de probes P1–P8 no `selftest()`, que roda no `tests/run-all.sh`.
**Reancorar:** #258 (`tests/check-checkpoint.sh:310` (`count_occ`)) e #249 (`:313` (`ANCHOR_SQ`)),
se `--anchors` os acusar fora do alvo.
**Reversível por:** `git revert` do commit do I1.

### I2 — a marca de "passou" do runner ancora (#249)

**O quê:** o predicado "ancorado" do I1 aceita também um padrão literal que começa por `'^` ou
`"^`, seguido de zero ou mais espaços e de `✓ ` (U+2713 e espaço). Só U+2713: é a marca medida
no vitest e no Playwright. `✔` (U+2714), `×`, `✘` e o `✓` fora do começo do padrão não ancoram.
Compare por expansão de parâmetro (tire `'^`, tire os espaços, teste o prefixo `✓ `), que funciona
igual sob `LC_ALL=C` e `C.UTF-8`, porque o literal é a mesma sequência de bytes.

A mensagem de FAIL passa a nomear as duas âncoras e mantém o trecho `pattern(s) anchored`. Por
exemplo: `… with $a of $g pattern(s) anchored on the ok prefix or on a pass mark ('^ *✓ ') — …`.

O `calibrate` e o `doc_rule` **não mudam**: o `OK_ANCHOR` continua sendo o prefixo dos sensores do
kit, e a prosa congelada continua dizendo só ele (decisão 7). No cabeçalho, escreva por que U+2713
(as marcas medidas, com as fontes do contexto verificado) e os limites declarados:
- um runner que imprimisse `✓` no texto de falha enganaria a regra (nenhum medido);
- as linhas de resumo (`Tests  N passed`) **não** contam, por decisão 5.

**Como (TDD):** um grupo de probes `local r3_p0 r3_f0`, cada fixture com `2>&1` e herestring:

| # | `grep` do fixture | quer |
|---|---|---|
| Q1 | `'^ ✓ src/a.test.ts > caso'` (vitest, um espaço) | rc 0 |
| Q2 | `'^  ✓ '` (Playwright, dois espaços) | rc 0 |
| Q3 | `'^✓ caso'` (zero espaço) | rc 0 |
| Q4 | `' ✓ caso'` (sem `^`) | rc 1 |
| Q5 | `'^ x ✓ caso'` (marca fora do começo) | rc 1 |
| Q6 | `'^ × caso'` e `'^  ✘ caso'` (marcas de falha) | rc 1 |
| Q7 | `'^ ✔ caso'` (U+2714) | rc 1 |
| Q8 | `'caso'` (o cego da M2) | rc 1 |
| Q9 | a forma da LH-4: `` `grep -c '^issue: LH-4$' docs/x/10-ticket.md` `` + `` `o=$(npm run test 2>&1); grep -c '^ ✓ src/test/a.test.tsx > ' <<< "$o"` `` | rc 0 |

O Q9 só passa com o I1 e o I2 juntos.

```bash
[ "$FAILS" -eq "$r3_f0" ] && pass "rule: a pass mark of a test runner at the start of a line anchors like the ok prefix ($((PROBES - r3_p0)) probe(s))"
```

Piso exato de novo. Sabotagem: aceitar `✓` em qualquer lugar do padrão, aceitar sem `^`, aceitar
U+2714, apagar a linha `pass`. Cada uma deixa o selftest vermelho. Rode também
`LC_ALL=C bash tests/check-checkpoint.sh --selftest; echo $?` e
`LC_ALL=C.UTF-8 bash tests/check-checkpoint.sh --selftest; echo $?`, os dois com rc `0`, e anote.
Meça a LH-4 (`bash tests/check-checkpoint.sh --check /home/joruge/repos/lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md 2>&1 | grep -c 'pattern(s) anchored'`,
**no máximo 1**) e anote. Não é Check porque lê fora do repo (limite declarado do `--red`).
**Check:** `` o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: a pass mark of a test runner at the start of a line anchors like the ok prefix' <<< "$o" `` → `1`
(vermelho no HEAD: `0`).
**Sensor durável:** os probes Q1–Q9 no `selftest()`.
**Reancorar:** #249 (`tests/check-checkpoint.sh:313` (`ANCHOR_SQ`)), se `--anchors` acusar.
**Reversível por:** `git revert` do commit do I2 (o I1 fica de pé sozinho).

### I3 — a linha que só carrega a âncora sai do teto de largura (#257)

**O quê:** no bloco de `tests/check-todo.sh:572-576`, antes do `print`, pule a linha cujo `$0`,
tirado o recuo (`sub(/^[ \t]+/, "")` numa cópia), é **um único span com forma de caminho**: casa
`` /^`[^` ]*[.\/][^` ]*`[ \t]*$/ `` (só ASCII, seguro no mawk). Quando a linha estourada **não** é
isenta mas carrega um span com forma de caminho (`` /`[^` ]*[.\/][^` ]*`/ ``), acrescente ao fim da
mensagem de hoje a saída, sem mudar o começo que os probes leem: por exemplo
`` — a line holding only the anchor `path:N` is exempt: write it alone and (`symbol`) on the next line ``.

**Como (TDD):** um grupo `rule_begin` … `rule_end <n> 'a line holding only the anchor is exempt from the width cap'`
logo depois de `:1809`, com um fixture **de verdade**: um arquivo de caminho longo (117 caracteres
mais `:420`) que carrega o símbolo, para o `--check` medir a âncora também. Use o mesmo `$box` e o
`with_decided` dos vizinhos.

| # | linha | quer |
|---|---|---|
| W1 | `` `<caminho de 117>:420` `` sozinha (125 caracteres), símbolo na linha seguinte | `--check` rc 0 |
| W2 | a mesma linha com `` (`sym`) `` no fim | `125+ characters` (recusada) |
| W3 | um span sozinho **com espaço** dentro, acima de 120 | recusada |
| W4 | um span sozinho **sem** `/` nem `.`, acima de 120 | recusada |
| W5 | uma linha de prosa acima de 120 com um span-caminho | recusada **e** com a saída na mensagem |
| W6 | uma linha de prosa acima de 120 sem span-caminho | recusada **sem** a saída (asserção de ausência, com o texto da saída como testemunha) |

Suba `RULES_FLOOR` de 11 para 12 e o piso total `168` para a contagem nova. Atualize o cabeçalho
da regra 5 (`:24-27`) com a isenção e com o limite: a linha isenta não tem teto, mas só carrega um
caminho. A prosa congelada que diz "nenhuma linha passa de 120" fica para o item da decisão 7.
Sabotagem: isentar qualquer span sozinho, isentar a linha com prosa depois do span, apagar a
saída da mensagem, apagar o `rule_end`. Cada uma deixa o selftest vermelho.
**Check:** `` o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a line holding only the anchor is exempt from the width cap' <<< "$o" `` → `1`
(vermelho no HEAD: `0`).
**Sensor durável:** os probes W1–W6 no `selftest()` do `check-todo.sh`.
**Reancorar:** #257 (`tests/check-todo.sh:211` (`WIDTH_CAP`)), se `--anchors` acusar.
**Reversível por:** `git revert` do commit do I3.

### I4 — o relay descarta a devolução que um recado superou (#264)

**O quê:** em `commands/sdd-plan.md`, seção `## Relaying the grill to the human`, um bullet novo
logo depois de `- **Nothing else resumes the planner while a question is pending.**`. O conteúdo,
em inglês:
- leia o que a `SendMessage` devolve;
- se o planner ainda estava rodando, o recado entra na fila e chega à volta em curso, e a próxima
  devolução já o responde;
- se o envio **retomou** um planner que já tinha devolvido, aquela devolução foi superada: nunca a
  mostre ao humano, espere a nova e repasse só ela;
- a medida: no grill da 0.4.0 do `lighthouse_project` (2026-10-14), um recado mandado com o planner
  rodando voltou `Resuming agent`, e a pergunta 2 voltou revista com a recomendação invertida.

As duas frases fixas que o probe lê (escreva-as literalmente):
`resumed a planner that had already handed back` e `never show the superseded hand-back`.

**Como (TDD):** primeiro o par em `command_relay_probes` (`tests/check-hat.sh:438`), lendo
`"$relay"`. Vermelho antes de escrever a prosa:

```bash
if grep -qF 'resumed a planner that had already handed back' <<< "$relay" \
   && grep -qF 'never show the superseded hand-back' <<< "$relay"; then
  pass "command: /sdd-plan waits for the new hand-back when a relay message resumed a planner that had already answered"
else
  fail "command: /sdd-plan lets the relay show a hand-back that a resumed planner superseded"
fi
```

Sabotagem: apagar cada frase, e mover o bullet para fora da seção. Cada uma deixa o par vermelho.
Rode `bash tests/check-lang.sh` (prosa inglesa).
**Check:** `` o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan waits for the new hand-back when a relay message resumed a planner that had already answered' <<< "$o" `` → `1`
(vermelho no HEAD: `0`).
**Sensor durável:** o par em `command_relay_probes`, que roda no `tests/run-all.sh`. O catálogo
não muta `commands/*.md`, então o par é o sensor inteiro (`check-hat.sh:378-380`).
**Reancorar:** #264 (`commands/sdd-plan.md:97` (`SendMessage`)), se `--anchors` acusar.
**Reversível por:** `git revert` do commit do I4.

### I5 — a branch da missão nasce sem upstream

**O quê:** `commands/sdd-plan.md:35` passa a dizer
`` `git worktree add ../<repo>-<slug> --no-track -b <branch> origin/<DEFAULT_BRANCH>` ``, com uma
frase do porquê: sem a flag, a branch rastreia `origin/<DEFAULT_BRANCH>`, então um `git pull` ali
traz a base calado e o `git status` conta ahead/behind contra ela. Medido no worktree deste lote em
2026-10-15. Reflua a linha se precisar, mantendo `git worktree add ../<repo>-<slug>` contíguo (o
literal de `check-hat.sh:550`). O motivo do `sdd kaizen` (`bin/sdd:11241`) e as duas citações dele
em `docs/` **não** se tocam: são o gêmeo congelado (commit `42b1a35`).

**Como (TDD):** primeiro um par novo em `command_worktree_probes` (`tests/check-hat.sh:544`),
separado do grande `if`, para o vermelho nomear esta frase:

```bash
if grep -qF 'git worktree add ../<repo>-<slug> --no-track -b <branch> origin/<DEFAULT_BRANCH>' <<< "$sec"; then
  pass "command: /sdd-plan cuts the mission branch with --no-track, so it never tracks the base"
else
  fail "command: /sdd-plan cuts the mission branch without --no-track, and it tracks the base"
fi
```

Sabotagem: tirar a flag e trocar a ordem. Cada uma deixa o par vermelho, e o par antigo de `:550`
continua verde.
**Check:** `` o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan cuts the mission branch with --no-track, so it never tracks the base' <<< "$o" `` → `1`
(vermelho no HEAD: `0`).
**Sensor durável:** o par em `command_worktree_probes`.
**Reancorar:** o item do relay (`commands/sdd-plan.md:35` (`git worktree add`)) e o #264, se
`--anchors` acusar.
**Reversível por:** `git revert` do commit do I5.

### I6 — fecho

**O quê**, nesta ordem, em um ou poucos commits:

1. **`RESOLVED by <hash>`** nos 5 itens (o hash curto, 7+ dígitos hex, **sem crase**: o Check conta
   `RESOLVED by` seguido de 7 hex), cada um com o hash do commit de código do seu incremento
   (#258 → I1, #249 → I2, #257 → I3, #264 → I4, relay `--no-track` → I5), no lugar que o template
   manda (contexto verificado). Os itens **ficam** até o merge: quem os apaga é o chore pós-merge
   do humano. O #256 cita `RESOLVED by` duas vezes em prosa, sem hash, e por isso o Check exige o hash.
2. **O item da decisão 7**, em `### Contrato e configuração`. Rascunho, a conferir com
   `bash tests/check-todo.sh --check TODO.md`:

   ```md
   - [ ] **A prosa congelada diz a regra 2 e o teto de largura mais estritos que os sensores** —
     `templates/checkpoint.md:27` (`check-x.sh`) — desde o lote 8 a regra 2 lê a variável e aceita `'^ *✓ '`, e o
     teto isenta a linha que só carrega a âncora; o template e o `agents/sdd-planner.md:111` ainda dizem só
     `^  ok    `, e o `templates/todo.pt-BR.md:24` e o `agents/sdd-executor.md:127`, "nenhuma linha passa de
     120". Não falha aberta, mas a saída só aparece na mensagem de FAIL. Direção: as quatro frases dizem a regra nova.
     — descoberto pelo `sdd-planner` na missão `20261015-lote-8-a-leva-que-nao-parte-a-janela` (2026-10-15)
   ```

   O símbolo `check-x.sh` está em `templates/checkpoint.md:32`, a 5 linhas da `:27`. A catraca
   sobe de 15 para 16 **no mesmo commit**.
3. **A entrada do `KAIZEN_LOG.md`**, no topo, intitulada
   `## 2026-10-15 — Lote 8: a leva que não parte a janela`:
   - a linha `**Missão:** `20261015-lote-8-a-leva-que-nao-parte-a-janela`` (o id inteiro, que o
     `gate_DOCS` lê);
   - **Antes**: 122 células recusadas nos 36 checkpoints dos alvos, 10 na LH-4, a linha de 125
     caracteres recusada;
   - **Depois**: os mesmos números **remedidos** com o comando do contexto verificado, no sensor
     novo, e as 4 linhas `ok` novas.
   - Feche com `---` antes da entrada do lote 7.
4. **A gaveta:** um parágrafo `**Hoje (2026-10-15).**` no fim da `## F3`. O lote 8 levou só os
   5 itens que não partem a janela, os 9 congelados e os 2 nascidos congelados esperam a triagem
   depois do veredito, e a janela do lote 7 tinha 1 de 3 missões.
5. **`20-handoff-exec.md`**, do `templates/handoff.md`, com `fase: EXEC`, `status: done`, `data:`
   saída de `date` no mesmo lote de comandos, e `gate:` a última linha do `tests/run-all.sh`. O
   `## TL;DR` tem até 5 linhas (teto duro de 20) e o `## Boot da próxima fase` diz o que o PR
   precisa (pendências 1 a 3 do `00-missao.md`).
6. **A suíte inteira:** `tests/run-all.sh`, verde. Ela passa dos 2 min do Bash tool: rode em
   background e espere a última linha.

**Check:** `` a=$(grep -c '^## 2026-10-15 — Lote 8: a leva que não parte a janela' KAIZEN_LOG.md); b=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/{n++} END{print n+0}' TODO.md); c=$(grep -c '^todo-findings 16$' tests/health-baseline.txt); d=$(test -f docs/handoffs/20261015-lote-8-a-leva-que-nao-parte-a-janela/20-handoff-exec.md; echo $?); echo "$a $b $c $d" `` → `1 5 1 0`
(vermelho no HEAD: `0 0 0 1`).
**Sensor durável:** o `gate_DOCS` (entrada do `KAIZEN_LOG` citando o id), o `check-todo.sh` (forma
e âncora do item novo) e o `sdd health` (catraca `todo-findings 16`). O fecho não cria sensor novo.
**Reversível por:** `git revert` dos commits do fecho.

## Medição do vermelho

`tests/check-checkpoint.sh --check` e `--red` sobre o `checkpoint.md` desta missão, rodados pelo
planner no HEAD `42b1a35`, com as linhas copiadas no `checkpoint-notas.md` (nota de 2026-10-15 do
`PLAN`). Cada Check é presença: a linha `ok` nova (I1–I5) ou o artefato do fecho (I6). Nenhum é
ausência.

## Teste de autocontenção

Feito pelo planner, lendo só os três arquivos, sobre o I1:
- o arquivo e as linhas a reescrever (`:307-319`);
- a regra nova em 8 passos, com as três situações de volta à regra de hoje;
- onde ficam os probes (depois de `:778`), os 8 fixtures com o rc que cada um quer, e o texto
  exato da linha `pass`;
- o piso a subir (`PROBE_FLOOR`, apertado);
- a sabotagem a fazer, a armadilha do subshell, a do `;` entre aspas e a da âncora do `TODO.md`;
- o Check.

Nada depende da conversa do grill. O que o grill decidiu está nas decisões 1–9 do `00-missao.md`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O leitor de capturas do I1 falha aberto numa forma de shell que ninguém previu | média | toda forma que ele não reconhece cai na regra de hoje (passo 3); P3–P5 e P8 provam a volta; a passada de sabotagem roda **contra o selftest**, que é o sensor que a mitigação nomeia |
| O `✓` muda de bytes sob `LC_ALL=C` | baixa | o literal é a mesma sequência de bytes nos dois locales; o I2 roda o selftest sob `LC_ALL=C` e `C.UTF-8` e anota os dois rc |
| Um probe antigo da regra 2 muda de veredito com a regra mais frouxa | baixa | é decisão, anotada com o porquê; a regra nova só é mais frouxa onde o grep não lê a saída misturada ou lê a marca de passou |
| Uma âncora do `TODO.md` sai do alvo e o `check-todo.sh` reprova a suíte | média | `bash tests/check-todo.sh --anchors TODO.md` em todo incremento, e reancorar no mesmo commit (tabela do contexto) |
| O carimbo fica inválido (`tests/` na chave) | certa | pendência 1 do `00-missao.md`: um `./bin/sdd health` só, depois da leva dos bots |
| Um diff que precise de `bin/`, `agents/`, `templates/` ou `config/` | baixa | parar e anotar: parte a janela e está fora de escopo (decisão 1) |
| O merge chega à `main` local com um alvo rodando | média | decisão 2: o pull só com o `ps` vazio |

## Verificação end-to-end

Com os 6 incrementos `done`:

1. `tests/run-all.sh` → verde.
2. `bash tests/check-checkpoint.sh --check /home/joruge/repos/lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md 2>&1 | grep -c 'pattern(s) anchored'`
   → no máximo `1` (M1). Antes: `10`.
3. O laço sobre os 36 checkpoints dos alvos (contexto verificado) → o número de depois, que vai
   para o `KAIZEN_LOG.md` (M3). Antes: `122`.
4. `bash tests/check-checkpoint.sh --check docs/handoffs/20261015-lote-8-a-leva-que-nao-parte-a-janela/checkpoint.md; echo $?`
   → `0`.
5. `bash tests/check-todo.sh --check TODO.md` → `ok    16 finding(s) …`.
6. `./bin/sdd adr check --mission 20261015-lote-8-a-leva-que-nao-parte-a-janela --phase plan; echo $?`
   → `0`.
7. `git status --short` → vazio. `git diff --stat fec0cca.. -- bin agents templates config` → vazio
   (a janela não partiu).
