---
missao: 20260831-a-rodada-que-andou
fase: REVIEW
rodada: 1
status: done
sessao: d8ffa84b-1d8b-4b45-a695-d43ad6815000
data: 2026-08-31 15:10
gate: "`tests/run-all.sh` → `suite green`, 0 FAIL, rc 0, ~85 s, rodado depois de cada um dos seis commits desta rodada. Árvore limpa (`git status --short` vazio) e HEAD em `7c0a92a`. Os dois mutantes novos medidos como o catálogo mede — sandbox `bin tests templates config agents CLAUDE.md TODO.md docs/adr`, `cmp -s` (âncora morde), `bash -n` (válido) e `SDD_MUTANT=1 run-all.sh` → rc 1 nos dois, matando exatamente as asserções nomeadas nos seus cabeçalhos. Métrica (1) re-conferida no ledger real depois dos consertos: `d89ea43`, `e9a3681` e `353b4b1` em `1 advanced · 0 churned · 0% waste` e `bf001fe` inalterada em `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste · 3 mission(s) · US$ 175.96`. ⚠️ O carimbo de mutação `829412c3ad9101d48b6c492b9cf42520` está MORTO — esta rodada commitou em `bin/` e `tests/`; quem re-carimba é a DOCS, antes do `gate_PR`."
---

# Review — rodada r1 — A rodada que andou

## TL;DR

