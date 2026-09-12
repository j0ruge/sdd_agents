---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
fase: REVIEW
rodada: 1
status: done
sessao: sdd-agents-12 [8e8f4c]
data: 2026-09-12 10:08
gate: "`bash tests/run-all.sh` → `suite green`, rc 0, 14 sensores; árvore limpa (`git status --porcelain` vazio) antes desta rodada escrever; 22 commits em `main..HEAD`. Achados reproduzidos com fixture sob `SDD_STATE_DIR` e controle negativo (ledger sem linha nova: buckets fecham 1=1); nenhum arquivo de código tocado por esta sessão."
---

# Review — rodada r1 — o juiz não mente sobre a janela

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Revisão do diff inteiro (22 commits, 16 arquivos, +1330/−168), com a QA em mãos. **12 achados: 4
HIGH, 3 MEDIUM, 5 LOW** — todos reproduzidos por comando, nenhum por leitura. As três métricas da
missão **estão cumpridas e foram re-verificadas por mim** (ledger limpo, catraca 95, guarda de
harness recusando). O que reprova é outra coisa: I4 e o filtro `$meta` acrescentaram duas classes
de linha que o cabeçalho de `sdd autonomy` conta e **nenhum bucket nomeia**, o `window_broken`
falha aberto na forma mais comum de missão, e os quatro campos novos da guarda saíram sem o único
leitor que existe para eles. Viraram **R1–R5**; esta rodada não conserta nada.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | Desenho forte e fiel ao `CLAUDE.md` — `is_close`, `graded_row` e `$harness_ok` escritos positivamente, uma definição por programa, `$every_row` separado de `$every_session` em vez de população borrada; mas dois leitores passaram a contar linhas que nenhum bucket nomeia, e o comentário do `$meta` afirma imunidade que o código não tem. |
| Type Safety | C | O contrato `guard.*` ganhou quatro campos (`why`, `harness`, `window_missions_stranded`, `window_broken`), foi para `docs/pipeline.md` e **não** foi para `agents/sdd-kaizen.md`, que segue lendo `(sessions, sufficient, degenerate_axis)` — é o "contrato quebrado em três lugares" que o `CLAUDE.md` chama de modo de falha mais caro do kit. A paridade de key-set entre os dois produtores do shape, essa sim, está asseverada. |
| Error Handling | B | `shellcheck -S warning` limpo, `bash -n` limpo, nenhuma captura SIGPIPE nova e nenhum `cd` relativo desguardado no código novo; o `retry-gate-red` fecha a porta silenciosa que o plano nomeou. Sobra um ramo: em `cmd_close` o `return 3` do chapéu cruzado corre **depois** da sessão paga e **antes** de `autonomy_close_row`. |
| Security | A | Varredura de segredos limpa (0 achados); nenhuma superfície de credencial nova — as linhas novas do ledger carregam `issue`, `session`, `rc`, `verified`, nada sensível, e `sdd close` não ganhou permissão nem ferramenta. |
| Performance | A | Nenhum caminho quente novo; o único custo quadrático da região (`history_of` sobre `$every_session`) já era declarado e o `history_rows_of` acrescentado segue a mesma forma e a mesma declaração, sobre um ledger real de 289 linhas. |
| Test Coverage | B | Os diferenciais novos são exemplares — `hmixed`/`hone`/`hfloor` e `winbroken`/`winwhole` diferem por uma tecla, cada um com piso anti-vacuidade, e os 11 mutantes novos estão todos registrados no `CATALOG` com âncora viva. O buraco é o complemento: nenhum `assert_bucket_sum` sobre as duas exclusões novas, nenhum regime de missão que atravessa o sha, e nenhum fixture de `close` no `check-kaizen.sh`. |
| Documentation | B | `docs/pipeline.md`, `CONTEXT.md` e `KAIZEN_LOG.md` documentam os campos novos com precisão e com antes/depois medido; contra isso, três contagens e frases que o próprio branch invalidou (`the eight call sites`, `written by 'sdd run' and 'sdd retry'`, o comentário citando `TODO:856`) e o agente do juiz não atualizado. |
| **Overall** | **B** | Missão substancial e bem executada: as três métricas do `00-missao.md` estão cumpridas e verificadas, a disciplina de asserção diferencial do repo foi respeitada, e os consertos de I1–I6 são reais. Ela não fecha porque a afirmação do título ainda não é inteiramente verdadeira — o `window_broken` falha aberto, e o juiz nunca foi ensinado a ler o que a guarda passou a dizer. São cinco incrementos, não um redesenho. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | A linha `event:"close"` é **admitida** por `cmd_autonomy` mas não cai em nenhum dos cinco buckets: entra no total do cabeçalho e some sem ser nomeada | `bin/sdd`, `cmd_autonomy` / `def is_close` (`:6123`) |
| 2 | HIGH | A exclusão `$meta` (KAIZEN) infla o total do cabeçalho pelo mesmo mecanismo, e o comentário ao lado afirma o contrário | `bin/sdd`, `cmd_autonomy` / binding `as $meta` (`:6211`) |
| 3 | HIGH | `window_missions_stranded` falha aberto: missão que atravessa a mudança de kit conta dos **dois** lados da subtração e some | `bin/sdd`, `kaizen_series` / binding `as $stranded` |
| 4 | HIGH | Os quatro campos novos da guarda não têm leitor: `agents/sdd-kaizen.md` está intocado no branch | `agents/sdd-kaizen.md:49-50` e `:79` |
| 5 | MEDIUM | `harness_mixed` veta `sufficient` para sempre, sem remédio nem override — e sem simetria com os dois irmãos estruturais | `bin/sdd`, `kaizen_series` / `sufficient:` |
| 6 | MEDIUM | `cmd_close`: o `return 3` do chapéu cruzado corre depois da sessão paga e antes de `autonomy_close_row` | `bin/sdd`, `cmd_close` |
| 7 | MEDIUM | A linha de `close` não carrega `cost_usd`/`dur_s`/`harness`: a sessão fica visível, o dinheiro dela não | `bin/sdd`, `autonomy_close_row` |
| 8 | MEDIUM | Nenhum fixture de `close` no `check-kaizen.sh`; os dois mutantes arrancam `is_close` **junto** com `is_gate_pass`, então um mutante estreito sobreviveria | `tests/check-kaizen.sh`; `tests/check-mutation.sh` |
| 9 | LOW | Contagens e frases que o próprio branch invalidou (`the eight call sites`; `written by 'sdd run' and 'sdd retry'`; comentário citando `TODO:856`) | `bin/sdd`; `tests/check-mutation.sh` |
| 10 | LOW | Os dois leitores discordam sobre linha KAIZEN malformada: `meta` de um lado, `unrecognized` do outro; `$stray` fica estruturalmente cego a corrupção em linha KAIZEN | `bin/sdd`, `cmd_autonomy` × `kaizen_series` |
| 11 | LOW | O invariante "não move `launch(es)` nem US$" só é asseverado no gêmeo livre, nunca no pago | `tests/check-autonomy.sh`, bloco `reopen_free`/`reopen_paid` |
| 12 | LOW | Blocos novos adjacentes chamam binários diferentes (`$SDD` × `$KSDD`) sem comentário que explique | `tests/check-kaizen.sh`, blocos novos |

