---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: REVIEW
rodada: 2
status: done
sessao: sdd-agents-adb6bfe6
data: 2026-09-12 14:40
gate: "`bash tests/run-all.sh` → `suite green`, rc 0, 1056 asserções `ok`; árvore limpa antes desta rodada escrever. Os cinco Checks de R1–R5 re-verificados um a um na saída da suíte (1 cada) e as três métricas do `00-missao.md` re-medidas por mim (`grep -c '\"repo\":\"/tmp' ~/.sdd/autonomy-log.jsonl` → 0; `95 finding(s)`; guarda de harness recusando). Carimbo de mutação conferido contra a árvore por recomputação de `mutation_stamp_key`: `724f5ce243685dea61e2feddf51cae6e` bate, então `300 caught of 300` é honesto agora. Nenhum arquivo de código tocado por esta sessão. ⚠️ SINAL DE LAÇO: `Error Handling` REGREDIU de B (r1) para C (r2) — a regressão foi introduzida pelo próprio R5 (a troca para `stream-json` no `cmd_close`); os demais critérios melhoraram ou ficaram (6 critérios abaixo de A na r1, 5 na r2; `Type Safety` C→A). Decisão humana registrada nas pendências."
---

# Review — rodada r2 — o juiz não mente sobre a janela

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Re-avaliação independente do round de consertos `1aa25ad..HEAD` (5 commits de código, 9 arquivos,
+581/−71), sem ter escrito nenhum deles. **Os cinco `R<n>` da r1 fecharam de verdade** — cada Check
verificado na saída da suíte, o contrato da guarda agora bate chave a chave com o agente do juiz, e
os mutantes novos foram medidos sob sabotagem em vez de contados à mão. **7 achados novos: 1 HIGH,
2 MEDIUM, 4 LOW**, todos reproduzidos por comando. O HIGH é uma regressão introduzida pelo próprio
R5: o `cmd_close` passou a jogar stderr dentro do `.jsonl` que ele mesmo parseia, e uma única linha
de stderr faz o `jq` abortar — a linha de `close` volta a ficar muda sobre o dinheiro, que é
exatamente o que R5 existia para consertar, e nada fica vermelho. Viraram **R6 e R7**; esta rodada
não conserta nada.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | Os cinco consertos são fiéis à régua do repo — `$stranded` reescrito positivamente, `$meta` somado de volta ao `$local_total` com a propriedade asseverada em vez de afirmada em comentário, e o `cmd_close` lendo `stream_summary`/`hat_init_facts` em vez de um segundo parser de custo. O que tira o A é uma divergência de forma na única linha que importa: `run_phase` manda stderr para um `.err` irmão e `cmd_close` escreve `2>&1` dentro do stream JSONL, mais duas frases da classe que a própria rodada estava fechando (comentário órfão, enumeração de escritores incompleta). |
| Type Safety | A | O achado #4 da r1 fechou de verdade e eu conferi os dois lados: o conjunto de chaves que `kaizen_series` publica em `guard.*` (`floor`, `why`, `harness`, `window_missions_stranded`, `window_broken`) bate exatamente com o que `agents/sdd-kaizen.md` passou a mandar ler, incluindo as duas entradas de `why` e a definição `window_broken: ($stranded > 0)`; o espelho `.claude/agents/` está idêntico à fonte, sincronizado por `sdd install --force` e não por `cp`. O shape da linha de `close` ganhou cinco campos e os produtores concordam sobre eles. |
| Error Handling | C | A regressão desta rodada, e ela é um fail-open: `cmd_close` redireciona `2>&1` para o `.jsonl` que `stream_summary` e `hat_init_facts` parseiam, então uma linha de stderr à frente do stream faz o `jq` sair 5, o guarda `2>/dev/null` seguido de `or true` engolir o erro, e custo, turns, cache e harness voltarem a `null` sem nada ficar vermelho. Junto vem a outra metade: as três mensagens de falha do `cmd_close` mandam o humano "see $logfile", que desde a troca para `stream-json` tem 0 byte quando a sessão morreu antes do `result`, e o stream cru não é nomeado em mensagem nenhuma. |
| Security | A | Varredura do diff limpa: nenhuma superfície de credencial nova, nenhuma permissão nem ferramenta acrescentada ao chapéu do `close`, e os quatro campos novos da linha de ledger são dinheiro, turnos, cache e versão de harness — nada sensível. O `--strict-mcp-config` e a lista de deny do chapéu seguem passados na sessão de `close`. |
| Performance | A | Nenhum caminho quente novo. A troca de `--output-format json` para `stream-json` acrescenta um arquivo em disco e duas passadas de `jq` sobre ele por invocação de `sdd close` — uma vez por missão, contra uma sessão paga de minutos. Os buckets novos (`$closes`, `$meta`) são dois `map(select(…))` seguidos de `length` sobre uma lista já materializada. |
| Test Coverage | B | Os testes desta rodada são o melhor do diff: dois regimes (`closein`/`closeaway`) escolhidos porque o primeiro rascunho sobreviveu aos três mutantes, pisos anti-vacuidade antes de cada conclusão, e as alegações de exclusividade dos mutantes medidas sob sabotagem — inclusive a correção honesta de uma frase podre herdada (`gate_pass_not_admitted` jurava duas asserções e eram dez). O buraco é o complemento: uma asserção de admissão do `close` lê um ledger sem nenhuma linha `close` e certifica verde uma sabotagem estreita dos dois leitores, e nenhum stub da suíte escreve em stderr, que é por isso que o HIGH acima passa despercebido. |
| Documentation | B | O `agents/sdd-kaizen.md` ficou preciso e com regra de leitura por entrada de `why`, e os comentários do `bin/sdd` passaram a descrever o que o código faz onde antes afirmavam o oposto. Contra isso, o contrato ficou em dois terços: `docs/pipeline.md:851` e `docs/failure-modes.md:115` ainda enumeram **cinco** buckets ("closes that sum over all five") quando o branch fez sete, e a tabela de schema do `docs/pipeline.md` ainda diz `on escalation rows` para `cost_usd`/`turns` sem nomear as linhas `event:"close"`, que agora os carregam — o modo de falha que a própria tabela declara na linha do `gate_why`. Herdado para a fase DOCS, não para um `R<n>`. |
| **Overall** | **B** | Rodada que andou de verdade: 12 achados viraram 5 fechados com commit, `Type Safety` subiu de C para A, e o número de critérios abaixo de A caiu de 6 para 5. Ela não fecha porque o conserto mais caro da r1 (o dinheiro na linha de `close`) foi entregue por um caminho que o desfaz em silêncio na primeira sessão que escrever uma linha em stderr, e porque uma asserção nova da mesma vizinhança não mede o que o título dela diz. São dois incrementos pequenos, não um redesenho — mas `Error Handling` regrediu B→C, que é sinal de laço e está nas pendências. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | `cmd_close` redireciona `2>&1` para o `.jsonl` que ele mesmo parseia; uma linha de stderr aborta o `jq` e a linha de `close` perde custo, turns, cache e harness em silêncio | `bin/sdd:7606` (`cmd_close`) contra `bin/sdd:3373` (`run_phase`) |
| 2 | MEDIUM | `both readers admit the close row instead of filing it as unrecognized` é **vazia**: o ledger que ela lê não tem nenhuma linha `close`, e ela certifica verde uma sabotagem estreita de `is_close` nos dois leitores | `tests/check-autonomy.sh:4963-4966` |
| 3 | MEDIUM | As três mensagens de falha do `cmd_close` mandam "see $logfile", que agora é o resumo destilado — 0 byte quando a sessão morreu antes do `result`; o stream cru não é nomeado em lugar nenhum | `bin/sdd:7639`, `:7644`, `:7648` |
| 4 | LOW | `mut_LEDGER_meta_bucket_unnamed` é o único mutante do lote sem comentário adjacente: o comentário dele está órfão, acima do par comentário+função de `mut_LEDGER_stranded_by_subtraction` | `tests/check-mutation.sh:3045-3066` |
| 5 | LOW | `autonomy_no_data` nomeia três escritores do ledger (`sdd run`, `sdd retry`, `sdd close`) e `cmd_kaizen` é um quarto — a mesma classe do #9 da r1, reintroduzida no commit que a fechou | `bin/sdd:5935` |
| 6 | LOW | `docs/pipeline.md` e `docs/failure-modes.md` ainda enumeram **cinco** buckets e afirmam que o sensor "closes that sum over all five"; R1 e R2 fizeram sete | `docs/pipeline.md:851`, `docs/failure-modes.md:115` |
| 7 | LOW | A tabela de schema do ledger diz `on escalation rows` para `cost_usd`/`turns` e não nomeia as linhas `event:"close"`, que passaram a carregá-los junto com `dur_s`, `cache_read` e `harness` | `docs/pipeline.md:829-830` |

