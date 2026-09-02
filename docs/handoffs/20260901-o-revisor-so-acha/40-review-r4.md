---
missao: 20260901-o-revisor-so-acha
fase: REVIEW
rodada: 4
status: done
sessao: 2a36efc4-2874-47d1-a530-0e500c566e99
data: 2026-09-02 08:45
gate: "`tests/run-all.sh` → **866** asserções `ok`, última linha `suite green`, rc 0, 105,70 s de relógio (medido com `/usr/bin/time`); rodada duas vezes nesta sessão com o mesmo resultado. Árvore limpa antes e depois (`git status --short` → 0 linhas), HEAD `76c44ba`, missão **sem linha `pending`** (R1–R10 e F1–F4 todos `done`). Os dois `R9`–`R10` da r3 re-verificados de fora com o Check de cada linha: **1 e 1** para o R9, **0, 0, 1** para o R10. O conserto do R9 foi **reproduzido nos dois sentidos** em script descartável — `2>` à direita ⇒ 3 erros crus, à esquerda ⇒ **0**, com o ramo de aviso ainda disparando e rc 0. Os **três** mutantes ancorados na faixa do journal foram aplicados numa cópia: os três mudam 1 linha, compilam e são pegos; os dois novos matam **exatamente** a asserção que nomeiam. Recusa nova do `run-all.sh` sabotada numa cópia ⇒ `check-templates.sh` rc **92** com a mensagem nomeada. Catálogo **227 = 227**, 7 espelhos de `agents/` com `diff -q` vazio, secrets pre-scan sobre `35863d9..HEAD` em `bin/ tests/ templates/ config/ agents/` → **0** casamentos. **1 achado (LOW), fora do diff desta missão** e roteado ao `TODO.md` pela fase DOCS; **nenhum incremento `R<n>` novo**. Nota **A** nos sete critérios. ⚠️ M2 medida e **não fecha**: laço de revisão **US$ 95,57 (67%)** de US$ 143,59 contra o teto de US$ 40 — com a outra metade do número no corpo, porque o custo por rodada caiu 17,92 → 16,38 → **6,71**."
---

