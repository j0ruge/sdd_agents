# O instrumento honesto — o ledger passa a dizer o que uma sessão fez, não só se ela escreveu

**Data:** 2026-08-28 · **Estado:** desenho **aprovado em grill** (três decisões, seção 3). Falta o plano
de execução e a execução.

Este documento é auto-contido de propósito. A sessão que o ler não participou da conversa que o
gerou e não precisa dela. Onde há número, ele foi medido sobre o ledger real
(`~/.sdd/autonomy-log.jsonl`, 151 linhas, 145 sessões) em 2026-08-28, antes de qualquer edição.

---

## 1. Onde o repo está

| | |
|---|---|
| `main` | `d30d199` — merge do PR #27 |
| branch desta missão | `feat/instrumento-honesto`, **empilhada** sobre `feat/o-gate-sabe-que-o-app-caiu` (`cfb5fa7`) |
| a branch de baixo | 12 commits, PR **ainda não aberto**; suíte verde; catálogo `166 caught, 0 known gap(s), of 166`; carimbo `ffc4b1e7…` válido |
| catraca do backlog | `todo-findings 77` |

Empilhada, e não ramificada da `main`, por um motivo medido: o bloco novo do
`tests/check-autonomy.sh` da branch de baixo termina na linha em que o bloco do leitor (`== reader ==`)
começa, e o `CATALOG=(…)` do `check-mutation.sh` é uma lista que as duas missões estendem. Ramificar
da `main` compraria dois conflitos de merge por construção. Quando o PR de baixo mergear, esta
branch faz rebase trivial — a base já está na `main`.

## 2. Por que esta missão existe

A pergunta do dono do kit é *"está maduro para projeto real?"*, e o instrumento que deveria
respondê-la responde errado — **na direção que lisonjeia o kit**.

**O leitor humano (`sdd autonomy`).** `stalled` está definido como `moved == false`: "a sessão não
escreveu nada no disco". Não é "a fase não avançou". Censo das 145 sessões do ledger:

| `gate` | `moved` | sessões | o que é | o que o leitor diz hoje |
|---|---|---|---|---|
| `pass` | `true` | 64 | avançou | — |
| `fail` | `true` | **68** | escreveu algo, o gate reprovou, o runner comprou outra sessão | **invisível** |
| `fail` | `false` | 13 | não escreveu nada | `stalled` |
| `pass` | `false` | 0 | — | — |

Sobre a missão real `20260827-condicoes-pagamento-mesmo-cliente` (SQ-111), que o handoff da missão
anterior descreve como *"~8 resgates humanos"*:

```
sales_quote/20260827-condicoes-pagamento-mesmo-cliente  6 session(s) · 0 stalled · ? intervention(s) · US$ 68.87
```

Zero `stalled`. Três `run_id` distintos na mesma missão — três vezes um humano digitou `sdd run`.
E `? intervention(s)`, porque a contagem da D16 lê linhas `- intervention:` do checkpoint de **outro
repo**, que este processo não alcança.

**O juiz (`sdd kaizen --series`, ADR 0001).** A rubrica `phase_label` lê `refez` quando há escalada,
`sdd retry` humano ou a **última** sessão da fase reprovou; `leve` quando há `auto_retry` ou
`moved == false`; `ok` no resto. Sobre as missões reais:

| missão · fase | sessões | gate reprovou | rótulo hoje |
|---|---|---|---|
| `frete-cif-fob` · EXEC | **7** | **5** | **`ok`** |
| `frete-cif-fob` · QA | 12 | 12 | `refez` |
| `condicoes-pagamento` · QA | 2 | 2 | `refez` |

Sete sessões, cinco reprovações, cada uma commitando algo, nenhuma retry automático — a fase
"acabou passando", e o juiz lê `ok`.

**A contagem de intervenções (D12/D16).** As linhas `- intervention:` escritas de verdade nos
checkpoints do `sales_quote`: `cif-forma-pagamento` 0, `frete-cif-fob` 1, `condicoes-pagamento`
**0**. A missão de três lançamentos tem zero anotações. O contador é um rótulo que o executor tinha de
lembrar de escrever, e não lembrou; `run_id` está em **toda** linha do ledger, de todo repo.

O handoff da missão anterior escreveu a frase que fecha o argumento: *"Sem isso não dá para provar
que esta missão funcionou."* E a regra da casa: *"sem número, não é kaizen — é opinião"*.

