---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: EXEC
status: done
sessao: 10d842b1-sdd-exec-r8
data: 2026-09-12 22:10
gate: "tests/run-all.sh -> 'suite green', 14 sensores, 1061 asseracoes ok, 0 FAIL (1058 antes do R8; as tres novas sao o piso do leitor humano, a assercao das mensagens de close e a dos escritores do no_data); os 14 hashes (I1-I6, R1-R8) existem no git log. Check do R8: 1111 (a=1 piso novo, b=1 mensagens de close, c=1 escritores, d==e com 304 mutantes definidos e 304 matriculados). ./bin/sdd health -> 'kit healthy', rodado DEPOIS do ultimo commit de codigo (12b15b8): 'ok suite green', 'ok mutation: score: 304 caught, 0 known gap(s), of 304', 'ok mutation stamp written - gate_PR can see that THIS content ran green' (.sdd/logs/mutation-stamp = 784f83349f8eb5b45f54d505a441e715), 'ok all 8 gates have a mutation in the catalogue', 'ok provenance: all 3 fixtures match the installed skills', 'ok ratchet: 1 known debt(s), none new'. Os quatro vermelhos do R8 foram observados ANTES em sandbox fiel (SDD_MUTANT=1, md5 provando a entrada da sabotagem), cada um matando exatamente a assercao que o nomeia. Nenhuma linha pending no checkpoint."
---

# Handoff — EXEC — o juiz não mente sobre a janela

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

✅ **A EXEC está `done`: 14 incrementos (I1–I6 + R1–R8), nenhuma linha `pending`, suíte verde
(1061 ok / 0 FAIL) e `./bin/sdd health` → `kit healthy` com `304 caught of 304` carimbado
(`784f8334…`), escrito **depois** do último commit de código (`12b15b8`).**
As três rodadas de REVIEW foram absorvidas: r1 virou `R1`–`R5`, r2 virou `R6`/`R7`, r3 virou o lote
`R8`. O `R8` fechou as duas asserções que **afirmavam medir mais do que mediam** — um `human:` que
era constante por causa do cwd e um conserto de mensagem que nada segurava —, cada vermelho
observado antes em sandbox fiel.
⚠️ **`REVIEW_MAX_ITER=3` e a r3 foi a terceira: o `R8` não terá re-avaliação independente sem a
porta humana** (`sdd run --phase REVIEW`). A decisão, com os dois lados escritos, é a pendência 1
do `40-review-r3.md` e está repetida nas pendências deste arquivo.
A seção *Por que a linha parou* fica no arquivo como **histórico**: descreve um estado que já não
é o do disco. O estado de hoje é o desta seção e o das seções *Rodada r1*, *r2* e *r3* abaixo.

## Estado do repo

> ⚠️ Esta seção foi **reescrita** ao fim do `R8`. Os números do parágrafo de Jidoka mais abaixo
> (`286 of 289`, "sem carimbo") são o retrato de 12/09 06:40 e não descrevem o disco de hoje.

- **Branch:** `feat/o-juiz-nao-mente-sobre-a-janela` — local, **sem upstream** (nunca empurrada).
- **Último commit de código:** `12b15b8` `fix(tests): R8 — as duas asserções que prometiam medir
  mais do que mediam`.
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, 14 sensores, **1061** asserções `ok`, 0 `FAIL`.
- **Catálogo de mutação:** **304** mutantes definidos e **304** listados no `CATALOG=(` — a
  igualdade que o `R7` restabeleceu e que o `R8` manteve ao matricular os três no mesmo commit em
  que os definiu. Evidência do carimbo no `gate:` do frontmatter.
- **Backlog:** `TODO.md` com **96** achados; `tests/health-baseline.txt` em `todo-findings 96`. O
  achado novo é o da r3 (grafia do `ok` do `check-templates.sh`), que a própria r3 deixou para este
  commit porque a catraca mora dentro da chave do carimbo.
- **E2E:** `E2E_CMD=""` no `.sdd/config.sh` — o kit não tem jornada de navegador; a "jornada" deste
  repo é a linha de comando, e é por ela que a QA tem de andar (ver boot abaixo).

## Por que a linha parou

O `TEST_CMD` está verde e todos os hashes existem, então o `gate_EXEC` passaria; o que reprova é o
sensor que o `gate_PR` lê. Os dois defeitos são de incrementos **anteriores** ao I6, e cada dono
foi provado por `git log -S`, não suposto:

**A — três âncoras de mutante apodrecidas pelo próprio conserto que elas guardavam.** O catálogo
reporta `CATALOGUE-BROKEN: <slug>` / *"the mutation did not apply — did the anchor change in
bin/sdd?"*, que **não** é o mesmo que `NOT caught`:

| Mutante | O `sed` procura | Quem moveu |
|---|---|---|
| `KAIZEN_composition_session_unit` | `composition: ($rows \| group_by(.repo // "")` | **I2**, `7e6b3f5` |
| `LEDGER_gate_pass_unrecognized` | `def is_unrecognized: (is_session or is_escalation or is_gate_pass) \| not;` | **I4**, `aa3c0a2` |
| `LEDGER_gate_pass_not_admitted` | `and (.event == "session" or is_escalation or is_gate_pass)` | **I4**, `aa3c0a2` |