# Review — rodada r4 — O revisor só acha

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Quarta rodada, aberta pela porta (a) que a r3 recomendou (`--phase REVIEW`, isenta do teto). Re-julguei
os dois consertos que **não escrevi**: o `R9` (ordem da redireção nos dois escritores de journal + a
recusa do `run-all.sh`) e o `R10` (o censo de "dez chamadores"). Os dois fecham de verdade, e a
prova não foi leitura — reproduzi o conserto do `R9` nos dois sentidos, sabotei a recusa nova até o
sensor ficar vermelho, e reapliquei os três mutantes da faixa. **1 achado, LOW, e ele está fora do
diff desta missão** (nasceu em `54ae6c9`, antes da base): vai para o `TODO.md` pela DOCS, não para um
`R<n>`. Nota **A** nos sete critérios — a primeira rodada da missão que fecha. Nada foi consertado
aqui.

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O `R10` fechou o censo podre na forma que o `CLAUDE.md` prescreve, e não com um número novo: as duas grafias mortas respondem `0` e `0`, e o bloco carrega os dois comandos que contam. Rodei-os verbatim — 13 sítios e 0 substituições —, e o 13 bate com o `awk` independente da r3 (13 sítios em 8 funções), então a frase "todo chamador" é sustentada por comando e não por prosa. O único borrão que achei é a grafia de 3 espaços do `ok` no `check-templates.sh`, e ela **precede a base da missão**. |
| Type Safety | A | Toda captura nova do ciclo continua guardada, e conferi o que a torna segura em vez de supor: os três sensores tocados rodam `set -uo pipefail` **sem `-e`** (`run-all.sh:10`, `check-templates.sh:41`, `check-autonomy.sh:15`), então o `grep -c` que responde `0` com rc 1 não mata a atribuição — a classe que o `CLAUDE.md` nomeia na região do `sdd health`. O `RS8_NAMED − RS8_CURATED` é subtração de contagens de linha com `curated ⊆ named`, logo nunca negativa. |
| Error Handling | A | O achado que segurava este critério em B foi consertado e **reproduzido por mim nos dois sentidos**, em script descartável com o corpo real da função: `2>` à direita ⇒ 3 `Permissão negada` crus em 3 chamadas; à esquerda ⇒ **0**, com o aviso curado ainda saindo uma vez e rc 0. Os dois escritores mudaram juntos, que era a exigência do achado, e a asserção única de regime 8 é o que impede fechá-los pela metade. |
| Security | A | Secrets pre-scan determinístico sobre `git diff 35863d9..HEAD -- bin/ tests/ templates/ config/ agents/`, só linhas acrescentadas: **0** casamentos para chave/segredo/senha/token/bearer/private-key. A superfície nova do ciclo é uma reordenação de redireção, um global de processo e uma recusa de variável de ambiente — nenhuma entrada de rede, arquivo ou credencial. O `chmod 000` do regime 8 vive dentro do `$OUTSIDE` que a fixture destrói, e a suíte roda verde depois dele. |
| Performance | A | Medido, não afirmado: **105,70 s** de relógio para 866 asserções, contra os ~105 s que a r3 registrou para 864 — o ciclo acrescentou duas asserções e um regime que abre um `sdd run`, e nada disso é distinguível do ruído. Nenhum gate ganhou execução de suíte; a probe nova roda `run-all.sh --list`, que por contrato não executa passo nenhum, e é justamente essa escolha que impede a recursão. |
| Test Coverage | A | O melhor trabalho do ciclo, e o verifiquei por sabotagem em vez de leitura. Apaguei a recusa nova do `run-all.sh` numa cópia da árvore: `check-templates.sh` sai **rc 92** com a mensagem nomeada, então a probe mede a propriedade e não a si mesma. Apliquei os **três** mutantes da faixa do journal: os três mudam 1 linha, compilam e são pegos, e os dois novos matam **exatamente** a asserção que nomeiam — a régua "um mutante por metade" está paga. Catálogo **227 definições = 227 entradas**, sem órfão dos dois lados. |
| Documentation | A | O `R9` mudou `docs/pipeline.md` no **mesmo commit** do conserto, e o texto novo diz a propriedade certa ("e só esse aviso", com o porquê da ordem das redireções) em vez de repetir a antiga. O cabeçalho de `pipeline_log_line` carrega o censo como comando e declara que o segundo `grep` derruba comentário de propósito — a armadilha do um-a-mais que o `CLAUDE.md` documenta. Os 7 espelhos de `agents/` estão `diff -q` vazios, e o diff de `agents/sdd-reviewer.md` **acrescenta** regra de reprodução em vez de remover (invariante M3 conferida linha a linha). |
| **Overall** | **A** | Um achado LOW, reproduzido, e ele nasceu em `54ae6c9` — fora do diff que esta rodada julga. A trajetória fecha: 12 → 8 → 3 → **0 achados no escopo**, e 4 → 3 → 3 → **0 critérios abaixo de A**. O desenho novo se provou pela quarta vez, e esta é a rodada em que ele paga o que prometeu: julguei dois consertos que não escrevi, com sabotagem e mutante, e o A não é o revisor certificando o próprio patch. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | **82 das 866 asserções da suíte imprimem `  ok` com TRÊS espaços**, e são inalcançáveis por qualquer Check conforme. O `CLAUDE.md` manda o Check ancorar em `^  ok    ` (quatro), e o `check-checkpoint.sh` **recusa** a alternativa por probe própria (`:499`, `three spaces instead of four is caught`). Medido: `grep -c "^  ok    missao.md: frontmatter key 'missao'"` → `0`; a forma de 3 espaços → `1`, e é proibida. O `calibrate()` que existe para pegar exatamente isso é **cego** a esses sítios: ele só enxerga arquivos que declaram `pass() { printf '`, e são 7 de 13 — **2 dos 8 sensores comportamentais** (`check-templates.sh` e `check-entrypoint.sh`) ficam de fora, enquanto o comentário do bloco promete "the `pass()` line of every behavioural sensor". ⚠️ **Fora do diff desta missão** (ver rota abaixo) | `tests/check-templates.sh:64` e `:101`; `tests/check-checkpoint.sh:318-345` (`calibrate`) |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

