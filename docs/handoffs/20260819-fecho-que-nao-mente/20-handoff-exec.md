---
missao: 20260819-fecho-que-nao-mente
fase: EXEC
status: done
sessao: d31eb00a-925b-4afb-87c2-dfde7828c869
data: 2026-08-19 21:35
gate: "tests/run-all.sh → `suite green`, rc 0, 1m42s (61% cpu), 565 asserções `ok`, zero `FAIL`; as sete asserções da métrica presentes com `^  ok    `: `mutation: a score whose caught differs from total is refused`, `surface: --list prints steps only, and a TEST_CMD carrying it is refused`, `gate_REVIEW: a placeholder Rationale does not buy an A`, `gate_PR: the mutation stamp is demanded only where the catalogue lives`, `mutation: a catalogue too small to have measured anything is refused`, `gate_PR: the stamp is read from the tree whose content the gate measures`, `gate_REVIEW: an unfilled gate field and a punctuated fill-in do not buy an A`. Checkpoint: 7 de 7 incrementos `done`, hashes 7a6653b / 2f71646 / 9fa5b0b / c962e2e / 688553f / 1dc713f / 272cb91, todos ancestrais de HEAD; `./bin/sdd status` imprime EXEC ✓ e projeta REVIEW."
---

# Handoff — EXEC — O caminho que certifica o fecho de uma missão para de afirmar o que não mediu

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Sete incrementos `done`, não quatro: a fase QA andou as jornadas que os quatro primeiros criaram e
achou **três defeitos dentro do próprio diff**, todos da classe que a missão existe para acabar. O
laço QA⇄EXEC funcionou e o EXEC foi re-derivado. Suíte verde, 565 asserções; catálogo de 104 → 115
mutantes. **A fase REVIEW não precisa rodar `sdd health` para começar** — mas a fase PR precisa do
carimbo, e ele morre em qualquer commit que toque `bin/ tests/ templates/ config/`.

## Estado do repo

- **Branch:** `fix/fecho-que-nao-mente` — **sem upstream**; nada foi empurrado (é da fase PR).
- **Último commit de código:** `272cb91` (F3). Depois dele só `docs/` e `TODO.md`.
- **Working tree:** limpo.
- **Suíte:** `tests/run-all.sh` → **verde**, rc 0, **1m42s**, 565 asserções. Partida da missão: 1m24s.
- **E2E:** `E2E_CMD=""` — o kit não tem interface; n/a por configuração, não por omissão.
- **Catálogo de mutação:** opt-in, **não** roda no `TEST_CMD`. `N` do `CATALOG=(`: **104**
  (`9bc65dd`) → **115**. A rodada completa está descrita em "Riscos".

## O que foi feito

Os quatro primeiros vieram da sessão EXEC anterior; os três `F` desta. O detalhe de cada desvio
está nas **65 notas** do `checkpoint.md`, que é o documento mais denso da missão.

- `7a6653b` — **I1.** A checagem 2 do `sdd health` lê os três números do `score:` e só diz `ok` com
  `gaps == 0` **e** `caught == total`. Antes, `score: 103 caught, 0 known gap(s), of 104` — o que a
  `main` carregou entre os PRs #12 e #13 — imprimia `ok`. Mutante `mut_HEALTH_mutation_survivor_blind`.
- `2f71646` — **I2.** `--list` imprime só passos, e um `TEST_CMD` que carregue `--list` é recusado:
  é um comando que sai 0 tendo rodado nada. Mutante `mut_HEALTH_testcmd_list_blind`.
- `9fa5b0b` — **I3.** O `awk` do `gate_REVIEW` passou a ler `f[4]`: `A` em toda linha com
  `PREENCHER` em toda justificativa deixou de comprar o selo. Nove mundos diferenciais; mutantes
  `mut_REVIEW_placeholder_rationale_blind` e `mut_REVIEW_gate_field_blind`.
- `c962e2e` + `1b31304` — **I4.** `cmd_health` grava um carimbo (md5 do conteúdo de
  `bin/ tests/ templates/ config/`) e `gate_PR` o exige como último requisito, só onde
  `tests/check-mutation.sh` existe. O segundo commit fecha a **janela**: a chave passou a ser lida
  antes e depois da rodada, senão um commit que aterrissasse durante os ~20 a 50 min do catálogo
  ganhava um verde do qual nunca participou. Mutantes `mut_PR_stamp_blind`, `mut_HEALTH_stamp_window_blind`.
- `688553f` — **F1.** Piso do catálogo: `score: 0 caught, 0 known gap(s), of 0` era `ok` e
  **gravava carimbo**. A checagem 2 passou a pesar o `of N` contra as definições `mut_*()` em disco,
  com `MUTATION_CATALOGUE_FLOOR=8` para o caso de os dois lados serem esvaziados. Quatro mundos;
  mutante `mut_HEALTH_catalogue_floor_blind`.
- `1dc713f` — **F2.** O escritor carimbava `$SDD_HOME` e o leitor cobrava sob `$REPO_ROOT`:
  divergem sempre que o `sdd` vem do `PATH` sobre uma worktree — o fluxo que o `README.md:30`
  documenta —, e o efeito era `gate_PR` **insatisfazível para sempre**. Uma pergunta única
  (`has_mutation_catalogue`) lida pelas duas pontas; mutante `mut_HEALTH_stamp_tree_blind`.