### Como o HIGH foi reproduzido

A régua é a assimetria entre as duas portas que lançam `claude` com `--output-format stream-json`.
`run_phase` manda stderr para um arquivo irmão; `cmd_close`, acrescentado por R5, mistura os dois:

```
bin/sdd:3373   ( cd "$REPO_ROOT" && "${cmd[@]}" ) > "$streamfile" 2>"${logfile%.json}.err" || rc=$?
bin/sdd:7606       … --max-budget-usd "$BUDGET_PER_PHASE_USD" ) > "$streamfile" 2>&1 || rc=$?
```

`stream_summary` e `hat_init_facts` fazem `jq` **sobre o arquivo**, e o `jq` aborta na primeira
linha que não é JSON — não a pula. Uma linha de stderr à frente do stream apaga as duas leituras:

```
$ printf 'Warning: some notice on stderr\n{"type":"system","subtype":"init","claude_code_version":"2.1.260"}\n{"type":"result","total_cost_usd":0.0362104,"num_turns":1,"usage":{"cache_read_input_tokens":18134}}\n' > dirty.jsonl

LIMPO (forma do run_phase — stderr foi para o .err):
  result:  [{"type":"result","total_cost_usd":0.0362104,…}]
  init:    [{"type":"system","subtype":"init","claude_code_version":"2.1.260"}]

SUJO (forma do cmd_close — 2>&1):
  result:  []
  init:    []
  jq rc = 5   (engolido por `2>/dev/null || true`)
```