Revisão adversarial em quatro frentes (semântica `jq` do ledger, fluxo bash do runner, sensores, e
sincronia de contrato), com reprodução exigida antes de qualquer conclusão. **Nove achados, seis
consertados nesta sessão com probe e mutante, quatro registrados no `TODO.md`, um refutado com
evidência.** Os dois graves eram a mesma família e nasceram do evento novo: uma closure sozinha
numa fatia cunhava um `ok` fantasma, e uma closure gravada uma vez derrubava o `refez` de **toda
sessão reprovada depois dela, para sempre** — os dois na direção da lisonja, que é a que o próprio
`00-missao.md` proíbe. A rodada **não fecha em A**: duas portas do escritor do I4 sobrevivem à
sabotagem, e chamá-las de cobertas seria o fail-open que este artefato existe para impedir.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os dois defeitos de lógica do evento novo consertados na raiz (`phase_label` lendo POSIÇÃO e não pertinência; `group_summary` recusando grupo sem sessão), cada um com o limite que sobra DECLARADO no comentário em vez de calado. |
| Type Safety | A | Guardas de nulo verificadas termo a termo contra jq 1.7 medido (`null > 2` false, `null < 2` true): a assimetria de uma guarda no braço de rodada contra duas no do EXEC é a ordem dos operandos e está certa. `tonumber? // null` fecha a entrada; `null \| has("rc")` é `false` e não erro, e a asserção que dependia disso carrega o `. != null`. |
| Error Handling | A | `set -euo pipefail` varrido nos sítios novos: `review_rounds_on_disk` não devolve não-zero por construção, `latest_matching` carrega o `\|\| true`, o bloco `\`-continuado do `jq -cn` não tem `#` no meio, e `gate_pass_rows` é CHAMADO e nunca `$( )`. A precondição de escopo dinâmico (morte alta com `PLAN: unbound variable`) passou a ser declarada no cabeçalho. |
| Security | A | Varredura determinística de segredos sobre o diff (`scan_secrets.sh`, catálogo regex): `{"findings": [], "errors": []}`. Nenhuma entrada externa entra em shell: todo valor vai ao `jq` por `--arg`, e o único `sed`/`grep` novo lê caminho de `mktemp -d` absoluto. |
| Performance | A | O evento novo não roda gate nenhum a mais — ele grava o que a derivação da própria volta já mediu, que é o motivo de existir. No máximo uma linha por fase por corrida contra as até seis por volta que a alternativa despejaria. Leitores continuam numa passada de `jq`; `historic_rounds` é `reduce` linear e preserva comprimento. |
| Test Coverage | **B** | **Duas portas do escritor do I4 sobrevivem à sabotagem sem estarem declaradas** — a guarda de fase da foto de REVIEW no `cmd_retry` (sem ela, todo `sdd retry <não-REVIEW>` nasce com `rounds_before: 0` em vez de `null`) e a escrita de `gate_failed` no retry inline, cuja consequência é uma linha `gate_pass` FALSA e permanente. Registradas no `TODO.md` com direção, não fechadas: fechá-las é fixture de duas voltas e não coube nesta janela. Tudo o mais mediu: 7 asserções e 2 mutantes novos, os dois provados em sandbox, e a varredura de 213 mutantes achou 0 âncora podre. |
| Documentation | A | As duas células do contrato que mentiam foram corrigidas (`gate_why` dizia `never` sobre uma chave que a terceira forma não tem; `kind` implicava presença na closure), e as duas regras novas entraram no `docs/pipeline.md` no MESMO commit do código. Enum de `event` conferido contra todo literal escrito pelo código: sem deriva. |
| **Overall** | **B** | Seis achados consertados com sensor durável e árvore limpa, mas o laço não fecha: duas regras do próprio incremento afirmam cobertura que não têm, e o `A` comprado com isso desligaria o sensor. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | Uma linha `gate_pass` derruba o `refez` de **toda** sessão reprovada depois dela, para sempre: a cláusula lia pertinência de conjunto, não posição | `bin/sdd:5261` |
| 2 | HIGH | Grupo cujo único membro é a closure cunha uma célula `ok` fantasma, `sessions: 0`, no histograma que o juiz cita primeiro | `bin/sdd:5289` |
| 3 | HIGH | Dois critérios de aceitação da missão ainda exigiam o número que o próprio ponto de corte falsificou | `01-plano.md:311`, `00-missao.md:136` |
| 4 | MEDIUM | A tabela de campos do contrato dizia `gate_why: Absent when never` sobre uma chave que a terceira forma de linha não tem; `kind` implicava presença | `docs/pipeline.md:590`, `:616` |
| 5 | MEDIUM | Fixture da closure carregava `gate_why`, campo que o writer nunca escreve — fixture imaginado em vez de copiado da fonte | `tests/check-kaizen.sh:414` |
| 6 | MEDIUM | A guarda de fase da foto de REVIEW no `cmd_retry` sobrevive à sabotagem e não está declarada | `bin/sdd:4568` |
| 7 | MEDIUM | A escrita de `gate_failed` na porta do retry inline sobrevive à sabotagem, sob comentário que invoca "um probe por porta" | `bin/sdd:4509` |
| 8 | MEDIUM | `$order` (`cmd_autonomy`) e `comparable_row` (`kaizen_series`) divergem sobre a linha nova, com comentário jurando paridade | `bin/sdd:4899` |
| 9 | MEDIUM | Missão que só tem `gate_pass` numa fatia conta em `missions` sem produzir célula gradeável | `bin/sdd:5318` |
| 10 | LOW | `cmd_retry` tem guarda de `review_after`/`review_max` inalcançável, sob comentário de paridade que não vale | `bin/sdd:4576` |
| 11 | LOW | Assimetria leitor × juiz sobre closure de kit sujo (levantada pela QA) | `bin/sdd:4904` |

## O que foi corrigido

- **#2 — a célula fantasma** — corrigido em `dfe4d63`. Prova: fixture de duas fatias
  (`kit_sha` diferente entre a sessão e a closure, que é TODA corrida do repo que constrói o kit,
  porque cada sessão commita) lia `labels {ok: 2}` sobre uma fatia com **uma** sessão, e a fatia
  anterior continuava com o `refez` falso intacto. Segundo mundo, independente do sha: sessão
  escrita com o kit sujo cai em `non_comparable` e a closure limpa fica sozinha. O `group_summary`
  passou a guardar só grupos com sessão ou escalada — o que não remove nada que já fosse contado,
  porque antes do `gate_pass` nenhum grupo sem sessão podia ler `ok` (grupo só de escalada lê
  `refez` no primeiro braço). Sensor: bloco `a closure alone in a slice mints no cell`
  (4 asserções, com piso contra fatia vazia) + mutante `LEDGER_gate_pass_mints_a_cell`, medido em
  sandbox: âncora morde, `bash -n` válido, rc 1, 2 asserções mortas.
