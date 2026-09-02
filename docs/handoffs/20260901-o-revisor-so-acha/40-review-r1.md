---
missao: 20260901-o-revisor-so-acha
fase: REVIEW
rodada: 1
status: done
sessao: 2762a593-d6f4-4381-b930-078f0c16f856
data: 2026-09-02 02:40
gate: "`tests/run-all.sh` → **858** asserções `ok`, última linha `suite green`, rc 0 (~105 s); árvore limpa antes e depois (`git status --short` vazio). Secrets pre-scan do `codereview` sobre `git diff main...HEAD --unified=0` → `{\"findings\":[],\"scanners\":[\"regex\"],\"errors\":[]}`. **A rodada NÃO fecha:** 12 achados (4 HIGH, 3 MEDIUM, 5 LOW), 4 deles reproduzidos à mão nesta sessão; 5 incrementos `R1`–`R5` `pending` escritos no `checkpoint.md`. Nota real **B** em Code Quality, Type Safety, Test Coverage e Documentation. M3 conferida com comando: `gate_REVIEW` byte a byte idêntico (176 linhas, `awk` de faixa contra `main`), nenhuma regra de reprodução/refutação removida de `agents/sdd-reviewer.md`, 7 de 7 espelhos `diff -q` vazios. M1 recomputada à mão contra o ledger cru: `review loop US$ 47.81 (57%)` bate com o que o instrumento imprime."
---