### Como os quatro HIGH foram reproduzidos

**#1 e #2 — a aritmética dos buckets, com controle negativo.** A régua é a do próprio
`assert_bucket_sum` (`tests/check-autonomy.sh`), cujo cabeçalho já diz o que está em jogo: *"a row
the reader recognises has to be NAMED somewhere the arithmetic closes over, or 'recognised'
degrades into 'silently dropped' — which is the same defect as `unrecognized`, only quieter"*. O
total do cabeçalho **não** é `$local_total`: é a variável de shell `total`, calculada por um `jq -s
… map(select(ledger_row_is_local)) | length` antes do programa grande, que não sabe do filtro
`$meta`.

```
CONTROL (1 sessão, nenhum tipo de linha novo):
  header_total=1  sum(buckets)=1  OK
A) + uma linha close (I4):
  header_total=2  sum(buckets)=1  *** DRIFT ***
B) + uma linha KAIZEN meta (o filtro $meta):
  header_total=2  sum(buckets)=1  *** DRIFT ***
```

A suíte fica verde porque nenhum fixture com `assert_bucket_sum` ao lado carrega linha de `close`
(`grep -c '"event":"close"' tests/check-autonomy.sh` → `0`) nem linha KAIZEN local. Os probes de
`close` medem o **escritor** (`autonomy_close_row` escreve a linha certa); nenhum mede o **leitor**.

