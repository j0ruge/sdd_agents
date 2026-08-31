---
missao: 20260831-a-rodada-que-andou
atualizado: 2026-08-31 12:00
---

# Checkpoint — A rodada que andou

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.** Um
> Check que grepa o texto solto responde "a asserção existe", nunca "a asserção passou".
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | A linha de REVIEW carrega `rounds_before`, `rounds_after` e `rounds_max` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the REVIEW row carries rounds_before, rounds_after and rounds_max' <<< "$o"` → `1` | done | 99f65bf |
| I2 | `def outcome` aprende que a rodada andou, com guarda de não-nulo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a REVIEW round that advanced reads advanced, never churned' <<< "$o"` → `1` | done | 60d2c88 |
| I3 | Caminho datado: linhas de REVIEW antigas recuperam a rodada do `gate_why` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a pre-schema REVIEW row recovers its round from gate_why' <<< "$o"` → `1` | done | c7c2e2e |
| I4 | A fase que fechou sem gastar sessão para de ler `refez` | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a phase that closed without a session does not read refez' <<< "$o"` → `1` | done | 715da79 |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-31 00:00 · `—` · Plano nascido pelo `sdd kaizen` sobre o veredito de `bf001fe`
  (`05-verdict.md` ao lado). `aprovacao:` vazio por contrato — o destravamento é
  `sdd approve 20260831-a-rodada-que-andou`.
- 2026-08-31 00:00 · `—` · **Estado do ledger ANTES da missão**, para o antes/depois do K8:
  `sdd autonomy --all-repos | grep bf001fe` →
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`.
  A série do mesmo sha: `labels {ok: 16, leve: 1, refez: 1}`, `advance_rate 0.91`,
  `escalations {}`, `guard.sufficient true`.
- 2026-08-31 00:00 · `I3` · **Ponto de corte da métrica.** Depois do I3 e ANTES do I4, rode
  `sdd autonomy --all-repos | grep bf001fe` e registre a saída aqui. Esperado:
  `22 advanced · 1 churned · 0 idle · 4% waste`, com `3 mission(s) · US$ 175.96` inalterados.
  Se não fechar, **pare** — não avance para o I4 com a métrica em aberto.
- 2026-08-31 00:00 · `I4` · **Condição de Jidoka escrita.** Se a asserção diferencial do I4 acusar
  diferença em qualquer campo além de `labels` — em especial nos cinco baldes de `excluded` —, o
  I4 vira `blocked` e missão própria. I1–I3 já entregam a métrica sozinhos.
- 2026-08-31 · `I1` · **A guarda de fase precisou de um mundo próprio, e o plano não previa isso.**
  Os dois primeiros probes que escrevi para ela (`a non-REVIEW row carries the three round fields
  as null`) nasceram verdes E sobreviveram à sabotagem: com a guarda removida nos dois sítios de
  leitura, a suíte ficou verde — 258 asserções, zero falha. Motivo medido: `current_phase()` avalia
  os gates em `$(...)`, então o `GATE_REVIEW_ROUNDS` do subshell morre e nenhum `gate_REVIEW` roda
  no shell pai daquele fixture. É a **mesma** armadilha que o irmão do EXEC documenta em
  `bin/sdd:4477`. Em vez de apagar a guarda, construí o mundo que a alcança — bloco
  `== a REVIEW round that passed does not follow the run into the next phase ==`, um gate de REVIEW
  que PASSA no shell pai seguido de uma volta que abre sessão de DOCS —, e aí os dois probes morrem.
- 2026-08-31 · `I1` · **Desvio do plano, declarado: DOIS mutantes em vez de um.** O plano nomeia
  `mut_RUN_review_rounds_photo_missing`; entrou também `mut_LEDGER_rounds_leak_across_phases`,
  porque a nota acima mostra que a guarda de fase é justamente a regra cujo probe nasce decorativo.
  Um terceiro (o escritor deixar de emitir os três campos) foi **recusado por redundância**: a mesma
  asserção o pega, e mutante custa uma suíte inteira.
- 2026-08-31 · `I1` · **Uma regra escrita foi removida por sabotagem, não por gosto.** O
  reset-on-entry de `GATE_REVIEW_ROUNDS`/`GATE_REVIEW_MAX` (irmão do que `gate_EXEC` tem) é
  inalcançável: a publicação é incondicional e fica acima de todo `return` da função, então
  sabotá-lo deixa a suíte verde. Removido, com o comentário dizendo **o que** o torna redundante e
  **o que** o traria de volta (mover a publicação para baixo de um `return`).
- 2026-08-31 · `I1` · **Inércia confirmada, que é a propriedade que torna o I1 seguro.**
  `./bin/sdd autonomy --all-repos | grep bf001fe` →
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`,
  idêntico ao estado registrado antes da missão. Nenhum leitor olha os campos novos até o I2.
