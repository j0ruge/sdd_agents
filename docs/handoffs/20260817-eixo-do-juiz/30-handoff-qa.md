---
missao: 20260817-eixo-do-juiz
fase: QA
status: done
sessao: d43ad98c-a6c7-460b-92e8-943a5c1c108d
data: 2026-08-17 13:05
gate: "projeto SEM interface (E2E_CMD e APP_URL vazios): as jornadas são comandos, andadas nesta sessão. (1) `bash tests/run-all.sh` → `suite green`, `score: 60 caught, 0 known gap(s), of 60` (medido ANTES do sensor novo). (2) `./bin/sdd health` → ok nos cinco. (3) `./bin/sdd kaizen --series | jq .guard` → `degenerate_axis: true`, `sufficient: false`. (4) `./bin/sdd kaizen --dry-run` → imprime `the kit_sha axis is degenerate here` citando `ADR 0003`. (5) `./bin/sdd autonomy` 52 linhas / `--all-repos` 63 linhas, cabeçalho `all repos (--all-repos)`, `other_repo` 11 → 0 — as duas saídas comparadas entre si, nunca contra constante. (6) `./bin/sdd help` documenta `--all-repos` com o porquê do default. (7) `git worktree add` + linha escrita de lá: checkout principal e worktree leem `sessions:1 other:0` os DOIS — identidade sobrevive. (8) balde `no_repo` em fixture diferencial: 3 sessões sem `repo` → `sufficient:false no_repo:3`; as MESMAS 3 com `repo` → `sufficient:true no_repo:0`; `--all-repos` não as admite. (9) jornada `sdd kaizen --all-repos` → **1 achado confirmado**, virou `BUG-1`, sensor `one series` em `tests/check-kaizen.sh` (vermelho com o bug presente, verde com o conserto simulado em worktree) e incremento `F1` pendente no checkpoint. Suíte AGORA vermelha de propósito (Jidoka), em exatamente 2 linhas esperadas."
---

# Handoff — QA — o eixo do juiz

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Nove jornadas de linha de comando andadas; oito confirmam a missão exatamente como o
`00-missao.md` prometeu. A nona — `sdd kaizen --all-repos`, a flag que o I3 criou — achou **1
defeito**: a flag alcança o gate e **não** alcança o prompt que o agente recebe, o que torna a
fase KAIZEN insatisfazível e custa duas sessões opus até `BLOCKED`. Virou sensor durável (2
asserções + 1 testemunha, vermelhas agora) e o incremento **`F1`**, pendente. A suíte está
**vermelha de propósito** até o F1 fechar. A próxima fase é **EXEC**, não REVIEW.

## Estado do repo

- **Branch:** `missao/20260817-eixo-do-juiz` — nunca empurrada; `origin` não conhece esta branch.
- **Último commit:** o desta sessão de QA (sensor + checkpoint + handoff).
- **Working tree:** limpo depois do commit desta sessão.
- **Suíte:** `tests/run-all.sh` → **vermelha, por construção**. Exatamente **2** linhas vermelhas,
  as duas esperadas e as duas fechadas pelo F1:
  1. `FAIL  one series: under --all-repos the gate demands the sha the prompt hands the agent`
  2. `FAIL  HARNESS-BROKEN: the copy is not green even without sabotage` — **não é defeito do
     harness**: é o *control run* do `check-mutation.sh` recusando-se a medir mutação sobre uma
     suíte que já não está verde. Some junto com a primeira.
  Antes do sensor novo a suíte estava verde, `score: 60 caught, 0 known gap(s), of 60`, e num
  worktree com o conserto aplicado à mão volta a ficar verde com `one series` = 2 — medido, não
  suposto.
- **E2E:** `E2E_CMD` vazio e sem `APP_URL`. Projeto **sem interface**: `docs/qa/` não existe e
  **não foi criado** (o gate lê a evidência do `gate:` deste arquivo). As jornadas são comandos e
  estão listadas lá, uma a uma, com o que se observou.