**Alvo:** os dois leitores derivam **o que a sessão fez** de campos que as 145 linhas já têm
(`gate` + `moved`), e a contagem de intervenções sai de um artefato (`run_id`) e não de prosa. Zero
migração; `v` continua `1`.

## 3. As três decisões, tomadas em grill (2026-08-28)

| # | Decisão | Alternativa recusada, e por quê |
|---|---|---|
| D-a | **A tri-estado entra nos DOIS leitores, no mesmo commit**, com asserção diferencial entre eles. | Só na janela humana: os dois instrumentos divergiriam sobre o mesmo arquivo — o juiz lendo `ok` onde o humano lê `5 churned` —, que é exatamente o que o `CLAUDE.md` diz que corrói o laço kaizen. |
| D-b | **`launches` é O número de intervenções que a D12/I13.4 lê**; as linhas `- intervention:` ficam como narrativa. **D16 emendada.** | Os dois lado a lado com a D16 intacta: o número oficial leria 0 na missão de 3 lançamentos e `?` fora do repo do kit. Apagar a prosa: perde a única fonte que diz o que o humano *fez*. |
| D-c | **Execução via superpowers** (este spec, plano em `~/.claude/plans/`, execução em sessão), como a missão anterior. | `sdd run` (dogfooding): a missão do instrumento seria medida pelo instrumento, mas a ADR 0003 diz que o eixo do kit degenera de qualquer forma, e custa US$ 48–133. |

A mudança da rubrica **não é emenda da ADR 0001** — é o caso que ela desenhou: *"Changing the
mechanical yardstick means changing runner code — dated in history, so a future reading of old
verdicts can tell which yardstick judged what."*

## 4. O desenho

### 4.1 Uma definição, emitida uma vez, costurada nos dois programas

O padrão já existe em `ledger_row_is_local()` (`bin/sdd:1712`): uma função bash que **imprime**
`def`s de jq, recebida pelos dois programas via `"$def"` / `"$(ledger_row_is_local)"`. Nasce ao lado
dela:

```bash
ledger_outcome_defs() {   # printed jq, spliced into cmd_autonomy AND kaizen_series
  printf '%s' 'def outcome: if .gate == "pass" then "advanced" elif .moved == true then "churned" else "idle" end;'
  # `$phases` chega por --arg a partir de $PHASES — UMA fonte para a ordem canônica.
  printf '%s' 'def phase_index: . as $p | ($phases | split(" ")) | index($p);'
}
```

- **Os dois programas recebem `--arg phases "$PHASES"`**, mesmo que só `cmd_autonomy` use
  `phase_index`: o jq resolve `$phases` em tempo de compilação, dentro de um `def` não chamado
  inclusive, e um programa que costura o `def` sem o `--arg` morre com *"$phases is not defined"*.
  É o preço de uma emissão só, e é barato.
- `outcome` só é aplicada a sessões **comparáveis** (`comparable` / `on_axis` de cada programa, que
  já exigem `has("moved")`). Linhas de schema velho continuam onde estão: não-comparáveis, contadas.
- `pass/false` não ocorre no ledger, mas a definição o classifica (`advanced`) sem quarto braço:
  o gate passou, e o gate é o artefato.
- **Por que uma emissão e não "a mesma grafia nos dois programas":** o `CLAUDE.md` mede a segunda
  forma — *"comentário que afirma paridade entre dois programas não é paridade"* — e a primeira já é
  a forma que `ledger_row_is_local` usa. A paridade continua **afirmada por asserção** (5.7), porque
  um programa pode deixar de costurar o `def` e ganhar cópia local; é o mutante `KAIZEN_outcome_inlined_old`.

### 4.2 `sdd autonomy` — tabela por `kit_sha`

```
hoje:  25d4e1c  6 session(s) · 0 stalled · 0% waste · 1 mission(s) · US$ 68.87
novo:  25d4e1c  6 session(s) · 5 advanced · 1 churned · 0 idle · 16% waste · 1 mission(s) · US$ 68.87
```

`waste = (churned + idle) × 100 / sessões`, piso. `stalled` desaparece: `idle` é o mesmo número com o
nome que diz o que ele é. **`waste` muda de régua** — sempre quis dizer "sessão que não fez a fase
avançar", e o que existia era a aproximação `moved == false`. O `KAIZEN_LOG` registra as duas
réguas lado a lado (seção 8).