# Review — rodada r1 — O revisor só acha

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Primeira rodada rodando o contrato novo. **12 achados** — 4 HIGH, 3 MEDIUM, 5 LOW — dos quais
**4 reproduzidos com medição nesta sessão** e o resto verificado linha a linha. Viraram
**5 incrementos `R1`–`R5` `pending`**; nada foi consertado aqui. Os dois piores são fail-opens
em sensores: a guarda `REVIEW-EDITED-CODE` acusa uma rodada **saudável** quando o arquivo da
missão tem acento, e as duas regras `refute()` que o `F1` criou são **case-sensitive**, logo
deixam passar exatamente a regressão que existem para impedir. O terceiro é o número que a janela 3
vai julgar: `CONTEXT.md` D22 ainda carrega os 60% que o próprio `KAIZEN_LOG.md` refutou para 57%.
Nota **B**. `tests/check-autonomy.sh` e o catálogo de mutação passaram uma sabotagem completa
**limpos** — o instrumento novo mede o que diz medir.

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | Dois fail-opens reproduzidos em `tests/check-templates.sh` (regras `refute()` cegas à maiúscula; `review_check` sem o qualificador que o rótulo promete) e o `GATE_WHY` do `gate_REVIEW` ainda diz "fixes must be committed" sobre uma sessão que não conserta mais. |
| Type Safety | B | `review_scope_check` trata a saída de `git diff --name-only` como caminho literal; com o `core.quotePath` padrão do git um caminho acentuado **dentro** do diretório da missão sai como `"docs/.../relat\303\263rio.md"` e escapa da allowlist — reproduzido, `n=1` onde a rodada saudável lê `0`. As coerções `jq` do I1 (`tonumber? // null`, `$fr == null` e não truthiness, `$cost > 0`) estão todas corretas. |
| Error Handling | A | Toda captura nova é guardada (`\|\| true`, sentinela `-` quando não há HEAD anterior), herestring no lugar de pipe (sem a classe 141/SIGPIPE), `n=$(( n + 1 ))` como atribuição e não comando aritmético, divisão por zero barrada por `if $cost > 0` antes do `/` — cinco passadas independentes não acharam um `set -e` novo. |
| Security | A | Secrets pre-scan determinístico sobre o diff inteiro: `{"findings":[],"scanners":["regex"],"errors":[]}`. Nenhuma superfície de injeção nova: a guarda **lê** nomes de arquivo e nunca os executa, e todo `git` roda com `-C "$REPO_ROOT"` em vez de `cd`. |
| Performance | A | O custo acrescentado por sessão é um `git diff --name-only` entre dois shas e uma passada `jq` a mais por grupo `(repo, missão)`; a suíte foi de 842 para 858 asserções sem mudança mensurável nos ~105 s de `tests/run-all.sh`. |
| Test Coverage | B | `tests/check-autonomy.sh` sobreviveu a uma sabotagem porta a porta **limpo** (cada uma das 3 portas derruba só a sua asserção; a célula do laço é diferencial; os pisos `turns_floor`/`committed:1`/`slash:1` provados armados) e o catálogo bate 223 = 223 — mas `check-templates.sh` tem dois fail-opens medidos e o caminho do `core.quotePath` não tem regime nenhum. |
| Documentation | B | `CONTEXT.md:62` (D22) ainda diz "janela 2: 29% e 60%" enquanto `KAIZEN_LOG.md:55`, escrito no mesmo commit, registra a correção para 57%; as linhas Antes/Depois de `KAIZEN_LOG.md:69-70` dizem 855 asserções e 222 mutantes contra 858 e 223 medidos hoje; e `docs/pipeline.md:442` ensina a ler um `0` que não distingue "medido limpo" de "não medido". |
| **Overall** | **B** | Quatro HIGH com reprodução, três MEDIUM e cinco LOW; cinco incrementos `R1`–`R5` `pending` no checkpoint. O desenho novo funcionou — a rodada achou sem consertar —, mas o diff não fecha em A nesta passada. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | `review_scope_check` compara a saída de `git diff --name-only` com a allowlist como se fosse caminho literal; com o `core.quotePath` padrão do git, um arquivo **dentro** do diretório da missão cujo nome tem acento sai entre aspas e em octal, não casa `"$mission_dir"/*` e a rodada saudável leva `REVIEW-EDITED-CODE` | `bin/sdd:2254` (casamento em `:2263-2277`) |
| 2 | HIGH | as duas regras `refute()` que o `F1` criou são **case-sensitive** e sem âncora: reintroduzir a seção antiga `## O que foi corrigido` (O maiúsculo) **ao lado** da nova deixa o sensor em `rc=0` — que é exatamente o cenário nomeado no comentário três linhas acima delas | `tests/check-templates.sh:278,280` |
| 3 | HIGH | `CONTEXT.md` D22 carrega duas vezes o `60%` da janela 2 que o `KAIZEN_LOG.md:53-55` refutou para `57%` no mesmo commit — e a nota do checkpoint que confere a D22 diz "batem, nada a corrigir" uma linha abaixo da nota que registra a correção. É a linha de base contra a qual a janela 3 vai julgar esta missão, errada na direção que faz o alvo parecer mais fácil | `CONTEXT.md:62` |
| 4 | HIGH | a verificação que a missão prescreve para a própria guarda é **vácua**: `grep -c REVIEW-EDITED-CODE … → 0` está documentado como "o que uma missão saudável parece", mas responde `0` idêntico quando a guarda **não está carregada** — que é o caso desta missão, medido | `docs/pipeline.md:442`; `01-plano.md:340,387` |
| 5 | MEDIUM | `review_check '^## Incrementos de conserto'` para antes do qualificador `(R<n>)` que o próprio rótulo promete: com o qualificador fora do template o sensor imprime `ok   review.md: section 'Incrementos de conserto (R<n>)'` e sai `rc=0`. É a família do `F2`, que a QA fechou um commit antes | `tests/check-templates.sh:266` |
| 6 | MEDIUM | dentro do `gate_REVIEW` — que a missão deliberadamente **não** mudou — o motivo de árvore suja ainda diz `fixes must be committed`, sobre a fase que deixou de consertar | `bin/sdd:1189` |
| 7 | MEDIUM | as linhas Antes/Depois do `KAIZEN_LOG.md` dizem 855 asserções e 222 mutantes; o medido hoje é 858 e 223 (o `F4` pousou depois de a entrada ser escrita). Célula de "Depois" preenchida com número que deixou de ser verdade, no registro que existe para guardar medição | `KAIZEN_LOG.md:69-70` |
| 8 | LOW | prosa em português numa fixture de `tests/`, que é superfície declarada **inglesa** do kit; o `check-lang.sh` não a pega porque nenhuma das palavras está no dicionário sem acento | `tests/check-gates.sh:900` |
| 9 | MEDIUM | duas contas do mesmo gemba convivem sem reconciliação: `US$ 636,66 de US$ 1.614,87` (39,4%) no agente e no `pipeline.md`, `US$ 636,66 de US$ 1.635,48` (38,9%) no `KAIZEN_LOG`. Cada par é internamente consistente — o ledger cresceu entre o I2 e o I4 —, mas nada diz isso | `agents/sdd-reviewer.md:26`; `docs/pipeline.md:192` |
| 10 | LOW | `reviewscope_files()` recupera a lista de arquivos com `awk -F': ' … $NF`: um caminho que contenha `": "` trunca o diagnóstico em silêncio. Limite não declarado no cabeçalho, como o resto do arquivo faz | `tests/check-autonomy.sh:4387` |
| 11 | LOW | o braço `else ""` da célula do laço (quando `$cost == 0`) não é alcançado por nenhuma fixture: a guarda de divisão por zero é correta e **não** é medida | `bin/sdd:5124` |
| 12 | LOW | `turns` é escrito no ledger e lido por nenhuma view humana — só por `jq` ad-hoc e por uma asserção. É instrumento cru, não campo morto, mas nada no kit diz isso a quem lê `docs/pipeline.md § Field reference` | `bin/sdd:2517` |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | #1 — a guarda acusa arquivo acentuado da própria missão | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a mission-directory file whose name is not ASCII is not flagged REVIEW-EDITED-CODE' <<< "$o"` → `1` |
| R2 | #2 — as regras `refute()` são cegas à maiúscula | `o=$(bash tests/check-templates.sh 2>&1); grep -c '^  ok    self-test: the forbidden-prose rules catch the capitalised spelling too' <<< "$o"` → `1` |
| R3 | #3 — a D22 carrega o 60% refutado | dois termos sobre a linha D22 do `CONTEXT.md`: `29% e 57%` presente, `60%` ausente |
| R4 | #4 — a verificação da guarda é vácua sob runner velho | o terceiro fail-open declarado no cabeçalho da função **e** em `docs/pipeline.md`, com a suíte verde |
| R5 | lote dos achados #5, #6, #8 e #9 (MEDIUM/LOW baratos) | quatro termos num Check só — ver a linha no `checkpoint.md` |