Os dois do `LEDGER` quebraram porque o I4 ensinou o quarto evento aos dois leitores e a linha real
hoje é `… or is_gate_pass or is_close)`. É o achado nº 1 do `TODO.md` acontecendo ao vivo:
*"âncora morta de mutante só aparece no catálogo inteiro"*.

**B — quatro mutantes definidos e nunca registrados.** `grep -c '^mut_' tests/check-mutation.sh`
responde **293**; o `CATALOG=(` tem **289**. Os quatro que faltam são exatamente os do I5
(`5e3c427`): `mut_KAIZEN_guard_harness_blind`, `mut_KAIZEN_guard_why_silent`,
`mut_KAIZEN_window_break_blind`, `mut_KAIZEN_window_ignores_verdict`. O `score:` **não** reclama
sozinho — `caught == of` continua verdadeiro sobre a lista encolhida; quem pega é a asserção de
piso do `sdd health`, que compara o que **rodou** com o que está **definido**.

**A causa comum, e é ela que interessa mais que os sete sintomas:** o catálogo é opt-in desde
`4c86712`, então rodá-lo é dever do incremento — e I2, I4 e I5 acrescentaram 12 mutantes
verificando cada um numa sandbox à mão, sem nunca rodar o catálogo inteiro. Sandbox por mutante
responde *"este mutante morde"*; só a passada completa responde *"a lista ainda é a lista"* e
*"nenhuma âncora apodreceu"*. As duas perguntas são diferentes e três sessões seguidas fizeram só
a primeira.

**Direção para a próxima sessão de EXEC** (é EXEC, não QA — nada aqui é bug de usuário):

1. re-ancorar os três `sed` na forma que o `bin/sdd` tem hoje (`tests/check-mutation.sh:837`,
   `:3020`, `:3036`), confirmando com `grep` no `bin/sdd` antes e depois;
2. acrescentar os quatro nomes ao `CATALOG=(` (`tests/check-mutation.sh:3274`);
3. provar que cada um dos sete **morde** — e que o `sed` mudou o arquivo, senão a conclusão é vazia;
4. só então `./bin/sdd health` (**20–50 min**), que escreve o carimbo e reabre o `gate_PR`;
5. voltar I2, I4 e I5 para `done` no checkpoint, **depois** do carimbo.

## O que foi feito

- `5956e80` — **I1.** As 11 linhas de fixture (`"repo":"/tmp…`) saem do
  `~/.sdd/autonomy-log.jsonl` com backup, e o runner passa a recusar escrever o ledger real a
  partir de um checkout sob `$TMPDIR`. Sem isto, todo número medido por I2–I5 seria ruído.
- `7e6b3f5` + `d93b9bd` — **I2.** O `$order` do `cmd_autonomy` e o `comparable_row` do
  `kaizen_series` param de divergir sobre a linha `gate_pass`; a paridade virou asserção
  **diferencial** (as duas saídas comparadas entre si sobre o mesmo arquivo), nunca o comentário
  que antes jurava *"same spelling on purpose, in both programs"*.
- `392f526` + `47113c7` — **I3.** `reopened` e a fronteira do laço de revisão leem a população que
  prometem, em vez de depender de a fase ter custado dinheiro.
- `aa3c0a2` + `659acf0` — **I4.** `sdd close` e `sdd retry` escrevem a linha de ledger que devem.
  O quarto evento `event: "close"` entrou pela **definição** (`is_close` nos dois leitores) e pelo
  contrato em `docs/pipeline.md`, no mesmo commit; a asserção do `close` é diferencial porque o
  comando tem dois braços e só um compra sessão.
- `5e3c427` + `a5d99a0` — **I5.** A guarda do juiz recusa fatia com **duas versões de harness** e
  publica `window_broken` como **instrumento**, não como cláusula de `sufficient` — pôr a ruptura
  dentro de `sufficient` reprovaria o veredito já escrito, que é gate insatisfazível.
- `4d9b7b8` — **I6.** Dez itens que não são fail-open e não têm consumidor fora da suíte saem do
  `TODO.md` e viram limite declarado no cabeçalho do sensor dono (sete) ou adiamento com evento de
  reabertura no `CONTEXT.md` (três, Y1–Y3). Catraca `todo-findings 105 → 95`, entrada de
  antes/depois no `KAIZEN_LOG.md`.

## Rodada r1 da REVIEW — R1 a R5 (acrescentado ao fim do `R5`)

A r1 achou 12 defeitos (4 HIGH, 3 MEDIUM, 5 LOW) e escreveu cinco linhas `R<n>`; cada uma foi
fechada por uma sessão de EXEC própria, em TDD, com o vermelho observado antes do conserto.