**#3 — `window_missions_stranded` falha aberto.** Ledger com a linha KAIZEN abrindo a janela e a
missão `20260902-m1` com `EXEC` em `aaaaaaa` e `QA` em `bbbbbbb` (o sha julgado):

```
{"latest":"bbbbbbb","stranded":0,"broken":false}
   ^ a grafia positiva responde 1 (a missão TEM linha fora do sha julgado)
```

Metade da evidência dessa missão foi comprada em outra versão do kit, e o campo que existe para
revelar exatamente isso responde `false`. A causa é a forma: `unique(missões da janela) −
unique(missões no sha julgado)` conta a missão que atravessa nos **dois** termos. A grafia
positiva — `map(select(.kit_sha != $latest)) | map(mission_key) | unique | length` — a conta. É a
mesma regra do `CLAUDE.md` que o resto do diff obedeceu: predicado de admissão se escreve
positivamente.

**#4 — contrato sem leitor.** `git diff main...HEAD --name-only -- agents/` é **vazio**.
`agents/sdd-kaizen.md:49-50` ainda enumera a guarda como `(missions_after_change,
missions_with_session, sessions, sufficient, degenerate_axis)`, e `:79` manda tratar
`sufficient: false` como estrutural **só** no caso `degenerate_axis`. `grep -n
'window_broken\|window_missions_stranded\|harness_mixed\|guard.why' agents/` não devolve nada. O
efeito é exatamente o que o comentário do próprio `bin/sdd` prevê para quem lê só o booleano:
*"a reader — human or gate — that sees only the boolean waits for missions that cannot help"*. O
campo `why` foi acrescentado para impedir essa leitura e o único leitor não foi avisado.
⚠️ O conserto sincroniza o espelho com `sdd install --force` — nunca `cp`, nunca Edit
(`CLAUDE.md`, seção dos agentes).

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | #1 — a linha `close` entra no total e não cai em bucket nenhum | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the buckets still sum to the header total (a close row)' <<< "$o"` → `1` ou mais |
| R2 | #2 — a exclusão `$meta` infla o total, e o comentário afirma o contrário | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the buckets still sum to the header total (a judge KAIZEN row)' <<< "$o"` → `1` ou mais |
| R3 | #3 — `window_missions_stranded` falha aberto na missão que atravessa o sha | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    guard: a mission straddling the kit change is stranded' <<< "$o"` → `1` ou mais |
| R4 | #4 — o juiz aprende a ler `why`, `harness` e a janela rompida | `grep -c 'window_broken' agents/sdd-kaizen.md` → `1` ou mais |
| R5 | lote dos achados #6–#9 da r1 (dois MEDIUM de `close`, o regime de `close` no juiz, as contagens podres) | `o=$(bash tests/run-all.sh 2>&1); a=$(grep -c '^  ok    close row carries cost_usd' <<< "$o"); b=$(grep -c '^  ok    close writes its row even when the hat guard fires' <<< "$o"); c=$(grep -c '^  ok    guard: a close row mints no version and no mission' <<< "$o"); echo "$a$b$c"` → `111` |