- 2026-08-31 · `I2` · **A passada de sabotagem achou TRÊS regras sem probe depois de o bloco já
  estar verde.** O plano previa dois probes; os dois nasceram verdes e passaram. Degradando cada
  regra do braço, só duas das cinco morriam: `.rounds_after != null`, a direção (`>` virando `!=`)
  e `.moved != false` sobreviviam. Duas ganharam mundo (m23, sessão que não escreveu nada; m24,
  contagem que DESCEU); a terceira foi **removida** — ver a nota seguinte.
- 2026-08-31 · `I2` · **Uma regra escrita foi removida por sabotagem, com prova e não com
  impressão.** `.rounds_after != null` é tautologia neste braço: o campo possivelmente nulo fica à
  **esquerda** de `>`, e `null > 2` é FALSO em jq 1.7 (medido; no braço do EXEC ele fica à esquerda
  de `<`, onde `null < 2` é VERDADEIRO — daí as duas guardas lá e uma só aqui). Com
  `rounds_before` já guardado, nenhuma linha muda de `outcome`. O comentário diz o que a traria de
  volta: trocar os operandos ou virar a comparação.
- 2026-08-31 · `I2` · **Um probe de sabotagem foi descartado por sabotar a coisa errada.** A
  primeira tentativa contra a guarda de não-nulo trocou `elif (` por `elif ((` e desbalanceou o
  `jq`: **117 falhas** — erro de sintaxe, não medição. Refeita ancorada no braço inteiro, com
  `bash -n` antes de concluir, deu as 3 falhas certas. Conclusão de probe que não sabotou o que
  dizia sabotar não vale, nem quando aponta para o lado certo.
- 2026-08-31 · `I2` · **Desvio do plano, declarado: QUATRO mutantes em vez de dois.** Entraram
  `LEDGER_outcome_rounds_undirected` e `_moved_blind` além dos dois nomeados, porque são os probes
  nascidos da sabotagem e probe que o catálogo não alcança apodrece — medido em
  `20260818-lote-facil`. Cada um mata uma asserção que nenhum outro mata; nenhum é redundante.
- 2026-08-31 · `I2` · ⚠️ **Âncora podre consertada no próprio diff.**
  `mut_AUTONOMY_progress_ignored` ancorava na **linha inteira** do `def outcome:`. A linha cresceu
  com o braço novo e a âncora parou de casar — no-op silencioso, que a guarda rc-90 `cmp -s` pega,
  mas só depois de uma rodada inteira de catálogo. Re-ancorado no **braço**. Não virou item do
  `TODO.md` pela régua D15: falha FECHADA e sem consumidor fora da suíte ⇒ dívida declarada, e ela
  está no cabeçalho do mutante. (Registrar moveria `tests/health-baseline.txt` e mataria o carimbo.)