## O que virou incremento

> Um `R<n>` por item, com a linha exata que foi para o `checkpoint.md`. Achado "resolvido" sem
> incremento é rótulo: quem prova que fechou é o commit do executor, na rodada seguinte.

- **Achado #1** — virou `R1`. O Check exige uma **sexta regime** no bloco `== the REVIEW scope
  guard ==` do `tests/check-autonomy.sh`, com um arquivo de nome não-ASCII **dentro** de
  `$mission_dir`, e a asserção `a mission-directory file whose name is not ASCII is not flagged
  REVIEW-EDITED-CODE` verde. O conserto medido aqui é `-c core.quotePath=false` no `git diff` de
  `bin/sdd:2254` (verificado: devolve o caminho UTF-8 literal) ou `-z` com split em NUL. ⚠️ O
  regime precisa do **piso** que os outros quatro já têm (a sessão rodou, ela realmente commitou),
  ou ele passa num mundo em que a fixture não foi montada.
- **Achado #2** — virou `R2`. O Check exige uma probe nova no `selftest()` do
  `tests/check-templates.sh` provando que as duas regras `refute()` enxergam a grafia com inicial
  maiúscula. Conserto medido: `grep -qiE` (ou classe `[Oo]`/`[Vv]`) nas duas chamadas de `:278` e
  `:280`, mais uma terceira regra que refuta o heading antigo `^## O que foi corrigido` inteiro —
  é ele, e não a frase solta, que o comentário de `:267-269` diz temer. ⚠️ `REVIEW_FLOOR` (hoje
  26) sobe no **mesmo diff**, e o piso do `selftest` também: piso que fica para trás continua
  passando descrevendo superfície menor.
- **Achado #3** — virou `R3`. Os dois `60%` da linha D22 do `CONTEXT.md` (o "25–60% por missão" da
  pergunta e o "janela 2: 29% e 60%" da decisão) passam a `57%`, que é o número que o instrumento
  do I1 lê e que o `KAIZEN_LOG.md:53-55` já registra com a justificativa. **O alvo não se move**
  (mediana ≤ 25%, máximo ≤ 50%): mexer no alvo depois de saber o resultado é o modo de falha que o
  próprio `KAIZEN_LOG` de 2026-08-31 nomeia. Corrigir a nota do `checkpoint.md:67` junto, que
  afirma ter conferido a D22 e não conferiu este número.