**Nenhum.** O único achado da rodada nasceu antes da base da missão (`54ae6c9`, ancestral de
`35863d9`) num arquivo que este diff não toca (`tests/check-checkpoint.sh`), e o conserto coerente
mexe em 82 linhas pré-existentes. Pelo roteamento da decisão 6 do grill e da tabela do agente —
MEDIUM/LOW **caro** ou fora de escopo → `TODO_FILE`, nunca `R<n>` — ele vai para o `TODO.md`, pela
fase DOCS. O `checkpoint.md` continua **sem linha `pending`**.

⚠️ **Por que não forcei um `R<n>` "barato" aqui.** A missão acrescentou **uma** grafia de 3 espaços
(`tests/check-templates.sh:101`, 4 asserções `does not carry`), e trocá-la sozinha por 4 espaços
deixaria o arquivo internamente inconsistente — parte das regras numa grafia, parte noutra — sem
tornar Check-ável nenhuma das 82. Seria um conserto que piora a leitura e não fecha a classe, ao
preço medido de **US$ 5,46** por sessão EXEC nesta missão. A escolha local do diff foi a certa dada
a casa em que ele escreve; quem está errado é a casa, e isso é conserto de outra missão.

## O que virou incremento

> Um `R<n>` por item, com a linha exata que foi para o `checkpoint.md`. Achado "resolvido" sem
> incremento é rótulo: quem prova que fechou é o commit do executor, na rodada seguinte.

Nada desta rodada virou incremento. O que segue é a verificação, **de fora**, dos dois que a r3
escreveu e que o executor fechou sem que eu tivesse escrito o patch.

### O que a rodada anterior fechou, verificado de fora

