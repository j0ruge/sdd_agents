---
missao: 20260925-o-sensor-le-o-que-a-ancora-diz
data: 2026-09-25
---

# Plano — o sensor lê o que a âncora diz

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em `5cb0101` (HEAD de `feat/todo-esqueleto-neutro`, 2026-09-25). Os números
de linha **andam** conforme os incrementos editam os arquivos, então confie no **nome da função** e
use a linha só como ponto de partida.

**Como executar**

- Execução **interativa**, uma sessão por incremento, nunca `sdd run` (ver `00-missao.md`).
- A suíte é `tests/run-all.sh`, o `TEST_CMD` do repo, com 16 sensores. Rode-a antes de cada commit.
- Rode a suíte **em primeiro plano**, nunca como tarefa de fundo do Bash tool. O hook limpa as
  sandboxes a cada commit, e o watchdog de memória já matou suíte de fundo.
- O `sdd health` leva ~1h21 e roda **uma vez**, no fim, depois dos revisores do PR. Nunca rode por
  incremento.
- `bash -n bin/sdd` é o smoke mínimo. O passo de lint do `run-all.sh` cobre `bin/sdd` e
  `tests/*.sh` com shellcheck.
- Os sensores imprimem `  ok    <asserção>` (2 espaços, `ok`, 4 espaços) na stdout e
  `  FAIL  <asserção>` na stderr. A única exceção hoje é o `check-templates.sh` (I6).

**`tests/check-todo.sh`** (1666 linhas, inalterado desde `3286c2f`)

- Regra 5, o teto:
  - cabeçalho em `:24` (`#   5. at most CAP content lines…`);
  - `:36` ainda diz "the ~6-line cap", e é para corrigir de passagem no I1;
  - `CAP="${SDD_TODO_CAP:-8}"` em `:160`, validado por `valid_cap` (`:177`);
  - a contagem é `nlines = 1` no início do item (`:455-456`) e `nlines++` por linha de continuação
    indentada (`:466`); a checagem é `if (nlines > cap)` em `:304-305`, dentro do `flush()`.
  - O comprimento da linha nunca é lido. Medido: um item de 1794 caracteres numa linha física dá
    `ok 1 finding(s), all within 8 lines`, rc 0.
- ⚠️ **O `awk` é o `mawk` 1.3.4, e `length()` conta BYTES.** O gawk não está instalado. Na seção
  aberta do `TODO.md`, o `mawk` acha 166 linhas acima de 100 "caracteres", e o python3 `len()`
  acha 20. Nenhuma passa de 120 caracteres; a maior tem 115 caracteres (118 bytes), no
  `TODO.md:450`. Para contar caracteres em `mawk` sem locale, descarte os bytes de continuação do
  UTF-8 (`0x80`–`0xBF`) antes do `length()`, por exemplo com `gsub(/[\200-\277]/, "", s)` sobre uma
  cópia. Prove com um probe de linha acentuada: 120 caracteres com acentos, mais de 120 bytes, tem
  de **passar**. Classe negada com multibyte não funciona no `mawk` (`CLAUDE.md`, seção do `mawk`).
- Localização da seção aberta:
  - `OPEN_MARKER_ERE='^<!-- sdd:open -->[[:space:]]*$'` em `:169`, usada por `has_open_marker`
    (`:215`);
  - no awk, a regra H2 `/^## /` em `:361`, "o marcador fica logo abaixo do H2"
    (`h2 && NR == h2 + 1`) em `:362`, e a comparação `t == omark` em `:363-364`;
  - a regra do marcador perdido em `:381-382`.
- Selftest:
  - `selftest()` em `:633`, com a guarda de veneno em `:637-643` (rc 97);
  - asserções `assert_clean` `:506` (rc 90), `assert_says` `:517` (91) e `assert_rc` `:557` (92);
  - `rule_begin`/`rule_end <floor> <texto>` em `:541-542`, que imprimem
    `  ok    rule: <texto> (<n> probe(s))`;
  - `RULES_FLOOR=6` em `:540`, e o piso de 117 probes em `:1521`. **Suba os dois** quando
    acrescentar regra ou probe; o selftest reprova se o reportado for menor que o piso;
  - a linha final do selftest fica em `:1538`.
- CLI (`case` em `:1648-1666`):
  - `--selftest`;
  - `--check <arquivo> [--allow-empty]` → `check_file` (`:1544`), que pula o selftest (rc 98 se o
    caminho nu chegar sem ele, `:1554-1557`);
  - `--count <arquivo>` → `count_file` (`:1621`);
  - sem argumento, roda o selftest e depois `check_file "$TODO"`;
  - rc 96 para opção desconhecida.
- Tabela de rc em `:146-153`: 89 sem tmp, 90–92 probe, 93 arquivo ilegível, 94 abaixo do piso, 95
  CAP inválido, 97 envenenado, 99 sem marcador.
- A linha final do lint é `printf '  ok    %d finding(s), all within %d lines and carrying anchor +
  date\n'` (`:1612`). É **contrato** com dois leitores:
  - o `bin/sdd` (`cmd_health`, bloco 3, `todo_line=… grep -m1 -E '^  ok    [0-9]+ finding\(s\)'`),
    que lê só o prefixo;
  - o **stub** do `tests/check-health.sh:208`, que copia o texto inteiro. Mudou o texto, mude o stub
    no mesmo commit.
- O `ROOT` é o diretório pai do script (`:158`), e `TODO="${SDD_TODO_FILE:-$ROOT/TODO.md}"` (`:159`).
  O `--check <arquivo>` usa o caminho como veio, relativo ao cwd. Hoje nenhuma âncora é resolvida
  contra nada.
- Regra da âncora de hoje: `flush()` `:271-272`,
  `if (head_of(body) !~ /`[^`]+`/) print "  line " start ": no non-empty `file:line` anchor…"`.
  `head_of` (`:263`) é o texto antes do último ` — ` fora de crase, e `last_sep` (`:250-258`) conta
  crases. O cabeçalho `:29-31` e `:96-97` diz "Not measured, on purpose: whether an anchor still
  points at real code". **É essa frase que o I7/I10 reescreve.**
- **O catálogo de mutação não alcança este sensor**: `grep -c check-todo tests/check-mutation.sh`
  dá 1, e é comentário. Quem mede o sensor é o selftest, mais uma passada de sabotagem adversarial
  manual. Registre cada sabotagem e o rc dela numa nota do `checkpoint-notas.md`. O
  `tests/run-all.sh:214` pula o `check-todo.sh` sob `SDD_MUTANT`.
- Saída real hoje: 8 linhas `^  ok    `, incluindo
  `ok    selftest: 117 probe(s), the sensor measures what it claims` e
  `ok    100 finding(s), all within 8 lines and carrying anchor + date`.

**#70 re-medido** (sabotagem numa cópia do script mais o `TODO.md`, em scratch)

| Afirmação | Onde está hoje | Mutação | Resultado |
|---|---|---|---|
| (a) contagem constante | `:1599` `printf '\n%d shape violation(s)\n' "$(grep -c . <<< "$violations")"`; o único probe é `:843-855` (`countable.md`, exatamente 3) | `$(grep -c …)` → `3` | rc 0, **sobrevive** |
| (c) `flush()` da caixa marcada | `:323-327`, com `flush(); next` em `:326` | `flush(); next` → `next` | rc 0, **sobrevive** |
| (d) `--check ''` | probe `:944-945` (`assert_rc 93`), despacho `:1662` `check_file "${2-$TODO}"` | `${2-$TODO}` → `${2:-$TODO}` | pego (rc 92) **se** `$ROOT/TODO.md` existe; sem ele, sobrevive |
| b1 | `OPEN_MARKER_ERE` `:169` | apagar o `^` | rc 0, **sobrevive** |
| b2 | idem | apagar `[[:space:]]*$` | rc 0, **sobrevive** |
| b4 / b5 | `:363-364` | `index(t, omark)` / tirar `[ \t>]` do início | sobrevivem, mas **continuam vermelhos**: só a mensagem muda. Por decisão do grill, viram limite declarado |

- Na (a), o fixture de 2 violações responde "2" normal e "3" com o mutante.
- Na (c), o fixture é `- [ ] sem título…` / `- [x] **fechado**` / `  e uma cauda — found by \`x\`
  (2026-08-16)`: 5 violações normal, 3 com o mutante.