- **Achado #4** — virou `R4`. O conserto é **declarar**, não adivinhar: o cabeçalho de
  `review_scope_check` já declara duas frouxidões (o `commit --amend` e o braço incondicional
  `tests/health-baseline.txt`) e falta a terceira, que é a maior — *uma sessão `sdd run` lançada
  antes do commit que criou a guarda carrega o `bin/sdd` anterior em memória, e a guarda
  simplesmente não existe naquele processo*. A mesma frase entra em `docs/pipeline.md`, ao lado
  da linha que hoje ensina a ler o `0` como saúde. E `01-plano.md § Para a fase DOCS` e
  `§ Verificação end-to-end` trocam o `grep -c … # 0 esperado` por evidência que pode de fato ser
  computada nesta missão (o `git diff` dos commits da rodada contra o HEAD pré-sessão). Pela régua
  de admissão do D15, dívida **declarada** é limite; dívida calada é o fail-open. ⚠️ O conserto
  durável — o `sdd run` avisar quando o `bin/sdd` mudou sob ele — **não** é este incremento: é o
  candidato que a QA já escreveu para o `TODO.md` e que precisa de decisão humana.
- **Achado #5** — virou `R5` (lote). `review_check '^## Incrementos de conserto'` ganha o
  qualificador `\(R<n>\)`, exatamente como a irmã do `checkpoint.md` em `:217-220` já faz e
  explica no comentário. O Check mede nos **dois sentidos** (com o qualificador fora do template o
  sensor tem de ficar `rc=1`), que é a única forma de provar que a asserção deixou de falhar
  aberta — a forma que o `F2` já usou.
- **Achado #6** — virou `R5` (lote). O `GATE_WHY` de `bin/sdd:1189` passa a falar do que a sessão
  REVIEW commita hoje. ⚠️ A **checagem** (árvore limpa) está certa e não muda; é a frase que
  ficou para trás. Isso não conta como mexer no `gate_REVIEW` para efeito da M3 — o teste é o
  comportamento, e ele é idêntico.
- **Achado #8** — virou `R5` (lote). A descrição da fixture de `tests/check-gates.sh:900` passa
  para inglês, como as vizinhas (`slice one`, `filler row`). São três linhas (`:900`, `:905`,
  `:909`) que repetem a string e têm de mudar juntas, ou o `sed` da `:905` para de casar.
- **Achado #9** — virou `R5` (lote). Uma cláusula em `agents/sdd-reviewer.md:26` e em
  `docs/pipeline.md:192` dizendo de quando é a medida, ou os dois números alinhados com o
  `KAIZEN_LOG.md:17`. É prosa de motivação, não de gate — por isso lote e não linha própria.

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.

- **"O instrumento do laço de revisão (M1) pode estar errado"** — **refutado com recomputação
  independente.** Recomputei `20260830-a-tela-que-mente-o-pagamento` por `jq` sobre o ledger cru,
  sem usar o programa do `bin/sdd`: `first_review_index=4`, `loop=US$ 47.81`, `total=US$ 84.42`,
  `share=57%` — idêntico ao `review loop US$ 47.81 (57%)` que o comando imprime. A aritmética de
  índice também foi testada no caso `$fr == 0` (REVIEW como primeira sessão): `0` não é engolido
  como falsy porque o teste é `$fr == null` e não truthiness.
- **"`turns` não está sendo escrito — 194 de 194 linhas respondem `has_turns=false`"** — a QA já
  havia refutado como defeito de código (R3 do `30-handoff-qa.md`) e eu **confirmei a causa por
  medição direta**, não por leitura: o processo `sdd run` desta missão (PID 3080293) começou em
  `2026-09-01 17:56:48`, e o commit que criou o campo (`88432ee`) é de `18:12:56`. As 9 linhas da
  missão carregam um `run_id` só. Não é bug; é a janela cega do achado #4.
- **"`turns` é campo morto (escrito e nunca lido)"** — **refutado**. Está na tabela de campos de
  `docs/pipeline.md`, tem asserção própria em `tests/check-autonomy.sh`, e o ledger JSONL **é** a
  interface: a decisão 9 do `00-missao.md` diz em tantas palavras que a distribuição das sessões de
  achar sai daí para decidir o teto na missão seguinte. O que sobra é o achado #12, que é "nada diz
  isso ao leitor" — LOW, e vai para o `TODO.md` pela fase DOCS, não para um `R<n>`.
- **"O `.claude/agents/` pode estar dessincronizado do `agents/`"** — **refutado**: `diff -q` nos
  7 pares devolve vazio.