Com isso `close_cost`, `close_turns` e `close_cache` viram string vazia, `LAST_PHASE_HARNESS` volta
a `""`, e `tonumber? // null` mapeia os quatro para `null` — a linha de `close` fica exatamente
como era **antes** de R5, que é o achado #7 da r1 de volta, agora com um sensor por cima dizendo
que está resolvido. É a classe que o `CLAUDE.md` chama de fail-open: o instrumento afirma medir o
que não mede, e o consumidor está fora da suíte (a D12 conta US$ por PR mergeado).

**Por que a suíte não vê:** nenhum stub de `claude` do `check-autonomy.sh` escreve em stderr — o
stub do mundo `$CLW`, reescrito por R5 justamente para carregar a linha `init`, faz `cat "$INIT_CLEAN"`
e `exit 0`. A asserção `close row carries cost_usd…` é verdadeira sobre um stream que nunca é sujo.

### Como o #2 foi reproduzido

A asserção fica no braço *já-Done*, três linhas depois de `kitguard_reset` (`: > "$LEDGER"`) e
logo **depois** da asserção que exige `rows:0` para `select(.event == "close")`. Ou seja: ela pede
aos dois leitores que admitam uma linha que não está no arquivo. Sabotando `is_close` sozinho — sem
`is_gate_pass` junto — nos dois leitores, ela sobrevive enquanto as vizinhas morrem:

```
$ sed -i 's@def is_unrecognized: (… or is_gate_pass or is_close) | not;@… or is_gate_pass) | not;@' bin/sdd
$ sed -i 's@and (.event == "session" or is_escalation or is_gate_pass or is_close)@and (.event == "session" or is_escalation or is_gate_pass)@' bin/sdd
$ bash tests/check-autonomy.sh
  FAIL  the human reader does not call the recorded closure unrecognized
  FAIL  the buckets still sum to the header total (a close row)
  ok    both readers admit the close row instead of filing it as unrecognized   ← as duas metades do título refutadas
```

A **propriedade** não está descoberta — as asserções novas de R1 seguram a metade humana e
`closein`/`closeaway` seguram a do juiz. É o sensor que é cego, e sensor que jura estar coberto é
o fail-open que o `CLAUDE.md` separa de dívida declarada.

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R6 | #1 e #3 — o stderr dentro do stream e o log vazio para onde as mensagens apontam | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    close keeps stderr out of the stream it parses' <<< "$o"` → `1` ou mais |
| R7 | lote dos achados #2, #4 e #5 — a asserção vazia, o comentário órfão e o quarto escritor | `o=$(bash tests/check-autonomy.sh 2>&1); a=$(grep -c '^  ok    floor: the close admission pair reads a ledger carrying a close row' <<< "$o"); b=$(awk '/^mut_LEDGER_meta_bucket_unnamed/{print (p ~ /^#/)?1:0} {p=$0}' tests/check-mutation.sh); c=$(awk '/It is written by/ && /sdd kaizen/{n++} END{print n+0}' bin/sdd); echo "$a$b$c"` → `111` |