- **`R9`** — fechado em `604d280`. Check re-rodado verbatim: **`1` e `1`**. E a propriedade foi
  **medida, não lida**: montei um script descartável com o corpo real da função contra um journal em
  `chmod 000` e rodei as duas grafias — `printf … >> f 2>/dev/null` imprime **3** `Permissão negada`
  crus em 3 chamadas, escoltando o aviso curado; `printf … 2>/dev/null >> f` imprime **0**, com o
  aviso curado saindo **uma** vez e rc 0. É exatamente o que o achado #1 da r3 pedia, nos **dois**
  escritores. A segunda metade (achado #3 da r3) foi conferida por **sabotagem**: apaguei o bloco de
  recusa do `tests/run-all.sh` numa cópia da árvore e `check-templates.sh` saiu **rc 92**, com
  `SENSOR-BROKEN` na mensagem que nomeia a variável — a probe mede o mundo, não a si mesma.
- **`R10`** — fechado em `f8fcb49`. Check re-rodado verbatim: **`0`, `0`, `1`**. E os dois censos
  embutidos no comentário foram **copiados e rodados**, que é a única coisa que distingue censo de
  ornamento: `grep -cE '^ *pipeline_log_line "' bin/sdd` → **13**, e
  `grep -E '\$\(pipeline_log_line' bin/sdd | grep -cv '^ *#'` → **0**. Amarrando cada sítio à função
  que o contém dá **8** funções, idêntico ao `awk` que a r3 rodou por conta própria — as duas
  medições independentes concordam, então o "dez" era mesmo falso nas duas leituras e a frase nova
  ("todo chamador", com o comando ao lado) é a forma que não apodrece.
- **O catálogo de mutação, medido e não presumido.** Apliquei numa cópia os **três** mutantes
  ancorados na faixa do journal. `mut_RUN_journal_write_stops_the_line` (reancorado pelo `R9`, cuja
  âncora o próprio `R9` havia apodrecido) aplica, muda **1** linha, compila e mata duas asserções
  (regimes 7 e 8). Os dois novos — `mut_RUN_journal_raw_redirection_error` e
  `mut_RUN_ledger_raw_redirection_error` — aplicam, mudam **1** linha cada, compilam e matam
  **exatamente uma**: a nomeada. A régua "um mutante por METADE da asserção" está paga, e as duas
  metades são distinguíveis pelo sensor.

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.
> Verifique; se estiver errado, registre aqui o porquê, com evidência.

- **"O instrumento `turns` do I1 não existe — nenhuma linha do ledger desta missão o carrega"** —
  **refutado, e eu quase o escrevi como achado.** O primeiro `grep` que rodei levava `| head -6` e
  devolveu só `returns`/`turns a red`, o que parecia confirmar. Sem o truncamento, o instrumento está
  lá: `bin/sdd:2822` lê `.num_turns` do log da sessão e `bin/sdd:2650` o emite como campo
  (`turns: ($turns | tonumber? // null)`), com `--by-mission` em `:4895` e o `review loop US$ X (N%)`
  em `:5257`; `tests/check-autonomy.sh` cita `turns` **30** vezes e está verde. A ausência do campo
  nas linhas desta missão é a **janela cega do runner velho**, já declarada por EXEC, QA, r1, r2 e
  r3: o processo `sdd run` que dirige a missão foi iniciado antes de `88432ee`, e o bash parseou o
  `bin/sdd` na partida. O `kit_sha` das linhas avança (`8f9113d → 51ce74c → cc69dd4 → 76c44ba`)
  porque ele descreve a **árvore**, não o processo. Consequência honesta, e a r3 não a disse: a
  metade "≤ 60 turnos" da M2 é **inaferível nesta missão por construção**.
- **"O `cd "$RS8"` do regime 8 está dentro de `$( )` sem `CDPATH=''` — a CRITICAL da r2 de
  `20260817` de novo"** — **refutado.** O operando é variável, que é o limite declarado da RULE 2 do
  `check-pipefail.sh`, e ele resolve **absoluto**: `$RS8` = `$OUTSIDE/…`, e `OUTSIDE` vem de
  `mktemp -d "${TMPDIR:-/tmp}/…"` (`:32`). Caminho começado por `/` não consulta `CDPATH`. Os sete
  regimes irmãos (`:4413`–`:4560`) usam a grafia idêntica: o regime 8 seguiu a casa, não a inventou.
- **"O resíduo declarado do `R6` ainda tem outro consumidor dentro do kit que o cabeçalho não
  nomeia"** — **refutado por enumeração**, e era a hipótese mais promissora que eu tinha (seria a
  repetição exata do achado #3 da r3). Varri `bin/` e `tests/` por toda invocação de
  `check-templates.sh`: existe **uma**, `tests/run-all.sh:211`, e é justamente a que o `R9` fechou.
  O `bin/sdd` nunca chama sensor individual — os gates chamam `TEST_CMD`, que é o `run-all.sh`. A
  frase do cabeçalho ("what is left is a reader OUTSIDE this kit") está correta.
- **"A recusa nova é frágil: quem apagar só o `exit 1` passa despercebido"** — **refutado por
  construção da probe.** Ela exige as **duas** coisas: rc não-zero **e** a variável nomeada na saída,
  com um piso que exige `--list` respondendo `0` num ambiente limpo. Apagar o `exit 1` (ou trocá-lo
  por `exit 0`) deixa `refuse_rc=0` e dispara o `broken`; morrer por outro motivo qualquer não nomeia
  a variável e dispara o outro `broken`. O piso é o que impede a probe de ler a falha alheia como a
  recusa que ela mede.
- **"O mutante reancorado do `R9` pode ter apodrecido a âncora de um vizinho"** — **refutado por
  medição**, o mesmo risco que a r2 e a r3 conferiram. Os três mutantes da faixa aplicam, mudam 1
  linha cada e compilam; o catálogo fecha **227 = 227** entre definições `^mut_…() {` e entradas do
  `CATALOG=(`, sem órfão dos dois lados.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta rodada, e é deliberado**, pelo mesmo motivo que o EXEC, a
> QA, a r1, a r2 e a r3 declararam: `tests/health-baseline.txt` está na chave do carimbo de mutação.
> Os itens abaixo são para a **fase DOCS** transportar ao `TODO.md` com a catraca no mesmo diff,
> **antes** do `./bin/sdd health`. Este repo é o kit, então nenhum item precisa da rota `kit:`.

- **NOVO (achado #1 desta rodada).** A âncora `^  ok    ` que o `CLAUDE.md` exige do Check e que o
  `check-checkpoint.sh` cobra não alcança **82 das 866** asserções da suíte, todas do
  `check-templates.sh`, que imprime `ok` com três espaços (`:64`, `:101`); e o `calibrate()`
  (`check-checkpoint.sh:318-345`), que existe para casar a âncora com o que os sensores imprimem, é
  cego a elas — ele só lê linhas `pass() { printf '`, logo enxerga **7 de 13** sensores e deixa de
  fora **2 dos 8 comportamentais**, enquanto o comentário promete "every behavioural sensor".
  Fail-open pela régua de admissão do D15: o sensor afirma medir uma população que não enumera.
  Direção do conserto: unificar o `check-templates.sh` em quatro espaços **e** dar ao `calibrate()`
  um piso de cobertura (todo sensor que imprime `  ok` declara o prefixo de forma legível a ele), não
  só o `CALIBRATE_FLOOR` de quantidade. Descoberto por `sdd-reviewer` na r4 de
  `20260901-o-revisor-so-acha` (2026-09-02).
- Os **nove** que as rodadas anteriores deixaram para a DOCS continuam de pé e não foram re-listados
  aqui para não fazer a DOCS transportar metade: os seis da r1, os dois da r2 e o do `R10`
  (`tests/check-entrypoint.sh:419` dizendo "all ten assertions" contra **14** probes — a segunda casa
  da mesma classe do achado #1 acima). Ver `40-review-r1.md`, `40-review-r2.md § Achados fora de
  escopo` e `checkpoint.md § Notas de execução`.

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.

- **A rodada fecha em A e a missão fica sem pendência de código.** `R1`–`R10` e `F1`–`F4` estão
  `done`, a árvore está limpa e a suíte verde. O caminho derivado a partir daqui é DOCS → PR. ⚠️ A
  r4 existe porque o humano usou a porta (a) que a r3 recomendou (`--phase REVIEW`, isenta do teto
  por construção); `review_rounds_on_disk` agora conta **4** arquivos contra `REVIEW_MAX_ITER=3`, o
  que **não** afeta o gate desta rodada (ele lê a nota do arquivo mais recente) mas fecha o caminho
  derivado para uma r5. Se a DOCS ou o PR trouxerem código novo, a re-revisão precisa da mesma porta.
- **A M2 não fecha, e as duas metades continuam apontando para lados diferentes — agora com mais
  dados.** Por **rodada**, o desenho novo entregou e melhorou: **US$ 17,92 → 16,38 → 6,71**, e a r3
  é a primeira rodada **abaixo** do teto de US$ 15. Por **laço**, piorou: **US$ 95,57 = 67%** de
  US$ 143,59, contra o teto de US$ 40 e contra os 61% que a r3 mediu. O que move o número é o mesmo
  que a r3 nomeou, agora com a conta fechada: **10 sessões EXEC depois da primeira linha REVIEW,
  US$ 54,55, média US$ 5,46 por incremento** — 3 a 5× o "US$ 1–2 por boot" com que a decisão 6 do
  grill desenhou a régua de lote. **A alavanca dominante é quantas linhas `R<n>` uma rodada escreve,
  não quanto uma rodada de achar custa**, e é isso que a janela 3 tem de medir. Registrado antes de
  a janela abrir, para que ninguém reescreva o alvo depois.
- **A metade "≤ 60 turnos" da M2 é inaferível nesta missão**, e isso não é falha do I1 (refutado
  acima, com o código): é a janela cega do runner velho. O primeiro `sdd run` iniciado **depois** do
  merge desta missão é o que passa a escrever `turns`, e é ele que a janela 3 lê. Quem confiar na
  M2 desta missão tem de saber que só a metade do dinheiro foi medida.
- **O carimbo de mutação continua morto**, e `gate_PR` o exige. A ordem não mudou e agora não tem
  mais commit de código pela frente: achados desta rodada + os nove anteriores → catraca do
  `TODO.md` → `./bin/sdd health`. ⚠️ O `TODO.md` ganha **um item novo** (o achado #1), então a
  catraca do `tests/health-baseline.txt` sobe junto, no mesmo diff, **antes** do `health`.
- **As pendências que EXEC, QA, r1, r2 e r3 abriram seguem de pé:** a coluna "Depois" do
  `KAIZEN_LOG.md` (8 células auto-declarantes, preenchidas pela DOCS de uma vez) e quando abrir e
  fechar a janela 3 (no sha do merge, padrão D19). A janela cega do runner velho esta rodada
  **confirma pela quarta vez** — o prompt de boot que recebi ainda é o pré-`03187e8`.