⚠️ **Ordem operacional, e ela já custou uma Jidoka nesta missão.** Todo `R<n>` acima toca `bin/` ou
`tests/`, o que **mata o carimbo de mutação** `17591a68…` que o `gate_PR` exige. O `./bin/sdd
health` (20–50 min) roda **depois do último commit de código de R1–R5**, nunca entre eles. Nenhum
achado desta rodada foi para o `TODO.md` **de propósito**: acrescentar item lá move
`tests/health-baseline.txt`, que está dentro da chave do carimbo, e pagaria o `sdd health` duas
vezes.

## O que virou incremento

- #1, a linha `close` reconhecida e não contabilizada — virou `R1` — fecha quando existir um
  `assert_bucket_sum` sobre um ledger que carrega uma linha `close` e o total do cabeçalho voltar a
  igualar a soma dos buckets (bucket novo nomeado, ou a linha fora do `total=`).
- #2, o `$meta` inflando o cabeçalho — virou `R2` — fecha quando o `total=` conhecer o filtro
  KAIZEN (ou o filtro sair do programa grande) e o comentário passar a descrever o que o código
  faz; a asserção é um `assert_bucket_sum` sobre ledger com linha KAIZEN local.
- #3, o `window_broken` cego à missão que atravessa — virou `R3` — fecha com a grafia positiva
  (`select(.kit_sha != $latest)`) e um regime de fixture em que uma missão tem linhas nos dois
  shas; o par `winbroken`/`winwhole` de hoje não cobre esse regime.
- #4, o contrato sem leitor — virou `R4` — fecha quando `agents/sdd-kaizen.md` mandar ler `why`,
  `harness`, `window_missions_stranded` e `window_broken`, com o espelho sincronizado por
  `sdd install --force`.
- #6, #7, #8 e #9 — viraram o lote `R5` — a linha de `close` passa a carregar seu custo, a porta do
  chapéu cruzado deixa de comê-la, o `check-kaizen.sh` ganha o regime de `close` (com mutante que
  arranque `is_close` **sozinho**, sem `is_gate_pass` junto) e as três frases podres são corrigidas.
  ⚠️ O Check de `R5` cobre #6, #7 e #8 por asserção; **#9 não entra nele** porque a célula do
  checkpoint só admite padrão ancorado em `^  ok    ` (regra cobrada por `tests/check-checkpoint.sh`,
  que reprovou a primeira grafia desta linha). As três frases se conferem na r2 por
  `grep -c 'the eight call sites' bin/sdd` → `0`.

Os achados **#5, #10, #11 e #12** não viraram incremento: o #5 é decisão humana (abaixo), e os três
últimos são LOW de baixo valor que ficam registrados aqui — a rota normal seria o `TODO.md`, e ela
está fechada nesta missão pelo preço do carimbo descrito acima.

## O que foi refutado

- **"I1(a), a guarda de escrita do ledger, não foi entregue"** — refutado. O commit `5956e80` só
  apaga as 11 linhas, mas a guarda existe e é anterior: `bin/sdd:2886-2889` recusa escrever no
  ledger real quando o checkout está sob o diretório temporário (`die "refusing to write the real
  autonomy ledger…"`), entregue pela ADR 0005 parte 3 em `28af7ea`, com as asserções `writer:` e o
  mutante `mut_LEDGER_tmp_repo_allowed`. O executor registrou isso honestamente na mensagem de
  commit em vez de reivindicar trabalho que não fez.
- **"A célula do laço de revisão pode passar de 100%"** — refutado. Numerador e denominador foram
  movidos **juntos** para `$every` (`$loop` e `$whole`), então o numerador é subconjunto do
  denominador por construção. Medido: `review loop US$ 2.00 (67%)`.