- **#1 — a closure derrubando o futuro** — corrigido em `d17aca6`. Reproduzido ponta a ponta num
  `sdd run` real com fixture hermético: a QA fecha de graça, a rodada de REVIEW reabre a QA, mais
  três sessões de QA reprovam gastando US$ 21 e nenhuma passa — a rubrica lia `leve` onde tem de
  ler `refez`, e numa variante com REVIEW lia **`ok`**, a nota mais alta, sobre uma fase que
  queimou três sessões e nunca fechou. Tudo com **um** `kit_sha`, que é o caso normal de repo-alvo:
  era o caminho comum, não a borda. A cláusula passou a pedir o ÚLTIMO de (sessões ∪ closures).
  Sensor: bloco `a closure does not outvote the sessions that came after it` (3 asserções — a
  reprodução, o piso da fase que DE FATO fechou, e a direção oposta no mesmo arquivo) + mutante
  `LEDGER_gate_pass_membership_not_position`, medido em sandbox: rc 1, e a única asserção que morre
  é a da reprodução, que é o que o torna dono dela.
- **#3 — os critérios de aceitação falsificados** — corrigido em `e320d21`. Os dois passam a citar
  a medição real. As notas datadas do `checkpoint.md` ficam como estão: são o registro de que a
  previsão existiu e foi derrubada, e apagá-las apagaria a prova.
- **#4 — a tabela de campos** — corrigido em `5f2b511`. `gate_why` agora diz
  `on event:"gate_pass" rows`, com o porquê; `kind` idem. Leitor que confiasse na tabela em vez da
  prosa lia `never` sobre chave ausente.
- **#5 — o fixture imaginado** — corrigido em `145b9fa`. As onze chaves do fixture são as onze do
  construtor, com a proveniência escrita acima do heredoc. 166 `ok` antes e depois: nenhuma
  asserção dependia do campo, que é justamente o que torna a divergência invisível até custar caro.
- **#10 (metade) — a precondição de escopo dinâmico** — declarada em `d17aca6`, no cabeçalho do
  `gate_pass_rows`: um segundo sítio de chamada sem os três mapas mata o runner com
  `PLAN: unbound variable` na primeira fase.

## O que foi refutado