## O que foi feito

- `00ad6fb` — nasce a asserção `one series` em `tests/check-kaizen.sh` (2 asserções contadas + 1
  testemunha de regime), o incremento `F1` no `checkpoint.md` e este handoff. Nenhuma linha de
  `bin/sdd` foi tocada: QA não conserta produção.

## O achado — `BUG-1`

**Uma invocação, duas séries.** `gate_KAIZEN` chama `kaizen_series` **em processo**, então toda
opção de ledger que a invocação carregar o alcança. O prompt de boot do KAIZEN (`bin/sdd:771`)
entrega ao agente uma **linha de comando escrita à mão**:

```
  1. run: "$SDD_HOME/bin/sdd" kaizen --series
```

`--all-repos` alcança o primeiro e não alcança a segunda. O plano desta missão já nomeava a
invariante, no "Contexto verificado": *"`gate_KAIZEN` exige `guard.sufficient` da MESMA série que o
agente é mandado citar"*. A flag nascida no I3 (`d62f08c`) a quebra.

**A consequência não é número errado — é fase insatisfazível.** O prompt manda escrever
`kit_sha_judged:` = "the series' latest kit_sha"; o gate procura um veredito cujo `kit_sha_judged`
seja o `latest` da **sua** série. Dois `latest`, nenhum veredito que o agente possa escrever e o
gate aceite: gate reprova → o runner repete uma vez → a segunda sessão escreve o mesmo sha →
`BLOCKED in KAIZEN — no-progress`, `autonomy_blocked_row`, rc 3. **Duas sessões opus compram uma
linha `blocked`.**

Medido à mão, mesmo repo, mesmo ledger de fixture (3 missões do kit num sha antigo + 3 de outro
repo num sha mais novo), diferença de uma flag:

| comando | observado |
|---|---|
| `sdd kaizen --dry-run` | `the born plan is already approved` — **nenhuma sessão gasta** |
| `sdd kaizen --dry-run --all-repos` | projeta uma sessão cujo prompt cita `kaizen --series` **sem** a flag |

E no fixture divergente: `--series` devolve `latest: qqq1111`, `--series --all-repos` devolve
`latest: zzz9999`. A flag sozinha decide se uma sessão é gasta, **e a sessão gasta lê a série
errada**.

⚠️ **Por que o ledger real não mostra isso hoje:** as linhas do próprio kit são as mais recentes,
então os dois `latest` coincidem (`47379ef` nos dois). O defeito acorda no dia em que missões
rodarem em repo-alvo — que é exatamente o cenário que o **ADR 0003** diz ser a única fonte
legítima de veredito. O sensor põe o fixture no regime que diverge de propósito, e afirma essa
divergência como **testemunha**, porque num fixture não-divergente o runner quebrado marca 2 de 2.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `tests/check-kaizen.sh` | seção `one series behind the verdict`: 2 asserções contadas + 1 testemunha de regime + os helpers `gate_sha`/`judge_prompt_sha` |
| `docs/handoffs/20260817-eixo-do-juiz/checkpoint.md` | a linha `F1` (`pending`) e 8 notas de execução `QA` — é lá que mora o detalhe caro do sensor |
| `docs/handoffs/20260817-eixo-do-juiz/30-handoff-qa.md` | este arquivo |

## Boot da próxima fase

**A próxima fase é `EXEC`, não `REVIEW`.** `current_phase()` devolve a primeira fase cujo gate
falha, e `gate_EXEC` reprova antes de chegar ao `TEST_CMD`, por causa do `F1` `pending`. É o laço
QA⇄EXEC funcionando; não há nada a consertar no runner por causa disso.

Ler, nesta ordem: `00-missao.md`, `20-handoff-exec.md`, este arquivo, e as notas `QA` do
`checkpoint.md`.

