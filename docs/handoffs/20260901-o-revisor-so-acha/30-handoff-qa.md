---
missao: 20260901-o-revisor-so-acha
fase: QA
status: done
sessao: 20d349be-732d-4333-849a-9b607ff4a946
data: 2026-09-01 19:33
gate: "sem interface (`E2E_CMD` e `APP_URL` vazios): 9 jornadas caminhadas no terminal. `tests/run-all.sh` → 855 asserções `ok`, última linha `suite green`, rc 0 (105 s). `./bin/sdd preflight` → `preflight ok`, 0 vermelhos, `7 kit agent(s) checked`. `./bin/sdd autonomy --all-repos --by-mission` → 16 células `review loop US$ X (N%)`; a janela 2 lê `25 · 29 · 57`. O laço de `20260831-a-rodada-que-andou` foi **recomputado à mão** por `jq` sobre o ledger cru → `loop US$ 66.34115 / total US$ 132.57396 = 50%`, idêntico ao que o instrumento imprime. `./bin/sdd run … --phase REVIEW --dry-run` → o prompt diz `you do NOT fix the code` e `R<n> increment`, e **não** contém `review and fix, INSIDE`. `./bin/sdd phase` → `QA`; `./bin/sdd status` → `next phase: QA`. `diff -q` dos 7 espelhos `agents/` × `.claude/agents/` → vazio. Registry `docs/qa/bugs/` sem nenhum `Status: open`. Resultado: 0 bug confirmado, 3 hipóteses levantadas e **refutadas com evidência**, 0 incremento `F<n>`."
---

# Handoff — QA — O revisor só acha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

9 jornadas caminhadas no terminal (o kit não tem interface: `E2E_CMD` vazio, e esta é a única
sessão da fase). **0 bug confirmado, 0 incremento `F<n>`, 0 spec nova** — não há superfície e2e a
instrumentar. Levantei 3 hipóteses de defeito e **refutei as 3 com evidência**, incluindo a que
parecia mais grave (o campo `turns` ausente em 194 de 194 linhas do ledger). Um fato operacional
com consequência real: **a métrica M2 desta missão não pode ser lida do ledger** — a fonte é
`.sdd/logs/<missão>/*.json` `.num_turns`, e os números já estão medidos abaixo.

## Estado do repo

- **Branch:** `feat/o-revisor-so-acha` — 9 commits à frente de `main` (`35863d9`), sem push.
- **Último commit:** `1a98a14` `chore(checkpoint): I4 fechado em a84adeb — EXEC completo, handoff escrito`
- **Working tree:** limpo antes desta sessão; esta fase acrescenta **só** este handoff.
- **Suíte:** `tests/run-all.sh` → **verde**, 855 asserções `ok`, `suite green`, rc 0 (105 s).
- **E2E:** `E2E_CMD=""` — o kit não tem interface. Não rodou por não existir, e **não** foi criada
  nenhuma spec: a caminhada é de linha de comando, e o defeito que ela achasse moraria na suíte
  `TEST_CMD`, nunca num `<E2E_DIR>` que este repo não tem.

## O que foi feito

QA não commita código. O que esta sessão produziu são as jornadas caminhadas e o veredito sobre
cada uma — o commit é deste handoff.

| # | Jornada (comando) | Observado |
|---|---|---|
| J1 | `./bin/sdd autonomy --by-mission` | 16 missões; o sufixo `· review loop US$ X (N%)` aparece só onde houve REVIEW. `20260901-o-revisor-so-acha` **não** imprime célula — é o comportamento que `bin/sdd:5085` promete ("a mission with no round prints no cell, rather than a `0%`") |
| J2 | `./bin/sdd autonomy --all-repos --by-mission` | 16 células `review loop`; a janela 2 (`sales_quote`) lê **25 · 29 · 57** — mediana 29%, máximo 57% |
| J3 | recomputação **independente** do laço, por `jq` sobre o ledger cru | `first REVIEW index = 5`, `loop = US$ 66.34115`, `total = US$ 132.57396`, `share = 50%` para `20260831-a-rodada-que-andou` — idêntico ao impresso, e igual ao US$ 66,34 que o `00-missao.md` cita para o PR #33 |
| J4 | `jq 'has("turns")'` sobre as 201 linhas do ledger | `194 session has_turns=false`, `7 blocked has_turns=false` — ver a refutação R3 abaixo |
| J5 | `./bin/sdd run 20260901-o-revisor-so-acha --phase REVIEW --dry-run` | o prompt diz `you do NOT fix the code`, `every finding that must be fixed becomes an R<n> increment` e `a source file in your diff means the hat slipped`; a frase antiga `review and fix, INSIDE` **não** aparece |
| J6 | `diff -q agents/*.md .claude/agents/*.md` | 7 de 7 idênticos — os espelhos que `sdd install --force` sincroniza estão em dia |
| J7 | `./bin/sdd preflight` | `preflight ok`, 0 vermelhos, `7 kit agent(s) checked`, `TEST_CMD ran green` |
| J8 | `./bin/sdd phase` e `./bin/sdd status` | `QA`; `next phase: QA — missing 30-handoff-qa.md`, I1–I4 todos `✓` com hash |
| J9 | `tests/run-all.sh` | 855 asserções `ok`, `suite green`, rc 0 |