- **"A segunda asserção do `check-gates.sh` (`and once R1 is done the ball comes back to REVIEW`)
  é vácua"** — **medido, e a conclusão é mais fraca que a acusação.** Sabotando `checkpoint_rows()`
  para só enxergar `^[IF][0-9]+$`, **só a primeira** asserção fica vermelha; a segunda continua
  verde porque `current_phase()` cai em `REVIEW` nos dois mundos. Mas isso não a torna fail-open:
  `checkpoint_rows`/`gate_EXEC` não distinguem prefixo em lugar nenhum (lido em `bin/sdd:277-309` e
  `:739-834`), então não existe bug plausível que quebre a segunda sem quebrar a primeira. O que
  está errado é o **comentário** que diz "a segunda é por que a primeira não é vácua" — vai como
  achado fora de escopo, não como `R<n>`.
- **"A ausência de uma quarta porta (`cmd_close`) na guarda é a porta desguardada que o
  `CLAUDE.md § 5` proíbe"** — **refutado**: o `sdd close` roda como fase `CLOSE`, e a primeira
  linha de `review_scope_check` só responde a `REVIEW`. Três portas, três probes, cada uma
  derrubando só a sua sob sabotagem — medido.
- **"O `shellcheck` ganhou aviso novo"** — **refutado**: histograma idêntico em `bin/sdd` entre
  `main` e HEAD (237 SC2317, 10 SC2015, 9 SC2016, 7 SC2031, 4 SC2295, 2 SC2012, 1 SC2002); nos
  sensores as contagens escalam com o código acrescentado, sem categoria nova.

### M3 — a invariante que o EXEC pediu que esta rodada conferisse, com o comando

- **`gate_REVIEW` não mudou.** `git diff main...HEAD -- bin/sdd | grep -E '^[-+].*gate_REVIEW'` →
  vazio; e a faixa da função extraída dos dois lados (`awk '/^gate_REVIEW\(\) \{/,/^\}/'` sobre
  `git show main:bin/sdd` e sobre `bin/sdd`) é **byte a byte idêntica**, 176 linhas. O achado #6
  é uma string **dentro** dessa função inalterada, não uma mudança nela.
- **Nenhuma regra de rigor foi removida de `agents/sdd-reviewer.md`.** *Reproduce before you
  conclude* (2 ocorrências — e é **nova**, não existia em `main`), *Receive criticism with rigour*
  (presente; a frase adaptou "mudando o código" para "escrevendo um `R<n>`", que é o mesmo rigor no
  contrato novo), *never end your turn with a command still running* (2), refutação com evidência
  (2). Uma linha saiu da lista de regras — *"An unfixed MEDIUM/LOW becomes a line in `TODO_FILE`"* —
  e foi **substituída** pela regra de roteamento completa, que continua garantindo que nada
  desaparece.
- **Os 7 espelhos estão em dia.** `diff -q agents/<n>.md .claude/agents/<n>.md` para os sete →
  nenhuma saída.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta rodada, e é deliberado**, pelo mesmo motivo que o EXEC e
> a QA declararam: `tests/health-baseline.txt` está na chave do carimbo de mutação
> (`01-plano.md § Configuração e pitfalls`). Os itens abaixo são para a **fase DOCS** transportar
> ao `TODO.md` com a catraca no mesmo diff, **antes** do `./bin/sdd health`. Este repo é o kit,
> então nenhum item precisa da rota `kit:`.

- **Achado #7, e é da própria DOCS:** as linhas Antes/Depois do `KAIZEN_LOG.md:69-70` dizem `855`
  asserções e `222` mutantes; o medido nesta rodada é **858** e **223** — `grep -c '^  ok'` sobre
  `tests/run-all.sh` e `grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' tests/check-mutation.sh`.
  **Deliberadamente não virou `R<n>`:** os `R1`, `R2` e `R5` mexem em `tests/`, então qualquer
  número que um executor escrevesse nasceria velho outra vez. Quem reconcilia é a DOCS, que já é
  dona dessa tabela e roda **depois** do último commit de código — reconciliar as duas linhas junto
  com a coluna "Depois" que ela já vai preencher.
- `reviewscope_files()` recupera a lista com `awk -F': ' … $NF` — `tests/check-autonomy.sh:4387` —
  caminho que contenha `": "` trunca o diagnóstico em silêncio; o resto do arquivo declara limites
  assim no cabeçalho e este não declara — descoberto por `sdd-reviewer` na missão
  `20260901-o-revisor-so-acha` (2026-09-02) → `TODO.md`