- **A assimetria leitor × juiz sobre closure de kit sujo (#11), que a QA levantou e decidiu não
  registrar, está REFUTADA como achado — a QA estava certa, e por um motivo a mais do que ela deu.**
  A QA argumentou pela régua D15 (o balde `$closed` é incondicional de propósito, o juiz declara a
  exclusão em `non_comparable`, cada tela é honesta sobre a própria população). Verificado, e
  procede. O motivo a mais: a única consequência **material** dessa assimetria era a célula fantasma
  do achado #2 — a closure limpa sobrevivendo sozinha depois de a sessão suja ser excluída —, e essa
  metade **não** era declarada; foi consertada em `dfe4d63`. Ou seja: a parte que a QA chamou de
  contabilidade honesta é honesta, e a parte que não era virou conserto com probe. Registrar o item
  no `TODO.md` teria descrito o sintoma no lugar da causa.
- **A guarda `sessions[$ph] > 0` do `gate_pass_rows` sobrevive à sabotagem e NÃO é achado.** Está
  declarada verbatim no comentário (`DECLARED, NO PROBE`) e no `checkpoint.md`, com o mundo que a
  torna relevante nomeado (armar o marcador no ramo `over_ceiling`) e com a distinção que este repo
  pagou em `d4deb35`/`7cbc8e2`: "não consegui construir o mundo" e "esse mundo não existe" são
  afirmações diferentes, e o comentário faz a primeira. Dívida declarada é limite, não defeito.
- **O `^` das duas regexes de `historic_rounds` sobrevive à sabotagem e NÃO é achado**, pelo mesmo
  motivo: o cabeçalho diz qual mundo não foi construído e por que a âncora fica (desancorar só o
  `test`, com `capture` ancorado, mata o leitor em vez de errar a conta).
- **O braço da rodada do `def outcome` responde `advanced` para um `rounds_after` STRING** (`"2" > 1`
  é verdadeiro em jq), onde o irmão do EXEC falharia fechado. Não é achado: o construtor passa todo
  valor por `tonumber? // null`, então nenhum writer alcança a forma — só edição à mão do ledger,
  que é o mesmo limite declarado que o irmão já carrega. Medido, não suposto.
- **A varredura de âncoras de mutante não achou nada.** Os 213 mutantes do catálogo aplicados a uma
  cópia do `bin/sdd` atual: `ok=213 noop=0 syntax=0`. As três âncoras que a própria missão
  re-ancorou em `8322699` continuam mordendo.

## Achados fora de escopo

- **#6 — a guarda de fase da foto de REVIEW no `cmd_retry` não tem probe** — registrado no `TODO.md`
  (2026-08-31), `7c0a92a`.
- **#7 — a porta de `gate_failed` do retry inline não tem probe** — registrado no `TODO.md`
  (2026-08-31), `7c0a92a`.
- **#8 — `$order` × `comparable_row` divergem sobre a linha nova** — registrado no `TODO.md`
  (2026-08-31), `7c0a92a`.
- **#9 — missão só com `gate_pass` conta em `missions` sem célula** — registrado no `TODO.md`
  (2026-08-31), `7c0a92a`.

A catraca do backlog subiu de `87` para `91` em `tests/health-baseline.txt`, no mesmo commit:
crescer é permitido, crescer calado não.

⚠️ **Um achado real que esta rodada NÃO registrou, e a razão:** as âncoras `bin/sdd:NNNN` dos
artefatos desta missão apodreceram — 16 de 20 apontam para a linha errada, com desvios de 31 a 467
linhas, porque os artefatos foram escritos contra o `bin/sdd` de `bf001fe` e a missão o cresceu em
~530 linhas. Não virou item novo porque é **letra por letra** o item já aberto
*"22 das 33 âncoras do `TODO.md` apontam para a linha errada"*: mesma classe, mesma causa, mesma
direção de conserto (âncora durável é o NOME, não o número). Abrir um segundo item seria contar o
mesmo problema duas vezes numa catraca que existe para medir taxa de nascimento.

## Pendências / Decisions for a Human

- **A rodada fecha em `B` e o laço continua.** Duas portas do escritor do I4 (achados #6 e #7)
  afirmam cobertura que não têm, e a r2 as fecha com fixture de duas voltas — a sessão em que
  reprovam é o retry que PASSA, que nenhum fixture de hoje alcança. I1–I4 estão entregues e a
  métrica está medida; o que falta é o probe, não o conserto.
- **O carimbo de mutação está morto e a DOCS é quem re-carimba.** Esta rodada commitou em `bin/` e
  `tests/`, e `tests/health-baseline.txt` também está dentro da chave. `./bin/sdd health
  --with-mutation` (20–50 min) roda **depois do último commit de código** e antes do `gate_PR`; o
  catálogo tem agora **213** mutantes.
- **A régua mudou no meio da janela de medição, de propósito** (grill de 2026-08-31, decisão 1), e
  esta rodada a mudou **mais uma vez**: o `phase_label` de hoje não é o de `464b41d`. Quem citar
  números de rótulo depois desta missão tem de dizer com qual `bin/sdd` os leu — e o achado #1
  significa que qualquer leitura feita entre `715da79` e `d17aca6` pode carregar um `leve` ou um
  `ok` onde a verdade é `refez`.
- **`sdd approve 20260831-a-rodada-que-andou`** segue sendo o único destravamento do plano
  kaizen-born — contrato do `gate_PLAN`, não pendência desta fase.