- `272cb91` — **F3.** O selo parou de ser vencido por uma tecla. `gate_field != ""` não distinguia
  campo ausente de campo escrito e deixado **em branco**, e `placeholder()` comparava a célula
  inteira por igualdade, então `TODO:`, `TBD.`, `-`, `?`, `WIP` e `FILL ME` compravam o `A`. Onze
  mundos; três mutantes novos mais um re-ancorado.
- `ca0a360` `dc6a6c9` `c8de654` `749f84d` `202af04` `3f958f3` — os `RESOLVIDO por <hash>` e os
  achados novos, sempre com a catraca `todo-findings` no mesmo commit: **72 → 86**.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md` | Tabela 7/7 `done` + **65 notas** — desvios, medições e armadilhas. Leia antes de qualquer outra coisa. |
| `bin/sdd` | `cmd_health` (checagens 2, 2b, 2c e o carimbo); `gate_REVIEW` (extrator `f[4]`, `placeholder()`, `gate_present`); `gate_PR` (carimbo); `frontmatter`/`frontmatter_has`; `has_mutation_catalogue`. |
| `tests/check-gates.sh` | Quatro asserções diferenciais novas (I3 nove mundos, I4 oito, F2 três, F3 onze). |
| `tests/check-health.sh` | Três asserções novas (I1, I2, F1) e o `CAPTURE_FLOOR` 16 → 22. |
| `tests/check-mutation.sh` | Onze mutantes novos; `CATALOG=(` de 104 para 115. |
| `TODO.md` + `tests/health-baseline.txt` | Quatro achados fechados com `RESOLVIDO por <hash>` e **14** abertos pela própria missão; catraca `todo-findings` **72 → 86**, sempre movida no mesmo commit do achado. |

## Boot da próxima fase

**A próxima fase é REVIEW** (`./bin/sdd status` → `next phase: REVIEW — no 40-review-r<N>.md`).
Ler nesta ordem: `00-missao.md`, este handoff, `30-handoff-qa.md`, e as notas do `checkpoint.md`.

⚠️ **O `gate_REVIEW` que vai julgar a sua rodada é o que esta missão endureceu.** Isso é
autorreferência real, não curiosidade: o `40-review-r1.md` que você escrever é medido pela regra do
I3 + F3. Concretamente, a rodada reprova se qualquer `Rationale` for célula vazia, `<…>`, só
pontuação (`-`, `?`, `...`) ou uma palavra de preenchimento **mesmo com pontuação colada**
(`TODO:`, `TBD.`, `WIP`, `FILL ME`); e o `gate:` do frontmatter, **se presente**, é julgado pela
mesma regra — inclusive escrito e deixado em branco. `clean`, `n/a` e `—` continuam válidos: são
as justificativas curtas do próprio `codereview`. Ausência do `gate:` é deixada em paz.

**O material da rodada já está reproduzido.** Os três `F` nasceram de defeitos no diff dos quatro
primeiros; a QA listou na última nota do `checkpoint.md` os candidatos que **investigou e
descartou com motivo** — não vale re-persegui-los. O que ninguém fez ainda: a passada adversarial
sobre as asserções do F2 e do F3 foi feita **pelo autor delas**, nesta sessão, e está registrada;
uma segunda opinião sobre elas é trabalho legítimo de review.

**Superfície visível ao usuário** (o kit não tem UI; "usuário" é o operador do runner):

- `sdd health` ganhou linhas novas de saída e cinco mensagens de recusa novas.
- `sdd why <missao> PR` pode responder `no green mutation catalogue for this content — run
  'sdd health' (...)`. É a mensagem que um humano vai ler mais vezes por causa desta missão.
- `sdd why <missao> REVIEW` pode nomear um critério com `placeholder Rationale`, ou dizer que o
  `gate:` do frontmatter ainda é placeholder — agora incluindo `(<empty>)`.
- Ambiente: nenhum. Sem serviço, sem porta, sem migração — `bash` e a suíte.

**Antes da fase PR, e só então:**

```
./bin/sdd health            # ~20 a 50 min — roda o catálogo E grava o carimbo do gate_PR
```

⚠️ **Quando rodar importa.** O carimbo chaveia no conteúdo de `bin/ tests/ templates/ config/`.
Qualquer commit que toque esses quatro — um conserto da REVIEW, um bump de
`tests/health-baseline.txt` pela catraca do backlog — o invalida. `CLAUDE.md`, `docs/` e `TODO.md`
**não** invalidam. Regra prática: `sdd health` **depois** do último commit de código. Se o
`gate_PR` reprovar com `no green mutation catalogue for this content`, o I4 está funcionando.

## Pendências / Decisions for a Human

- **A convenção do `RESOLVIDO por` × a catraca do backlog.** Esta missão seguiu o cabeçalho escrito
  do `TODO.md` (item fechado fica, com o hash no corpo, até o merge), enquanto a missão passada
  apagou na hora (`6136d39`). Enquanto as duas coexistirem, `todo-findings` significa coisas
  diferentes em missões diferentes. — `TODO.md`, § Contrato e configuração.
- **CI rodando `tests/run-all.sh --with-mutation`.** Decisão de custo humana; a QA mediu o número
  que faltava: **30 min** por rodada. O I4 fechou o buraco por dentro do kit, sem infraestrutura.
  — `00-missao.md` § Fora de escopo.
- **As três decisões de desenho que nasceram sem humano** (plano kaizen-born): carimbo em vez de
  CI, escopo por artefato, chave no conteúdo. O F2 é consequência medida da terceira e **não** a
  revoga — só exige que escritor e leitor concordem na árvore. — `00-missao.md` § Decisões do grill.

## Riscos e não-feitos

- ⚠️ **A rodada final de `./bin/sdd health` foi disparada nesta sessão e NÃO foi vista terminar.**
  Começou sobre a árvore limpa de `3f958f3` (último commit que toca os quatro diretórios), log em
  `/tmp/f3-health.log`, destacada com `setsid` — porque **duas rodadas de background desta missão
  já morreram** sem imprimir `score:`, e uma terceira foi morta por medir árvore em movimento. O
  gate desta fase é o `TEST_CMD`, que está verde. Quem for para o PR **confere a linha `score:`
  desse log** e, se ela não estiver lá, roda `./bin/sdd health` de novo. Só vale linha `score:` de
  rodada cuja árvore não se mexeu.
- **A métrica da missão já fechou**, na fase QA: `score: 110 caught, 0 known gap(s), of 110`,
  `kit healthy`, contra o `N >= 108` que o `00-missao.md` pede. Os três `F` levaram o catálogo a
  **115**, então a rodada nova é maior que a que fechou a métrica — não a substitui, a supera.
- **Três rodadas de sabotagem desta sessão produziram probes inválidos**, dois morrendo alto (o
  desenho funcionando) e **um concluindo `RED ✓` sem ter sabotado nada**, por citação de shell
  quebrada. Refeito, o resultado se confirmou. Está na nota do `checkpoint.md` porque a lição não é
  "aconteceu": é que a regra escrita do `CLAUDE.md` sobre probe que prova primeiro que sabotou
  **não bastou de novo**, agora por uma classe nova (aspas), e o que denunciou foi o `git status`.
- **O ramo `[ -z "$key" ]` do `gate_PR` e a guarda `[ -n "$cwd_root" ]` do F2 não têm mundo que os
  alcance** e estão declarados como tal nos comentários. Dívida declarada, não coberta.
- **O carimbo cobre 4 dos 8 caminhos que a `sandbox()` copia.** Estreitamento deliberado, com a
  fronteira registrada no `TODO.md` — chavear no `CLAUDE.md` custaria uma rodada extra por missão,
  porque a fase DOCS o edita a caminho do PR.
- **A suíte:** 1m24s → 1m42s (+21%), quase tudo em invocações reais de `sdd health` e `sdd phase`
  dentro dos fixtures. Registrado, não convertido em achado: o limiar de ~60 s da tabela de riscos
  do plano já estava vencido antes da missão começar, então mede a coisa errada. Se a REVIEW quiser
  cortar relógio, o corte é asserção — e a resposta provavelmente é "não corte".
- **Não-feitos declarados no plano, todos intactos:** a re-derivação das âncoras do `TODO.md`, o CI,
  o auto-teste do `check-templates.sh` e as famílias grandes do `check-todo.sh`/`check-health.sh`.

## Achados fora de escopo

> Registrados no `TODO.md` deste repo (é o kit). Aqui fica só o ponteiro, para o PR conseguir citar.

- O carimbo cobre 4 dos 8 caminhos que a `sandbox()` copia → `TODO.md` (I4).
- A checagem 2b lê o `TEST_CMD` do kit e não do repo-alvo → `TODO.md` (I2).
- `que`, `nao` e `sem` são stopwords do `check-lang.sh` e o `-w` as casa dentro do slug hifenizado,
  então citar o slug desta missão em `tests/` reprova → `TODO.md` (I3).
- `gate:` **ausente** no `40-review-rN.md` é deixado em paz, então ausente e placeholder afirmam o
  mesmo nada → `TODO.md` (I3). ⚠️ O F3 fechou o caso **em branco**, que é outro; o ausente segue.
- O piso do catálogo mora só no consumidor: quem imprime o `score:` segue sem nenhum, e duas frases
  do runner mandam rodar `--with-mutation` à mão → `TODO.md` (F1).
- Nenhum sensor recusa a próxima invocação de fixture sem `cd`, e foi assim que uma suíte travou
  5 min disparando o catálogo real → `TODO.md` (F2).
- `FIXME` e `XXX` são recusados pelo `gate_REVIEW` sem nenhum mundo que prove: tirar qualquer uma
  das duas da lista deixa as asserções verdes → `TODO.md` (F3).
- Os sete achados da fase QA, três em § Sensores que faltam e quatro em § Contrato e configuração
  → `30-handoff-qa.md` § Achados fora de escopo.