- 2026-08-31 · `I2` · **Inércia no ledger real, medida e não suposta.**
  `./bin/sdd autonomy --all-repos | grep bf001fe` →
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`,
  idêntico ao estado antes da missão. O porquê está medido: o ledger tem **25 linhas de REVIEW e
  `0` com `rounds_before`** — todas anteriores ao esquema. Quem move o número é o I3, e é lá que o
  ponto de corte da métrica tem de ser aferido.
- 2026-08-31 · `—` · ⚠️ **Ordem que custa 20 a 50 min quando se erra:** `./bin/sdd health`
  roda **depois do último commit de código**. Registrar achado no `TODO.md` move
  `tests/health-baseline.txt`, que mora dentro da chave do carimbo e o invalida.
- 2026-08-31 · `I3` · 🛑 **PONTO DE CORTE DA MÉTRICA: NÃO FECHOU. O I4 está `blocked` por isso, e
  a decisão que destrava é humana.** O que o plano mandava medir, medido:
  `./bin/sdd autonomy --all-repos | grep bf001fe` →
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96` —
  **idêntico ao estado antes da missão**, contra o `22 advanced · 1 churned · 4% waste` prometido.
  O I3 **não** falhou: o mecanismo funciona e está provado no ledger real. O que está errado é a
  **premissa factual do `00-missao.md` sobre qual linha é a churn de `bf001fe`**.
- 2026-08-31 · `I3` · **A prova, por diff e não por prosa.** Rodando o `bin/sdd` do HEAD anterior e
  o da árvore contra o MESMO ledger, exatamente três fatias se movem, todas de
  `0 advanced · 1 churned · 100% waste` para `1 advanced · 0 churned · 0% waste`: `d89ea43`,
  `e9a3681` e `353b4b1`. São, uma a uma, a forma que o `00-missao.md` descreve — `40-review-r1.md:
  Test Coverage = B`, `40-review-r1.md: Code Quality (Zen) = C`, `40-review-r2.md: Code Quality
  (Zen) = C`. Nenhuma outra célula, nenhum custo e nenhuma contagem de missão se moveram.
- 2026-08-31 · `I3` · **Por que `bf001fe` não se move, e é a leitura HONESTA.** A única linha de
  REVIEW reprovada da fatia tem `gate_why: "no 40-review-r<N>.md"` — a sessão não pousou arquivo de
  rodada **nenhum**. Recupera 0 rodadas, `0 > 0` é falso, e ela continua `churned` por mérito
  próprio: uma sessão que não pousou rodada não avançou rodada. Fazê-la ler `advanced` seria trocar
  um rótulo falso por outro, que é o que o próprio `00-missao.md` § Métrica (2) proíbe. A outra
  churn da fatia é a **QA** de `o-rascunho-fantasma-do-mount`, fora do alcance do I1–I3 por
  construção. Ou seja: a fatia `bf001fe` não contém nenhuma linha da forma que esta missão conserta.
- 2026-08-31 · `I3` · **A decisão do humano, em uma frase.** O instrumento está consertado e o
  número-alvo estava errado; escolher entre (a) reescrever a métrica (1) do `00-missao.md` para a
  medição real — as três fatias acima — e seguir para o I4, ou (b) outra coisa. Não é decisão de
  sessão headless: mexer no alvo para bater o alvo é o modo de falha que a Métrica (2) nomeia.
  I1–I3 estão entregues e são reversíveis por revert; o I4 é independente deles.
- 2026-08-31 · `I3` · **Desvio do plano, declarado: CINCO mutantes em vez de um.** Além do
  `LEDGER_historic_rounds_blind` que o plano nomeia, entraram `_repairs_photo`,
  `_no_file_is_a_round`, `_memory_blind` e `AUTONOMY_historic_sentence_before_comparability` —
  todos nascidos da passada de sabotagem, e cada um mata asserção que nenhum outro mata (medido:
  5, 2, 3, 4 e 1 asserções). Um sexto, o reset-restaurado, foi **recusado por redundância**: morre
  na mesma asserção do `_memory_blind`, que também mata a segunda.
