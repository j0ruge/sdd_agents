---
missao: 20261121-l3-gates-do-fim-da-linha
fase: REVIEW
rodada: 4
status: done
sessao: worker-r4
data: 2026-11-21 17:15
gate: "tests/run-all.sh em 3000409 → rc 0 (17:04 → 17:15), 'suite green', 0 linhas '^  FAIL', 2289 linhas '^  ok    ', 'anchors: all 954 mutants still apply and leave valid code', a asserção nova em '^  ok    '; árvore limpa (git status --porcelain vazio) antes do commit da rodada"
reviewed_head: 3000409a4d2f69042f164a2119b9a1b6ff67102d
---

# Review — rodada r4 — L3: gates do fim da linha

## TL;DR

Rodada delta sobre `39ad63f..3000409`: dois commits, a própria r3 (`f2559cb`, só a pasta da missão)
e o conserto do P2 do Codex no PR #458 (`3000409`). O P2 está **fechado**: sobre a árvore suja o
`gate_EXEC` arma o `GATE_EXEC_DIRTY` também no ramo "não rodou", com frase própria, e o `cmd_run`
para com rc 3 antes da sessão. Os dois mutantes novos mudam uma linha cada e derrubam só a asserção
nova, cada um pelo motivo certo. Quatro LOW, todos de prosa ou de registro. Nenhum `R<n>`. Segredos
limpos. Nota A em todo critério.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O conserto é local: a árvore é lida uma vez, antes do ramo "não rodou", e o `test_cmd_red_why` continua sendo a única definição do motivo, com o argumento opcional `dirty` que só o `gate_EXEC` passa. |
| Type Safety | A | `${1:-}` e `${exec_dirty:+dirty}` são seguros sob `set -u`, a captura do `exec_dirty` tem fallback vazio e é guardada sob `set -e`, e o `shellcheck -S warning` dos três arquivos do head sai limpo. |
| Error Handling | A | A direção que falhava aberta fechou: o "não rodou" sobre a árvore suja para a linha (rc 3, nenhuma sessão); sobre a limpa o motivo continua estável; e o `git status` que falha cai em "limpa", como já caía antes. |
| Security | A | Segredos limpos (regex + gitleaks, 0 achados em 283 linhas adicionadas) e nenhuma superfície nova: o argumento `dirty` é um literal e não vem de entrada. |
| Performance | A | O `git status --porcelain` passou a rodar uma vez quando a suíte falha, em vez de uma vez no ramo da árvore suja; nenhuma chamada nova ao `git` nem sessão nova. |
| Test Coverage | A | Uma asserção nova pelo `sdd run` real (rc 3, contagem de sessões no journal, a frase do ramo e a ausência de `never started`), e cada mutante novo a derruba sozinho; medido aqui, a base dá 551 `ok` e 0 `FAIL`. |
| Documentation | A | `pipeline.md` (`### EXEC`) e `failure-modes.md` descrevem o head. Três restos de prosa (o exemplo `true; no_such_cmd` contradito pelo limite, a linha do journal e o escopo da seção de falha) são LOW para o chore. |
| **Overall** | **A** | O P2 do Codex fecha com asserção e dois mutantes que morrem pelo motivo certo, e nenhuma propriedade antiga ficou sem medida. Os quatro achados são LOW e nenhum tem consumidor que pague uma rodada. |