O conserto do `F1` — **decisão registrada, não re-litigar**: `--all-repos` **propaga** para a
linha do prompt, em vez de ser recusada fora de `--series`. O humano que digitou a flag pediu a
leitura entre projetos; honrá-la nos dois lados restaura a invariante sem remover nenhuma
capacidade, e recusar removeria uma que ele pediu explicitamente. A alternativa (recusar
`--all-repos` no caminho do veredito) está em "Decisions for a Human" abaixo, **não bloqueia**, e
se o humano a escolher o sensor muda com ela.

Forma verificada num worktree, à mão, com a suíte inteira verde depois:

```
  1. run: "$SDD_HOME/bin/sdd" kaizen --series${LEDGER_ALL_REPOS:+...}
```

O `F1` exige também a mutação `KAIZEN_prompt_series_unflagged` no `tests/check-mutation.sh`
(catálogo 60 → 61) — é ela que prova a última milha da asserção, e o Check do incremento ancora no
`ok` dela justamente porque o *control run* só imprime essas linhas com a suíte verde.

⚠️ Duas armadilhas já pagas nesta sessão, para não se repetirem no conserto:
- o `eval` da linha do prompt tem de rodar no `cwd` e no `SDD_STATE_DIR` do runner; no ambiente
  do arquivo de teste ele lê o **outro** ledger de fixture e os dois lados voltam iguais por um
  motivo que nada tem a ver com a flag;
- a testemunha do regime afirma a **propriedade** (`differ`), nunca o par literal de shas — par
  literal é movido em conjunto por qualquer edição de fixture, e foi assim que a primeira versão
  do sensor reportou `ok` sobre um fixture que deixara de divergir.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **O juiz pode, em política, julgar o kit com linhas de repo-alvo?** O `usage()` do runner diz
  que "the judge must never take another project's rows as a verdict about this kit"; o **ADR
  0003** diz que a evidência de veredito **vem** de repo-alvo real. As duas frases convivem hoje
  só porque ninguém rodou `sdd kaizen --all-repos` a sério. O `F1` restaura a invariante sem
  responder isso: mantém as duas metades lendo uma série só, qualquer que seja a escolhida. Se a
  resposta for "não", o conserto vira *recusar* a flag fora de `--series` e o sensor
  acompanha — material de **ADR 0004**. Onde ver: `bin/sdd` `usage()` (`--all-repos`) e
  `docs/adr/0003-judge-axis-evidence-from-target-repos.md`.

## Riscos e não-feitos

- **A suíte fica vermelha até o F1 fechar.** É Jidoka, e é a única forma de o achado virar sensor
  antes do conserto — mas quem rodar `tests/run-all.sh` ou `sdd health` no meio do caminho vê
  vermelho e precisa saber que são **as duas linhas listadas em "Estado do repo"**, nenhuma outra.
- **Não walkei `sdd kaizen` sem `--dry-run`.** Gastaria uma sessão opus real e escreveria no
  ledger global. Toda a cadeia até `run_phase` foi observada pela projeção, que é o que o próprio
  kit usa para isso; a parte não observada é `run_phase` em diante, comum a todas as fases.
- **A varredura dos 5 itens do `TODO.md` continua devendo** os do I1 e do I2 (`RESOLVIDO por
  <hash>`), como o `20-handoff-exec.md` já registrava. É da fase **DOCS**, não desta.
- **`missions` não sobe com `--all-repos` no ledger desta máquina** — sobe no fixture do sensor.
  Já registrado pelo EXEC; reconfirmado aqui: é o eixo degenerado, não a flag.
- **Nada foi empurrado, nenhum PR foi aberto.**

## Achados fora de escopo

- **Nenhum.** O único achado desta fase é do escopo da missão: `--all-repos` nasceu no `I3` desta
  branch, e o defeito está na flag que ela criou. Nada foi acrescentado ao `TODO.md`.