- 2026-08-31 · `I3` · **DUAS regras do irmão do EXEC foram recusadas com mundo construído, não com
  gosto.** O plano dizia "as mesmas duas regras do EXEC, cada uma com fixture próprio"; a Gemba
  mostrou que nenhuma das duas transfere. Não há regra de `M` (o teto é config, não sai da prosa),
  e o reset num gate que passa é **ativamente nocivo**: as rodadas contam ARQUIVOS, arquivos nunca
  somem, então a contagem atravessa o pass — com reset, uma fase reaberta cuja sessão não pousou
  nada leria `1 > 0` como o progresso mais alto do ledger. O fixture `m10` é esse mundo e fica
  vermelho no dia em que alguém "restaurar" a simetria (medido: 1 asserção, exatamente ela).
- 2026-08-31 · `I3` · **A guarda ganhou uma segunda condição que o plano não previa.** É
  `rounds_before == null` **E** `rounds_after == null`. Sem a segunda, o caminho datado repara a
  linha cuja FOTO sumiu — que é a forma exata do `mut_RUN_review_rounds_photo_missing` — e deixa
  aquele mutante pontuando de graça. É a mesma classe de dano que o irmão do EXEC já pagou uma vez
  e consertou no escritor.
- 2026-08-31 · `I3` · ⚠️ **Três conclusões de sabotagem foram descartadas por não terem sabotado o
  que diziam sabotar**, e todas pela mesma armadilha: `perl -0pi -e` **interpola `$r`, `$k`, `$n`
  no lado de SUBSTITUIÇÃO**, o que desbalanceia o `jq` e produz 105 falhas — erro de sintaxe com
  fantasia de medição. A quarta e as seguintes usam `sed` (sem interpolação, que é o que o próprio
  `check-mutation.sh` já usa) mais um **piso**: o leitor tem de continuar imprimindo uma tabela
  sobre um ledger trivial antes de qualquer conclusão. Um **controle sem sabotagem nenhuma**
  explicou de quebra o `kaizen_fails=1` que aparecia em toda rodada — era `adr 0003`, artefato de
  a sandbox não copiar `docs/`, e não medição.
- 2026-08-31 · `I3` · **Uma regra ficou sem probe e está declarada, não escondida.** O `^` das duas
  regexes: desancorar o `test` deixa a suíte inteira verde, e o mundo que faria isso importar —
  `gate_why` nomeando `40-review-r<N>.md` fora do primeiro caractere — nenhum `gate_REVIEW` escreve
  hoje. O cabeçalho diz **qual mundo não consegui construir**, nunca que ele não existe, e por que
  a âncora fica (com `capture` ancorado, desancorar só o `test` mata o leitor em vez de errar a
  conta). Já o `test` em si NÃO é redundante e tem probe: trocado por `true`, 7 asserções morrem.
- 2026-08-31 · `I3` · **De lambuja, um item do `TODO.md` fechou** (`7a34766`): a frase de divulgação
  passou a contar sobre `comparable`. Medido no ledger real, a do EXEC caiu de **53 para 51** — as
  duas linhas anotadas que saíam depois como não-comparáveis. A catraca **não** desce: o item fica
  no arquivo até o PR mergear e `check-todo.sh` segue em `87 finding(s)`, igual ao baseline.
- intervention: decisão do ponto de corte — o humano escolheu o caminho (a): a métrica (1) do `00-missao.md` foi reescrita para a medição real (as três fatias `d89ea43`/`e9a3681`/`353b4b1`; `bf001fe` inerte por mérito) e o I4 voltou a `pending` — EXEC — sem custo de sessão
- 2026-08-31 · `I4` · **O Jidoka do I4 NÃO disparou: a asserção diferencial fecha.** Duas fatias
  idênticas, uma com as linhas `gate_pass` e outra sem (o mesmo arquivo menos uma linha, via
  `grep -v`), comparadas campo a campo: `outcomes`, `advance_rate`, `moved_rate`, `cost_usd`,
  `sessions`, `missions`, `composition`, `escalations`, `guard` e os **cinco** baldes de `excluded`
  saem idênticos; só `labels` difere. O risco nomeado no plano era real e foi medido antes do
  conserto: sem a admissão na série, `excluded.unrecognized` respondia **1** — o juiz acusando bug
  do próprio kit por uma linha que o runner escreveu de propósito.