Os quatro Checks acima foram medidos **vermelhos** nesta sessão antes de virarem linha: `0`, `0`,
`0` e `0`.

⚠️ **#1 e #3 vão no MESMO `R<n>` de propósito**, contra a regra de "um HIGH por linha": os dois se
consertam na mesma linha de código (`2>` para um `.err` irmão) mais a menção do arquivo cru nas
mensagens, e separá-los faria o executor abrir duas sessões para editar a mesma função. O `R6`
continua revertível sozinho.

⚠️ **Ordem operacional.** `R6` e `R7` tocam `bin/` e `tests/`, então **matam** o carimbo
`724f5ce243685dea61e2feddf51cae6e`, que hoje está válido e que o `gate_PR` exige. O
`./bin/sdd health` (20–50 min) roda **depois do último commit de código de R7**, nunca entre eles.

## O que virou incremento

- #1 e #3, o stderr dentro do stream e o `$logfile` vazio — viraram `R6` — fecham quando o
  `cmd_close` mandar stderr para o `.err` irmão (a forma que o `run_phase` já usa), as mensagens de
  falha nomearem o arquivo que de fato carrega o erro, e existir uma asserção que reproduza um
  stub de `claude` **escrevendo em stderr** e ainda assim exija `cost_usd`/`harness` não-nulos na
  linha de `close`. Sem a metade do stub sujo o conserto não é medido: a suíte de hoje é verde com
  e sem ele.
- #2, #4 e #5 — viraram o lote `R7` — a asserção de admissão passa a ler um ledger que carrega uma
  linha `close` (o mundo `$CLW`, antes do `kitguard_reset`) com um piso próprio nomeando-a, ou sai
  do arquivo por redundante; o comentário de `mut_LEDGER_meta_bucket_unnamed` volta para cima da
  função dele; e `autonomy_no_data` passa a nomear `sdd kaizen`.
- #6 e #7 **não viraram `R<n>`** — são prosa e o gate tolera `B` em `Documentation`; conserto de
  prosa escreve prosa nova para a rodada seguinte medir, e foi esse laço que custou quatro rodadas
  em `20260902-o-rascunho-legado-fala-cru`. Ficam na seção abaixo, endereçados à fase **DOCS**, que
  roda depois desta e cujo checklist de drift é exatamente onde eles moram.

### Fechados pela rodada anterior, verificados aqui