### As três hipóteses que levantei e refutei

Cada uma foi levantada como defeito plausível e **morta por leitura de código ou por comando**, não
por opinião. Estão aqui porque a próxima rodada não deve gastar dinheiro reabrindo-as.

- **R1 — "uma linha de escalada com `phase: REVIEW` desloca a fronteira do laço."** O laço usa
  `(map(.phase) | index("REVIEW"))` como fronteira e soma `EXEC` com `.key > $fr`; uma escalada
  admitida no grupo mudaria o índice e varreria para dentro EXEC **anterior** à revisão — exatamente
  o que `bin/sdd:5082` promete não fazer. **Refutada:** `bin/sdd:5041` monta `$mgroups` com
  `map(select(is_session and comparable))`, e escalada não é `is_session`. Confirmado no ledger real:
  as 7 linhas `blocked` carregam `phase` (`EXEC`×6, `QA`×1) e nenhuma entra na conta.
- **R2 — "o `findings file` que o prompt manda commitar está fora da allowlist da guarda."** O boot
  do REVIEW manda commitar "40-review-r\<N\>.md, checkpoint.md and the findings file", e
  `review_scope_check` só perdoa três padrões (`bin/sdd:2250-2252`); um quarto arquivo faria a guarda
  disparar em **toda rodada saudável**, que é o modo de falha que o próprio comentário de
  `bin/sdd:2248` nomeia. **Refutada:** o "findings file" é o `TODO_FILE` (`bin/sdd:2886` e `:2905`,
  "Out-of-scope findings from `sdd` missions"), que é o segundo braço da allowlist (`bin/sdd:2251`).
  Os três caminhos perdoados são exatamente os três que uma rodada saudável escreve.
