---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 9
status: done
sessao: rodada do worker (o ato review do commands/sdd-worker.md), feita por um subagente sdd-reviewer da sessão orquestradora, fora do runner, com escopo delta 67fb6f9..95a1b31 (a skill invocada com base=67fb6f9290bab52fdb474dce7765c36de3b8fc1b, rodada de verificação)
data: 2026-11-19 07:48
gate: tests/run-all.sh no 95a1b31 verde, rodado pela sessão orquestradora (rc 0, suite green, 2165 linhas ok e nenhuma linha FAIL, anchors 903 de 903, 838 s, 07:23:42 a 07:37:40, head_after igual ao head) e run-checks.py sobre as 31 linhas done do checkpoint (31 de 31 no esperado, rc 0, 2560 s); nesta rodada shellcheck -S warning limpo e bash -n rc 0 no bin/sdd-worker e no tests/check-worker.sh, check-todo.sh rc 0 (91 achados, every anchor on target), check-checkpoint --check rc 0 e --red com o R19 vermelho no head, segredos (regex e gitleaks, 8 arquivos, 277 linhas acrescentadas) sem achado, o tests/check-worker.sh inteiro em três cópias mktemp do head em paralelo (A, o head, rc 0 e 67 probes; B, com o leitor da fonte (b), rc 1 e só a família discarded vermelha, 102.00 no lugar de 17.00 e 10.00; C, o leitor sem o campo no fixture, rc 0 e as mesmas linhas ok de A), as cópias apagadas no fim; árvore limpa no 95a1b31; nota A em todo critério, as mesmas letras da r8, nenhum achado de severidade e um lote de LOW (R19)
reviewed_head: 95a1b3179e6ed852df12e00344c50ab0e54fb445
---

# Review — rodada r9 — O worker orquestrador

## TL;DR

Rodada delta do worker sobre `67fb6f9..95a1b31` (o R18 em `8f741f5`, a decisão das 06:21 em `a1f98d3`, a r8 em `c2545d2` e os commits de checkpoint e handoff), pela régua do dono das 20:30.
Os dois LOW da r8 fecharam como o R18 dizia, refeitos em três cópias, e o `KAIZEN_LOG.md` conta dezoito `R<n>`.
Nenhum CRITICAL, HIGH nem MEDIUM de confiança: nota A em todo critério, como na r8.
Dois LOW novos, ambos do delta, viram o lote R19, que não segura a nota. Nada foi consertado aqui.
A parte (a) do R19 só mexe no checkpoint; a parte (b) mexe em `tests/` e compraria uma r10 (pendência 1).

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O delta de código são dois comentários e um `jq -c` no laço do fixture da R69; nenhum símbolo novo (Bucket A vazio), e `shellcheck -S warning` e `bash -n` passam limpos nos dois arquivos. |
| Type Safety | A | Nenhuma linha executável do `bin/sdd-worker` mudou; o campo novo do fixture é um objeto que o `jq -c` mescla na linha do `spent`, e com o código de hoje as 67 probes dão as mesmas linhas inteiras (cópia A). |
| Error Handling | A | O laço do fixture roda sob `set -uo pipefail` sem `-e`, e um `jq` que falhasse deixaria o ledger sem a linha e a `discarded: ` vermelha pela soma, nunca calada; o `budget` não mudou no delta. |
| Security | A | Nenhum verbo que concede mudou no delta, e a varredura de segredos (regex e gitleaks, 8 arquivos, 277 linhas acrescentadas) não achou nada. |
| Performance | A | Nada executável mudou no programa; o `check-worker.sh` inteiro rodou em 46 s em três cópias em paralelo. |
| Test Coverage | A | O achado #1 da r8 fechou: com o leitor da fonte (b) a `discarded: ` fica vermelha e só ela (cópia B), e sem o campo no fixture fica verde (cópia C); o Check do R18 não distingue as duas (achado #1), LOW do lote R19, que pela régua não segura a nota. |
| Documentation | A | O achado #2 da r8 fechou: o comentário do `cmd_budget` conta os três gastos como o `docs/pipeline.md` e a ADR 0022 §8, sem perder a frase que a `ceiling: ` lê; sobra a frase irmã dos Declared limits of R69 (achado #2), no lote R19. |
| **Overall** | **A** | Nenhum CRITICAL, HIGH nem MEDIUM de confiança: os dois LOW da r8 fecharam pelo R18 (`8f741f5`), e os dois LOW novos vão ao lote R19. |

## Movimento contra a r8