Nenhuma outra célula muda. `mission(s)`, custo, o bloco `escalations`, o parágrafo de contabilidade
(quatro baldes somando ao total do cabeçalho — `assert_bucket_sum` continua) ficam como estão.

### 4.3 `sdd kaizen --series` — por grupo `kit_sha`

Dois campos novos em `group_summary` e uma cláusula nova na rubrica:

```jq
outcomes:     ($sess | map(outcome) | reduce .[] as $o ({advanced:0, churned:0, idle:0}; .[$o] += 1)),
advance_rate: (if ($sess|length) == 0 then null
               else (($sess | map(select(.gate == "pass")) | length) / ($sess|length) * 100 | round / 100) end),
```

`phase_label`:

```jq
def phase_label:
  if (map(select(is_escalation)) | length) > 0
     or (map(select(.event == "session" and .invocation == "retry")) | length) > 0
     or ((map(select(.event == "session")) | last | .gate) != "pass")
  then "refez"
  elif (map(select(.event == "session" and (.auto_retry == true or .moved == false or .gate == "fail"))) | length) > 0
  then "leve"
  else "ok"
  end;
```

Uma cláusula: **qualquer sessão da fase com `gate == fail` ⇒ pelo menos `leve`**. O EXEC de
`frete-cif-fob` sai de `ok` para `leve`. `refez` não muda.

- **`moved_rate` fica.** O nome diz o que ele mede, e trocá-lo quebraria o único consumidor. Deixa de
  ser a manchete no prompt do juiz (`agents/sdd-kaizen.md:41,106`): a manchete passa a ser
  `outcomes` + `advance_rate`.
- **Três rótulos, não quatro.** A magnitude (5 `churned` vs 1) mora em `outcomes` no grupo e no
  `detail` por fase (cada entrada ganha o seu `outcomes`); o rótulo é categoria. Um quarto rótulo
  mudaria o conjunto de chaves `{ok, leve, refez}` que `check-kaizen.sh` afirma e que o prompt do juiz
  cita, para dizer o que um número ao lado já diz.
- A série vazia (`[ ! -s "$file" ]`, o segundo produtor da forma) **não** ganha os campos novos no
  topo: eles vivem dentro de `latest`/`previous`, que já são `null` ali. `check-kaizen.sh` compara os
  dois produtores como conjunto de chaves — a asserção existente continua verde sem edição.

### 4.4 `launches` e `reopened` — só em `sdd autonomy --by-mission`

```jq
def launches: map(.run_id) | unique | length;
# reopened: sessão numa fase ABAIXO de outra cujo gate já tinha PASSADO, na ordem $PHASES.
# Fase fora da ordem (KAIZEN) tem phase_index null e não conta em nenhum dos dois lados.
def reopened: reduce .[] as $r ({maxpass: -1, n: 0};
                ($r.phase | phase_index) as $i
                | (if $i != null and $i < .maxpass then .n += 1 else . end)
                | (if $i != null and $r.gate == "pass" then .maxpass = ([.maxpass, $i] | max) else . end)) | .n;
```

`reopened` com **essa** definição, e não "índice de fase andou para trás", porque a segunda conta o
laço desenhado: `frete-cif-fob` fez `EXEC after QA` três vezes com a QA **reprovada** — é o pipeline
funcionando (a QA abre incremento de fix, o EXEC o executa) e lê **0**; a SQ-111 fez `QA after PR
passed` e lê **1** — os US$ 7,61 que a branch de baixo fecha. Sobre o ledger inteiro, a definição
concorda com a contagem à mão do handoff anterior (`lote-facil`: 4 lançamentos, 2 reaberturas).

**A população — o ponto que quase passou.** A linha por missão hoje é desenhada sobre as **mesmas**
sessões comparáveis da tabela por versão, de propósito: `check-autonomy.sh` compara a soma de dinheiro
das duas tabelas. Só que a QA pós-PR da SQ-111 tem `kit_dirty: true` (o kit estava sendo editado
entre dois lançamentos), logo é **não-comparável** — e `reopened` derivado sobre as comparáveis leria
**0** exatamente na missão que motivou o campo.

Decisão: `session(s)`, `outcomes` e `US$` continuam sobre as comparáveis (a soma fecha);
**`launches` e `reopened` são derivados sobre TODAS as sessões locais da missão** (`is_session`,
sem `comparable`), porque são fatos sobre a história humana da missão e não sobre uma versão do
kit — um lançamento que caiu num kit sujo foi um lançamento. Quando as duas populações diferem para
alguma missão da tabela, o parágrafo de contabilidade ganha **uma** frase dizendo isso, na forma
`(launches and reopened are counted over every session of the mission, N of them non-comparable)`,
com `N` somado sobre as missões impressas. Uma missão sem nenhuma sessão comparável continua não
aparecendo (como hoje) — limite declarado, seção 11.

