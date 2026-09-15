---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: REVIEW
rodada: 3
status: done
sessao: sdd-agents-f4 [6a7eb9]
data: 2026-09-12 19:40
gate: "`bash tests/run-all.sh` → `suite green`, rc 0, **1058** asserções `ok`, 0 `FAIL`; árvore limpa antes e depois desta rodada escrever (`git status --short` vazio). `shellcheck -S warning` e `bash -n` limpos sobre os três arquivos do diff. Carimbo de mutação **recomputado** com a grafia exata de `mutation_stamp_key` (`CDPATH='' cd` + `LC_ALL=C sort -z` + `md5sum`): `79484a242bdfd073a6169581d3bffd4a`, idêntico a `.sdd/logs/mutation-stamp` — o carimbo está VIVO. Catálogo: `grep -cE '^mut_' tests/check-mutation.sh` = 301 = tamanho do `CATALOG`, e **as 301 âncoras aplicadas uma a uma sobre uma cópia do `bin/sdd` de hoje: `live=301 dead=0`**. As três métricas do `00-missao.md` re-medidas (`95 finding(s)`; `grep -c '\"repo\":\"/tmp'` → 0; `guard: two harness versions in one slice make it unanswerable`). `R6` e `R7` verificados **sob sabotagem**, nunca pela saída verde. ⚠️ A rodada NÃO fecha: `Test Coverage` fica em `B` por dois MEDIUM reproduzidos — o `human:` da asserção que o `R7` moveu é uma CONSTANTE (sabotar só o leitor humano a deixa `ok`), e a outra metade do `R6` foi entregue sem sensor nenhum (desfazê-la deixa a suíte inteira verde, rc 0). Nenhuma letra regrediu contra a r2. ⚠️ TETO DE RODADAS ATINGIDO: `REVIEW_MAX_ITER=3` e esta é a r3; a porta humana está na pendência 1."
---