- No b1, um marcador indentado ou citado (`> <!-- sdd:open -->`) dá `--count` → `0` com rc 0,
  quando o certo é rc 99.
- No b2, um marcador com texto depois muda o `--check` de 99 para 1.

**Âncoras do `TODO.md`** (auditoria completa em `5cb0101`)

- O `TODO.md` tem 823 linhas: marcador aberto em `:22`, `## Decidido` em `:822`, 100 itens
  (`bash tests/check-todo.sh --count TODO.md` → `100`, igual a `todo-findings 100` em
  `tests/health-baseline.txt`).
- Formas de âncora:
  - 85 são `arquivo:N` com N > 1 (inclui faixas e listas);
  - 6 são `arquivo:1` (itens em `:138`, `:229`, `:599`, `:617`, `:665`, `:776`);
  - 6 são só caminho (`:299`, `:470`, `:508`, `:650`, `:683`, `:760`);
  - 1 é caminho + `(símbolo)` (`:784`, `bin/sdd` (`BUDGET_MISSION_USD`));
  - 2 são outras: `:515`, cuja primeira crase é a palavra `frontmatter`, e `:524`, o glob
    `templates/*.md`.
- As 85 apontam arquivos existentes e linhas dentro do arquivo. Pelo veredito manual: **63 erradas**,
  11 certas, 6 perto (até ~10 linhas), 5 incertas.
- Os corretos prováveis, medidos para cada uma, estão na tabela abaixo. É **ponto de partida**:
  confira cada um, porque os incrementos I3–I5 movem o `bin/sdd` antes da re-ancoragem.