- **R3 — "o campo `turns` não é escrito: 194 de 194 linhas de sessão respondem `has_turns=false`."**
  Era a mais grave, porque o campo é o instrumento do I1. **Refutada como defeito de código:** o
  construtor emite a chave **incondicionalmente** — levantei o programa `jq` verbatim de
  `bin/sdd:2483-2502` e ele responde `{"event":"session","turns":7}` com o global preenchido e
  `{"event":"session","turns":null}` com ele vazio. A causa é outra, e é real: as 4 linhas desta
  missão compartilham **um** `run_id` (`fe7f4add`), e esse processo `sdd run` foi lançado **antes**
  de `88432ee` (18:12:56) pousar o campo — ele carrega o `bin/sdd` pré-I1 em memória. Consequência
  medida na seção seguinte.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260901-o-revisor-so-acha/30-handoff-qa.md` | este handoff: as 9 jornadas, as 3 refutações com evidência, e o que a REVIEW/DOCS precisa saber sobre a M2 |
| `docs/qa/` | **não tocado.** A árvore existe desde 2026-08-21/24 (um humano rodou `qa-report` à mão) e pertence às skills: li o registry e os relatórios, não escrevi nem apaguei nada |
| `checkpoint.md` | **sem linha `F<n>`** — nenhum bug sanável foi confirmado. A tabela fica como o EXEC a deixou |

## Boot da próxima fase

A próxima fase derivada do disco é **REVIEW**, e ela é o primeiro teste real do contrato novo
(`./bin/sdd run 20260901-o-revisor-so-acha`, ou `--phase REVIEW`). O que ela precisa saber:

1. **A M2 desta missão NÃO pode ser lida do ledger — e isto é o achado operacional desta fase.**
   O `00-missao.md` § Métrica 2 manda ler `turns` e `cost_usd` "na linha do ledger". As linhas desta
   missão **não terão `turns`** (R3 acima): o processo que as escreve é anterior ao I1, e é o
   **mesmo processo** que vai escrever as linhas de QA e de REVIEW — o campo só nasce no ledger no
   **próximo** `sdd run`. A fonte que funciona hoje é `.sdd/logs/<missão>/*.json` `.num_turns`, já
   medida para as quatro sessões de EXEC:

   | sessão | `num_turns` | `total_cost_usd` |
   |---|---|---|
   | `EXEC-20260901-175649-870e03b5` | 74 | 7.18 |
   | `EXEC-20260901-181534-3908ad36` | 80 | 7.77 |
   | `EXEC-20260901-183546-00d3be15` | 56 | 5.67 |
   | `EXEC-20260901-185903-ab979cf8` | 53 | 4.65 |

   Comando: `jq -r '.num_turns' .sdd/logs/20260901-o-revisor-so-acha/REVIEW-*.json`. **Ler `turns`
   do ledger e encontrar `null` não é o instrumento quebrado** — é este fato, e concluir o contrário
   custaria uma rodada.

2. **O que a M3 pede que a REVIEW confira** (o EXEC pediu explicitamente, e QA não o fez para não
   duplicar): `gate_REVIEW` inalterado (A em toda linha + `Rationale` com frase) e o diff de
   `agents/sdd-reviewer.md` sem remover nenhuma regra de reprodução ou refutação.
3. **A guarda mede esta sessão.** `review_scope_check` compara o HEAD anterior com o de agora e
   emite `warn` + `REVIEW-EDITED-CODE` no `pipeline.log` para qualquer arquivo fora de
   `docs/handoffs/20260901-o-revisor-so-acha/`, `TODO.md` e `tests/health-baseline.txt`. Uma rodada
   que escreva só o relatório e o checkpoint é silenciosa — verificado na allowlist (R2).
4. **Não rodar `./bin/sdd health`** nesta fase (15–50 min; o carimbo é da DOCS, depois do último
   commit de código).
5. **Cosmético, para a rodada decidir:** o `checkpoint.md` desta missão ainda tem o heading antigo
   `## Incrementos de fix (QA)` (linha 88), enquanto `templates/checkpoint.md:63` já diz
   `## Incrementos de fix (QA e REVIEW)` — o checkpoint foi instanciado antes do I2. Não quebra gate
   nenhum (suíte verde com ele em disco) e o corpo da seção **já** explica o `R<n>` em prosa (linhas
   95–97); a REVIEW edita esse arquivo de qualquer forma para escrever seus `R<n>`.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno. **Não bloqueiam o pipeline** — viram seção do PR.

- **Nenhuma nova nesta fase.** As duas que o EXEC abriu seguem de pé e continuam sendo do humano:
  a coluna **Depois** do `KAIZEN_LOG.md` (preenchida pela DOCS, depois de a REVIEW rodar) e
  **quando abrir e fechar a janela 3** (no sha do merge desta missão, padrão D19).
- Nenhum bug foi marcado `Closable by: human`, porque **nenhum bug foi aberto**: o registry
  `docs/qa/bugs/` não tem uma linha `Status: open` e esta sessão não acrescentou nenhuma.

## Riscos e não-feitos

- **A cobertura desta QA é de superfície de comando, não de laço completo.** Caminhei o que o
  humano digita (`autonomy`, `run --dry-run`, `phase`, `status`, `preflight`, `install`) e recomputei
  o número do laço à mão. O que **não** foi caminhado ponta a ponta é uma rodada REVIEW real
  escrevendo `R<n>` e um EXEC fechando-o — por construção: essa é a fase seguinte, e é ela o
  primeiro teste real do desenho.
- **A guarda `REVIEW-EDITED-CODE` foi verificada por leitura e pelas 4 asserções da suíte, não
  provocada em sessão real.** Provocá-la exigiria uma sessão REVIEW que commitasse código — que é
  exatamente o que a missão existe para impedir.
- **`turns` continua sem uma única leitura real em ledger** (R3). O primeiro valor verdadeiro
  aparece no próximo `sdd run`, e ninguém o viu ainda em produção.
- **Não rodei `./bin/sdd health` nem o catálogo de mutação (222).** É opt-in, leva 15–50 min, e o
  carimbo pertence à fase DOCS depois do último commit de código — rodá-lo aqui só queimaria tempo,
  e registrar achado mata a chave.
- **Não reabri o que o EXEC já declarou não-feito** (catálogo ponta a ponta, cegueira da guarda a
  `commit --amend`) — está em `20-handoff-exec.md § Riscos` e continua valendo.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta fase, e é deliberado, pelo mesmo motivo que o EXEC
> declarou:** `tests/health-baseline.txt` (a catraca do backlog) está na chave do carimbo de
> mutação, então registrar achado aqui mataria o carimbo mais uma vez. Este repo **é** o kit, então
> o destino é o `TODO.md` daqui e nenhum item precisa da rota `kit:` — quem transporta, com a
> catraca no mesmo diff e **antes** do `./bin/sdd health`, é a fase DOCS.
>
> Os três achados que o EXEC deixou para a DOCS (`env-cleanup` do `run_phase`, `surface()`
> enumerado do `check-lang.sh`, e a **classe** "piso que fica para trás") continuam válidos e
> **não** são repetidos aqui: estão em `20-handoff-exec.md § Achados fora de escopo`. A DOCS deve
> transportar os de lá **e** o de baixo.

- Uma sessão do runner escreve suas linhas de ledger com o `bin/sdd` que tinha em **memória** ao ser
  lançada, não com o que está no disco no fim — `bin/sdd` (`autonomy_session_row`/`run_phase`) — a
  missão que ACRESCENTA um campo ao ledger é, por construção, a única que não o registra, então o
  primeiro instrumento novo nasce sempre com uma janela cega do tamanho da própria missão, e uma
  métrica que nomeie o ledger como fonte (a M2 deste `00-missao.md`) fica insatisfazível sem que
  nada esteja quebrado; candidato: o `sdd run` avisar quando `bin/sdd` mudou sob ele, ou a métrica
  citar `.sdd/logs/` como fonte no ciclo em que o campo nasce — descoberto por `sdd-qa` na missão
  `20260901-o-revisor-so-acha` (2026-09-01) → `TODO.md`