- 2026-08-31 · `I4` · **O mundo do writer teve de ser o laço QA⇄EXEC, e não uma bancada.** Não
  existe estado que mude entre um gate que reprova e a derivação seguinte **a não ser** que uma
  fase rode no meio — `run_check_cmd` memoiza e `current_phase` roda no mesmo shell. Logo "o gate
  passou sem sessão" só é alcançável indo **para trás** primeiro: QA registra bug + incremento de
  fix, `gate_QA` recusa, a derivação pousa em EXEC (fase anterior, incremento pendente), o EXEC
  fecha os dois, e a derivação seguinte acha `gate_QA` verde. É o desenho do pipeline, não uma
  contorção — e é letra por letra a história da célula `refez` da janela 2.
- 2026-08-31 · `I4` · **Uma regra nasceu com probe decorativo por regime de fixture, e foi
  consertada com um mundo e não com um remendo.** O one-shot (`gate_pass_logged`) sobreviveu à
  sabotagem porque o fixture parava em `--max-phases 3`: a linha é escrita no topo da volta que
  deriva REVIEW e `gate_failed[QA]` nunca é limpo, então uma corrida que para ali não diz nada
  sobre o marcador. Com a quarta volta (REVIEW passa, deriva DOCS) o mutante mata 2 asserções.
- 2026-08-31 · `I4` · **A regra do ramo derivado ganhou probe no fixture da DEGRADAÇÃO, que já
  existia.** Mover a chamada para fora do `else` deixava a suíte verde — nenhuma asserção olhava.
  O mundo que importa é o único caminho em que `force_phase` sobrevive para uma volta com fase
  reprovada atrás: o `PUBLISH_ON_REVIEW_BLOCKED=draft`, que pula para PR sobre um REVIEW cujo gate
  ainda reprova. Sem a regra, o runner grava que a fase que ele **desistiu de revisar** fechou
  limpa. Asserção nova lá, medida 0 → 1.
- 2026-08-31 · `I4` · **Uma asserção era vacuamente verde e o `. != null` é que a torna medição.**
  Em jq 1.7 `null | has("rc")` responde **false**, não erro (medido), então "e nenhum campo de
  sessão" passava sobre um ledger sem a linha. Mesma família do piso que este arquivo cobra em toda
  parte.
- 2026-08-31 · `I4` · **Uma regra ficou sem probe e está DECLARADA, não escondida.** O teste
  `sessions[$ph] > 0` — a condição que o humano nomeou no grill — é redundante hoje: `gate_failed`
  só é escrito nos dois sítios que incrementam `sessions`, então o teste seguinte já o implica, e
  sabotá-lo deixa a suíte verde. Fica porque decide **qual falha** o próximo escritor de
  `gate_failed` produz — armar o marcador no ramo `over_ceiling` (fase cujo teto veio do DISCO não
  abre sessão nenhuma) gravaria, sem ele, que uma fase fechou de graça numa corrida em que ela
  nunca rodou. O comentário diz qual mundo não consegui construir, nunca que ele não existe.