- `R1` (#1 da r1, a linha `close` sem bucket) — fechado em `1563bc8` — o sexto bucket existe, e a
  soma fecha: `the buckets still sum to the header total (a close row)` → `1 ok`, com o piso
  `the fixture really does put a close row in the header total` provando que o fixture não é vazio.
- `R2` (#2 da r1, o `$meta` inflando o cabeçalho) — fechado em `a26d489` — `$local_total` virou
  `length + $meta`, a frase mudou de `$outside` para `$inside`, e o comentário passou a descrever o
  código. Medido por mim: `the outside group quotes the header total, judge row included` → `1 ok`.
- `R3` (#3 da r1, `window_missions_stranded` cego) — fechado em `154f58f` — grafia positiva
  (`select(.kit_sha != $latest)`) e o regime `winstraddle` que os dois fixtures antigos não cobriam:
  `guard: a mission straddling the kit change is stranded` → `1 ok`.
- `R4` (#4 da r1, contrato sem leitor) — fechado em `477cb9a` — conferido chave a chave contra
  `kaizen_series`, com o espelho `.claude/agents/sdd-kaizen.md` byte-idêntico à fonte.
- `R5` (lote #6–#9 da r1) — fechado em `c78b167` + `ed8e1ec` — `close row carries cost_usd…`,
  `close writes its row even when the hat guard fires…` e `guard: a close row mints no version and
  no mission` todos `1 ok`, e as três frases podres do #9 respondem `0`. ⚠️ Fechado **e** origem do
  achado #1 desta rodada: o caminho escolhido para entregar o dinheiro é o que o desfaz.

## O que foi refutado

- **"O `$local_total = length + $meta` conta as linhas do juiz duas vezes"** — refutado. As linhas
  KAIZEN são filtradas para fora na linha **seguinte** ao binding (`bin/sdd:6233`,
  `map(select((… .phase == "KAIZEN") | not))`), então nenhum bucket abaixo as vê e a soma de volta
  restaura exatamente o que o `total=` do shell já contava. Medido no fixture de três linhas:
  cabeçalho 2, buckets 1+1=2.
- **"O mutante `mut_RUN_close_writes_no_row` apodreceu quando a linha ganhou quatro argumentos"** —
  refutado, e foi consertado dentro da própria rodada (`ed8e1ec`): a âncora passou a ser
  `autonomy_close_row .*`, que é a forma que não apodrece no próximo argumento. Verifiquei os **300**
  mutantes do catálogo contra o `bin/sdd` atual: nenhuma âncora morta.
- **"Mover o `return 3` do chapéu para depois da linha de ledger afrouxou a Jidoka"** — refutado. O
  rc continua 3 e a linha continua parando; a asserção `close writes its row even when the hat guard
  fires, and still stops the line` exige `3 1 1 SQ-1`, isto é, rc 3 **e** a linha de `close` **e** a
  linha de `blocked` **e** o issue nomeado. Os censos de porta do `CLAUDE.md` seguem `3`/`8`/`4`.
- **"O carimbo de mutação está morto desde `1563bc8`, como as notas avisavam"** — refutado para o
  estado de hoje. Recomputei `mutation_stamp_key` sobre `bin tests templates config`:
  `724f5ce243685dea61e2feddf51cae6e`, idêntico ao arquivo `.sdd/logs/mutation-stamp`. O EXEC
  re-carimbou em `c73e9a7` depois do último commit de código, na ordem certa.
- **"`harness_mixed` vetando `sufficient` para sempre é um bug e devia virar `R<n>`"** — mantido como
  **não-conserto**, pelo mesmo argumento da r1 e agora com um dado a mais: R4 ensinou o juiz a
  **nomear** a razão e a responder `indeterminado`, que era a metade que faltava para a resposta ser
  honesta em vez de muda. Reverter o veto contraria a métrica 3 aprovada em
  `aprovacao: humano-2026-09-11`. Segue como decisão de desenho abaixo.

## Achados fora de escopo

Nenhum foi para o `TODO.md`, e a omissão continua deliberada pelo motivo que a r1 registrou: o
arquivo está dentro da catraca `todo-findings 95`, cujo movimento arrasta `tests/health-baseline.txt`
— que está dentro da chave do carimbo de mutação. Os achados #6 e #7 são drift de documentação e
têm dona: a fase **DOCS**, que roda depois desta e antes do PR, com as âncoras exatas na tabela
acima. Os demais viraram `R6`/`R7`.

## Pendências / Decisions for a Human

1. **Sinal de laço: `Error Handling` regrediu B → C.** A régua desta fase manda parar o laço quando
   uma rodada termina com **alguma letra mais baixa** que a anterior, porque isso costuma significar
   que os consertos custam mais do que compram. Aqui a leitura é ambígua e o humano decide com os
   dois fatos na mão: a regressão é **real e local** — o R5 entregou o dinheiro da linha de `close`
   por um caminho que o desfaz em silêncio —, mas o resto do laço andou (12 achados → 7, 4 HIGH → 1,
   `Type Safety` C → A, 6 critérios abaixo de A → 5, e cinco `R<n>` fechados com commit e Check
   verificado). `REVIEW_MAX_ITER=3`, então há exatamente uma rodada de orçamento. Minha
   recomendação, e é só isso: **rodar a r3**, porque `R6`/`R7` são dois consertos pequenos de escopo
   fechado e a alternativa é levar ao PR um fail-open que a própria missão foi criada para eliminar.
   Se a decisão for parar, `R6` precisa ir para o `TODO.md` antes do PR — não é achado que se perca.

2. **`harness_mixed` veta `guard.sufficient` sem remédio nem override** — herdada da r1, **ainda
   sem dono**, e R4 mudou o quadro sem fechá-la: o juiz agora nomeia a razão e responde
   `indeterminado`, o que torna a resposta honesta, mas um `kit_sha` que atravessou um bump de
   harness continua não podendo ser graduado `melhorou`/`piorou` nunca, e os dois irmãos estruturais
   (`degenerate_axis`, `window_broken`) não vetam. As três saídas seguem as da r1: (a) manter;
   (b) rebaixar a anotação, como `window_broken`; (c) manter o veto com override humano em artefato.

3. **`BUDGET_MISSION_USD` e o laço de revisão a 66%** — as duas pendências herdadas do
   `00-missao.md` e do `05-verdict.md` seguem abertas e sem dono. Esta rodada não as toca; registra
   que a missão está prestes a fechar com elas em aberto, e que a pendência 1 acima é justamente a
   que custa dinheiro.