### 4.5 A linha por missão

```
hoje:  condicoes-pagamento  6 session(s) · 0 stalled · ? intervention(s) · US$ 68.87
novo:  condicoes-pagamento  6 session(s) · 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened · US$ 68.87
```

- Quando o checkpoint da missão é legível (repo local, mesmo mecanismo de hoje), a linha acrescenta
  ` · N intervention note(s)` entre `reopened` e `US$` — a narrativa, com o nome que diz o que ela
  é: `… 1 reopened · 2 intervention note(s) · US$ 68.87`. Quando não é, **nada**: o `?` existia para
  não imprimir um zero falso no número oficial, e o número oficial agora está em toda linha.
- **`launches`, não `launches − 1`.** O número impresso é o fato (quantas vezes `sdd run` ou
  `sdd retry` abriu); "intervenções = lançamentos − 1" é a **leitura**, escrita na D16 e no prompt
  do juiz. Um `− 1` no leitor seria a primeira aritmética de opinião dentro de um instrumento que só
  imprime fatos — e leria `0` numa missão abandonada no primeiro lançamento, que é uma intervenção.

### 4.6 O que NÃO muda

- Nenhum campo novo na **linha** do ledger; `v` continua 1. Nenhuma migração.
- `moved_rate`, `labels` (as três chaves), `escalations`, `guard`, `composition`, `excluded`: intactos.
- `launches`/`reopened` **não** entram na série do juiz: a série agrupa por `kit_sha`, e uma missão
  que atravessa duas versões contaria seus lançamentos duas vezes. A D16 diz que o instrumento da
  D12 é `sdd autonomy --by-mission`, e é lá que eles vivem. Limite declarado no cabeçalho do jq.
- O lembrete pós-pipeline (`kaizen_reminder`) não imprime nem `stalled` nem `waste` — não é superfície.
- `sdd close` continua fora do ledger (achado, seção 10).

## 5. Sensores — cada asserção nasce vermelha antes do código

`tests/check-autonomy.sh`, bloco `== reader ==`, fixture escrito à mão (é o nosso formato; a regra de
proveniência cobre saída de skill de terceiro):

1. **Tri-estado por versão** com contagens todas diferentes (`3 advanced · 2 churned · 1 idle`) —
   dois campos trocados não passam por coincidência.
2. **`waste` diferencial contra a régua velha**: o mesmo fixture tem `idle% ≠ (churned+idle)%`, e a
   asserção exige o segundo **e a ausência** do primeiro na linha.
3. **`launches` conta `run_id` distintos**: três linhas com um `run_id` só leem `1 launch(es)`; duas
   missões com 2 e 1 `run_id` leem `2` e `1`.
4. ⭐ **`reopened`, o par diferencial**: dois fixtures iguais exceto o gate da fase de cima —
   `EXEC, QA(pass), EXEC` → `1 reopened`; `EXEC, QA(fail), EXEC` → `0 reopened`. Mais uma linha
   `KAIZEN` depois de `PR(pass)` que **não** conta.
5. **A população**: missão com uma linha `kit_dirty:true` num `run_id` novo — a linha lê
   `1 session(s)` **e** `2 launch(es)`, e a frase de contabilidade aparece. Diferencial: com a linha
   suja removida, `1 launch(es)` e a frase some.
6. **`?` nunca mais** (`assert … absent "? intervention"`), e `intervention note(s)` aparece só com o
   checkpoint presente — o fixture do repo local escreve um `checkpoint.md` com duas linhas
   `- intervention:` e afirma `2 intervention note(s)`; sem o arquivo, a célula não existe.
7. ⭐ **Paridade janela × série**: sobre o mesmo fixture, o histograma `A advanced · C churned · I idle`
   da última linha da tabela por versão **==** `.latest.outcomes` de `sdd kaizen --series` — a forma
   que o `CLAUDE.md` exige no lugar de "same spelling in both".
8. `assert_bucket_sum` continua fechando sobre o fixture estendido.

A única asserção existente sobre a régua velha é `50% waste` (`check-autonomy.sh:1392`); ela muda de
número junto com a régua e o comentário diz por quê.