Movimento: a r3 tinha os oito em A sobre `39ad63f`; a r4 mantém, agora sobre `3000409`.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW (prosa) | O comentário do `test_cmd_red_why` contradiz o limite que o delta acabou de declarar logo abaixo. A linha 1014 ainda dá `true; no_such_cmd` como exemplo de uma suíte que **começou**, e a 1017 ainda afirma "One line is the shell's message alone, in any locale". Medido aqui (`( eval 'true; no_such_cmd_r4' ) </dev/null >log 2>&1`): rc 127 e **uma** linha, então esse caso é lido como "não rodou", exatamente o caso do `DECLARED LIMIT` (`printf x > f; no_such_cmd`, linha 1021). O efeito ficou fechado (sobre a árvore suja a parada vale), e sobra a frase. Resíduo do LOW #3 da r3 → chore: trocar o exemplo por `echo x; no_such_cmd` (o mesmo do `check-gates.sh`) e rebaixar a frase da 1017 a "na leitura do gate". | `bin/sdd:1014`, `bin/sdd:1017` |
| 2 | LOW (prosa) | A linha do journal da parada ainda diz `red suite over a dirty working tree`, inclusive quando o motivo é "não rodou". O `dim` logo acima foi corrigido para "the suite did not pass", e o journal é o que o humano lê no `tail -F`. O `kind` do ledger (`dirty-tree`) segue certo → chore: "suite did not pass over a dirty working tree". | `bin/sdd:10208` |
| 3 | LOW (prosa) | A seção `A gate says TEST_CMD did not run` nomeia os três gates no Symptom (`gate_EXEC`, `gate_QA` ou `gate_REVIEW`, "never started", a segunda volta como `no-work`), e a frase nova "Over a dirty tree the reason reads … and the line stops (rc 3, `dirty-tree`)" não diz que isso vale só para o `gate_EXEC`. O `gate_QA` e o `gate_REVIEW` chamam `test_cmd_red_why` sem argumento (`bin/sdd:2030`, `2296`) e não têm parada de árvore suja. O parágrafo do `pipeline.md:245-262` está dentro de `### EXEC` e fica com o escopo certo pelo contexto. Achado do verificador de prosa, conferido no código → chore. | `docs/failure-modes.md:1033-1035`, `docs/failure-modes.md:1043-1047` |
| 4 | LOW (registro) | O `3000409` inverte a **conclusão** de uma decisão do plano aprovado: o I1 diz que o braço do 126/127 "**não** arma o `GATE_EXEC_DIRTY`" (`01-plano.md:263-265`). O argumento do I1 (a frase da árvore suja seria falsa) foi honrado com uma frase própria, e o desvio está no corpo do commit, no comentário do `gate_EXEC` e nos dois docs. Falta dizê-lo em algum artefato da missão que o dono lê no merge → uma linha no corpo do PR (ou no `checkpoint-notas.md`): "desvio do I1, a parada vale sobre a árvore suja (Codex P2)". | `docs/handoffs/20261121-l3-gates-do-fim-da-linha/01-plano.md:263-265` |

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os quatro achados são LOW: três de prosa e um de registro. Nenhum é fail-open,
e nenhum tem consumidor fora da suíte que pague uma rodada (régua do dono e D15).

## O que virou incremento

Não houve `R<n>` na r3. O delta é o conserto do P2 do Codex, conferido abaixo.

### O P2 do Codex no PR #458: **fechado** em `3000409`

O mundo do Codex: um `printf changed > tracked.txt; missing_command` sai 127 com um diagnóstico só,
o `test_cmd_red_why` o lia como "não rodou", e o `gate_EXEC` pulava a parada da árvore suja. No head:

- **O caminho.** O `gate_EXEC` lê a árvore uma vez, **depois** do `run_check_cmd`
  (`bin/sdd:1683-1684`), então pega também a sujeira que o próprio `TEST_CMD` deixou. Ele chama
  `test_cmd_red_why ${exec_dirty:+dirty}`, e no ramo "não rodou" arma `GATE_EXEC_DIRTY=1` quando a
  árvore está suja (`bin/sdd:1685-1688`). O `cmd_run` lê o marcador (`bin/sdd:10202`) **antes** do
  `mission_budget_blown` e do `no_work_check` (`bin/sdd:10335`), então a parada sai com rc 3 e
  nenhuma sessão.