- 2026-08-31 · `I4` · **Desvio do plano, declarado: CINCO mutantes, e o que caiu foi o
  `phase_label`.** O plano nomeia `mut_RUN_gate_pass_row_missing` e
  `mut_LEDGER_phase_label_last_session_blind`; o segundo **não entrou**, por medição e não por
  gosto: as asserções que ele mata são subconjunto estrito das que `LEDGER_gate_pass_not_admitted`
  mata (os dois tiram o rótulo de `refez`; só o segundo move `unrecognized`). Mutante que não mata
  nada que outro não mate é a redundância que o `CLAUDE.md` manda remover. Entraram no lugar
  `RUN_gate_pass_ignores_own_session`, `RUN_gate_pass_off_the_derived_branch` e
  `LEDGER_gate_pass_unrecognized` — cada um é o **único** dono de uma asserção nomeada no seu
  cabeçalho. Um sexto (`is_escalation` aprendendo `gate_pass`) foi **recusado por sabotar a coisa
  errada**: ele mata o `jq` (chave `null` em `group_by(.kind)`), 7 asserções morrem de erro de
  sintaxe e não de medição.
- 2026-08-31 · `I4` · 🛠️ **O `sdd health` achou TRÊS âncoras podres, uma por incremento desta
  missão, e elas foram consertadas no commit `8322699` — não viraram achado do `TODO.md`.**
  `208 caught of 211`, `3 problem(s)`, e os três são `CATALOGUE-BROKEN` (rc 90, a guarda `cmp -s`):
  mutantes que **deixaram de mutar**, que é pior que sobreviver, porque pontuam zero em silêncio
  lendo na tela como mutante que funciona. `KAIZEN_series_escalations_dropped` ancorava a linha
  inteira da admissão da série (o I4 lhe acrescentou `or is_gate_pass`);
  `AUTONOMY_outcome_reads_moved_only` citava o `def outcome:` braço a braço (o I2 lhe acrescentou o
  braço da rodada); `RUN_retry_pending_before_null` ancorava a linha de argumentos do retry com `$`
  no fim (o I1 lhe acrescentou os três argumentos de REVIEW, e com eles a continuação `\`). O
  conserto é o mesmo dos três e já tinha sido ensinado pelo `mut_AUTONOMY_progress_ignored` dois
  incrementos atrás: **ancorar no menor fragmento que ainda nomeia a sabotagem**. Medido depois:
  os três aplicam, deixam o `bin/sdd` válido e matam 19, 32 e 1 asserções.
  ⚠️ **Nenhum incremento virou `blocked` e a razão é a régua, não a conveniência:** o `TEST_CMD`
  (`tests/run-all.sh`) estava e está **verde**, os quatro Checks passam, e o catálogo é opt-in fora
  do `TEST_CMD` desde `4c86712` exatamente para não trancar fase. Pela régua D15 também não vira
  item do backlog: falha **fechada** (quem a reportou foi a própria guarda) e sem consumidor fora
  da suíte ⇒ dívida **declarada**, no cabeçalho de cada um dos três mutantes. **Re-medido depois
  do conserto:** `./bin/sdd health --with-mutation` → `mutation: score: 211 caught, 0 known gap(s),
  of 211`, `mutation stamp written`, `kit healthy` (carimbo `829412c3ad9101d48b6c492b9cf42520`).
- 2026-08-31 · `I4` · **Métrica no ledger real, medida e não suposta.**
  `./bin/sdd autonomy --all-repos` → `d89ea43`, `e9a3681` e `353b4b1` em
  `1 advanced · 0 churned · 0% waste` (o que o I1–I3 entregou) e `bf001fe` inalterada em
  `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`, como
  a métrica (1) reescrita manda. O I4 é **inerte hoje**: `0` linhas `gate_pass` no ledger real, a
  frase de divulgação nova não aparece. O evento nasce aqui e povoa da próxima corrida em diante —
  a mesma propriedade que tornou o I1 seguro.

> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`.
>
> ⚠️ O marcador é **inglês e minúsculo**, como `pending`/`done`/`blocked`: é contrato, não prosa.
> O texto depois dos dois-pontos vai no idioma do `OUTPUT_LANG`, como o resto deste arquivo.
> Só conta quando abre a linha — `intervention` no meio de uma frase é prosa e não é contado.
>
> - intervention: <o que o humano teve de fazer> — <fase> — <custo, se houver>

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