- **"O `close` contamina a série do juiz"** — refutado. Com três sessões e uma linha `close` no
  mesmo sha: `missions: 3`, `detail_cells: 3` (todas `EXEC`), `composition.missions: 3`,
  `excluded` tudo zero. `graded_row` e `shas_in_file_order`, ambos positivos, mantêm a linha fora —
  o `close` não cunha versão, não vira missão e não deixa célula fantasma.
- **"O par US$/percentual do laço de revisão é um defeito de exibição não declarado"** — refutado.
  O parágrafo de contabilidade foi atualizado no mesmo diff e dispara exatamente quando as duas
  populações divergem (`launches, reopened and the review loop are counted over every session of
  the mission, N of them non-comparable`). É limite declarado, no código e em `docs/pipeline.md`.
- **`reopened` e a métrica 3** — verificados como **corretos**, não refutados: um `gate_pass` livre
  seguido de novo `EXEC` responde `1 reopened` (antes lia 0 quando a fase não custara dinheiro), e
  uma fatia com duas versões de harness responde `sufficient: false, why: ["harness_mixed"]`.

## Achados fora de escopo

Nenhum. Nada desta rodada foi para o `TODO.md`, e a omissão é deliberada: o arquivo está dentro da
catraca (`todo-findings 95`) cujo movimento invalida o carimbo de mutação que o `gate_PR` exige.
Os quatro achados que não viraram `R<n>` (#5, #10, #11, #12) ficam registrados neste relatório.

## Pendências / Decisions for a Human

1. **`harness_mixed` veta `guard.sufficient` para sempre, e isso foi o que o plano pediu** (métrica
   3 do `00-missao.md`, aprovada em `aprovacao: humano-2026-09-11`). Reproduzido: uma fatia que
   atravessa um bump de harness responde `sufficient: false` com o piso já batido, e **cinco
   missões novas na versão nova não curam** — `$harness` é `unique` sobre a fatia inteira, que é
   presa ao `kit_sha`:

   ```
   A) 3 missões, piso batido, harness 2.1.262 + 2.1.263 → sufficient:false, why:["harness_mixed"]
   B) +5 missões, todas em 2.1.263                      → sufficient:false, why:["harness_mixed"]
   ```

   Consequência: `gate_KAIZEN` (`bin/sdd:7048-7052`) aceita **só** `indeterminado` enquanto
   `sufficient` for falso, então esse `kit_sha` nunca pode ser graduado `melhorou`/`piorou`. O gate
   continua satisfazível — o veredito `indeterminado` fecha —, então **não** é a classe "gate
   insatisfazível" do princípio 1; é um veredito permanentemente mudo sobre uma versão, sem remédio
   e sem override. Os dois irmãos estruturais não vetam: `degenerate_axis` nunca entrou em
   `sufficient`, e `window_broken` foi deliberadamente escrito para **não** vetar ("It does NOT
   veto"). `harness_mixed` é o único que veta, e a assimetria não está argumentada em lugar nenhum.
   Num repo-alvo o custo é maior: o `kit_sha` fica parado por definição, então um alvo que bumpou o
   Claude Code no meio da janela fica trancado até o **kit** mudar.
   **Não escrevi `R<n>` para isto de propósito** — reverter o veto contraria a métrica que o humano
   aprovou, e concordar performaticamente com uma crítica é pior que o achado. As três saídas são:
   (a) manter como está, aceitando `indeterminado` como resposta honesta; (b) rebaixar
   `harness_mixed` a anotação, como `window_broken`; (c) manter o veto e acrescentar um override
   humano registrado em artefato, como já existe para outras portas. É decisão de desenho, não de
   execução.

2. **Prioridade, herdada do `00-missao.md` e ainda aberta:** as pendências 1 (`BUDGET_MISSION_USD`
   calibrado abaixo do custo real) e 2 (o laço de revisão a 66%) continuam sem dono. Esta rodada
   não as toca; só registra que seguem abertas com a missão prestes a fechar.