| `R<n>` | Achado | O que consertou | Commit |
|---|---|---|---|
| R1 | #1 — a linha `close` entrava no total do cabeçalho de `sdd autonomy` e não caía em bucket nenhum | Sexto bucket (`$closes`) com frase própria; `assert_bucket_sum` passou a somar seis termos | `1563bc8` |
| R2 | #2 — a exclusão `$meta` (KAIZEN) inflava o mesmo total, e o comentário ao lado afirmava o contrário | Sétimo termo + `$local_total` somando `$meta` de volta; comentário reescrito para dizer o que o código faz | `a26d489` |
| R3 | #3 — `window_missions_stranded` falhava aberto na missão que atravessa o sha julgado | Grafia positiva (`select(.kit_sha != $latest)`) e o regime de fixture `winstraddle`, que não existia | `154f58f` |
| R4 | #4 — os quatro campos novos da guarda não tinham leitor | `agents/sdd-kaizen.md` aprendeu a ler `why`, `harness`, `window_missions_stranded` e `window_broken`; espelho por `sdd install --force` | `477cb9a` |
| R5 | lote #6–#9 — custo na linha de `close`, porta do chapéu, regime de `close` no juiz, contagens podres | Abaixo | `c78b167` |
| R5 | o defeito que o `sdd health` do próprio R5 revelou | Âncora do `mut_RUN_close_writes_no_row` deixou de soletrar a lista de argumentos | `ed8e1ec` |

**O que o `R5` mudou, achado a achado:**

- **#6** — em `cmd_close`, o `return 3` do chapéu cruzado corria **entre** a sessão paga e o
  `autonomy_close_row`: o close que mais vale contar, aquele cuja sessão cruzou o próprio chapéu,
  era o único que o ledger nunca via. O `return 3` passou para depois da linha; o rc não mudou.
- **#7** — a linha de close dizia **qual** sessão foi gasta e calava **quanto** custou, então a D12
  (US$ por PR mergeado) lia todo close da história do kit como grátis. O braço passou a streamar
  como toda outra sessão e lê `stream_summary` + `hat_init_facts` — as **mesmas duas definições**
  do `run_phase`, nunca um segundo parser. Entram `cost_usd`, `dur_s`, `turns`, `cache_read` e
  `harness`; vazio vira `null` por `tonumber?`, nunca `0`.
- **#8** — não havia fixture de `close` no `check-kaizen.sh`, e os dois mutantes existentes
  arrancavam `is_close` **junto** com `is_gate_pass`: quem os matava era a metade `gate_pass`.
  Entram três mutantes estreitos — um por **definição** que a closure atravessa — e **dois
  regimes**, porque as três definições leem populações diferentes.
- **#9** — quatro frases que o próprio branch invalidou (a quarta achada ao medir, não listada pela
  r1): `the eight call sites` (são dez — o número saiu do comentário e virou `grep`), `written by
  'sdd run' and 'sdd retry'` (o `sdd close` também escreve), um comentário citando item de backlog
  que o I6 apagou, e o `mut_LEDGER_gate_pass_not_admitted` jurando ser pego por duas asserções "e
  por mais nada" quando são dez.

**Os cinco achados que NÃO viraram `R<n>`** continuam registrados no `40-review-r1.md` e em lugar
nenhum mais: #5 é decisão humana (abaixo, em Pendências) e #10, #11 e #12 são LOW de baixo valor. A
rota normal seria o `TODO.md`, e ela foi fechada **de propósito** nesta missão pelo preço do
carimbo — item novo move `tests/health-baseline.txt`, que está dentro da chave.

## Rodada r2 da REVIEW — R6 e R7 (acrescentado ao fim do `R7`)

A r2 achou 7 defeitos (1 HIGH, 2 MEDIUM, 4 LOW) e escreveu duas linhas `R<n>`. Os quatro Checks
foram medidos **vermelhos** pela própria rodada antes de virarem linha (`0 0 0 0`).

| `R<n>` | Achado | O que consertou | Commit |
|---|---|---|---|
| R6 | #1 (HIGH) e #3 — `cmd_close` jogava `2>&1` dentro do `.jsonl` que ele mesmo parseia; uma linha de stderr aborta o `jq` e a linha de `close` voltava a `null` em custo, turns, cache e harness | `.err` irmão, a forma que o `run_phase` já usa; `$close_logs` nomeia os três arquivos nas mensagens de falha | `12012a5` |
| R7 | #2, #4 e #5 — asserção de admissão vazia, comentário órfão do mutante `meta`, `autonomy_no_data` com um escritor a menos | Abaixo | `6a8310a` |
| R7 | o defeito que o `sdd health` do próprio `R7` revelou | `mut_RUN_close_stderr_into_stream` matriculado no `CATALOG` | `bde643d` |

**O que o `R7` mudou, achado a achado:**