As mesmas letras: A em todo critério na r8 e aqui. Pelo chapéu, letras iguais são platô, mas um
platô em A é o laço fechado pela nota, não parado: nada abaixo de A sobra para subir. Atrás desta
rodada há um commit de conserto, `8f741f5` (R18), e o que ele prometia está refeito abaixo. O que
resta é o lote R19, de dois LOW, e se ele compra uma rodada é decisão do dono (pendência 1).

## Relatório da skill

- **Round:** verificação sobre `67fb6f9...95a1b31` (`base=` colado do `40-review-r8.md`,
  `git merge-base --is-ancestor` rc 0, os achados abertos da r8 lidos da tabela dela, codereview
  2.30.1, `prose_units.py` rc 0 com 6 arquivos de prosa, 2 de código, 92 unidades). Não rodou inteira.
- **Secrets Detection:** PASS, 0 linhas (`scan_secrets.sh`, regex e gitleaks, 8 arquivos, 277
  linhas acrescentadas, nenhum erro).
- **Fase B:** dois arquivos de código (`bin/sdd-worker`, só comentário no delta, e
  `tests/check-worker.sh`), lidos inline pela sessão, como a skill manda com até três. A varredura
  de código morto também foi inline: o delta não define função nem global nova (Bucket A vazio).
- **Verificador:** um agente sonnet sobre cinco arquivos de prosa (`KAIZEN_LOG.md`, `TODO.md`, o
  `20-handoff-exec.md`, o `checkpoint.md` e as notas; 23 unidades), relançado uma vez, como o contrato
  manda quando o `Units read:` fica abaixo do que recebeu: as duas passadas voltaram com 22 de 23. Os
  cinco arquivos tomaram então o fluxo de hoje, feito inline pela sessão sobre o diff inteiro deles,
  como na r8. As duas passadas não acharam nada contradito; a única nota delas está em "Achados fora
  de escopo".
- **Fora do verificador:** o `40-review-r8.md`, o relatório da rodada anterior, cujas afirmações datam
  do `67fb6f9`. Os achados dele fecham em "O que virou incremento", refeitos aqui.