`tests/check-kaizen.sh`, bloco `== series ==`:

9. `outcomes` **exato** sobre o fixture atual (`.previous.outcomes`, `.latest.outcomes`), e por fase
   em `detail[]`.
10. `advance_rate` num fixture em que **difere** de `moved_rate`; os dois afirmados na mesma linha.
11. **O `leve` alargado**: grupo novo no fixture — `fail/true` seguido de `pass/true`, mesmo `run_id`,
    sem `auto_retry`, sem escalada — que hoje lê `ok` e passa a ler `leve`. **Controle:** o grupo
    `m3/EXEC` (`pass/true` sozinho) continua `ok`.
12. As três asserções de `refez` intactas; o conjunto de chaves de `labels` inalterado (o literal
    `{"ok":N,"leve":N,"refez":N}` muda só de números).

## 6. Mutantes — sete, cada um com o assassino nomeado (`166 → 173`)

| Mutante | Sabotagem (âncora em CÓDIGO) | Quem mata |
|---|---|---|
| `AUTONOMY_outcome_reads_moved_only` | `def outcome` degradado para `if .moved then "advanced" else "idle"` — a régua velha com nome novo | 5.1 (`churned` some) |
| `KAIZEN_outcome_inlined_old` | `kaizen_series` deixa de costurar `$(ledger_outcome_defs)` e ganha `def outcome` local na régua velha | **5.7** — é o mutante que prova que a paridade é medida, não afirmada |
| `KAIZEN_churn_reads_ok` | `phase_label` perde `or .gate == "fail"` | 5.11 |
| `AUTONOMY_waste_idle_only` | `waste` volta a contar só `idle` | 5.2 |
| `AUTONOMY_launches_counts_rows` | `unique` removido de `launches` | 5.3 |
| `AUTONOMY_reopened_ignores_gate` | `maxpass` avança em qualquer sessão, `pass` ou não | 5.4, a metade `QA(fail)` |
| `AUTONOMY_reopened_comparable_only` | `launches`/`reopened` derivados de `$mgroups` | 5.5 |

Regra da casa: o mutante prova primeiro que sabotou o que dizia sabotar (`cmp` no `run_mutant` já
devolve rc 90 quando a âncora não casa). Âncora em código, nunca em prosa; `sed` com `\@…@` quando
a linha carrega `|`.

## 7. Docs — no mesmo commit do código, pela regra do contrato em três lugares

| Arquivo | O quê |
|---|---|
| `docs/pipeline.md:594` | linha `moved`: *"exactly what `sdd autonomy` counts as a stalled session"* → `idle`, e a tri-estado |
| `docs/pipeline.md:656-661` | a rubrica: `leve` ganha a cláusula; a forma da série ganha `outcomes` e `advance_rate` |
| `docs/pipeline.md` (ledger) | o que `sdd autonomy --by-mission` imprime: `launches`, `reopened`, `intervention note(s)`, a população |
| `agents/sdd-kaizen.md:41,106` | os campos da série; a manchete vira `outcomes`/`advance_rate`; a leitura "intervenções = lançamentos − 1" via `sdd autonomy --by-mission` (D16) |
| `CONTEXT.md` D16 | **emendada**: o contador é `run_id` distintos; a prosa é narrativa; a medição que a derrubou (0 linhas na missão de 3 lançamentos). Verbete **Churn** no glossário |
| `templates/checkpoint.md:44-46` | a nota `- intervention:` deixa de ser "o que o `sdd autonomy --by-mission` conta" e passa a ser "o que aconteceu" |
| `README.md:61` | `waste per kit version` continua verdade; ganha `launches` |
| `docs/failure-modes.md:81` | `moved_rate` → `outcomes`/`advance_rate` |
| `KAIZEN_LOG.md` | a entrada, seção 8 |

## 8. A medição — capturada ANTES de qualquer edição

Capturada com `sdd autonomy --all-repos --by-mission`, `sdd autonomy --all-repos` e
`sdd kaizen --series` na sessão que escreveu isto. As saídas brutas **não** são commitadas — carregam
o caminho de repos de cliente, o motivo pelo qual o próprio ledger nunca entra no git — e a tabela
abaixo é o registro; é ela que vai para o `KAIZEN_LOG`:

