---
missao: 20261121-l3-gates-do-fim-da-linha
fase: REVIEW
rodada: 3
status: done
sessao: worker-r3
data: 2026-11-21 16:37
gate: "tests/run-all.sh em 39ad63f → rc 0 (16:18 → 16:32), 'suite green', 0 linhas '^  FAIL', 2288 linhas '^  ok    ', 'anchors: all 952 mutants still apply and leave valid code'; árvore limpa (git status --porcelain vazio) antes do commit da rodada"
reviewed_head: 39ad63ff5725c80dce93344e0dbe1629bbae480f
---

# Review — rodada r3 — L3: gates do fim da linha

## TL;DR

Rodada delta sobre `0d3f87c..39ad63f` (onze commits: a r2, a DOCS e o `50-pr.md`, o ⛔ da anatomia §4
aplicado pelo worker em `0125046`, e os quatro consertos da revisão do CodeRabbit no PR #458). Dos 16
achados do CodeRabbit, 13 estão fechados com asserção, 2 refutações se sustentam no código e na
ADR 0024, e o `10310` é anterior ao delta. Os 9 mutantes novos mudam cada um uma linha só, a que
dizem mudar, e cada assassino cai pelo motivo certo. Seis LOW, nenhum `R<n>`. Segredos limpos.
Nota A em todo critério.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Cada conserto é local e mora na definição que já existia (test_cmd_red_why devolve 0 só no did-not-run, gate_PR lê o estado da 2ª resposta), com o porquê e o achado do CodeRabbit no comentário. |
| Type Safety | A | O verified_head passa por ^[0-9a-f]{7,64}$ antes do rev-parse, a regra do reviewed_head, e a contagem de linhas segue guardada por ${printed:-0} antes de qualquer -gt. |
| Error Handling | A | As direções de falha ficaram fechadas: o 127 calado volta a citar o log, a suíte que começou mantém a parada da árvore suja, o estado que não é MERGED cai nas verificações e uma cerca sem fim no corpo conta menos linhas kit:, nunca mais. |
| Security | A | Segredos limpos (regex + gitleaks, 0 achados em 703 linhas adicionadas); o verified_head deixa de aceitar ref que anda e o rename deixa de esconder o caminho de origem. |
| Performance | A | Um teste -ef por log do histórico (até 50) e um awk sobre o corpo do PR, que já era lido; nenhuma chamada nova ao gh nem ao git. |
| Test Coverage | A | Onze asserções novas no check-gates.sh (uma por achado e duas de guarda: a volta do TEST_CMD e a contagem de leituras do corpo) e uma no check-hat.sh, e os nove mutantes novos derrubam, cada um, a sua asserção com o got do achado (medido aqui em cópias, sem SDD_MUTANT). |
| Documentation | A | pipeline.md, failure-modes.md e o chapéu do publisher descrevem o código do head (o revert e o teto conferidos no cmd_run); três contadores escritos antes dos consertos ficaram velhos, LOW de prosa para o chore. |
| **Overall** | **A** | Os 13 consertos fecham o que dizem sem abrir defeito novo, as duas refutações se sustentam, e os seis achados da rodada são LOW sem consumidor que pague uma rodada. |

Movimento: a r2 tinha os oito em A sobre `0d3f87c`; a r3 mantém, agora sobre os quatro commits de
conserto do CodeRabbit (`git log 0125046..39ad63f`).

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | A família do rename não fechou com o `gate_PR`: dois leitores de "o que mudou entre dois commits" ainda rodam `git diff --name-only` com a detecção de rename do porcelain, e um `git mv` sem mudança de um caminho de fora para dentro do escopo lista só o destino. Reproduzido no git 2.43.0: `git mv run.sh docs/handoffs/m/run.sh` → `git diff --name-only A HEAD` dá só `docs/handoffs/m/run.sh`; `--no-renames` e `diff-tree -r` dão os dois. É fail-open em gate que afirma ler "código fora do `writes:`" (`review_head_ok`) e na guarda do chapéu (`hat_diff_names`). Fora do delta (ADR 0023 e fronteira do chapéu) → `TODO.md` | `bin/sdd:13436` (`review_head_ok`), `bin/sdd:4921` (`hat_diff_names`) |
| 2 | LOW | As duas portas de `handoff_blocked_escalation` ficam depois do `run_phase` (`bin/sdd:10358` → `10445`), então um `sdd run` retomado sobre um `50-pr.md` ou uma rodada que já dizem `status: blocked` compra uma sessão do chapéu antes do rc 3 — na REVIEW, uma sessão opus. É a decisão escrita no I2 do plano ("não acrescente uma terceira porta"), anterior ao delta, e o comentário do marcador não declara o custo. O "Unverified" do CodeRabbit → `TODO.md` | `bin/sdd:10445`, `bin/sdd:10589` |
| 3 | LOW | O comentário afirma que "One line is the shell's message alone, in any locale", e o CodeRabbit (4654284445) pediu decisão própria para esse caso: um wrapper que escreve uma linha sua e sai 127 é lido como did-not-run e, sobre a árvore suja, pula a parada dela. Mundo raro, sem medida; o limite cabe no comentário (D15), não no `TODO.md` | `bin/sdd:1017` |
| 4 | LOW | `cut -b 1-200` guarda o **começo** da linha do shell, que abre com o caminho do `bin/sdd` e do alvo (`<kit>/bin/sdd: line 995: <caminho>: …`): com caminhos longos o `Permission denied`/`No such file` some do motivo. Medido aqui: as duas asserções antigas do I1 caem numa cópia do kit sob o scratchpad, no head e na base, e passam no worktree. Falha fechada e cosmética; chore | `bin/sdd:1031`, `bin/sdd:1035` |
| 5 | LOW (prosa) | Contadores escritos antes dos consertos do CodeRabbit e já falsos no head: o `KAIZEN_LOG.md` diz, de "Depois (head da branch)", `→ **943**` mutantes e 32 asserções novas (`grep -c '^mut_' tests/check-mutation.sh` → 952 no head); o parágrafo ⛔ aplicado em `0125046` diz "entre os 17 da missão" (o diff de `a0004df..HEAD` acrescenta 26 `mut_*`); a linha F6 da gaveta diz "PR a abrir" (o #458 está aberto). Chore, nunca `R<n>` | `KAIZEN_LOG.md:19-21`, `.claude/rules/anatomia-do-agente.md:285`, `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21` |
| 6 | LOW | Os dois LOW da r2 seguem abertos, por escolha registrada na `45-docs.md` (D15): o `a; b` de dois comandos ausentes ainda é lido como "a suíte começou", e a discriminação `-gt 1` entre did-not-run e started não tem mutante (o `mut_RUN_test_cmd_started_skips_dirty` sabota o retorno do ramo, não a fronteira). Nada piorou no delta | `bin/sdd:1036` |

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os seis achados são LOW: o #1 e o #2 estão fora do delta e vão ao `TODO.md`
pela régua D15 (o #1 é fail-open de gate, o #2 tem consumidor fora da suíte, o dinheiro de uma
sessão); o #3 e o #4 são limite a declarar ou conserto barato para o lote do chore; o #5 é prosa; o
#6 é a dívida da r2, já decidida.

## O que virou incremento

Não houve `R<n>` na r2. Os consertos deste delta vieram da revisão do CodeRabbit, conferidos um a um
abaixo, com o commit de quem consertou e a prova.

### Os 16 achados do CodeRabbit no PR #458

| Achado | Veredito | Evidência conferida nesta rodada |
|---|---|---|
| 4654284439 — projeto Playwright sem nome | **fechado** em `e41809f` | A proveniência existe: `formatTestTitle` em `sales_quote/node_modules/playwright/lib/reporters/base.js` (1.58.2), linha 448, `projectName ? \`[…] › \` : ""`, e `generateSummaryMessage` indenta cada caso com `"    "` (linha 192). O parser lê `^    [^ ]` e o prefixo `[` é opcional (`bin/sdd:895-897`). `mut_QA_e2e_unnamed_project_dropped` muda só a linha 895 e derruba `gate_QA reads the failed block of a Playwright project with no name` com `got: 0 — QA: E2E_CMD failed …`, sem histórico |
| 4654284443 — log atual por grafia | **fechado** em `e41809f` | `[ "$f" -ef "$log" ]` (`bin/sdd:923`). `mut_QA_e2e_current_log_by_spelling` muda só essa linha e derruba `gate_QA leaves the log it just wrote out of the history when the mission is named with a leading slash` com `expected: 1\|0  got: 0\|1` |
| 4654284445 — 126/127 sem saída | **fechado** em `0143fec` | `printed == 0` cai no motivo da suíte vermelha com `see <log>` (`bin/sdd:1029-1046`). `mut_RUN_test_cmd_silent_reads_not_run` muda só a linha 1030 e derruba `gate_EXEC reads a TEST_CMD that exited 127 with no output as a red suite, citing its log` com `got: EXEC: TEST_CMD did not run (rc 127) — the suite never started…` |
| 4654284448 — a suíte que começou pulava a árvore suja | **fechado** em `0143fec` | O ramo started devolve 1 (`bin/sdd:1038`) e o `gate_EXEC` cai na parada (`bin/sdd:1671-1685`); o `return 1` final mantém a frase escrita acima, e entre as duas nada reescreve o `GATE_WHY`. `mut_RUN_test_cmd_started_skips_dirty` muda só a linha 1038 e derruba `gate_EXEC keeps the dirty-tree stop for a TEST_CMD that started and then exited 127` com `got: EXEC: TEST_CMD stopped on a command it could not start (rc 127: …command not found) after it printed output…`. A asserção do started da r1 passou a ler árvore limpa (`norun_why_clean`), e o `! grep -qF 'DIRTY'` dela prova que a árvore estava mesmo limpa |
| 4654284452 — rota do PR que já existe | **fechado** em `39ad63f` | `agents/sdd-publisher.md:95-99` manda o "way back of step 5" (linha 124) antes do corpo quando o motivo cita `verified_head:`, que o `gate_PR` confere antes do corpo (`bin/sdd:2896` antes de `2950`). Espelho: `cmp agents/sdd-publisher.md .claude/agents/sdd-publisher.md` → rc 0. Asserção no `check-hat.sh:1294-1304`; prosa, sem mutante |
| 4654284456 — verified_head como ref | **fechado** em `bfbc460` | `bin/sdd:2899`, a mesma régua do `review_head_ok`; o motivo diz `a hex sha, never a ref`. `mut_PR_verified_head_ref_admitted` muda só a linha 2899 e derruba `gate_PR refuses a verified_head that is a ref and not a sha` com `expected: PR\|1  got: DONE\|0` |
| 4654284461 — rename esconde a origem | **fechado** em `bfbc460` | `diff --no-renames` em `bin/sdd:2914`, reproduzido no git 2.43.0 (achado #1). `mut_PR_verified_head_renames_hidden` muda só essa linha e derruba `gate_PR reads the path a file left when it moved into the mission folder after verified_head` com `expected: PR\|1  got: DONE\|0`. A família tem mais dois sítios fora do delta: achado #1 |
| 4654284463 — `mdir_rel` com `/<missão>` | **fechado** em `bfbc460` | `mission_id` (`bin/sdd:333`) tira as barras; `bin/sdd:2922`. `mut_PR_verified_head_mission_arg_raw` muda só essa linha e derruba `gate_PR admits a later commit in the mission folder when the mission is named with a leading slash` com `got: PR — … docs/handoffs/20260101-fixture/50-pr.md changed between verified_head …` |
| 4654284464 — estado da leitura do corpo | **fechado** em `bfbc460` | `body_state` é a 1ª linha (`bin/sdd:2973`); só `MERGED` pula os ⛔ e as `kit:` (comparação positiva: estado vazio ou `CLOSED` cai nas verificações), e o carimbo do fim continua. `mut_PR_body_merged_state_ignored` muda só a linha 2975 e derruba `gate_PR skips the blocked-row and kit checks when the body read says the PR merged after the first call` com `expected: DONE\|0  got: PR\|1`. O `mut_PR_merged_rechecked` ganhou assassino próprio, a contagem de `state,body` no log do stub (`gate_PR asks gh for no body of a merged PR`), porque o `assert_phase DONE` deixou de distingui-lo: medido aqui, ele derruba só essa asserção (`expected: 0  got: 1`) |
| 4654284466 — `kit:` cercada no corpo | **fechado** em `bfbc460` | O corpo é contado pelo `FENCE_AWK` (`bin/sdd:2988-2993`), o mesmo do `mission_kit_lines`; `- [ ] kit:` segue contando. `mut_PR_body_kit_lines_counted_in_fence` apaga só a linha 2990 (12 espaços; a do `mission_kit_lines` tem 4 e fica fora do `/^gate_PR() {$/,/^}$/`) e derruba `gate_PR counts no kit line inside a fence of the PR body` com `expected: PR\|1  got: DONE\|0`. O `mut_PR_kit_lines_uncounted` foi re-ancorado na indentação nova e ainda muda só a linha 2994 |
| 4654284467 — o revert não limpa a recusa | **fechado** em `39ad63f` | Conferido no código: `review_later_code_ok` lê cada commit de `rev-list <commit da rodada>..HEAD` com `diff-tree` (não o diff líquido), e o teto da REVIEW vale só no caminho derivado (`bin/sdd:10230-10239`, `[ -z "$force_phase" ]`). O texto de `docs/failure-modes.md:1061-1068` diz as duas coisas. Prosa, sem mutante |
| 4654284469 — PR OPEN sem `mission_tip` | **refutação sustentada** | ADR 0024, decisão 2 (`docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md:44`): "With no `mission_tip` the comparison is skipped"; plano item 6 (`01-plano.md:219`). O `mission_tip` (`bin/sdd:1113-1126`) devolve o `HEAD` quando o checkout está no `branch:`, e o `cmd_run` e o `cmd_retry` chamam `ensure_mission_branch` antes de qualquer fase (`bin/sdd:9996`, `10703`): dentro do runner a ponta vazia não acontece. Sobra a leitura de fora do branch (`sdd status`/`why`/`phase` num clone sem o ref), que pode mostrar DONE sem comprar sessão. Mudar isso é mudar a ADR: decisão do dono, nunca do conserto |
| 4654284471 — histórico como causa | **fechado** em `e41809f` | `docs/pipeline.md:361-366` e o comentário de `bin/sdd:2042-2046` dizem "location match, not a cause" e incluem as corridas anteriores desta missão. Prosa |
| 4654284472 — `TMPDIR` com espaço | **refutação sustentada** | Medido aqui: o `check-gates.sh` inteiro sobre uma cópia do head com `TMPDIR=".../tmp/sp ace"` → rc 1, 335 `ok`, 215 `FAIL` (`QA reports the unclosed report`, `QA reports the Pending matrix`…), os números do relatório do conserto. O sensor não roda com espaço no `TMPDIR`, e falha **fechado** (vermelho); consertar as duas sondas do 126 não muda isso. Sem consumidor fora da suíte (D15) |
| 4654284475 — `mut_PR_merged_head_read` largo | **fechado** em `bfbc460` | A faixa termina em `  local docs=() kit_n=0 kit_k=0 blocked_body`: aplicado a uma cópia, o mutante muda só a linha 2884 (a guarda do head), e a 2950 (a do corpo, do `mut_PR_merged_rechecked`) fica como está. Medido aqui: o único assassino é `gate_PR passes a 50-pr.md with no verified_head, and does not read the head of a merged pull request` (`expected: DONE\|DONE  got: DONE\|PR`) |
| Comentário "Unverified" — `bin/sdd:10310` | **fora do delta, sustentado** | O `run_phase` (`bin/sdd:10358`) vem antes das duas portas (`10445`, `10589`), desenho de `20260826-o-laco-da-qa` mantido pelo I2 do plano (`01-plano.md:346-347`, "não acrescente uma terceira porta"). O efeito é real e não está declarado no código: achado #2, ao `TODO.md` |

### Como os mutantes foram conferidos

- **Aplicação:** cada função `mut_*` do `tests/check-mutation.sh` do head extraída e aplicada a uma
  cópia do `bin/sdd` (`git show HEAD:bin/sdd`), com `diff` contra o original e `bash -n`. Os nove novos,
  o estreitado, o re-ancorado e os dois cujo trecho mudou: 2 linhas de diff cada (1 no
  `PR_body_kit_lines_counted_in_fence`, que apaga), sempre a linha nomeada no comentário do mutante,
  e todos com `bash -n` ok. Script e saídas em `scratchpad/r3/mut/`.
- **Assassino:** uma cópia `git archive HEAD` por mutante, com o `bin/sdd` mutado, e
  `bash tests/check-gates.sh` **sem** `SDD_MUTANT` (todas as asserções correm), contra uma cópia
  intocada. A base dá rc 1 com exatamente duas FAIL, as duas do I1 do achado #4 (ambiente). Cada
  mutante dá essas duas mais a sua, e só a sua: os onze medidos (os nove novos, o `PR_merged_head_read` estreitado e o `PR_merged_rechecked` de assassino novo) saem rc 1 com 547 `ok` e 3 `FAIL`, e a terceira é a asserção nomeada na tabela de cima, com o got do achado. Saídas em `scratchpad/r3/out/`.

## O que foi refutado

- Nada do código do delta. As duas refutações do conserto (4654284469 e 4654284472) se sustentam,
  com a evidência na tabela acima.

## Achados fora de escopo

Propostos ao `TODO.md`, com o texto pronto (o worker escreve; esta rodada não escreve no worktree).
Os dois entram pela régua D15: o primeiro é fail-open de gate e de guarda, o segundo tem consumidor
fora da suíte. A proposta 2 do relatório do conserto (só o `review_head_ok`) foi alargada para a
família, porque consertar a função não fecha a classe.

1. Na seção de sensores que faltam:

   ```
   - [ ] **Dois leitores de "o que mudou" ainda listam com detecção de rename, e um `git mv` para dentro do escopo esconde o caminho que saiu** —
     `bin/sdd:13436` (`review_head_ok`) — e `bin/sdd:4921` (`hat_diff_names`, a guarda do chapéu): `git diff --name-only`
     sem `--no-renames` mostra só o destino de um arquivo movido sem mudança (git 2.43.0: `git mv run.sh
     docs/handoffs/m/run.sh` → só o destino; `--no-renames` e `diff-tree -r` dão os dois), e a saída do código de fora
     do `writes:` passa calada nos dois. O `gate_PR` ganhou `--no-renames` no PR #458 (CodeRabbit 4654284461), e o
     `review_later_code_ok` lê por `diff-tree`. Direção: `--no-renames` nos dois, com o mundo do `git mv` no
     `check-gates.sh`/`check-hat.sh` e um mutante por sítio; o censo é `grep -nE 'diff (--[a-z-]+ )*--name-only' bin/sdd`.
     — descoberto na r3 da REVIEW de `20261121-l3-gates-do-fim-da-linha` (2026-11-21)
   ```

2. Na seção de prioridade ou de custo, a critério do worker:

   ```
   - [ ] **Um `sdd run` retomado sobre um handoff que já diz `status: blocked` compra uma sessão antes de parar** —
     `bin/sdd:10445` (`handoff_blocked_escalation`) — as duas portas do laço do `cmd_run` ficam depois do `run_phase`
     (desenho de `20260826-o-laco-da-qa`; o I2 do L3 manteve: "não acrescente uma terceira porta"), então o `50-pr.md`
     ou a rodada de REVIEW que já declaram `blocked` pagam uma sessão do chapéu (na REVIEW, opus) antes do rc 3 quando
     o humano relança sem ter agido; o `sdd retry` também. O marcador poupa a 2ª sessão, nunca a 1ª, e o comentário
     dele não diz isso. Direção a decidir: porta antes da sessão para o marcador que a derivação armou, ou o limite
     declarado no comentário. — CodeRabbit "Unverified" no PR #458, conferido na r3 de
     `20261121-l3-gates-do-fim-da-linha` (2026-11-21)
   ```

Para o lote do chore de pós-merge (não são item do `TODO.md`):

- Achado #3: declarar no comentário do `test_cmd_red_why` (`bin/sdd:1017`) que uma linha só é lida
  como a mensagem do shell sem prova, e que um wrapper de uma linha com `exit 127` cai no
  did-not-run.
- Achado #4: guardar o fim da linha do shell no motivo, não o começo (a parte depois de
  `: line <N>: `, ou os últimos 200 bytes), para o `Permission denied` sobreviver a caminho longo;
  as duas asserções do I1 deixam de depender do tamanho do caminho do checkout.
- Achado #5: o `KAIZEN_LOG.md` (952 mutantes e a conta de asserções no head que mergear), o
  "entre os 17 da missão" da anatomia §4 (26 no head) e o "PR a abrir" da linha F6 da gaveta.

## Pendências / Decisions for a Human

- A refutação de 4654284469 deixa a ADR 0024 como está (sem `mission_tip`, o `gate_PR` não
  compara). Recusar o PR `OPEN` nesse caso é mudar a decisão 2 da ADR, e fica com o dono, se ele
  quiser; nenhuma sessão é comprada pelo caso de hoje.