| item (linha no TODO) | âncora de hoje | alvo provável |
|---|---|---|
| 34 | tests/check-mutation.sh:2647 | ~2637 (guarda `cmp -s` rc 90) |
| 42 | bin/sdd:614 | ~1088 (Âncora 1 no `gate_QA`) |
| 50 | bin/sdd:686 | ~1110 (Âncora 3) |
| 59 | tests/check-health.sh:930 | ~222 |
| 66 | tests/check-todo.sh:66 | 86–94 |
| 73 | tests/check-health.sh:291 | ~1578 (`health_kit_root`) |
| 82 | bin/sdd:668 | 1629/1635 (`mutation_stamp_key`) |
| 91 | tests/check-health.sh:826 | 1582 (`CAPTURE_FLOOR`, hoje **36**; o item diz 12) |
| 99 | tests/check-health.sh:754 | 1392 / 1448 |
| 107 | tests/check-todo.sh:1190 | 1141–1144 (item do #70, sai no I11) |
| 115 | tests/check-checkpoint.sh:227 | 235–236 |
| 123 | bin/sdd:946 | 2502–2532 (`ledger_repo_root`) |
| 130 | tests/check-autonomy.sh:1443 | 4225–4251 |
| 146 | bin/sdd:1591 | ~4394 |
| 153 | tests/check-todo.sh:278 | ~352 |
| 160 | tests/check-todo.sh:190 | 264 / 273 (`tail_of`) |
| 169 | bin/sdd:2453 | 7161–7169 (`moved2` do `cmd_kaizen`) |
| 176 | tests/check-mutation.sh:203 | 670, 1796 |
| 183 | bin/sdd:1950 | ~6485 (`cmd_approve`) |
| 191 | bin/sdd:188-218 | ~322 (`frontmatter_write`) |
| 199 | bin/sdd:1405 | ~4354 |
| 206 | bin/sdd:1356 | ~4655 |
| 213 | tests/check-gates.sh:281 | ~291 (`assert_jidoka`) |
| 237 | tests/check-autonomy.sh:127 | ~133 |
| 245 | bin/sdd:213 | 3703–3704 |
| 252 | bin/sdd:646 | `cmd_preflight` ~4368 |
| 259 | tests/run-all.sh:103,112,119 | 198, 207, 214, 221 |
| 276 | templates/missao.md:44 | 45 (linha do critério **d**) |
| 291 | tests/check-dry-run.sh:116 | 176–177 |
| 307 | bin/sdd:475-492 | 1708, 1716 |
| 315 | tests/check-autonomy.sh:208 | ~424 |
| 330 | bin/sdd:1080 | ~2364 (`pipeline_log_line`) |
| 346 | bin/sdd:568 | ~1439 |
| 353 | tests/check-lang.sh:51 | ~60 (`STOPWORDS`) |
| 360 | bin/sdd:461 | 1077–1084 / 1250 |
| 368 | bin/sdd:1982 | ~4983–5016 |
| 375 | tests/check-mutation.sh:1631 | ~2439 |
| 383 | bin/sdd:578 | ~1373 |
| 391 | bin/sdd:806 | 1629–1635 |
| 399 | tests/check-lang.sh:123 | 176–183 (o piso hoje é 41) |
| 415 | bin/sdd:5257 | ~8165 |
| 422 | tests/check-gates.sh:897 | ~1156 |
| 444 | bin/sdd:4395 | ~5333 |
| 454 | bin/sdd:870 | ~1471 |
| 462 | bin/sdd:2183 | 5084–5096 (item do #116, muda no I3) |
| 478 | bin/sdd:2039 | ~5092 (item do #118, muda no I4) |
| 486 | bin/sdd:688 | ~1635 |
| 494 | TODO.md:16 | **conteúdo velho**: o cabeçalho não tem mais `RESOLVIDO`. Re-verificar o item |
| 501 | bin/sdd:4354 | ~9060 |
| 532 | tests/check-pipefail.sh:231 | ~283 (`CD_RE`) |
| 540 | bin/sdd:2735 | 3590–3595 |
| 547 | bin/sdd:2393 | **conteúdo velho**: `review_scope_check` tem 0 ocorrências; candidato ~3020 |
| 554 | bin/sdd:2774 | ~3704 |
| 561, 586 | bin/sdd:2650 | ~3413 / 3469 |
| 571 | docs/pipeline.md:326-570 | 923–1245 |
| 578 | bin/sdd:2568 | `cmd_autonomy` ~7700 |
| 592 | bin/sdd:5250 | `cmd_adr` ~6300 |
| 639 | bin/sdd:2891 | 2945–2986 |
| 675 | agents/sdd-publisher.md:31-39 | 41–44 |
| 700 | bin/sdd:310 | 649–682 |
| 718 | bin/sdd:786 | 959 / 1008 |
| 727 | bin/sdd:1896 | ~2830–2842 |
| 736 | bin/sdd:328 | ~493 |
| 745, 753 | bin/sdd:1918 | ~2842 |
| 767 | agents/sdd-qa.md:118 | 97–123 |
| 792 | agents/sdd-reviewer.md:45 | ~178 |
| 799 | bin/sdd:6260 | 6472–6477 |
| 806 | tests/check-coordination.sh:524 | ~616 |
| 814 | bin/sdd:9309 | 9319–9326 |

- Sem alvo provável achado: 267 (`bin/sdd:989`), 321 (`bin/sdd:2738`) e 407 (`README.md:152`).
  Leia o item, ache o código e, se o item não se sustenta mais, trate-o como conteúdo velho.
- Itens com **conteúdo** velho (decisão 5 do grill):
  - `:91`, o piso 12 → 36;
  - `:229`, "o sensor confere que existe", o que é falso;
  - `:494`, o `RESOLVIDO`;
  - `:547`/`:548`, o `review_scope_check`.
- Medido também: a regra "existe + dentro do intervalo" reprovaria **0** de 85, e a regra "termo do
  item a ±10 linhas", sem símbolo declarado, reprovaria 52 de 85, inclusive âncoras certas (`:26`,
  `:284`, `:429`). Por isso a regra decidida exige um **símbolo citado**, ADR 0011.

**`TEST_CMD` no `bin/sdd`** (9680 linhas)

- `load_config()` em `:102` já faz `bash -n "$CONFIG_FILE" || die "… has a bash syntax error"`
  (`:106`) antes do `source` (`:108`). Por isso a linha `config syntax valid` do preflight (`:4526`)
  nunca falha: o `load_config` morre antes.
- **Os 7 sítios que sourceiam o config por uma chave** (decisão 6), todos engolindo erro de parse:

  | Linha | Comando | Chave | Como perde o erro |
  |---|---|---|---|
  | `:4108` | `cmd_install` | `HANDOFF_DIR` | `>/dev/null 2>&1` + `\|\| true` |
  | `:4110` | `cmd_install` | `TODO_FILE` | idem |
  | `:4112` | `cmd_install` | `QA_DOCS_PATH` | idem |
  | `:4114` | `cmd_install` | `OUTPUT_LANG` | idem |
  | `:4828` | `health --release` | `RELEASE_FORBIDDEN_WORDS` (config do kit) | `2>/dev/null` + `\|\| words=""` |
  | `:5087` | `health` 2b | `TEST_CMD` (config do kit) | `>/dev/null 2>&1` + `\|\| true` |
  | `:7772` | `autonomy` | `HANDOFF_DIR` de `$repo/.sdd/config.sh` | `>/dev/null 2>&1` + `\|\| true` |

- O health 2b está dentro de `cmd_health()` (`:4903`):
  - config do kit em `$kit/.sdd/config.sh` (`:5069`), com `$kit` vindo de `health_kit_root`
    (`:1592`);
  - `health_bad "the kit's .sdd/config.sh declares no TEST_CMD — …"` em `:5096`;
  - o comentário de `:5084-5085` admite a lacuna e aponta para o `TODO.md`. **Reescreva-o** quando
    fechar.
- Regras do `--list`:
  - health 2b em `:5091-5093`, `case " $kit_test_cmd " in *" --list "*)`, só para o config do kit.
    Ele imprime `ok "TEST_CMD runs the suite (…)"` em `:5098`;
  - `test_cmd_looks_noop()` em `:3942`, com `case " $tc " in *" --list "*|*" --listTests "*|*"
    --collect-only "*)`. É chamado por `cmd_preflight` (`:4529`) e vale para qualquer alvo;
  - o comentário em `:3935-3938` declara a duplicação **deliberada**, e a decisão 7 a reverte.
- `run_check_cmd()` em `:653` faz `( cd "$REPO_ROOT" && eval "$cmd" )` (`:671`). Por isso TAB e
  `"--list"` chegam à suíte como `--list`: medido, com uma suíte testemunha gravando o argv.
- `cmd_preflight()` em `:4368`:
  - roda o `TEST_CMD` em `:4546` (`run_check_cmd "$TEST_CMD" "preflight-test"`);
  - o `_fail "TEST_CMD FAILED (rc $test_rc): … gate_EXEC, gate_QA and gate_REVIEW run this same
    command, so a red suite makes the EXEC phase unsatisfiable …"` fica em `:4550-4552`.
  - Nada no preflight detecta falta de manifesto. Os únicos testes de manifesto são a cadeia
    `if/elif` do `cmd_install()` (`:4036`, cadeia em `:4060-4065`: `package.json`,
    `pyproject.toml`, `Cargo.toml`, `go.mod`) e o `node_gate_scripts` (`:3894`).
  - Medido greenfield: `npm test` sem `package.json` dá rc 254 com `npm error code ENOENT … Could
    not read package.json`.
- `5cb0101` não causa nem conserta o #53:
  - `NODE_GATE_SCRIPTS` (`:3891`), `node_test_cmd` (`:3902`), `node_scripts_outside_test_cmd`
    (`:3912`) e o `warn` em `:4556-4565` só agem com `package.json` presente;
  - a forma composta `npm run lint && … && npm test` sem manifesto falha igual (medido).

**Testes do `TEST_CMD`**

- `tests/check-health.sh`:
  - `build_fixture` (`:166`), `set_test_cmd` (`:235`) e `health_run` (~`:306`);
  - o probe do `--list` fica em `:1348-1388`;
  - ⚠️ a regra `guard:` (`CAPTURE_FLOOR=36`, `:1582`) **enumera toda captura `x="$(…)"` na região
    do `cmd_health`**. Toda captura nova precisa de guarda (`|| rc=$?`, `|| true` ou
    `if x="$(…)"; then`), e o censo muda o número. Leia o cabeçalho da regra antes de mexer. O
    próprio comentário em `:5080-5082` conta que um exemplo colado ali já foi contado como captura
    e deixou a catraca vermelha.
- `tests/check-preflight.sh`:
  - `FIX=$(mktemp -d …)` em `:36`, e os stubs `claude`/`gh` que saem 1 em `:82-85`;
  - o repo compartilhado nasce em `:98-101`, com `sdd install` em `:107`;
  - ⚠️ o **config do fixture compartilhado** (`:115-123`) põe `TEST_CMD="npm test"` **sem
    `package.json`**. Esse fixture É um repo greenfield, então o I5 muda o que o preflight imprime
    para ele. Rode o sensor inteiro e ajuste as asserções que dependiam do `fail` antigo, **sem
    afrouxar**;
  - helpers `assert_has` `:45`, `assert_lacks` `:51`, `assert_eq` `:60`, `noop_case` `:466`,
    `ok_case` `:482`, `run_case` `:516` (com testemunha de argv; `PROBE` do `mktemp` em `:507`),
    `node_target` `:969` e `nw_case` `:988`.
- `tests/check-mutation.sh` (catálogo, opt-in; `--anchors` roda na suíte rápida e reprova mutante
  cuja âncora não aplica mais):
  - `mut_PRE_testcmd_never_run` `:745`, `mut_PRE_testcmd_noop_blind` `:2014`,
    `mut_PRE_testcmd_noop_runs_anyway` `:2023`, `mut_HEALTH_testcmd_list_blind` `:2489`, e os quatro
    `mut_PRE_node_*` em `:2030-2047`;
  - `ANCHOR_FLOOR=392` em `:4548`;
  - ⚠️ reescrever o `case` do `--list` **quebra a âncora** de `mut_HEALTH_testcmd_list_blind` e de
    `mut_PRE_testcmd_noop_blind`. Atualize os mutantes no mesmo commit e rode
    `bash tests/check-mutation.sh --anchors`, que leva segundos;
  - **gate ou regra nova do `bin/sdd` entra com mutante** (`CLAUDE.md`), e mutante novo sobe o
    `ANCHOR_FLOOR`;
  - não existe mutante para o caminho de erro de parse.

**`check-templates.sh` e `calibrate()`** (#151)

- `tests/check-templates.sh` imprime `ok` com três espaços em quatro lugares: `check()` (`:64`,
  `printf '  ok   %s: %s\n'`), `refute()` (`:101`), e as duas checagens das variantes do todo
  (`:447`, `:455`). As linhas de selftest (`:185`, `:235`, `:245`, `:278`, `:288`) e o resumo
  `rule:` (`:544`) já usam quatro.
- Hoje saem 98 linhas de 3 espaços e 6 de 4. O selftest não parseia o prefixo `ok`: os probes de
  `check()`/`refute()` mandam a saída para `/dev/null` e contam `$fails`. O `REVIEW_FLOOR=26`
  (`:533`) conta chamadas.
- Nenhum Check de checkpoint lê o `ok` de 3 espaços do `check-templates.sh`, e o `run-all.sh` lê só
  o rc. Mudar a grafia não quebra nada que existe.
- `tests/check-checkpoint.sh`:
  - `calibrate()` (`:318`) só lê linhas que começam **exatamente** com `pass() { printf '` e
    contêm `%s`;
  - `CALIBRATE_FLOOR=4` (`:317`) e `OK_ANCHOR='^  ok    '` (`:111`);
  - hoje imprime `ok    the ok anchor is the prefix the suite's sensors actually print (8
    sensor(s))`. Os sensores `check-adr` e `check-mutation` escapam por grafarem o `pass()` de
    outro jeito, o que fica fora de escopo.

**Outros**

- `tests/check-lang.sh` varre `docs/adr/*.md`, `tests/*.sh`, `bin/sdd` e `README.md` como
  **superfície inglesa**. Prosa nova em `tests/`/`bin/` é inglês; `TODO.md`, `KAIZEN_LOG.md`,
  handoffs e `templates/todo.pt-BR.md` são pt-BR.
- O `templates/todo.md` (en) e o `templates/todo.pt-BR.md` são a fonte única do formato do item. O
  `check-templates.sh` (`:440-460`) exige o mesmo esqueleto nos dois (`todo_shape`) e roda
  `check-todo.sh --check <variante> --allow-empty` sobre cada um. A linha de formato do item aberto
  mostra `` `<arquivo:linha>` ``.
- Não há nenhum `RESOLVED by` no `TODO.md` hoje (`grep -c` → 0).
- Os itens que esta missão fecha, com a linha de hoje:
  - `:26`, regra 5 (1800 caracteres);
  - `:107`, #70;
  - `:229`, #86;
  - `:462`, #116;
  - `:478`, #118;
  - `:617`, #136;
  - `:760`, #151.

  O `:665` é fundido no `:523`. O #53 **não** tem item: é issue externa, fechada pelo `Closes #53`
  do PR.
- A ADR `docs/adr/0011-ancora-do-todo-carrega-simbolo.md` está escrita e é o contrato da regra da
  âncora. Leia-a antes do I7.

## Arquitetura da mudança

Três arquivos de sensor e uma função do runner concentram quase tudo:

- `tests/check-todo.sh` ganha:
  - duas regras de lint: a linha física de até 120 caracteres (I1) e a âncora com símbolo (I7,
    ligada no lint no I10);
  - probes do #70 (I2);
  - um modo novo `--anchors <arquivo>` (I7), que só **mede** as âncoras. É a ferramenta da
    re-ancoragem (I8, I9) e a testemunha que os Checks leem.
- `bin/sdd` ganha:
  - `config_read_key` (I3), a única definição de "ler uma chave do config", usada nos 7 sítios;
  - um predicado único para "este `TEST_CMD` pede para listar e não rodar" (I4), usado pelo health
    2b e pelo `test_cmd_looks_noop`;
  - um ramo estreito de `warn` no preflight para o runner sem manifesto (I5).
- `tests/check-templates.sh` passa a imprimir por um `pass()` de quatro espaços, que o `calibrate()`
  do `tests/check-checkpoint.sh` passa a contar (I6).

A **ordem** é deliberada. Os incrementos que editam o `bin/sdd` (I3–I5) vêm **antes** da
re-ancoragem (I8, I9), senão cada um deles empurraria as âncoras recém-consertadas. A regra da
âncora nasce em modo relatório (I7) e só entra no lint padrão (I10) com o `TODO.md` já limpo, então
a suíte nunca fica vermelha por causa dela. Depois do I10, todo commit que mover código sob uma
âncora deixa a suíte vermelha, e **é para isso que a regra existe**: incremento de conserto (R<n>)
re-ancora o que moveu no mesmo commit.

**Gramática da regra da âncora (ADR 0011; o I7 implementa exatamente isto):**

1. **Âncora** é a **primeira** crase da cabeça do item (`head_of`) cujo conteúdo tem forma de
   caminho: contém `/` ou `.`, não contém espaço nem `*`, e opcionalmente termina em `:N`, `:N-M`
   ou `:N,M,…`. Numa faixa ou lista, vale o primeiro número. Uma crase que não tem forma de caminho
   (`frontmatter`) é pulada, não é âncora.
2. **Base de resolução:** `git -C "<diretório do arquivo checado>" rev-parse --show-toplevel`, com
   fallback para o próprio diretório. **Nunca `$ROOT`.**
   - ⚠️ Se usar `cd` com operando relativo dentro de `$( )`, ponha `CDPATH=''` (regra `cdpath:` do
     `check-pipefail.sh`).
   - Prefira `git -C`, que dispensa o `cd`.
3. **Violação A:** a âncora não nomeia um arquivo regular sob a base. Mensagem:
   `line <L>: anchor \`<caminho>\` names no file of this repository`.
4. **Símbolo** é qualquer **outra** crase da cabeça do item, com 4 ou mais caracteres e diferente
   do caminho da âncora, que `grep -nF` acha no arquivo ancorado.
5. **Violação B:** nenhuma crase da cabeça é achada no arquivo. Mensagem:
   `line <L>: anchor \`<caminho>:<N>\` — no backticked symbol of the item occurs in <caminho>`.
6. **Violação C:** N > 1 e nenhuma ocorrência de nenhum símbolo está a 10 linhas ou menos de N
   (`|ocorrência − N| ≤ 10`). Mensagem:
   `line <L>: anchor \`<caminho>:<N>\` is off target — nearest \`<símbolo>\` is at line <M>`.
7. Âncora **sem N, ou com N = 1**, é de arquivo inteiro: basta o símbolo ocorrer em qualquer lugar
   do arquivo.
8. Vale **só na seção aberta**, só para a **primeira** âncora do item, e só para itens (não para
   registros decididos).
9. Toda violação começa com `line <L>: anchor \``, e o texto é o que o grep dos Checks lê. Mantenha
   a forma.
10. O `--anchors <arquivo> [<prefixo>]`:
    - mede só os itens cuja âncora começa com `<prefixo>`, quando ele é dado (o I8 usa `bin/sdd`);
      sem prefixo, mede todos;
    - imprime cada violação na **stderr** como `  FAIL  <violação>`;
    - imprime um resumo que segue a convenção dos sensores: `  ok    anchors: <N> measured, 0 off
      target` na **stdout** quando não há violação, e `  FAIL  anchors: <N> measured, <M> off
      target` na **stderr** quando há. N é o número de itens medidos;
    - sai com 0 se M = 0 e 1 se não, e 93 se o arquivo for ilegível. Sem marcador aberto, sai com 99,
      como o `--count`;
    - os Checks exigem N ≥ 1 (`[1-9][0-9]*`), então um prefixo que não casa nada não passa por
      vácuo. O `tests/check-checkpoint.sh` recusa Check que grepa saída mesclada sem âncora no
      `ok`: foi medido neste planejamento, e é por isso que o resumo é uma asserção `ok`/`FAIL`.

Implementação sugerida, não obrigatória: o `awk` emite, por item, `L<TAB>âncora<TAB>símbolos`, e um
laço bash faz os `grep -nF`. O `mawk` não abre arquivo de forma confortável, e 100 itens × `grep`
custa milissegundos. Dentro do `awk`, lembre do `mawk` orientado a byte: para cortar
crase use `index()`/`substr()`, nunca classe negada multibyte.

## Incrementos

A tabela executável vive em `checkpoint.md`. Aqui fica o porquê.

### I1 — a regra 5 recusa linha física acima de 120 caracteres

**O quê:** uma regra nova de lint no `check-todo.sh`. Na seção aberta, qualquer linha física com
mais de 120 **caracteres** vira violação: `line <L>: <n> characters on one physical line, cap is
120 — the long analysis lives in the handoff`. O teto de 8 linhas físicas continua como está.
Corrija o "~6-line" do cabeçalho em `:36` e descreva a regra nova no cabeçalho, junto da regra 5
(`:24`).
**Onde:** `tests/check-todo.sh` (awk do lint, cabeçalho, `selftest()`, `RULES_FLOOR`, piso de probes).
**Como (TDD):** escreva primeiro um bloco `rule_begin`…`rule_end` com três probes, todos por
`--check` sobre fixtures em tmp:
- (1) item de uma linha com 121 caracteres ASCII: reprova, e a mensagem diz `cap is 120`;
- (2) item de uma linha com exatamente 120 caracteres **com acento**, que passam de 120 bytes:
  passa, e é esse probe que prova caractere e não byte;
- (3) item com 1800 caracteres numa linha: reprova.

Rode e veja o vermelho pelo motivo certo: (1) e (3) passam hoje. Depois implemente.
Passada adversarial:
- troque a contagem de caracteres por `length()` cru: o probe (2) tem de ficar vermelho;
- troque `> 120` por `> 1200`: o (1) tem de ficar vermelho;
- restrinja a regra à primeira linha do item: um probe com a linha longa na **continuação** tem de
  ficar vermelho. Acrescente esse quarto probe.

Registre as sabotagens e os rc nas notas.
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a physical line of the open section holds at most 120 characters' <<< "$o"` → `1`
**Sensor durável:** o selftest do `check-todo.sh`, que roda em `tests/run-all.sh`.
**Reversível por:** `git revert` do commit. O `TODO.md` não muda, porque tem 0 linhas acima de 120.

### I2 — o selftest fica vermelho em toda sabotagem que o #70 listou

**O quê:** probes novos no `selftest()`, num bloco `rule_end` próprio chamado
`the selftest goes red under every sabotage issue 70 listed`:
- (a) um **segundo** fixture com contagem **diferente de 3** (por exemplo 2), exigindo
  `^2 shape violation(s)`;
- (c) o fixture da caixa marcada de três linhas (ver "Contexto verificado" § #70), exigindo **5**
  violações e o texto das duas que o mutante esconde (a data e "indented line that belongs to no
  finding");
- (d) `--check ''` com `SDD_TODO_FILE` apontando para um caminho **inexistente**, exigindo rc 93,
  para que o fallback `${2:-$TODO}` deixe de ser vácuo onde não há `TODO.md`;
- b1: um arquivo cujo único marcador aberto está **indentado**, e outro com o marcador **citado**
  (`> <!-- sdd:open -->`). Os dois têm de sair com rc 99 no `--count` e no `--check`;
- b2: um marcador seguido de texto (`<!-- sdd:open --> x`), com rc 99.

No cabeçalho, declare b4/b5 como limite (régua D15): "a comparação do marcador aceita variantes que
só mudam a mensagem, e o resultado segue vermelho". Suba `RULES_FLOOR` e o piso de probes.
**Onde:** `tests/check-todo.sh`.
**Como (TDD):** para cada probe, **aplique a mutação correspondente** numa cópia em scratch e veja o
selftest ficar vermelho com o rc 90/91/92 do probe novo. Depois volte ao código íntegro e veja
verde. Mutações:
- (a) `$(grep -c . <<< "$violations")` → `3`;
- (c) `flush(); next` → `next` em `:326`;
- (d) `${2-$TODO}` → `${2:-$TODO}`;
- b1: tirar o `^` do `OPEN_MARKER_ERE`;
- b2: tirar o `[[:space:]]*$`.

⚠️ O probe prova primeiro que sabotou o que dizia sabotar. Ancore a mutação em **código**
(`sed` sobre o texto exato), nunca em número de linha, e faça o script de sabotagem **morrer alto**
se o `sed` não mudou nada (`cmp -s` antes e depois). Registre os 5 rc nas notas.
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: the selftest goes red under every sabotage issue 70 listed' <<< "$o"` → `1`
**Sensor durável:** o selftest do `check-todo.sh`.
**Reversível por:** `git revert`.

### I3 — `config_read_key`: config que não parseia é dito, nos sete sítios (#116)

**O quê:** uma função `config_read_key <arquivo> <CHAVE>` no `bin/sdd`, perto do `load_config`:
- roda `bash -n <arquivo>`. Se falhar, escreve na stderr `<arquivo> does not parse:` seguido do
  diagnóstico do `bash -n`, e retorna **2**;
- se parsear, faz `source` num subshell com stdout nulo e imprime o valor da chave na stdout
  (rc 0; vazio se a chave não existe).

Ela é **chamada** por substituição de comando só para o valor. Não use global para passar erro: a
função roda em subshell e o global morreria (`CLAUDE.md`, função lida como `x="$(f)"`).

Os 7 sítios passam a usá-la:
- **health** (`:4828` e `:5087`): com rc 2, `health_bad "the kit's .sdd/config.sh does not parse —
  <diagnóstico>"`, e o "declares no TEST_CMD" fica só para a chave realmente ausente;
- **install e autonomy** (`:4108-4114`, `:7772`): com rc 2, `warn` com o diagnóstico, e seguem com
  o fallback de hoje;
- reescreva o comentário `:5084-5085`, que admitia a lacuna.

**Onde:** `bin/sdd`, `tests/check-health.sh`, `tests/check-preflight.sh` (install) e
`tests/check-mutation.sh`.
**Como (TDD):** primeiro os probes.
- `check-health.sh`: fixture do kit com `TEST_CMD="tests/run-all.sh` sem fechar aspas. A saída tem
  de conter `does not parse` e **não** `declares no TEST_CMD`. Asserção:
  `a kit config that does not parse is reported as not parsing, never as a missing TEST_CMD`.
- `check-preflight.sh`: `sdd install` sobre um alvo cujo `.sdd/config.sh` não parseia avisa
  `does not parse` na saída. Asserção: `install says the config does not parse instead of using
  defaults in silence`.

Veja os dois vermelhos pelo motivo certo, e implemente. Mutante novo `mut_HEALTH_config_parse_blind`
(o ramo rc 2 do health 2b volta a cair em "declares no TEST_CMD"); suba o `ANCHOR_FLOOR`.
⚠️ A regra `guard:` do `check-health.sh` conta as capturas da região do `cmd_health`: guarde cada
uma (`if v="$(config_read_key …)"; then … else rc=$?; …`) e ajuste o `CAPTURE_FLOOR` **só** se o
censo mudar legitimamente, explicando no commit.
**Check:** `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    a kit config that does not parse is reported as not parsing, never as a missing TEST_CMD' <<< "$o"` → `1`
**Sensor durável:** as duas asserções mais o mutante no catálogo.
**Reversível por:** `git revert`.

### I4 — um predicado só recusa `--list` com TAB ou entre aspas (#118)

**O quê:** uma função `test_cmd_lists_only <tc>` (nome sugerido) que:
- normaliza o espaço em branco: TAB, e qualquer `[[:space:]]`, vira espaço;
- tira as aspas simples e duplas que envolvem um argumento;
- casa ` --list ` / ` --listTests ` / ` --collect-only ` como argumento inteiro, com padding nos
  dois lados, para não acusar `--listen-port`.

O `test_cmd_looks_noop` passa a chamá-la para a parte de listagem, e o health 2b também, no lugar do
seu `case` próprio. O comentário de `:3935-3938` (duplicação deliberada) passa a dizer que existe
uma definição só e por quê: a duplicação deixou TAB e aspas passarem nas duas.
**Onde:** `bin/sdd`, `tests/check-preflight.sh`, `tests/check-health.sh` e `tests/check-mutation.sh`.
**Como (TDD):**
- probe no `check-preflight.sh`, no molde do `run_case`, com testemunha de argv: TAB antes de
  `--list`, e `"--list"` entre aspas. Os dois têm de dar `TEST_CMD runs nothing` e testemunha
  `NOT RUN`. Asserção: `a TAB or a quoted --list is refused like a spaced one`;
- probe no `check-health.sh`, que estende `:1348-1388`, para TAB e aspas no config do kit.
  Asserção: `health refuses a TAB or a quoted --list in the kit's TEST_CMD`;
- probe negativo: `--listen-port` continua aceito.

Atualize a âncora de `mut_HEALTH_testcmd_list_blind` e de `mut_PRE_testcmd_noop_blind` para o código
novo, e acrescente `mut_PRE_testcmd_list_unnormalised` (o predicado deixa de normalizar). Rode
`bash tests/check-mutation.sh --anchors`.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a TAB or a quoted --list is refused like a spaced one' <<< "$o"` → `1`
**Sensor durável:** as asserções mais os mutantes.
**Reversível por:** `git revert`.

### I5 — o preflight greenfield avisa em vez de reprovar, e só nesse caso (#53)

**O quê:** no `cmd_preflight`, quando o `TEST_CMD` falha, antes do `_fail` de `:4550`, verifique se
a **primeira palavra** do `TEST_CMD` é um runner conhecido e se o manifesto dele **não existe na
raiz do repo**:

| runner | manifesto |
|---|---|
| `npm`, `yarn`, `pnpm` | `package.json` |
| `cargo` | `Cargo.toml` |
| `go` | `go.mod` |
| `pytest` | `pyproject.toml`, `pytest.ini`, `setup.cfg` ou `tox.ini` |

Nesse caso, e **só** nesse, emita `warn "TEST_CMD failed and <manifesto> does not exist yet
(<TEST_CMD>) — expected if I1 creates the scaffold; from EXEC on, this is a hard gate"`. Em qualquer
outro caso, o `_fail` fica igual. A tabela runner → manifesto é **uma** definição (array ou
`case`).
**Onde:** `bin/sdd` (`cmd_preflight`), `tests/check-preflight.sh` e `tests/check-mutation.sh`.
**Como (TDD):** probes primeiro.
- (1) alvo sem `package.json` e `TEST_CMD="npm test"`: sai `warn` com `expected if I1 creates the
  scaffold`, e **não** sai `TEST_CMD FAILED`. Asserção: `a runner without its manifest at the root
  is a warn, not a fail`.
- (2) alvo **com** `package.json` e suíte vermelha: segue `TEST_CMD FAILED`. Asserção: `a red suite
  with its manifest present still fails`.
- (3) `TEST_CMD` de runner desconhecido que falha (`./suite-red.sh`, já coberto pelo `run_case`):
  segue `fail`.

⚠️ O fixture compartilhado do `check-preflight.sh` (`:115-123`) é greenfield (`npm test` sem
`package.json`). Rode o sensor inteiro depois de implementar e ajuste as asserções que liam o `fail`
antigo nesse fixture, preservando o que elas mediam. Mutante `mut_PRE_greenfield_warn_always` (o
rebaixamento vale mesmo com manifesto), que o probe (2) pega. Suba o `ANCHOR_FLOOR`.
**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a runner without its manifest at the root is a warn, not a fail' <<< "$o"` → `1`
**Sensor durável:** as asserções mais o mutante.
**Reversível por:** `git revert`.

### I6 — `check-templates.sh` fala o `ok` de quatro espaços, e o `calibrate()` passa a vê-lo (#151)

**O quê:** no `tests/check-templates.sh`, um helper de **uma linha**, exatamente
`pass() { printf '  ok    %s\n' "$*"; }`, porque é essa a forma que o `calibrate()` reconhece
(começa com `pass() { printf '` e contém `%s`). `check()`, `refute()` e as duas checagens inline
(`:447`, `:455`) passam a imprimir por ele. No `tests/check-checkpoint.sh`, **suba o
`CALIBRATE_FLOOR`** para 9, para que a perda de um sensor calibrado deixe de ser silenciosa.
**Onde:** `tests/check-templates.sh` e `tests/check-checkpoint.sh`.
**Como (TDD):**
- Red: suba o `CALIBRATE_FLOOR` para 9 primeiro. O `check-checkpoint.sh` fica vermelho com `only 8
  sensor(s) declare an ok prefix`.
- Green: acrescente o `pass()` ao `check-templates.sh`.
- Confira que `bash tests/check-templates.sh 2>/dev/null` **não** tem nenhuma linha que case
  `^  ok   [^ ]`: a contagem tem de ser `0`.
- Adversarial: grafar o `pass()` com três espaços tem de deixar o `check-checkpoint.sh` vermelho com
  `the suite's sensors disagree about the ok prefix`.
**Check:** `o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    the ok anchor is the prefix the suite.s sensors actually print (9 sensor(s))' <<< "$o"` → `1`
**Sensor durável:** o `calibrate()` do `check-checkpoint.sh`, que agora inclui o `check-templates.sh`.
**Reversível por:** `git revert`.

### I7 — a regra da âncora nasce, medida pelo selftest, em modo relatório (`--anchors`)

**O quê:** implementar a **gramática da regra da âncora** (seção Arquitetura, itens 1 a 10) no
`check-todo.sh`, exposta **só** pelo modo novo `--anchors <arquivo>`. O lint padrão e o `--check`
**ainda não** a aplicam; quem liga é o I10. Reescreva, no cabeçalho, a frase "Not measured, on
purpose: whether an anchor still points at real code" (`:29-31`, `:96-97`), apontando a ADR 0011 e
dizendo que a regra vive no `--anchors` até o I10. Declare os limites da ADR 0011 § Consequences.
**Onde:** `tests/check-todo.sh`.
**Como (TDD):** um bloco `rule_begin`…`rule_end` com o texto
`an anchor names a file of the checked repo and sits within 10 lines of a symbol the item cites`.
Os probes criam um **repo git temporário** (`git init -q` num `mktemp -d`) com um arquivo de
código e um `TODO.md` de esqueleto dentro dele, e rodam `--anchors` **de outro cwd**, o que prova a
base de resolução. Probes mínimos:
- (1) âncora certa: rc 0 e `  ok    anchors: 1 measured, 0 off target`;
- (1b) o filtro de prefixo: `--anchors <f> outro/` mede 0 itens e o resumo diz `0 measured`;
- (2) N a 11 linhas do símbolo: violação C, com `nearest` e o número;
- (3) arquivo inexistente: violação A;
- (4) nenhuma crase do item no arquivo: violação B;
- (5) `:1` com o símbolo lá embaixo: passa;
- (6) um glob como âncora: violação A;
- (7) um arquivo com o mesmo nome **só no `$ROOT` do kit** e não no repo do fixture: violação A.
  Esse é o probe que mata a resolução contra o `$ROOT`;
- (8) um símbolo de 3 caracteres que casa perto de N: não conta, e sai violação B ou C;
- (9) `--anchors` sem marcador aberto: rc 99.

Passada adversarial obrigatória, uma sabotagem por sub-regra, cada uma com o selftest vermelho:
- base `$ROOT` no lugar do repo checado;
- distância 10 → 1000;
- mínimo de 4 caracteres → 1;
- aceitar glob;
- pular a violação A;
- medir a âncora da **última** crase de caminho em vez da primeira.

Registre cada rc nas notas. Suba `RULES_FLOOR` e o piso de probes.
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: an anchor names a file of the checked repo and sits within 10 lines of a symbol the item cites' <<< "$o"` → `1`
**Sensor durável:** o selftest.
**Reversível por:** `git revert`. Nada no lint padrão muda neste incremento.

### I8 — re-ancorar as âncoras do `bin/sdd` no `TODO.md`

**O quê:** rodar `bash tests/check-todo.sh --anchors TODO.md` e, para **todo** item cuja âncora é
`bin/sdd:…`:
- corrigir o N para a linha que a mensagem `nearest` indica, **conferindo** que aquela linha é o
  código de que o item fala;
- quando a cabeça do item não tiver símbolo, acrescentar à cabeça o nome da função ou variável em
  crase. É esse símbolo que a regra passará a cobrar.

Itens de conteúdo velho que caem no `bin/sdd` (`:547`/`:548` `review_scope_check`) são reescritos
aqui, com uma nota por item: o que o item dizia, o que o código diz hoje, e se o achado ainda vale.
Achado que não vale mais **sai** da seção aberta e vira registro decidido (templates/todo.pt-BR.md
§ Ciclo de vida), com a catraca movida no mesmo diff e anotada.
**Onde:** `TODO.md` e, se algum item sair, `tests/health-baseline.txt`.
**Como (TDD):** o Red é a própria saída do `--anchors` de antes, que lista as violações `bin/sdd`.
Guarde a contagem inicial numa nota. Mantenha toda linha editada em 120 caracteres ou menos
(regra do I1) e os itens em 8 linhas ou menos.
**Check:** `o=$(bash tests/check-todo.sh --anchors TODO.md bin/sdd 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"` → `1`
**Sensor durável:** a regra do I7, que o I10 liga no lint da suíte.
**Reversível por:** `git revert`, que só afeta texto do `TODO.md`.

### I9 — re-ancorar o resto e reescrever os itens velhos

**O quê:** o mesmo trabalho do I8 para toda âncora que não é `bin/sdd`: `tests/*`, `agents/*`,
`templates/*`, `docs/*`, `README.md`, `TODO.md`, handoffs. Também:
- as duas âncoras que não são caminho: o `:515`, que ganha `bin/sdd:<linha>` como primeira crase de
  caminho, e o `:524`, cujo glob vira um arquivo real, por exemplo `templates/handoff.md:1` com um
  símbolo;
- os itens de conteúdo velho `:91` (piso 12 → 36), `:229` ("confere que existe", que é falso) e
  `:494` (`RESOLVIDO`), e qualquer outro achado no caminho, com uma nota por item;
- os três sem alvo provável (`:267`, `:321`, `:407`): leia, ache ou declare velho.
**Onde:** `TODO.md` e talvez `tests/health-baseline.txt`.
**Como (TDD):** como no I8.
**Check:** `o=$(bash tests/check-todo.sh --anchors TODO.md 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"` → `1`
**Sensor durável:** a regra do I7 no lint, a partir do I10.
**Reversível por:** `git revert`.

### I10 — a regra da âncora entra no lint padrão, e o formato do item passa a pedi-la

**O quê:**
- O `check_file`, usado pelo caminho nu e pelo `--check`, passa a aplicar as violações A/B/C como
  violações de forma, e todo alvo que rode `--check` herda a regra.
- A linha final do lint vira
  `  ok    <n> finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.
- **Atualize o stub do `tests/check-health.sh:208` no mesmo commit** (contrato; ver Contexto). O
  regex do `bin/sdd` só lê o prefixo `[0-9]+ finding\(s\)` e não muda.
- No `templates/todo.md` e no `templates/todo.pt-BR.md`, a linha de formato do item aberto passa a
  mostrar a âncora com símbolo, por exemplo `` `<arquivo:linha>` `` seguida de uma crase de
  `<símbolo>` na cabeça, e o texto do bloco diz a regra em uma frase, com o link para a ADR 0011.
  Os dois continuam com o mesmo esqueleto (`todo_shape`) e passando no `--check --allow-empty`.
- Atualize o cabeçalho do sensor: a regra vive no lint, não mais só no `--anchors`.
- Prove que um fixture do selftest antigo continua com as contagens de antes. ⚠️ Os fixtures do
  selftest de hoje têm âncoras fictícias (`x.sh:1` etc.): com a regra no lint, eles ganham violações
  novas e contagens como o `^3 shape violation(s)` quebram. **Crie o arquivo ancorado ao lado de
  cada fixture**, com o símbolo, em vez de afrouxar a regra ou de pôr uma chave de desligar. Chave
  de desligar é fail-open.
**Onde:** `tests/check-todo.sh`, `tests/check-health.sh`, `templates/todo.md` e
`templates/todo.pt-BR.md`.
**Como (TDD):** um probe de caminho (a regra do `CLAUDE.md`, "o selftest tem de exercitar o
CAMINHO") roda `--check` num fixture com âncora fora do alvo e exige rc 1 e a violação C **pelo
caminho do lint**, não pelo `--anchors`. Adversarial: apagar a chamada da regra no `check_file`
tem de deixar esse probe vermelho.
**Check:** `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    [0-9]* finding(s), all within 8 lines, carrying anchor + date, every anchor on target' <<< "$o"` → `1`
**Sensor durável:** o lint do `check-todo.sh` na suíte, mais o `check-templates.sh` sobre as duas
variantes.
**Reversível por:** `git revert`. Os I8/I9 continuam valendo como texto.

### I11 — contabilidade do backlog: `RESOLVED by`, fusão, catraca, achado do stub e KAIZEN_LOG

**O quê:**
- Os itens consertados ganham `RESOLVED by <hash>` com o hash do commit que os consertou:
  - regra 5 (`:26` de hoje) ← I1;
  - #70 ← I2;
  - #116 ← I3;
  - #118 ← I4;
  - #151 ← I6;
  - #86 e #136 ← I10.

  São 7 itens. Eles **ficam** na seção aberta até o merge e só então são apagados.
- O item "Os demais `templates/*.md` só existem em pt-BR" (`:665` de hoje) é **fundido** no item
  "`templates/` é single-language" (`:523`): acrescente ao sobrevivente a frase do precedente
  `todo.<lang>.md`, e apague o duplicado citando o sobrevivente. Catraca −1.
- Registre o achado do stub do `sdd adr new` (ver `00-missao.md` § Pendências): o stub manda
  escrever em `OUTPUT_LANG`, mas o `check-lang.sh` varre `docs/adr/*.md` como superfície inglesa.
  Catraca +1.
- `tests/health-baseline.txt`: `todo-findings` passa a ser igual ao `--count`. Esperado: 100 − 1 + 1
  = 100, mais ou menos qualquer movimento já anotado no I8/I9.
- `KAIZEN_LOG.md`: uma entrada com antes/depois medido:
  - 63 → 0 âncoras fora do alvo;
  - item de 1794 caracteres aceito → recusado;
  - 5 sabotagens do #70 sobrevivendo → 0;
  - 8 → 9 sensores calibrados;
  - `TEST_CMD` com TAB ou aspas certificado → recusado.
**Onde:** `TODO.md`, `tests/health-baseline.txt` e `KAIZEN_LOG.md`.
**Como (TDD):** o Red é o próprio Check antes do trabalho: 0 `RESOLVED by`.
**Check:** `b=$(grep -o '^todo-findings [0-9]*' tests/health-baseline.txt); c=$(bash tests/check-todo.sh --count TODO.md); grep -c "^todo-findings $c\$" <<< "$b"; grep -c 'RESOLVED by [0-9a-f]\{7,\}' TODO.md` → `1` e `7`
**Sensor durável:** a catraca `todo-findings` do `sdd health`, que roda uma vez no fim.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| I3–I5 empurram linhas do `bin/sdd` e as âncoras que o I8 acertou apodrecem de novo | alta, por isso a ordem | A re-ancoragem vem **depois** dos I3–I5. Depois do I10, a própria suíte acusa, e o conserto re-ancora no mesmo commit. |
| Um símbolo comum (`local`, `printf`) satisfaz a regra perto de qualquer linha | média | Mínimo de 4 caracteres, sabotagem obrigatória no I7, e o limite declarado na ADR 0011. Símbolo fraco é dívida escrita, não fail-open calado. |
| O `mawk` conta bytes e a regra de 120 reprova linha acentuada | alta se ninguém lembrar | O probe (2) do I1 existe exatamente para isso. |
| Reescrever o `case` do `--list` quebra âncoras de mutante | certa | Atualizar os mutantes no mesmo commit e rodar `check-mutation.sh --anchors`. |
| O fixture compartilhado do `check-preflight.sh` é greenfield e muda de `fail` para `warn` no I5 | certa | Ajustar as asserções dependentes sem afrouxar; ver o ⚠️ do I5. |
| Os fixtures do selftest do `check-todo.sh` ganham violações de âncora no I10 | certa | Criar o arquivo ancorado ao lado do fixture, nunca uma chave de desligar. |
| Alvos (`sales_quote` e outros) com âncoras podres ficam vermelhos no `--check` | média | É a regra funcionando (ADR 0011, Consequences). Registrar no corpo do PR, na seção de riscos. |
| O carimbo de mutação é invalidado por cada commit em `bin/`, `tests/`, `templates/` e `config/` | certa | `sdd health` **uma vez**, depois de todos os revisores do PR (`CLAUDE.md`, seção do carimbo). |

## Verificação end-to-end

Com todas as linhas `done`:

```bash
tests/run-all.sh; echo rc=$?                                   # rc=0
o=$(bash tests/check-todo.sh 2>&1)
grep -c '^  ok    rule: a physical line of the open section holds at most 120 characters' <<< "$o"   # 1
grep -c '^  ok    rule: the selftest goes red under every sabotage issue 70 listed' <<< "$o"          # 1
grep -c '^  ok    rule: an anchor names a file of the checked repo and sits within 10 lines' <<< "$o" # 1
grep -c 'every anchor on target' <<< "$o"                                                             # 1
o=$(bash tests/check-todo.sh --anchors TODO.md 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"  # 1
o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '(9 sensor(s))' <<< "$o"                            # 1
o=$(bash tests/check-templates.sh 2>/dev/null); grep -c '^  ok   [^ ]' <<< "$o"                        # 0
bash tests/check-mutation.sh --anchors; echo rc=$?                                                    # rc=0
```

Depois, fora da execução e na ordem do `CLAUDE.md`:
1. abrir o PR com `Closes #53`;
2. esperar **todos** os revisores e consertar numa leva;
3. rodar `./bin/sdd health` uma vez, que carimba e confirma `todo-findings`;
4. merge;
5. apagar os 7 itens `RESOLVED by` provados por `git merge-base --is-ancestor`;
6. re-sincronizar o espelho de issues com a skill `todo-to-github-issues`, que fecha #70, #86,
   #116, #118, #136 e #151.