| | Antes (régua `moved`) | Depois (régua `gate`+`moved`) |
|---|---|---|
| 145 sessões, todos os repos | `13 stalled` | `64 advanced · 68 churned · 13 idle` |
| SQ-111, por missão | `6 session(s) · 0 stalled · ? intervention(s)` | `6 session(s) · 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened` |
| `frete-cif-fob` · EXEC, no juiz | `ok` | `leve` |
| `25d4e1c` (latest), série | `moved_rate: 1, labels: {ok:5, leve:0, refez:1}` | `outcomes: {advanced:5, churned:1, idle:0}, advance_rate: 0.83`; `labels` **não** muda — o único grupo com reprovação nesta fatia (QA, 1 sessão comparável) já lê `refez` pela última sessão |
| `lote-facil` | `9 session(s)` | `4 launch(es) · 2 reopened` — bate com a contagem à mão de `20260828-…-handoff.md §9` |

O "depois" é recapturado com os mesmos três comandos após o último commit de código; o diff é a
entrada. Sem os dois lados, não entra.

## 9. Ordem de execução — e por que ela não mata o carimbo

A chave do carimbo é o conteúdo de `bin/ tests/ templates/ config/`. `templates/checkpoint.md`
**está** na chave; `agents/`, `docs/`, `CONTEXT.md`, `KAIZEN_LOG.md` não. `tests/health-baseline.txt`
está, e é onde a catraca `todo-findings` mora.

1. **O achado do `sdd close`** (seção 10) entra no `TODO.md` e a catraca sobe `77 → 78` no
   `health-baseline.txt` — primeiro, porque mexe em `tests/`.
2. Código + testes + `templates/checkpoint.md`, em incrementos TDD (o plano os enumera).
3. `./bin/sdd health --with-mutation` — `173 caught of 173`, carimbo escrito.
4. Docs, `CONTEXT.md`, `KAIZEN_LOG.md` (recaptura do "depois" antes de escrever a entrada).
5. Handoff em `docs/superpowers/specs/2026-08-28-instrumento-honesto-handoff.md`.

## 10. Achado desta conversa — vai para o `TODO.md`, não se conserta aqui

**`sdd close` abre uma sessão e não escreve linha no ledger.** `grep -n 'autonomy_.*_row' bin/sdd`
não devolve nenhuma linha dentro de `cmd_close`, e `docs/pipeline.md` promete *"uma linha JSON por
sessão gasta ou escalada"*. O ledger afirma cobrir o que não cobre — fail-open pela régua D15, e
tem consumidor fora da suíte (o juiz e o D12). Direção: `cmd_close` passa por `run_phase` ou escreve
a linha com `invocation: close`, e o enum de `invocation` no `pipeline.md` aprende o valor **no mesmo
commit** — o mesmo contrato de cauda aberta que `kind` carrega.

## 11. Limites declarados (cabeçalho dos sensores e do jq, não backlog)

- `launches` **subconta**: subir o app à mão entre dois lançamentos é um resgate que vira **um**
  `run_id` novo, não dois. É um piso honesto; o teto (a prosa) ninguém preenche.
- Uma missão cujas sessões são **todas** não-comparáveis não aparece na tabela por missão — como hoje.
- `launches`/`reopened` não estão na série do juiz (4.6).
- `pass/false` é classificado `advanced` sem fixture próprio: o regime não ocorre no ledger, e um
  fixture que o inventasse mediria a suposição, não o mundo.

## 12. Fora de escopo, com motivo

- **Renomear `moved_rate`** — quebraria o único consumidor para dizer o que `advance_rate` já diz.
- **Qualquer campo novo na linha** — tudo deriva do que as 145 linhas já têm; é o que faz a
  história inteira reler-se com a régua nova.
- **`sdd close` no ledger** — achado, seção 10.
- **A faxina D15 e o custo do REVIEW** — as duas missões seguintes do handoff anterior (§9),
  intocadas.
- **Sensor novo** — custaria cinco lugares; tudo entra nos sensores que já leem o ledger.

## 13. Aceitação

```bash
./tests/run-all.sh                                   # suite green, as 12 asserções novas verdes
./bin/sdd health --with-mutation                     # score: 173 caught, 0 known gap(s), of 173 · carimbo escrito
./bin/sdd autonomy --all-repos --by-mission | grep condicoes-pagamento
#   … 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened …   e NENHUM `?`
./bin/sdd kaizen --series | jq '.latest.outcomes, .latest.advance_rate'
git diff main -- KAIZEN_LOG.md | grep -c 'churned'   # ≥ 1: a entrada existe, com os dois lados
```