- **Cost footprint:** dois verificadores sonnet (cerca de 250 mil tokens somados), nenhum agente por
  arquivo, Fases A, B, B2 e C no modelo principal; três corridas do `check-worker.sh` em cópias.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | A parte (c) do Check do R18 conta `campaign: "di-gone"` no bloco da R69, e o comentário da linha 4760 basta para ela: numa cópia com o laço do fixture de volta ao `spent … >> …` sem o `jq` (o defeito do achado #1 da r8 de volta, e a família verde com o leitor da fonte (b)), o Check segue `1 0 0 0`. O Check que o `run-checks.py` relê antes de cada rodada não guarda a parte (a) do conserto | `docs/handoffs/20261117-o-worker-orquestrador/checkpoint.md:51` (a parte `c=` do Check do R18), `tests/check-worker.sh:4760` |
| 2 | LOW | Frase irmã da contagem de gastos que o R18 mudou no `cmd_budget`: os Declared limits of R69 dizem que as duas frases do `docs/pipeline.md` (o parágrafo **The campaign ceiling is a hard limit.**) e do template contam a campanha passando do assinado "only by the runner's overrun and by this spend". Desde o R17 (c) e o `a8b09ee` elas contam três gastos, o terceiro o da sessão que orquestra e dos subagentes dela (`docs/pipeline.md:2000` a `2003`, `templates/delegation.md:72` a `76`) | `tests/check-worker.sh:460` |

### Reprodução

- **#1:** três clones do head em `mktemp -d` no scratchpad, cada um sob `timeout -k 10 600` e
  `prlimit --as` de 4 GB, com `TMPDIR` próprio. A, o head como está: `tests/check-worker.sh` rc 0,
  `ok    discarded: …`, 67 probes. B, com o leitor da fonte (b) no `cmd_budget` (o `select` do jq
  admitindo também `.campaign == $cid`, com `--arg cid` lido do `campaign:` da delegação, a cópia B da
  r8): rc 1, e o diff das linhas `ok` de A e B é só a `discarded: ` e o total, com `closed removed: …
  'campaign US$ 102.00 of 200.00 — 2 mission(s) …' (want … 17.00 …)` e `dropped removed: … 102.00 …
  (want … 10.00 …)`. C, o leitor de B com o laço do fixture sem o `jq -c '. + {campaign: "di-gone"}'`:
  rc 0, as mesmas linhas `ok` de A. Então é o campo do fixture, e só ele, que deixa a família vermelha
  no dia da fonte (b). O Check do R18 em A dá `1 0 0 0` (`c=2`: o comentário e a linha do `jq`), e em C
  também `1 0 0 0` (`c=1`: só o comentário da linha 4760).
- **#2:** `grep -n "only by the runner's overrun and by this spend" tests/check-worker.sh` → `460`,
  escrita no `998d077` (R16), antes do R17 (c); o `docs/pipeline.md:2000` a `2003` e o
  `templates/delegation.md:72` a `76` contam os três gastos, e a ADR 0022 (linha 130) também.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R19 | #1 e #2 (lote de LOW) | `r=$(grep '^. R18 .' docs/handoffs/20261117-o-worker-orquestrador/checkpoint.md); a=$(grep -cF '{campaign: "di-gone"}' <<< "$r"); d=$(sed -n '/^# Declared limits of R69/,/^# Declared limits of R67/p' tests/check-worker.sh); b=$(grep -c "only by the runner's overrun and by this spend" <<< "$d"); c=$(grep -c 'orchestrating' <<< "$d"); test "$c" -ge 1; echo "$a $b $?"` → `1 0 0` |

Nasceu vermelho no head: o Check imprime `0 1 1`. O R19 não acrescenta linha `ok` a família nenhuma.

## O que virou incremento

- **#1 e #2 viram o lote `R19`**, com Check de comando e a suíte, sem passada de sabotagem nem
  mutante (régua do dono, item 3):
  - (a) a parte (c) do Check do R18 passa a contar a grafia do código, o objeto
    `{campaign: "di-gone"}` do `jq -c`, que o comentário da linha 4760 não carrega; só o
    `checkpoint.md` muda, e o R18 segue `done` com o Check novo dando `1 0 0 0` no head e `1 1 0 0`
    numa cópia como a C;
  - (b) a frase dos Declared limits of R69 passa a contar os três gastos que as duas frases lidas
    contam, ou deixa de contá-los, sem tocar as frases que a `discarded: ` e a `ceiling: ` leem.

**Achados da r8, fechados pelo R18 e conferidos aqui:**

- **#1 → R18 (a), `8f741f5`.** As três linhas de ledger do fixture levam `campaign: "di-gone"`
  (`tests/check-worker.sh:4794`), e o cabeçalho (453 a 456), o comentário do bloco (4760 e 4761) e o
  handoff (linha 96) dizem o que o fixture grava. Refeito nas cópias A, B e C acima: com o código de
  hoje nada muda, com a fonte (b) a família fica vermelha, e é o campo que a deixa.
- **#2 → R18 (b), `8f741f5`.** `grep -c 'never past the one signed' bin/sdd-worker` → `0`, e a frase
  nova (757 a 762) conta os três gastos como o `docs/pipeline.md:2000` a `2003` e a ADR 0022 §8: os
  dois primeiros apontam para os Declared limits do mesmo comentário (o excesso do runner na linha 763
  e a missão largada no parágrafo do R16), o terceiro diz que fica fora dos dois tetos. A frase "never
  passes the signed" segue na linha 755, que a `ceiling: ` lê (`tests/check-worker.sh:4485` e `4493`),
  e as do limite e do remédio, que a `discarded: ` lê, seguem lá (cópia A verde).
- **(c) → R18 (c), `8f741f5`.** O `KAIZEN_LOG.md` diz dezoito `R<n>`, e a lista por rodada soma 18
  (2+2+1+5+3+2+2+1, com "R18 da r8"); `grep -c 'dezessete .R<n>.' KAIZEN_LOG.md` → `0`.
- **Decisão das 06:21 → `a1f98d3`.** A rota (a) está na nota do checkpoint, e esta rodada é a r9 que
  ela pedia.
- **Grafias antigas procuradas** em `bin/`, `tests/`, `commands/`, `docs/` (fora os handoffs, que são
  registro), `templates/`, `KAIZEN_LOG.md`, `CONTEXT.md` e `README.md`: "never past the one signed" e
  "dezessete `R<n>`" dão zero; "never passes the signed" segue no `bin/sdd-worker:755` e nas quatro
  leituras do sensor. Procuradas também as irmãs da contagem ("overrun", "by this spend", "past its
  own cap", "orchestrating session", "passa do assinado"): a única que conta dois gastos é a do
  achado #2; as linhas 306 e 482 do sensor dizem só que os textos escrevem a fase que o runner pode
  gastar além do teto, o que segue verdade. Nenhuma interface de verbo mudou no delta.
- **A âncora do `TODO.md`.** `bin/sdd-worker:1214` (`cmd_pr_ready`) andou as quatro linhas que o
  comentário do `cmd_budget` cresceu, e o `check-todo.sh` responde rc 0, every anchor on target.

## O que foi refutado

- **"O Check do R18 dá `1 0 0 0` por acaso"** não vale para o head: em A, `c=2` conta o comentário e
  a linha do `jq`, e o `a`, o `d`, o `e` e o `f` leem o que o R18 escreveu. O que vale é o achado #1:
  o Check passaria também sem o conserto da parte (a).
- **"Um `jq` que falhasse no laço do fixture calaria a família"** não se sustenta: o sensor roda sem
  `-e`, e a linha que não fosse escrita tiraria o gasto dela da soma, então o `disc_is` de `alive`
  já leria menos que 102.00 e a família ficaria vermelha.

## Achados fora de escopo

Nenhum registrado no `TODO.md` nesta rodada. Citado, de forma:

- O `20-handoff-exec.md:147` diz que o R18 "mexeu num fixture do sensor, num comentário do
  `bin/sdd-worker` e no `KAIZEN_LOG.md`" e deixa de fora a âncora do `TODO.md` e o cabeçalho do
  sensor (verificador, LOW form). A frase é sobre o que quem usa o kit vê, e a lista do R18 no mesmo
  arquivo (linha 117) nomeia a âncora. Forma, numa linha do delta, sem consumidor fora da suíte: não
  entra pela régua D15 nem compra lote.

## Pendências / Decisions for a Human

1. **O R19 e uma r10.** O item `review` do `pr-ready` aceita depois do `reviewed_head:` só commit
   que toca a pasta da missão (`docs/pipeline.md`, item 1). A parte (a) do R19 só muda o
   `checkpoint.md`; a parte (b) muda o `tests/check-worker.sh`, e depois dela o `pr-ready` responde
   `not-ready review` até uma rodada reler o head. Três rotas:
   - (a) o executor fecha o R19 inteiro, e uma r10 delta sobre `95a1b31..<head>`, só do lote,
     regrava o `reviewed_head:`, como a r9 fez com o R18;
   - (b) o executor fecha só a parte (a), que não compra rodada, e a parte (b) fica registrada aqui
     como frase de comentário do sensor que conta dois gastos onde o texto lido conta três; a linha
     do R19 é reescrita com o Check só da parte (a), e a decisão fica na nota do checkpoint;
   - (c) o merge sai sobre esta rodada com o R19 `pending`, a forma que você recusou às 06:21 para o
     R18.

   Recomendo (b): a parte (a) é a que guarda um conserto (o campo do fixture, que nenhum outro sensor
   lê hoje), e custa uma sessão leve sem rodada; a parte (b) é uma frase de comentário sobre prosa
   não lida, cujo erro não muda verbo, sensor nem gate, e uma r10 por ela repetiria o laço de prosa
   que a régua das 20:30 existe para cortar. Se preferir a simetria com as 06:21, a (a) custa o R19
   inteiro e uma r10 de dois arquivos.
2. **Seguem as da r8, da r7, da r6 e da missão.** A fonte da missão largada é o item do `TODO.md` (o
   `campaign:` na linha `session` do ledger, no `bin/sdd`); o fixture já grava o campo. O `pr-ready`
   não lê o corpo de uma revisão nem o `local/ci` (item aberto no `TODO.md`). Seguem as pendências do
   `00-missao.md`: assinar a delegação, o pager do kit, o espelho de issues, o `aprovacao:` sob
   `full`, a rule e o carimbo. O merge do PR #414 continua com você.

## Boot da próxima fase

EXEC do `R19`, uma sessão, no worktree `/home/joruge/repos/sdd_agents-worker`, na rota que o dono
escolher (pendência 1). Leia a linha do R19 no `checkpoint.md` e o parágrafo dele em "O que virou
incremento" acima; a cópia C de "Reprodução" é o mundo em que o Check novo do R18 tem de ficar fora
do esperado.

- É um lote de LOW: Check de comando e a suíte, sem passada de sabotagem nem mutante.
- Na parte (a), o R18 continua `done`; só a parte `c=` do Check dele muda, sem `|` cru na célula.
- Na parte (b), não toque as frases que a `discarded: ` lê (`DISC_LIMIT`, `DISC_REMEDY`) nem a
  "never passes the signed", que a `ceiling: ` lê.
- Rode `shellcheck -S warning` no `tests/check-worker.sh` e o `tests/check-todo.sh` antes do commit,
  não a suíte inteira: a sessão orquestradora a roda no fim.

Se houver r10, ela é do worker, delta, com `base=95a1b3179e6ed852df12e00344c50ab0e54fb445` e esta
tabela de achados.