- **O argumento do plano honrado.** A frase da árvore suja do ramo vermelho ("the uncommitted
  changes are what the suite is running against") continua fora do ramo "não rodou". Esse ramo tem
  frase própria (`bin/sdd:1046-1047`), que diz o que o gate sabe: os dois casos não se separam.
- **Sem defeito novo nas vizinhanças pedidas.**
  - `no_work_check`: a parada da árvore suja vem antes dele, e sobre a árvore limpa o motivo segue
    sem log, logo estável.
  - `gate_QA` e `gate_REVIEW`: chamam sem argumento, `"${1:-}"` cai na frase de antes, e eles não
    têm parada de árvore suja. O custo do erro de leitura ali é uma frase, e o limite o declara.
  - A mensagem do `cmd_run`: o `dim` virou "did not pass", verdadeiro nos dois ramos; a linha do
    journal ficou para trás (achado #2).
  - A captura sob `set -euo pipefail`: guardada, e o fallback "limpa" é o mesmo do
    `[ -n "$(…)" ]` de antes quando o `git` falha sem saída.
  - O `local` no meio da função: a forma que o arquivo já usa (`local rows; rows=…` no mesmo
    `gate_EXEC`).
- **O que não muda e já era assim.** O `sdd retry` não lê `GATE_EXEC_DIRTY` em ramo nenhum. É
  anterior ao delta e vale igual para a suíte vermelha.

### Os dois mutantes novos e a asserção nova

Cada mutante foi extraído do `tests/check-mutation.sh` do head e aplicado a uma cópia do `bin/sdd`,
com `diff` e `bash -n`. Depois rodei o `bash tests/check-gates.sh` **sem** `SDD_MUTANT`, numa cópia
`git archive HEAD` em `/tmp/mc-r4<x>`, contra uma cópia intocada.

| Mutante | Linha que muda (`diff`) | Resultado no `check-gates.sh` |
|---|---|---|
| — (base) | nenhuma | rc 0, 551 `ok`, 0 `FAIL` |
| `mut_RUN_test_cmd_not_run_skips_dirty` | só a 1686, `[ -z "$exec_dirty" ] \|\| GATE_EXEC_DIRTY=1` → `:`; `bash -n` ok | rc 1, 550 `ok`, 1 `FAIL`: a asserção nova, `got: exit 3, 1 → 3 log(s)`. Duas sessões foram compradas, e é a contagem que a derruba, não o rc. |
| `mut_RUN_test_cmd_not_run_dirty_unsaid` | só a 1046, `if [ "${1:-}" = dirty ]; then` → `if false; then`; `bash -n` ok | rc 1, 550 `ok`, 1 `FAIL`: a asserção nova, `got: exit 3, 1 → 1 log(s)`. Parou sem sessão, mas com a frase errada, e é a frase que a derruba. |

A asserção nova é vermelha pelo motivo certo nos dois lados. O rc 3 é compartilhado com a parada do
orçamento e com a do `no-work`, então ela exige também:

- a frase que **só** o ramo "não rodou" sobre árvore suja escreve
  (`or stopped at its first step, over a DIRTY working tree`);
- a ausência da frase do outro ramo (`the suite never started`);
- a contagem de sessões do journal (`n_norun_dirty == n_dirty`).

O primeiro mutante prova que a contagem morde, e o segundo prova que a frase morde.

### Os mundos 126/127 que passaram para a árvore limpa

A propriedade antiga ("sobre a árvore suja o 'não rodou' ganha da frase da árvore suja") não ficou
sem medida: a asserção nova a lê pelo `sdd run`, que exige `TEST_CMD did not run (rc 127: `. O
mutante cujo assassino era o mundo que mudou foi re-medido aqui:

| Mutante | Resultado no `check-gates.sh` |
|---|---|
| `mut_RUN_test_cmd_not_run_reads_red` | rc 1, 548 `ok`, 3 `FAIL`: o mundo 126/127 da árvore limpa, a asserção nova e o `gate_QA and gate_REVIEW say the same of a TEST_CMD that did not run` |

Os outros três mutantes do bloco continuam com o assassino de antes, que o delta não tocou:

- `mut_RUN_test_cmd_started_skips_dirty`: o `nr127sd`, sobre a árvore suja;
- `mut_RUN_test_cmd_silent_reads_not_run`: o `nr127z`, sobre a árvore limpa;
- o mutante da linha `GATE_EXEC_DIRTY=1` do ramo vermelho (`tests/check-mutation.sh:757`): o par
  `out_dirty`, e a âncora dele não casa a linha nova.

O mundo 126 (`Permission denied`) sobre a árvore suja não tem asserção própria. A extração da linha
é o mesmo código medido na limpa, e só o molde da frase muda.

As saídas estão em `scratchpad/r4/out/` (`base.log`, `skip.log`, `unsaid.log`, `red.log`) e os
mutantes aplicados em `scratchpad/r4/mut/`.

## Estado dos LOW da r3

| # da r3 | Estado | Evidência no head |
|---|---|---|
| 1. A família do rename (`review_head_ok`, `hat_diff_names`) | **segue aberto** → `TODO.md` (o worker transporta) | O delta não toca os dois sítios (`bin/sdd:13434`, `bin/sdd:4937`), e o `TODO.md` ainda não tem o item: `grep -c 'no-renames' TODO.md` → 0. |
| 2. `handoff_blocked_escalation` compra uma sessão antes do rc 3 | **segue aberto** → `TODO.md` (o worker transporta) | As portas seguem depois do `run_phase` (`bin/sdd:10462`, `bin/sdd:10606`), e o item ainda não está no `TODO.md`. |
| 3. "Uma linha é a mensagem do shell" e o wrapper que pula a parada | **fechado em substância** pelo `3000409`, com resíduo de prosa (achado #1 desta rodada) | O efeito (pular a parada da árvore suja) acabou, e o limite está declarado (`bin/sdd:1021-1025`). A frase absoluta da 1017 e o exemplo da 1014 ficaram. |
| 4. `cut -b 1-200` guarda o começo da linha | **segue aberto** → chore | `bin/sdd:1037` e `bin/sdd:1041` sem mudança. Medido aqui: a base dá 0 `FAIL` numa cópia em `/tmp/mc-r4base` (caminho curto) e a r3 deu 2 `FAIL` sob o scratchpad (caminho longo), o que confirma a dependência do tamanho do caminho. |
| 5. Contadores velhos (`KAIZEN_LOG.md`, anatomia §4, gaveta F6) | **segue aberto** → chore, e mais velho | `grep -c '^mut_' tests/check-mutation.sh` → 954 no head (952 na r3), e `KAIZEN_LOG.md:21` ainda diz 943. O "entre os 17 da missão" agora deveria contar 28. |
| 6. `a; b` lido como "começou" e o `-gt 1` sem mutante | **segue aberto** (decidido na `45-docs.md`, D15) | `bin/sdd:1042` sem mudança. Medido: `no_a; no_b` deixa 2 linhas e cai em "started", que sobre a árvore suja já parava. |

## O que foi refutado

- **"As medidas da r3 não têm saída salva"** (verificador de prosa, sobre
  `40-review-r3.md:8, 92-95`): refutado. As saídas citadas existem no scratchpad da sessão que rodou
  a r3 (`scratchpad/r3/mut/`, `scratchpad/r3/out/`, mais os `out2-*.log`), e o template permite
  "saídas em <caminho>" quando o arquivo está lá.
- **"O parágrafo do `pipeline.md` generaliza a parada da árvore suja aos três gates"** (verificador
  de prosa): refutado para o `pipeline.md`. O parágrafo está dentro de `### EXEC`
  (`docs/pipeline.md:236`), e a última frase dele diz que a definição escreve o motivo para os
  três, não a parada. Sustentado só para o `failure-modes.md` (achado #3).
- **Rodada de verificação do `TODO.md`:** o verificador leu 41 de 42 unidades duas vezes, então o
  arquivo caiu no fluxo inteiro, feito aqui. As 42 linhas mudadas diferem só no número da âncora
  (`diff` das linhas `-`/`+` com `bin/sdd:N` e `check-mutation.sh:N` normalizados, vazio), e o
  `tests/check-todo.sh` rodado pelos verificadores respondeu
  `91 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.

## Achados fora de escopo

Nenhum item novo para o `TODO.md`. Os quatro desta rodada vão ao lote do chore de pós-merge:

- Achado #1: no comentário do `test_cmd_red_why` (`bin/sdd:1014`, `1017`), trocar o exemplo
  `true; no_such_cmd` por um que imprime antes (`echo x; no_such_cmd`) e dizer que uma linha só é
  lida como a mensagem do shell **na leitura do gate**, sem prova.
- Achado #2: a linha do journal em `bin/sdd:10208`, `suite did not pass over a dirty working tree`.
- Achado #3: escopar ao `gate_EXEC` a frase da árvore suja em `docs/failure-modes.md:1043-1047`, e
  no Symptom (`:1033-1035`) dizer que sobre a árvore suja o `gate_EXEC` para como `dirty-tree`.
- Achado #4: uma linha no corpo do PR sobre o desvio do I1.

Continuam pendentes da r3: os dois itens propostos ao `TODO.md` (#1 e #2, com o texto pronto na
`40-review-r3.md`) e o chore dos #4 e #5.

## Pendências / Decisions for a Human

- O desvio do I1 (achado #4) é do worker, por um P2 do Codex, e honra o argumento do plano. O dono
  decide, no merge, se basta registrá-lo no corpo do PR.