- o braço `else ""` da célula do laço de revisão (`$cost == 0`) não tem fixture — `bin/sdd:5124` —
  a guarda contra a divisão por zero do `jq` está correta e **não é medida**, então uma frouxidão
  futura (`$cost >= 0`) abortaria o `--by-mission` inteiro sobre um ledger real com missão de custo
  nulo e nada nesta suíte avisaria; fecha com uma fixture diferencial de missão de custo todo nulo
  **com** rodada — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha`
  (2026-09-02) → `TODO.md`
- `turns` não aparece em nenhuma view humana — `bin/sdd:2517` — está na tabela de campos do
  `docs/pipeline.md` e é lido só por `jq` ad-hoc, então quem instala o kit não descobre que ele
  existe; candidato: dizer no `§ Field reference` que é instrumento cru, ou pendurá-lo na célula do
  `review loop` — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)
  → `TODO.md`
- o comentário de `tests/check-gates.sh:897-898` afirma que a segunda asserção "é por que a
  primeira não é vácua" — `tests/check-gates.sh:897` — medido: sob a sabotagem realista
  (`checkpoint_rows` cego a `R<n>`) só a primeira cai, e a segunda fica verde por um motivo
  diferente do que o comentário alega. É a classe *"comentário que afirma paridade não é
  paridade"* que o `CLAUDE.md` já nomeia; ou o comentário baixa a alegação, ou a asserção ganha o
  mundo que a distingue — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha`
  (2026-09-02) → `TODO.md`
- a refutação **R2** do `30-handoff-qa.md:79` afirma que "o prompt nomeia `TODO.md`
  explicitamente" — `docs/handoffs/20260901-o-revisor-so-acha/30-handoff-qa.md:79` — nem o
  `phase_extra REVIEW` nem `agents/sdd-reviewer.md` contêm a string `TODO.md`, só a variável
  `TODO_FILE`; a **conclusão** da refutação continua certa (o `TODO_FILE` está na allowlist, com
  probe), só a evidência citada não existe — imprecisão num artefato de trilha de auditoria, não
  defeito de código — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha`
  (2026-09-02) → `TODO.md`
- o `TODO.md` carrega 4 itens já fechados e mergeados (`RESOLVIDO por 594ef07` ×3 e `c7c2e2e` ×1,
  os dois ancestrais de `main` por `git merge-base --is-ancestor`) que a própria regra de ciclo de
  vida do arquivo manda apagar — `TODO.md:691` — **pré-existente**, não nasceu nesta branch, e é
  ocorrência da lacuna já declarada em `TODO.md:482`; a faxina cabe na triagem do `sdd kaizen`,
  não nesta missão — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha`
  (2026-09-02) → `TODO.md`

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.

- **A janela cega do runner velho precisa de conserto durável, e ele é uma decisão.** O `R4` só
  **declara** o limite. Fechá-lo de verdade tem duas formas com preços diferentes: (a) o `sdd run`
  compara o hash de `bin/sdd` na entrada com o de agora e avisa/para; (b) toda métrica que nomeia o
  ledger como fonte passa a citar `.sdd/logs/` no ciclo em que o campo nasce. A QA já escreveu o
  candidato para o `TODO.md`; a escolha entre parar a linha e só avisar é do humano, porque (a)
  pode reprovar uma missão em voo que está saudável. **Não bloqueia o pipeline.**
- **A M2 desta missão não fecha, e o número é este.** Esta sessão gastou **US$ ~15,4** — o teto que
  a M2 declarou é ≤ US$ 15 por sessão REVIEW. Os turnos não podem ser lidos do ledger (achado #4);
  a fonte é `jq -r '.num_turns' .sdd/logs/20260901-o-revisor-so-acha/REVIEW-*.json`, que só existe
  depois desta sessão. O laço inteiro (REVIEW + EXEC dos `R1`–`R5`) contra o teto de US$ 40 é o que
  a fase DOCS mede. Registrado agora, antes de o resultado do laço ser conhecido, para que ninguém
  reescreva o alvo depois.
- **As duas pendências que EXEC e QA abriram seguem de pé:** a coluna "Depois" do `KAIZEN_LOG.md`
  (preenchida pela DOCS) e quando abrir/fechar a janela 3 (no sha do merge, padrão D19).