- **#2 (MEDIUM, fail-open)** — `both readers admit the close row instead of filing it as
  unrecognized` morava no braço *já-Done*, três linhas depois de o `kitguard_reset` truncar o
  ledger e logo **abaixo** da asserção que prova `rows:0`: pedia aos dois leitores que admitissem
  uma linha que não estava no arquivo. Sobre um ledger vazio os dois respondem `0 unrecognized`
  independentemente do que admitam. O par mudou para o mundo `$CLW3` (o do stderr sujo, cujo ledger
  **carrega** a linha) e ganhou um piso que o diz —
  `floor: the close admission pair reads a ledger carrying a close row`.
  **Medido nos dois sentidos**, que é a metade que faltava: sob a sabotagem estreita de `is_close`
  nos dois programas (`is_unrecognized` e o eixo do juiz, sem `is_gate_pass` junto, com o md5
  provando antes que o `perl` mudou o arquivo) a asserção agora responde **`FAIL`** onde a r2 a
  mediu **`ok`**, e o piso segue `ok` — o vermelho nomeia a causa em vez de o sensor sumir.
- **#4 (LOW)** — o comentário de `mut_LEDGER_meta_bucket_unnamed` estava colado acima do par
  comentário+função de `mut_LEDGER_stranded_by_subtraction`: lido de cima para baixo, o catálogo
  descrevia um mutante com a prosa de outro. Voltou para cima da própria função, sem mudar palavra.
- **#5 (LOW)** — `autonomy_no_data` nomeava três escritores do ledger e há **quatro**: `sdd kaizen`
  roda a fase KAIZEN pelo `run_phase`, que escreve `autonomy_session_row` como qualquer outra. A
  frase dizia a um humano *"você nunca rodou esses três"* sobre um ledger em que o próprio laço do
  juiz já havia escrito. Mesma classe do #9 da r1, reintroduzida no commit que a fechou.

### ⚠️ O achado que o `sdd health` do `R7` produziu (e a régua que ele deixa)

Ao carimbar depois do último commit de código, a **primeira** passada reprovou:
`mutation: the catalogue ran 300 of the 301 mutant(s) tests/check-mutation.sh defines`.

`mut_RUN_close_stderr_into_stream` nasceu **completo** no `R6` — função, âncora viva e comentário
medindo a sabotagem — e ficou **fora do `CATALOG`**. O laço itera o `CATALOG`, então o mutante
nunca correu e o `score:` seguia dizendo `300 caught of 300`: a única asserção que prova o conserto
do HIGH da r2 não tinha nada, no CI, exigindo que ela morresse sob sabotagem. **Definir não é
matricular**, e é a mesma classe que a missão inteira persegue — o instrumento afirmando medir o
que não mede. O `R6` mediu o mutante à mão numa sandbox e concluiu dali: a conclusão estava certa,
a matrícula é que não aconteceu. Quem viu foi a checagem de **TAMANHO** do `sdd health`
(`total != defined`), que existe exatamente para o catálogo estreitado continuar imprimindo
`caught == of`. A âncora foi re-conferida contra o `bin/sdd` de hoje **antes** da matrícula (o
`sed` muda a árvore), para ela não entrar morta.

> **Régua para a próxima sessão que escrever mutante:**
> `grep -cE '^mut_' tests/check-mutation.sh` tem de bater com o tamanho do `CATALOG`.

**Os dois achados que NÃO viraram `R<n>`** — #6 e #7 da r2 — são **drift de documentação** e estão
endereçados à fase **DOCS** com âncora exata: `docs/pipeline.md:851` e `docs/failure-modes.md:115`
ainda enumeram **cinco** buckets (hoje são sete), e a tabela de schema do `docs/pipeline.md`
(`:829-830`) diz `on escalation rows` para `cost_usd`/`turns` sem nomear as linhas `event:"close"`,
que passaram a carregá-los. Prosa não compra rodada, e o gate tolera `B` em `Documentation`.

## Rodada r3 da REVIEW — R8 (acrescentado ao fim do `R8`)

A r3 fechou em **B** com 7 achados (2 MEDIUM, 5 LOW), nenhuma letra regredida contra a r2 e duas
subidas (`Error Handling` C→A, `Code Quality` B→A). Cinco viraram um `R<n>` de lote; os dois de
prosa (#6 e #7) foram endereçados à fase DOCS, ao lado dos #6/#7 da r2.

| `R<n>` | Achado | O que consertou | Commit |
|---|---|---|---|
| R8 | #1 e #2 (MEDIUM) + #3, #4 e #5 (LOW) — duas asserções que afirmavam medir mais do que mediam, e três de robustez na mesma vizinhança | Abaixo, achado a achado | `12b15b8` |

**Os dois MEDIUM eram a mesma classe que a missão inteira persegue: instrumento que afirma medir o
que não mede.**

- **#1 (MEDIUM) — o `human:` era uma CONSTANTE.** O `R7` fechou metade do achado #2 da r2: mudar o
  par de admissão para o mundo `$CLW3` tornou o termo `judge:` real, mas o `human:` não. A causa é o
  **cwd**: `sdd autonomy` rodava do `$FIX` enquanto a linha de `close` nasce em `$CLW3`, então
  `ledger_row_is_local` a descartava como `other_repo` **antes** de qualquer classificação e o
  comando caía no ramo *"none of the N row(s) … were born in this repo"*, que não imprime linha de
  `unrecognized` haja o que houver. Numa asserção cujo título diz *"both readers"* e cujo comentário
  jura *"in both programs, over the SAME file"*. Conserto de uma linha — o leitor humano roda dentro
  do repo da linha — mais um **segundo piso**, `floor: the human reader reads the repo the close row
  was born in`, que existe porque uma mudança futura de cwd devolveria o termo à condição de
  constante em silêncio.
- **#2 (MEDIUM) — a outra metade do `R6`, entregue sem sensor nenhum.** As três mensagens de falha
  do `cmd_close` que passaram a nomear os três arquivos não tinham probe: revertê-las para
  `see $logfile` deixava **a suíte inteira verde, rc 0**. A asserção nova mede o **conteúdo** e não
  o marcador (`check-gates.sh` já tinha os mundos em que a mensagem sai), e dos seus três termos
  só `raw:` e `err:` decidem algo — `summary:` era verdadeiro sob as duas formas, por isso é piso.
- **#3 (LOW) — o piso `armed:` não era independente da propriedade que guardava.**
  `CLOSE_DIRTY_ARMED` lia o `.err`, que **só existe por causa do conserto**, então sob o mutante
  respondia `armed:false` — *"o veneno nunca foi armado"* exatamente no mundo em que ele disparou —,
  e o par `armed:true pure:false` que o comentário promete era inalcançável. A testemunha passou
  para o lado do **stub** (um marcador que ele escreve na linha antes de imprimir em stderr, num
  diretório que nenhuma redireção do `cmd_close` alcança). Medido: sob
  `mut_RUN_close_stderr_into_stream` a asserção agora lê `armed:true pure:false`, onde antes lia
  `armed:false`.
- **#4 (LOW) — o quarto escritor do `autonomy_no_data` também não tinha sensor.** A única asserção
  sobre a frase lia o **prefixo** (`no data: the ledger at `) e nada do corpo. A nova colhe os nomes
  da **saída** e não da fonte, com `grep -oE "'sdd [a-z]+'" | sort -u`, de modo que um escritor
  perdido **e** um escritor inventado movem o termo.
- **#5 (LOW) — `jq -e` era a pergunta errada.** O `-e` faz o rc depender do **último valor**: um
  arquivo 100% JSON terminado em `null`/`false` sai 1, indistinguível do 5 de um arquivo sujo, que é
  o único rc que a linha quer. Falhava **fechada** hoje (o fixture termina no objeto `result`), logo
  era robustez e não fail-open. Sem `-e`, o rc diz "parseável" e nada mais.

**Os quatro vermelhos foram observados ANTES**, em sandbox fiel (`bin tests templates config
agents` + `CLAUDE.md TODO.md` + `docs/adr`, rodada com `SDD_MUTANT=1`), com `md5sum` provando que a
sabotagem entrou no arquivo — e cada um matou **exatamente** a asserção que o nomeia:

| Sabotagem | O que morreu |
|---|---|
| `is_close` só no `cmd_autonomy` (primeira das duas ocorrências, `perl -0pi` sem `/g`) | as duas asserções vizinhas **mais** `both readers admit the close row`, que era a que a r3 mediu **`ok`** |
| `see $close_logs` → `see $logfile` | `close names the raw stream and the stderr beside the summary` |
| a frase perde `and 'sdd kaizen'` | `autonomy_no_data names every writer the runner has` |
| o leitor humano volta a rodar do `$FIX` | `floor: the human reader reads the repo the close row was born in` |

⚠️ **A régua que o `R7` deixou foi cumprida: definir não é matricular.** Os três mutantes novos
(`RUN_close_admission_human_reader_only`, `RUN_close_logs_summary_only`,
`RUN_no_data_drops_a_writer`) entraram no `CATALOG` no mesmo commit, e a conta bate nos dois lados —
`grep -cE '^mut_'` → **304**, tamanho do `CATALOG` → **304** —, com o `sdd health` confirmando
`304 caught, 0 known gap(s), of 304` numa passada só. A quarta sabotagem da tabela acima não vira
mutante de catálogo **por construção**: ela degrada o arquivo de teste, e o catálogo muta o
`bin/sdd`. Ela vive no comentário do piso, como limite declarado.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint.md` | A tabela: as **14 linhas** (I1–I6, R1–R8) `done`, nenhuma `pending` |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/checkpoint-notas.md` | As notas de execução (append-only); as de I6 explicam o corte do décimo item |
| `docs/pipeline.md` | Contrato da **forma de linha** do ledger — quarto evento `close` — e da **forma da série** (`harness`, `window_broken`) |
| `CONTEXT.md` | Nova tabela **Decisões adiadas por YAGNI** (Y1–Y3), cada uma com o evento que a reabre |
| `KAIZEN_LOG.md` | Entrada de 2026-09-12: a régua D15 aplicada, 105 → 95 com a tabela item a item |
| `TODO.md` | **96** achados (o 96º é o da r3, a grafia do `ok` do `check-templates.sh`); a seção que se chamava "Adiados por YAGNI" foi renomeada porque ficou sem adiamentos |
| `tests/health-baseline.txt` | `todo-findings 96` — a catraca que morde nos dois sentidos |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/40-review-r1.md` | A rodada r1: os 12 achados, os 4 refutados e as pendências humanas |
| `tests/check-kaizen.sh` | Os dois regimes de `close` (`closein`, `closeaway`) e as três asserções do `R5` |
| `tests/check-mutation.sh` | **304** mutantes, 304 matriculados; os três estreitos de `close` do `R5`, o do stderr (`R6`, matriculado no `R7`) e os três do `R8` |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/40-review-r2.md` | A rodada r2: os 7 achados, os 5 refutados e o sinal de laço (`Error Handling` B→C) |
| `tests/check-autonomy.sh` | O mundo `$CLW3` (stub sujo) e, desde o `R8`, o par de admissão do `close` com **dois** pisos: o que prova a linha no arquivo e o que prova que o leitor humano lê o repo em que ela nasceu |
| `docs/handoffs/20260911-o-juiz-nao-mente-sobre-a-janela/40-review-r3.md` | A rodada r3: os 7 achados, as 6 refutações e a pendência do teto de rodadas |
| `tests/check-gates.sh` | Os nove regimes de `close` e, desde o `R8`, a asserção que lê o **conteúdo** das mensagens de falha (stream cru e `.err`), não só o marcador |

## Boot da próxima fase

✅ **A próxima fase é a QA.** A ressalva que ocupava este lugar ("a próxima fase é EXEC de novo")
foi resolvida: nenhuma linha do checkpoint está `blocked` ou `pending`, e o carimbo de mutação
existe (`304 caught of 304`, carimbo `784f8334…`, escrito depois de `12b15b8`). O que segue é o
boot da QA, atualizado ao fim do `R8`.

⚠️ **A decisão que a QA tem de saber que está pendurada, porque ela decide se existe uma r4:**
`REVIEW_MAX_ITER=3` e a r3 foi a terceira. O `R8` — os dois MEDIUM da r3 — foi escrito **depois**
da última rodada de nota, então nenhum revisor que não o escreveu o avaliou. A r3 deixou os dois
lados na sua pendência 1; a porta é `sdd run --phase REVIEW`, e a foto de `rounds_before` é tirada
fora da guarda do teto justamente para esse caso. A alternativa legítima é aceitar a r3 como a
última rodada de nota e registrar no PR que o `R8` não teve re-avaliação independente.

⚠️ **O que mudou no diff DEPOIS que este boot foi escrito** (rodadas r1, r2 e r3, `R1`–`R8`) e que
a QA tem de andar junto com os quatro pontos abaixo — do `R8`, três superfícies de linha de comando
seguem **idênticas** ao que o `R7` deixou (o `R8` é só sensor, com uma exceção: nenhuma mensagem do
`cmd_close` mudou de texto, apenas passou a ser medida):

5. **`sdd autonomy` — o cabeçalho volta a fechar com os buckets.** Eram cinco buckets e o total do
   cabeçalho contava linhas que nenhum deles nomeava (`close` e a exclusão `$meta` do juiz). Hoje
   são **sete termos** e a soma fecha. Confira somando os buckets impressos e comparando com o
   `N row(s)` do cabeçalho, sobre um ledger que tenha uma linha `close`.
6. **A linha de `close` carrega dinheiro.** `sdd close` agora streama como toda outra sessão:
   `cost_usd`, `dur_s`, `turns`, `cache_read` e `harness` entram na linha. Consequência para a QA:
   o log de close em `.sdd/logs/<missão>/CLOSE-*.json` passou a ter um **irmão** `.stream.jsonl`
   ao lado (o bruto), e o `.json` agora é o `result` destilado, não o blob do `--output-format
   json`. Quem lê aquele arquivo à mão vê uma forma diferente.
7. **`sdd close` que cruza o chapéu escreve a linha ANTES de parar a linha.** O rc continua 3.
8. **(r2/`R6`) O stderr do `sdd close` mudou de arquivo.** Ele ia para dentro do `.stream.jsonl` e
   agora vai para um `.err` **irmão**, a forma que o `run_phase` já usava. Consequência prática
   para a QA: quem for ler o diretório `.sdd/logs/<missão>/` de um close vê **três** arquivos
   (`CLOSE-*.json` destilado, `*.stream.jsonl` bruto e `*.err`), e as mensagens de falha do
   `sdd close` passaram a **nomear os três** em vez de mandar "see $logfile" — que tinha 0 byte
   quando a sessão morria antes do `result`.
9. **(r2/`R7`) `sdd autonomy` sobre um ledger vazio nomeia QUATRO escritores**, não três: a linha
   `no data:` passou a citar `sdd kaizen` junto de `sdd run`, `sdd retry` e `sdd close`. É texto
   que um humano lê, então é jornada: rode `SDD_STATE_DIR=$(mktemp -d) ./bin/sdd autonomy` e
   confira a frase.

**O que é user-visible neste diff.** Nada de navegador: o produto é a CLI `bin/sdd` e os artefatos
que ela escreve. As superfícies que mudaram, e que é por onde a jornada anda:

1. **`sdd kaizen` / a série do juiz** — ganhou dois campos publicados. A guarda recusa a fatia com
   mais de uma versão de harness e a série carrega `window_broken`. Confirmado no recorte real da
   janela 4 (`head -280` do ledger): `sufficient: true`, `harness: ["2.1.263"]`,
   `window_broken: true` com 3 missões encalhadas.
   ⚠️ **Não rodar `sdd kaizen` de verdade nesta branch** — o piso é 3 e ele commita na branch
   corrente. Para exercitar, use um ledger de fixture, como os probes fazem.
2. **`sdd autonomy`** — `reopened`, a fronteira do laço de revisão e a admissão da série agora leem
   a mesma população. Compare `sdd autonomy --by-mission` com `sdd kaizen --series` sobre o mesmo arquivo: a
   divergência que o I2 fechou aparecia exatamente aí.
3. **O ledger `~/.sdd/autonomy-log.jsonl`** — quarto evento `event: "close"`, e o arquivo real foi
   limpo de 11 linhas de fixture (backup ao lado). Toda view humana que conta **sessões** tem de
   escopar por `.event == "session"`; foi assim que dois probes vizinhos quebraram no I4. O total do
   cabeçalho e a soma dos baldes fazem o contrário **de propósito** — contam toda linha local, close,
   escalada, fechamento de gate, juiz e não reconhecida inclusive —, e escopá-los por sessão quebraria
   o `assert_bucket_sum` do `check-autonomy.sh`, que fecha a soma dos sete termos contra esse total.
4. **`sdd health`** — a catraca do backlog passou a 95.

**Por onde começar, concretamente:**

```bash
cd /home/joruge/repos/sdd_agents
git log --oneline main..HEAD          # os commits da missão (13 incrementos)
tests/run-all.sh                      # ~45 s, tem de sair verde
bash tests/check-todo.sh              # ok 95 finding(s)
./bin/sdd kaizen --series             # a forma da série, com harness e window_broken
SDD_STATE_DIR=$(mktemp -d) ./bin/sdd autonomy   # a linha 'no data:' e os quatro escritores (R7)
sed -n '/event/,/window_broken/p' docs/pipeline.md   # o contrato que a QA confere contra a saída
```

**Ambiente:** nenhum. Sem stack, sem `.env`, sem credencial — o kit é bash + markdown e a suíte é
hermética.

## Pendências / Decisions for a Human

- **O veredito `melhorou` sobre `a0e34df` foi escrito com o instrumento que esta missão consertou**
  (`05-verdict.md`, já no diretório da missão). Nada nesta missão o reescreve, de propósito: mudar
  a régua depois de conhecer o resultado é o modo de falha que o `KAIZEN_LOG.md` nomeia. Se o
  veredito deve ser **reemitido** com o instrumento novo, é decisão do humano, não do pipeline.
- ⚠️ **`harness_mixed` veta `guard.sufficient` para SEMPRE, e isso foi o que o plano pediu** —
  achado #5 da r1, MEDIUM, deliberadamente **sem** `R<n>`. Reproduzido: uma fatia que atravessa um
  bump de harness responde `sufficient: false, why: ["harness_mixed"]` com o piso já batido, e
  missões novas na versão nova **não curam** (`$harness` é `unique` sobre a fatia, que é presa ao
  `kit_sha`). Consequência: `gate_KAIZEN` só aceita `indeterminado` nesse estado, logo esse
  `kit_sha` nunca é graduado. O gate continua **satisfazível**, então não é a classe do princípio 1
  — é um veredito permanentemente mudo sobre uma versão. Os dois irmãos estruturais não vetam
  (`degenerate_axis` nunca entrou em `sufficient`; `window_broken` foi escrito para não vetar), e a
  assimetria não está argumentada em lugar nenhum. Três saídas no `40-review-r1.md`: (a) manter;
  (b) rebaixar a anotação, como `window_broken`; (c) manter o veto com override humano registrado
  em artefato. **É decisão de desenho, e reverter a métrica que o humano aprovou em
  `aprovacao: humano-2026-09-11` não é coisa que o executor faz sozinho.**
- ⚠️ **(r2) `Error Handling` regrediu B → C e a r2 recomendou rodar a r3.** A régua manda parar o
  laço quando uma letra desce, e a rodada registrou os dois fatos: a regressão era **real e local**
  (o caminho que o `R5` escolheu para entregar o dinheiro o desfazia em silêncio) e o resto do laço
  andou (12 → 7 achados, 4 → 1 HIGH, `Type Safety` C → A). `R6` e `R7` fecharam exatamente essa
  regressão, então a r3 tem por onde re-medir. `REVIEW_MAX_ITER=3`: resta **uma** rodada de
  orçamento, e a decisão de gastá-la ou ir ao PR é humana.
- **O alvo "<30 s" da D7 continua não atingido e sem dono.** Os dois itens de custo da suíte foram
  deliberadamente **mantidos** no `TODO.md` no I6: não são fail-open, mas são decisão humana
  pendente (subir o alvo ou aposentá-lo por escrito), e cabeçalho de sensor não é lugar de decisão
  de humano.

## Riscos e não-feitos

- ✅ **RESOLVIDO ao fim do `R7`: o carimbo existe e é o de hoje** (`.sdd/logs/mutation-stamp` =
  `79484a242bdfd073a6169581d3bffd4a`, `301 caught of 301`, `kit healthy`), escrito **depois** do
  último commit de código (`bde643d`). O valor `724f5ce2…` que esta linha citava era o do `R5` e
  morreu com `R6`/`R7`. O parágrafo abaixo fica
  como histórico — e o aviso dele continua valendo: **qualquer** commit em
  `bin/ tests/ templates/ config/` invalida o carimbo, e registrar achado no `TODO.md` também,
  porque `tests/health-baseline.txt` está entre esses caminhos. Custo de re-carimbar hoje: **45
  min** por passada, medido duas vezes nesta sessão.
- **[histórico] NÃO HÁ carimbo de mutação, e é por isso que a linha parou.** `tests/health-baseline.txt` está
  dentro da chave do carimbo e o I6 mexeu nele, então esta sessão rodou `./bin/sdd health` depois
  do último commit de código (`4d9b7b8`), na ordem certa — e ele voltou vermelho. O
  `.sdd/logs/mutation-stamp` não existe (fica fora do git, então não aparece no diff). Enquanto os
  sete mutantes da seção *Por que a linha parou* não forem consertados, **o `gate_PR` não tem como
  passar**: é gate insatisfazível, e o kit prefere parar a fingir.
  ⚠️ Depois do conserto: qualquer commit em `bin/ tests/ templates/ config/` invalida o carimbo de
  novo, e registrar achado no `TODO.md` também, porque o baseline está entre esses caminhos.
- **[histórico, resolvido] A EXEC voltou a ser chamada e destravou as três linhas `blocked`.** Foi
  o desenho funcionando, não um acidente.
- ⚠️ **A lição do `R5` para quem tocar `bin/sdd` daqui em diante: âncora de mutante que soletra
  argumento apodrece.** O `R5` deu quatro argumentos novos ao `autonomy_close_row`, e o
  `mut_RUN_close_writes_no_row` foi a `CATALOGUE-BROKEN` — o `sed` dele listava os quatro
  argumentos originais. Isso custou **uma passada inteira de catálogo (45 min)**. Âncora morta
  **não** aparece como `NOT caught` e **não** derruba o `score:` (`caught == of` continua
  verdadeiro); só a passada completa a vê. Ancore na **chamada** (`autonomy_close_row .*`), nunca
  na lista de argumentos.
- ⚠️ **Alegação de exclusividade em comentário de mutante ("caught by X, and by nothing else") só
  vale MEDIDA**, rodando a suíte inteira sob a sabotagem. Duas dessas frases estavam falsas neste
  arquivo — uma delas desde o dia em que foi escrita (jurava duas asserções; são dez). As três
  novas do `R5` foram medidas uma a uma antes de a frase ser escrita.
- **Custou duas passadas de catálogo (≈100 min) para nomear três mutantes**, e a segunda foi
  evitável: `./bin/sdd health 2>&1 | tail -25` **come a lista** — os `fail` saem em stderr no meio
  da saída. Redirecione para arquivo e grepe `CATALOGUE-BROKEN|NOT caught`.
- ⚠️ **`pgrep -f check-mutation.sh` casa o próprio shell que espera** (o padrão está no argv do
  `zsh -c`), então `until ! pgrep -f …` nunca termina. Espere pelo **PID**.
- **Os quatro achados marcados `RESOLVIDO por` continuam no `TODO.md`** (I4 e I5, hashes `aa3c0a2` e
  `5e3c427`) e **contam** nos 95. Eles só se apagam depois que o PR que cita a evidência for
  mergeado, provado por `git merge-base --is-ancestor <hash> main` — nunca pelo rótulo do PR. Ou
  seja: a catraca vai cair de novo num chore pós-merge, e isso é o ciclo de vida, não um defeito.
- **Os mutantes novos foram verificados à mão, em sandbox, e não pelo `TEST_CMD`** — o catálogo é
  opt-in desde `4c86712`. Cada verificação checou primeiro que o `sed` MUDOU o arquivo
  (`diff -q` ⇒ `ANCHOR ROTTEN`), senão "sabotei e a suíte caiu" seria conclusão de sabotagem vazia.
  ⚠️ `tests/check-mutation.sh --list` **não é flag**: ele ignora e roda o catálogo inteiro.
  Para contar mutantes, `grep -c '^mut_' tests/check-mutation.sh`.
- **Um mutante foi recusado com argumento escrito, não esquecido.**
  `mut_KAIZEN_guard_harness_negative` trocava `($n == 0 or $n == 1)` por `($n > 1 | not)`, que
  sobre inteiros é a MESMA função — nenhum probe poderia matá-lo. O comentário declara **qual
  mundo não consegui construir**, em vez de afirmar que ele não existe.
- **Não verificado:** o comportamento das mudanças do ledger sobre um `~/.sdd/autonomy-log.jsonl`
  de OUTRA máquina, e a migração de uma missão iniciada antes do split de notas. As duas formas
  convivem por desenho.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

**O repo desta missão É o kit**, então achado de kit entra no `TODO.md` deste próprio repositório —
que é exatamente o que o I6 acabou de encolher. Nenhum achado novo foi registrado nesta sessão, e a
abstenção é deliberada e tem preço medido: o `tests/health-baseline.txt` está dentro da chave do
carimbo de mutação, então registrar um achado depois do `sdd health` mata o carimbo que o
`gate_PR` exige. O que a sessão encontrou e não virou item novo:

- A seção `### Adiados por YAGNI` do `TODO.md` ficou sem nenhum adiamento e guarda hoje doze
  achados que missões recentes apendaram ao fim do arquivo sem classificar. → **consertado no
  próprio diff** (`4d9b7b8`): a seção foi renomeada dizendo o que é, com ponteiro para Y1–Y3 do
  `CONTEXT.md`. Não virou item porque não sobrou defeito.
- O item aberto *"Slug de missão em pt-BR não pode ser citado na superfície inglesa"* foi
  **reproduzido de graça** nesta sessão: citar `20260819-fecho-que-nao-mente` num comentário de
  `tests/check-health.sh` reprovou o `check-lang.sh` na linha escrita. → **já é um dos 95**, com a
  reprodução agora nas notas de execução do I6. Nenhum item novo.