# Review — rodada r3 — o juiz não mente sobre a janela

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Re-avaliação independente do round de consertos `c64f119..HEAD` (3 commits de código, 3 arquivos,
+133/−50), sem ter escrito nenhum deles. **O HIGH da r2 fechou de verdade e eu o medi sob sabotagem**:
o mutante do `stderr` mata exatamente uma asserção na suíte inteira, e é a nova. As 301 âncoras do
catálogo mutam o `bin/sdd` de hoje (`live=301 dead=0`) e o carimbo bate. **7 achados novos: 2 MEDIUM,
5 LOW.** Os dois MEDIUM são a mesma classe, e é a que a missão inteira persegue: o `R7` consertou
**metade** do achado #2 da r2 — sabotar só o leitor humano deixa `both readers admit the close row`
verde, porque o termo `human:` é uma constante —, e a outra metade do `R6` (o achado #3) foi entregue
**sem sensor nenhum**, com a suíte inteira sobrevivendo ao conserto desfeito. Viraram **R8**; esta
rodada não conserta nada. Nenhuma letra regrediu contra a r2 e duas subiram.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O `B` da r2 tinha três causas nomeadas e as três fecharam. A divergência de forma acabou: `cmd_close` manda stderr para o `.err` irmão, que é a grafia do `run_phase` — e, medido agora, é também o contrato que `docs/pipeline.md:611` (`<PHASE>-<ts>.err` para o stderr da sessão) já declarava e que o `2>&1` violava em silêncio, então o conserto aproximou o código da documentação em vez de criar uma terceira forma. O comentário órfão foi para cima da função a que pertence e o `autonomy_no_data` passou a nomear os quatro escritores. `$close_logs` é uma definição só, montada uma vez e lida em três mensagens, declarada acima das duas guardas que podem sair da função. `shellcheck -S warning` e `bash -n` limpos; nenhuma captura sob `-e`, nenhum `printf \| grep -q`, nenhum `cd` relativo, nenhum `awk` novo no diff. |
| Type Safety | A | Mantido da r2 e re-conferido nesta: o conjunto de chaves `guard.*` que `kaizen_series` publica segue batendo com o que `agents/sdd-kaizen.md` manda ler (`grep -c 'window_broken' agents/sdd-kaizen.md` → 4), o espelho `.claude/agents/` continua idêntico à fonte, e a forma da linha de `close` não mudou neste round — os cinco campos que ela ganhou no `R5` continuam produzidos e lidos pelas mesmas duas definições (`stream_summary`, `hat_init_facts`) que o `run_phase` usa. Nenhum campo novo, nenhum shape novo, nenhum produtor novo para divergir. |
| Error Handling | A | A regressão que derrubou este critério para `C` na r2 está fechada, e eu a medi pelo lado da falha e não pelo lado do verde. O `2>&1` saiu, e a premissa que o fundava foi re-verificada em vez de repetida: `jq` sobre um arquivo com uma linha não-JSON à frente sai **5 sem imprimir nada** — ele aborta, não pula —, então o `2>&1` realmente esvaziava `stream_summary` e `hat_init_facts` juntos. Sob o mutante que devolve o `2>&1`, a asserção lê `armed:false pure:false null null` e a suíte sai 1. A outra metade também fechou: as três mensagens de falha deixaram de mandar o humano para um `$logfile` que tem 0 byte exatamente no caso em que ele é lido, e nomeiam os três arquivos. Que essa metade não tenha sensor é achado de `Test Coverage`, não deste critério — o comportamento está certo no disco de hoje. |
| Security | A | Varredura do diff limpa. O round não acrescenta superfície de credencial, não mexe em `ALLOWED_TOOLS`/`PERMISSION_MODE`, não toca o `hat_disallowed`/`hat_mcp` da sessão de `close` e não introduz caminho de rede novo. O único artefato novo em disco é um `.err` irmão do stream que já existia, no mesmo `.sdd/logs/` ignorado pelo git — e ele reduz exposição em vez de aumentá-la, porque tira o stderr de dentro de um arquivo que dois leitores parseiam. Nenhum segredo, nenhum caminho de escrita fora do que a fase já escrevia. |
| Performance | A | Nenhum caminho quente novo, e o delta é trivialmente limitado: um descritor de arquivo e um `.err` a mais por invocação de `sdd close`, que acontece **uma vez por missão** contra uma sessão paga de minutos. `$close_logs` é uma concatenação de três variáveis avaliada uma vez. As mudanças em `tests/` acrescentam um mundo de fixture (`$CLW3`) e um mutante ao catálogo — a suíte rápida segue em ~5 min e o catálogo cresceu de 300 para 301, +0,3%. |
| Test Coverage | B | O que foi feito aqui é forte e eu o medi em vez de o aceitar: o mutante novo mata **exatamente uma** asserção na suíte INTEIRA (a nova), o comentário de exclusividade que o `R7` mudou de lugar é verdadeiro (três asserções, dois sensores, medidas uma a uma), as 301 âncoras estão vivas e o mutante que o `R6` esqueceu de matricular foi matriculado. O que segura o `A` são dois achados da MESMA classe que a missão persegue, ambos reproduzidos. **(a)** O `R7` fechou **metade** do achado #2 da r2: mudar o par de admissão para o mundo `$CLW3` tornou o termo `judge:` real, mas o termo `human:` é uma **constante** — `sdd autonomy` roda do cwd `$FIX` enquanto a linha nasce em `$CLW3`, e `ledger_row_is_local` a descarta como `other_repo` antes de qualquer classificação. Sabotando só o `is_close` do leitor humano, duas asserções vizinhas morrem e `both readers admit the close row` fica **`ok`** — numa asserção cujo título diz "both readers" e cujo comentário jura "in both programs, over the SAME file". É a testemunha-constante e o comentário-que-afirma-paridade, as duas regras que este repo tem por escrito. **(b)** A outra metade do `R6` não tem sensor nenhum: trocar `see $close_logs` de volta por `see $logfile` deixa a suíte inteira VERDE, rc 0. Mais três LOW da mesma vizinhança. Viraram `R8`. Não é `C` porque a cobertura **cresceu** de verdade nesta rodada e eu provei cada ganho sob sabotagem; é `B` porque duas asserções afirmam medir mais do que medem. |
| Documentation | B | Os comentários que o round escreveu são do melhor padrão do repo: nomeiam o achado que os fundou, dizem o que foi MEDIDO e não o que se supõe, e o do `$close_logs` explica por que `$logfile` tem 0 byte justamente quando alguém o lê. O `20-handoff-exec.md` é honesto ao ponto de registrar contra si mesmo que o `R6` definiu um mutante sem matriculá-lo. Contra isso, três coisas. O drift herdado ganhou uma **terceira** âncora e ela está dentro do código: `bin/sdd:6295` diz "closes the sum over all six" e `:6297` chama `$closes` de "The SIXTH bucket", enquanto o `$meta` que o `R2` desta própria missão criou é o **sétimo** e é somado — a mesma frase de `docs/pipeline.md:851` e `docs/failure-modes.md:115`. A tabela de schema (`:829-830`) segue dizendo `on escalation rows` sem nomear as linhas `event:"close"`. E o comentário do par de admissão promete "in both programs" sobre uma asserção que mede um programa só. O primeiro e o segundo vão para a DOCS com âncora exata; o terceiro morre junto com o `R8`. Prosa não compra rodada, e o gate tolera `B` aqui. |
| **Overall** | **B** | A rodada andou, e mais do que qualquer uma antes dela: os sete achados da r2 fecharam ou foram endereçados, `Error Handling` subiu `C → A`, `Code Quality` subiu `B → A`, nenhuma letra regrediu, e os critérios abaixo de `A` caíram de 4 para 2 — dos quais um (`Documentation`) o gate tolera. O laço estava funcionando. Ela não fecha porque os dois consertos da r2 que envolviam **instrumento** foram entregues pela metade, e as duas metades que faltam são exatamente o que a missão existe para matar: uma asserção cujo título promete dois leitores e mede um, e um conserto que nada segura. Nenhum dos dois é redesenho — é um `R8` de lote num arquivo de sensor. ⚠️ Mas `REVIEW_MAX_ITER=3` e esta é a r3: não há orçamento de rodada para re-avaliar o `R8` sem a porta humana. A decisão, com os fatos dos dois lados, está na pendência 1. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | O termo `human:` da asserção que o `R7` moveu é uma **constante**: `sdd autonomy` roda do cwd `$FIX` e a linha de `close` nasce em `$CLW3`, então `ledger_row_is_local` a descarta como `other_repo` antes de classificar, e o leitor humano nunca poderá imprimir `unrecognized` — sabotar só o `is_close` dele deixa a asserção `ok`. O `R7` fechou metade do achado #2 da r2, com título e comentário prometendo os dois leitores | `tests/check-autonomy.sh`, `both readers admit the close row…`; causa em `bin/sdd:2324` (`ledger_row_is_local`) e `bin/sdd:6145` |
| 2 | MEDIUM | A outra metade do `R6` — o conserto do achado #3 da r2, as três mensagens de falha do `cmd_close` que passaram a nomear os três arquivos — foi entregue **sem sensor nenhum**: revertê-la deixa a suíte inteira verde, rc 0, e nenhum mutante do catálogo a alcança | `bin/sdd:7631` (`close_logs`), lido em `:7660`, `:7669`, `:7672` |
| 3 | LOW | O piso `armed:` não é independente da propriedade que ele guarda: `CLOSE_DIRTY_ARMED` é lido do `.err`, que **só existe por causa do conserto**, então sob o mutante o piso responde `armed:false` — "o veneno nunca foi armado" exatamente no mundo em que ele disparou. A combinação `armed:true pure:false` é inalcançável, e é justamente ela que o comentário diz que o piso existe para nomear | `tests/check-autonomy.sh`, `CLOSE_DIRTY_ARMED` |
| 4 | LOW | O conserto do achado #5 da r2 (o quarto escritor em `autonomy_no_data`) também não tem sensor: a única asserção sobre essa frase lê o prefixo `no data: the ledger at `, nunca a lista de escritores, e reverter a sentença para três escritores passa verde. O comentário ao lado declara a regra "Writer added to the runner ⇒ writer added to this sentence" sem instrumento atrás dela | `bin/sdd:5935-5940`; asserção em `tests/check-autonomy.sh:4226-4228` |
| 5 | LOW | `CLOSE_DIRTY_PURE` pergunta a pureza do stream com `jq -e . "$arquivo"`, e o `-e` faz o rc depender do ÚLTIMO valor: um arquivo 100% JSON cujo último valor é `null`/`false` responde 1 exatamente como um arquivo sujo. Falha FECHADA hoje (a última linha do fixture é o objeto `result`), então é robustez e não fail-open | `tests/check-autonomy.sh`, `CLOSE_DIRTY_PURE` |
| 6 | LOW | `bin/sdd:6295` diz que a aritmética do leitor humano "closes the sum over all six" e `:6297` chama `$closes` de "The SIXTH bucket", mas o `$meta` criado pelo `R2` desta missão é o **sétimo** bucket somado — a mesma frase podre do achado #6 da r2, uma terceira vez e agora dentro do código | `bin/sdd:6295`, `bin/sdd:6297` |
| 7 | LOW | `cmd_kaizen` carimba `AUTONOMY_INVOCATION="run"`, então o quarto escritor que a frase nova nomeia não é distinguível pelo campo que nomeia o escritor: o ledger tem três valores de `invocation` (`run`, `retry`, `close`) para quatro escritores. A frase está certa sobre QUEM escreve; o campo é que não diz | `bin/sdd:7287` contra `bin/sdd:5935` |

### Como o #1 foi reproduzido

A régua é a diferencial: sabotar **só** o leitor humano e exigir que uma asserção que promete os dois
leitores fique vermelha. Numa sandbox fiel (`bin tests templates config agents` + `CLAUDE.md TODO.md`
+ `docs/adr`, rodada com `SDD_MUTANT=1`), sabotando a linha 6145 — a definição do `cmd_autonomy` — e
deixando a 6565 — a do `kaizen_series` — intacta:

```
md5 antes    0db5f1d1e7d881db9fc0cf481153ae64
6145:    def is_close: .event == "close";   →   def is_close: .event == "zzzz";
6565:    def is_close: .event == "close";   (intacta)
md5 depois   672ba4378f6e464a4805cbe9256d3da8      ← a sabotagem ENTROU

  FAIL  the human reader does not call the recorded closure unrecognized
  FAIL  it names the closure instead, so nothing leaves the accounting in silence
  ok    both readers admit the close row instead of filing it as unrecognized   ← FICOU VERDE
```

Duas asserções vizinhas — que medem o leitor humano de verdade — morrem, e a que se chama "both
readers" sobrevive. A causa é o cwd: `CLOSE_AUT="$( "$SDD" autonomy … )"` roda do `$FIX`, enquanto a
linha de `close` nasce com `repo` igual a `$CLW3`; `ledger_row_is_local` a descarta como `other_repo`
**antes** de qualquer classificação, e o comando cai no ramo "none of the N row(s) … were born in
this repo", que não imprime linha de `unrecognized` haja o que houver. O piso novo (`floor: the close
admission pair reads a ledger carrying a close row`) prova que a linha está no **arquivo**, não que o
leitor humano a lê — por isso ele não fecha este buraco.

Sabotando os **dois** programas a asserção morre (medido: `expected human:0 judge:0`, `got human:0
judge:1`) — e a decomposição mostra que quem se moveu foi só o `judge:`. O remédio é de uma linha:
rodar o leitor humano dentro do repo da linha, `( cd "$CLW3" && "$SDD" autonomy )`.

### Como o #2 foi reproduzido

Duas medições, e a primeira sozinha já basta — nenhum arquivo de teste cita as palavras que o
conserto acrescentou (`grep -rn 'raw stream:' tests/*.sh` → nada; a única asserção sobre as mensagens
de `close`, `tests/check-gates.sh:3323`, lê `UNVERIFIED` e `is still open`, ambos intocados). A
segunda é a régua do repo — degrade a regra e exija vermelho:

```
md5 antes   0db5f1d1e7d881db9fc0cf481153ae64
$ sed -i 's/see \$close_logs/see $logfile/g' "$S/bin/sdd"
md5 depois  aeb6c6a8f89e0633607dc5a1c80aebbb     ← a sabotagem ENTROU
$ ( cd "$S" && SDD_MUTANT=1 tests/run-all.sh )
rc=0        ← nenhum FAIL. A suíte inteira sobrevive ao conserto desfeito.
```

Isto não é o mesmo que dizer que as mensagens não têm teste: `check-gates.sh:3289` e `:3325` já
asseveram os **marcadores**. O que não tem probe é exatamente o que o `R6` acrescentou.

### Como o #5 foi reproduzido

```
$ printf '{"a":1}\n{"b":2}\n'  > pure_ok.jsonl    ; jq -e . pure_ok.jsonl    → rc 0   (puro)
$ printf '{"a":1}\nnull\n'     > pure_falsy.jsonl ; jq -e . pure_falsy.jsonl → rc 1   (PURO, e mesmo assim 1)
$ printf 'notjson\n{"a":1}\n'  > dirty.jsonl      ; jq -e . dirty.jsonl      → rc 5   (sujo)
```

O ramo que a asserção quer distinguir é o 5; o `-e` mistura o 1 do último valor falso com ele. A
grafia que pergunta só o que ela quer é `jq . "$f" >/dev/null 2>&1` (sem `-e`), ou `jq -e 'true'`.

### Como o #6 foi reproduzido

Os buckets que fecham a soma contra o `total=` do shell são sete, todos em `bin/sdd:6426-6452`:
`$skipped`, escalations, `$closed`, `$closes`, `$stray`, `$meta`, mais as sessões comparáveis. A
asserção que prova que o sétimo entra na conta existe e passa:

```
$ grep -cF '  ok    the buckets still sum to the header total (a judge KAIZEN row)' /tmp/r3-suite.log
1
$ grep -n 'all six\|SIXTH bucket' bin/sdd
6295:    # closes the sum over all six.
6297:    # The SIXTH bucket, and it exists for exactly the reason the fifth does, one event later: …
```

O código conta sete e o comentário diz seis. É prosa, e por isso vai para a DOCS e **não** para um
`R<n>` — mas é a terceira âncora da mesma frase, e quem for consertar `docs/pipeline.md:851` tem de
consertar esta no mesmo commit ou a divergência sobrevive dentro do arquivo que a missão saneou.

## Incrementos de conserto (R\<n\>)

| R\<n\> | Achado | Check escrito no checkpoint |
|---|---|---|
| R8 | lote dos achados #1 e #2 (MEDIUM) e #3, #4 e #5 (LOW) desta rodada | quatro termos numa expressão só, verificados na saída de `tests/run-all.sh`, mais a testemunha diferencial do #1 |

A linha exata que foi para o `checkpoint.md` está na seção seguinte. Os cinco entram num `R<n>` só
porque são baratos e da mesma classe (asserção de sensor, um arquivo), e a régua do repo é explícita:
abrir uma sessão de EXEC custa US$ 1–2, então cinco achados baratos em cinco sessões custam mais que
os consertos. Nenhum deles é CRITICAL ou HIGH, então nenhum precisa ser revertível sozinho.

⚠️ **Quem pegar o `R8` precisa de quatro coisas escritas aqui e não descobertas lá:**

1. **O #1 se conserta rodando o leitor humano dentro do repo da linha** — `( cd "$CLW3" && "$SDD"
   autonomy )` —, e a asserção só vale se, sabotando **só** o `is_close` do `cmd_autonomy`
   (`bin/sdd:6145`, deixando o do `kaizen_series` em `:6565` intacto), ela ficar **vermelha**. Hoje
   ela fica verde: esse é o vermelho que você tem de observar antes de escrever o conserto. Mutante
   novo no catálogo pela mesma porta.
2. **A asserção do #2 tem de medir o CONTEÚDO, não o marcador.** `check-gates.sh` já tem os mundos em
   que a mensagem sai (`:3289`, `:3325`). Basta exigir, na mesma saída capturada, que ela nomeie o
   stream cru **e** o `.err` — e a asserção só vale se, revertida para `see $logfile`, ela ficar
   vermelha. O #4 é o mesmo desenho sobre `autonomy_no_data`.
3. ⚠️ **Matricule todo mutante novo no `CATALOG`.** Definir não é matricular, e foi exatamente isso
   que o `R6` errou seis horas atrás — só a checagem de TAMANHO do `sdd health` viu. Depois de
   escrever: `grep -cE '^mut_' tests/check-mutation.sh` tem de bater com o tamanho do `CATALOG`.
4. ⚠️ **O carimbo de mutação vai morrer com este incremento.** `tests/` está dentro de
   `MUTATION_STAMP_PATHS`, então `./bin/sdd health` (20–50 min) roda **depois** do último commit de
   código do `R8`. Hoje o carimbo está VIVO (`79484a242bdfd073a6169581d3bffd4a`, recomputado nesta
   sessão) e o `gate_PR` tem o que exigir; depois do `R8` ele não terá, até o health correr.
   Aproveite a mesma passada para levar a linha do `TODO.md` da seção "Achados fora de escopo"
   abaixo, com `todo-findings` indo a `96` em `tests/health-baseline.txt`.

## O que virou incremento

- Achado #1 desta rodada (MEDIUM, o `human:` constante) — virou `R8`.
- Achado #2 desta rodada (MEDIUM, a metade do `R6` sem sensor) — virou `R8`.
- Achados #3, #4 e #5 desta rodada (LOW, mesma vizinhança e mesmo arquivo) — viraram `R8`.
- Achados #6 e #7 — **não** viraram `R<n>`: são prosa, e vão para a fase DOCS com âncora exata, ao
  lado dos #6 e #7 da r2. Prosa não compra rodada, e o gate tolera `B` em `Documentation`.

### Fechados pela rodada anterior, verificados aqui

Nada foi aceito pelo verde. Tudo foi medido pelo lado da falha, em sandbox fiel (`SDD_MUTANT=1`),
com o `md5sum` provando **antes** que a sabotagem entrou no arquivo:

- **`R6` — achado #1 da r2 (HIGH, o `2>&1` no stream que o próprio `cmd_close` parseia)** — fechado
  em `12012a5`. Prova: com `mut_RUN_close_stderr_into_stream` aplicado (md5 `0db5f1d1…` →
  `72cfcbbc…`), a suíte INTEIRA sai rc 1 com **exatamente uma** asserção vermelha — `close keeps
  stderr out of the stream it parses, so a noisy session still carries its money` —, que é a alegação
  de exclusividade escrita no comentário do mutante, agora medida em vez de afirmada. A premissa
  também foi re-verificada e não repetida: `jq` sobre um arquivo com uma linha não-JSON à frente sai
  5 sem imprimir nada. E o `2>"$errfile"` aproxima o `cmd_close` do contrato que
  `docs/pipeline.md:611` já declarava.
- **`R7` — achado #2 da r2 (MEDIUM, a asserção de admissão vazia)** — fechado **pela metade** em
  `6a8310a`, e a metade que fechou é real: sabotando `is_close` nos DOIS programas (md5 `0db5f1d1…` →
  `fd78f02c…`) a asserção agora responde `FAIL` onde a r2 a media `ok`, e o piso novo segue `ok` sob
  a mesma sabotagem. A metade que **não** fechou é o achado #1 acima.
- **`R7` — achado #4 da r2 (LOW, o comentário órfão)** — fechado em `6a8310a`, e o comentário que
  mudou de lugar é VERDADEIRO: sob `sed -i '/row(s) written by the judge excluded from the axis/d'`
  (md5 `0db5f1d1…` → `a426bc39…`) a suíte mata exatamente três asserções em dois sensores — `and it
  is named where the arithmetic can reach it`, `the buckets still sum to the header total (a judge
  KAIZEN row)` e `differential: ...and the meta row is excluded by NAME on both sides, table
  intact` —, que é palavra por palavra o que o comentário promete.
- **`R7` — achado #5 da r2 (LOW, o quarto escritor de ledger)** — fechado em `6a8310a` quanto ao
  texto (`awk '/It is written by/ && /sdd kaizen/{n++} END{print n+0}' bin/sdd` → `1`), mas sem
  sensor: é o achado #4 desta rodada.
- **A matrícula esquecida, achada pelo próprio EXEC** — `bde643d`. Verificado de fora:
  `grep -cE '^mut_' tests/check-mutation.sh` → 301, tamanho do `CATALOG` → 301, e **as 301 âncoras
  aplicadas uma a uma sobre uma cópia do `bin/sdd` de hoje: `live=301 dead=0`**. Nenhuma âncora
  morta, que é a classe que a `main` já carregou por dias entre os PRs #12 e #13.
- **As três métricas do `00-missao.md`**, re-medidas nesta sessão: `95 finding(s)` (metric 1),
  `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` → `0` (metric 2), e `guard: two harness versions
  in one slice make it unanswerable — sufficient false, and the reason is named` verde, com o gêmeo
  de uma versão só respondendo o contrário (metric 3).

## O que foi refutado

- **"O `R6` afrouxou a Jidoka ao declarar `close_logs` depois das duas guardas"** — refutado. A
  declaração está em `bin/sdd:7631`, **acima** de `kit_guard_check` (`:7632`) e `hat_guard_check`
  (`:7633`), então nenhum caminho lê a variável antes de ela existir; e quando uma das guardas
  devolve 3 a função retorna antes das mensagens, que é o comportamento que o `R5` comprou e que a
  asserção `close writes its row even when the hat guard fires, and still stops the line` segue
  exigindo (verde nesta rodada).
- **"O `.err` acrescentado ao `cmd_close` é um arquivo novo sem contrato documentado"** — refutado, e
  é o inverso: `docs/pipeline.md:611` já dizia "Plus `<PHASE>-<ts>.err` for the session's stderr"
  desde antes desta missão. Quem estava fora do contrato era o `2>&1` do `R5`. O `R6` não criou forma
  nova; parou de violar a que existia.
- **"O `cd "$CLW3"` novo em `check-autonomy.sh` é um `cd` relativo desguardado"** — refutado.
  `$CLW3` é `"$OUTSIDE/close-ledger-dirty-stderr"`, absoluto por construção, e a RULE 2 (`cdpath:`)
  do `check-pipefail.sh` declara operando **variável** como limite conhecido.
- **"O `R6` introduziu captura sob `set -e` ou forma SIGPIPE"** — refutado. `check-autonomy.sh` roda
  `set -uo pipefail` (sem `-e`) e toda captura nova carrega `|| true`; os greps novos tomam arquivo
  ou herestring, nunca `printf | grep -q`; as linhas novas do `bin/sdd` são atribuições `local`
  simples. `git diff c64f119..HEAD -- bin/ tests/ | grep -c awk` → `0`, então nenhuma classe negada
  multibyte do `mawk` entrou.
- **"A suíte encolheu: 973 asserções `ok` contra as 1058 que o `R7` registrou"** — refutado, e o erro
  era o meu instrumento. `grep -c '^  ok    '` responde 973 porque o `check-templates.sh` imprime com
  TRÊS espaços; `grep -cE '^ +ok'` responde **1058**, que bate. A suíte não encolheu — mas a
  divergência de grafia que me enganou virou achado fora de escopo, abaixo.
- **"O mutante `mut_RUN_close_stderr_into_stream` também casa a linha equivalente do `run_phase` e
  portanto é largo demais"** — refutado. `grep -cF '> "$streamfile" 2>"$errfile" || rc=$?' bin/sdd`
  → `1`; o `run_phase` escreve `2>"${logfile%.json}.err"`, grafia diferente. Aplicando a `sed` do
  mutante a uma cópia, o `diff` contra `HEAD:bin/sdd` mostra **uma** linha alterada, a 7617.
- **As cinco refutações da r2** seguem de pé; duas eu re-medi com instrumento mais forte (âncoras
  mortas: 0 de 301, não amostradas; carimbo: recomputado, não lido).

## Achados fora de escopo

- `tests/check-templates.sh` imprime `  ok   ` com três espaços, contra o `  ok    ` de quatro que o
  `CLAUDE.md` e o `templates/checkpoint.md` declaram para TODO sensor e exigem como âncora de todo
  Check; são 85 das 1058 asserções. A linha, pronta para o `TODO.md`:

  ```md
  - [ ] `check-templates.sh` imprime `  ok   ` (3 espaços) contra o `  ok    ` (4) que o `CLAUDE.md` declara para todo sensor — `tests/check-templates.sh` — 85 das 1058 asserções da suíte não casam com a âncora que todo Check é obrigado a usar; falha fechada (o Check dá 0), mas quem escrever Check sobre esse sensor perde tempo achando que a asserção sumiu — descoberto por `sdd-reviewer` na missão `20260911-o-juiz-nao-mente-sobre-a-janela` (2026-09-12)
  ```

  ⚠️ **Ela NÃO foi escrita no `TODO.md` por esta sessão, e a razão é medida, não preguiça:** a catraca
  do backlog mora em `tests/health-baseline.txt` (`todo-findings 95`), `tests/` está dentro de
  `MUTATION_STAMP_PATHS`, e registrar o achado agora mataria o carimbo de mutação que o `R7` acabou
  de escrever e que o `gate_PR` exige — exatamente a colisão que o `CLAUDE.md` documenta e que o
  `docs/failure-modes.md` descreve. Como o `R8` já vai matar o carimbo e obrigar um `./bin/sdd health`
  depois dele, **a rota barata é o `R8` levar esta linha junto**, no mesmo commit que toca `tests/`,
  com o `todo-findings` indo a `96`. Se o `R8` não for executado, o item fica com a fase DOCS. A
  decisão é da pendência 1.

## Pendências / Decisions for a Human

1. ⚠️ **TETO DE RODADAS ATINGIDO, e esta é a decisão que a missão precisa.** `REVIEW_MAX_ITER=3` e
   esta é a r3. A nota é `B` por dois achados MEDIUM de escopo fechado, e não há orçamento de rodada
   para re-avaliar o `R8` do jeito normal. Os dois lados, sem recomendação disfarçada de fato:
   - **A favor de fechar o `R8`:** os dois MEDIUM são a classe que a missão inteira existe para
     matar — instrumento que afirma medir o que não mede. Um deles é uma asserção cujo título diz
     "both readers" e que sobrevive à sabotagem de um dos dois leitores; o outro é um conserto que
     nada segura. Os dois foram reproduzidos, não suspeitados. E esta rodada já mostrou que a classe
     **reincide dentro do próprio round de conserto**: o `R6` definiu um mutante e não o matriculou,
     e só a checagem de tamanho do `sdd health` viu. Levar isso ao PR é assinar que a missão que
     consertou o juiz deixou dois instrumentos mentindo no arquivo que ela mesma tocou.
   - **Contra:** nenhum dos dois é fail-open ao nível da suíte — o leitor humano É medido por duas
     asserções vizinhas, e as mensagens de `close` têm os marcadores asseverados. O `R8` custa uma
     sessão de EXEC (US$ 1–2), mais um `./bin/sdd health` de 20–50 min para re-carimbar, mais — se
     você quiser a re-avaliação independente — uma quarta rodada que só existe pela porta humana.
   - **A porta, se a decisão for fechar:** `sdd run --phase REVIEW` é como um humano pede a rodada
     que destrava a missão; a foto de `rounds_before` é tirada **fora** da guarda do teto justamente
     para esse caso, então a r4 seria medida honestamente no ledger. A alternativa legítima é fechar
     o `R8` e **aceitar a r3 como a última rodada de nota**, registrando no PR que o `R8` não foi
     re-avaliado por um revisor que não o escreveu.
   - **Se a decisão for NÃO fechar o `R8`:** os achados #1 a #5 têm de ir para o `TODO.md` antes do
     PR, com a linha da seção anterior junto — não são achados que se percam, e o `TODO.md` é a única
     rota que sobra. O `todo-findings` iria a `97` e o health teria de rodar assim mesmo.
2. **`harness_mixed` veta `guard.sufficient` sem remédio nem override** — herdada da r1 e da r2,
   **ainda sem dono**, e nada nesta rodada a mexeu. Um `kit_sha` que atravessou um bump de harness
   continua não podendo ser graduado `melhorou`/`piorou` nunca, enquanto os dois irmãos estruturais
   (`degenerate_axis`, `window_broken`) apenas anotam. As três saídas seguem as da r1: (a) manter;
   (b) rebaixar a anotação, como `window_broken`; (c) manter o veto com override humano em artefato.
   Registro porque importa para a decisão 1: a missão vai fechar com ela em aberto.
3. **`BUDGET_MISSION_USD` e o laço de revisão a 66%** — as duas pendências herdadas do `00-missao.md`
   e do `05-verdict.md` seguem abertas e sem dono. Esta rodada não as toca. Nota de contexto para a
   decisão 1: esta missão é mais uma cujo laço de REVIEW consumiu as três rodadas do teto, e a
   pendência 3 é exatamente a que pergunta se isso deve continuar acontecendo.
