---
missao: 20261121-l3-gates-do-fim-da-linha
fase: REVIEW
rodada: 5
status: done
sessao: worker-r5-chore
data: 2026-11-21 18:13
gate: "tests/run-all.sh em ccacdc3 → rc 0 (17:49 → 18:00), 'suite green', 0 linhas '^  FAIL', 2289 linhas '^  ok    ', 'anchors: all 954 mutants still apply and leave valid code'; sdd review-base → full (o merge 86e16c0 entrou depois da r4), rodada inteira; árvore limpa (git status --porcelain vazio) antes do commit da rodada"
reviewed_head: ccacdc33e33ab6141131d0574c9025cb76c5eed0
---

# Review — rodada r5 — L3: gates do fim da linha (o pós-merge, PR #460)

## TL;DR

Rodada inteira sobre `86e16c0..ccacdc3`, porque o merge `86e16c0` entrou depois da r4 (`sdd review-base` respondeu
`full`). São 5 commits do chore pós-merge: o lote de prosa no `bin/sdd` (só comentário e o texto de uma linha do
journal), o `commands/sdd-plan.md`, o `KAIZEN_LOG.md`, a anatomia § 4 e a gaveta, o `TODO.md` com a catraca, e o
diário com o `handoff-L3.md`. Cada número e cada frase nova foram medidos de novo e conferem. Seis LOW, todos de
prosa ou de registro. Nenhum `R<n>`. Segredos limpos. Nota A em todo critério.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | A única mudança executável é o texto de uma linha do journal (`bin/sdd:10208`), e nenhum sensor nem leitor a lê: o `grep` em `bin/` e `tests/` só acha a linha de `mission budget`. O resto do `bin/sdd` é comentário, e as frases novas conferem com o código. |
| Type Safety | A | Nenhuma expansão nova nem captura nova. `bash -n bin/sdd` e `shellcheck -S warning bin/sdd tests/check-gates.sh` saem rc 0 no head. |
| Error Handling | A | Nenhum ramo mudou de comportamento. A parada `dirty-tree` segue com o mesmo `kind` no ledger e o mesmo rc 3, e só a frase do journal deixou de dizer "red suite", porque desde o `3000409` a parada vale também para o "não rodou". |
| Security | A | O `scan_secrets.sh` (regex + gitleaks) dá 0 achados nas 158 linhas adicionadas de 11 arquivos, e o diff não abre superfície nova. |
| Performance | A | Não há chamada nova a `git`, a sessão nem a suíte. O diff só tem texto. |
| Test Coverage | A | O diff não traz comportamento novo a cobrir. No head, o `check-hat.sh` dá 152 `ok` e 0 FAIL, o `check-lang.sh` rc 0, o `check-mutation.sh --anchors` 954 de 954 e o `check-todo.sh` 81 medidos e 0 fora do alvo. As frases do `sdd-plan.md` que o `check-hat.sh` ancora continuam lá. |
| Documentation | A | Cada frase nova foi conferida e é verdadeira: o código (`test_cmd_red_why`, o `cmd_run`), a skill `ticket`, o ledger (US$ 37,03, 15 sessões, 34 939 s) e os contadores (954, 28, 143 → 152, 123 → 127, `R1` nos três). Sobram seis LOW de prosa e de registro, que vão ao próximo chore sem abaixar a nota. |
| **Overall** | **A** | O chore cumpre o ciclo de vida: os 13 itens saem com os hashes ancestrais de `86e16c0`, os 3 novos passam na D15 e no sensor, a catraca bate e o diário é só acréscimo. Nenhum achado chega a MEDIUM. |

Movimento: a r4 tinha os oito em A sobre `3000409`. A r5 mantém os oito em A, agora sobre `ccacdc3`.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW (prosa) | O exemplo vencido do r4 #1 tem um gêmeo no sensor, que o `152f7cd` não tocou. O comentário dá `` `bash -c 'true; x'` `` como uma suíte que **começou**. Medido aqui, `( eval "bash -c 'true; x_r5'" )` sai rc 127 com **uma** linha (`bash: linha 1: x_r5: comando não encontrado`), então o gate lê esse caso como "não rodou", que é o mundo do `DECLARED LIMITS` de `bin/sdd:1020-1021`. A asserção logo abaixo usa a grafia certa (`echo the suite started; …`) → chore: trocar o exemplo por `echo x; no_such_cmd`. | `tests/check-gates.sh:408` |
| 2 | LOW (prosa) | O cabeçalho do comentário que o lote reescreveu diz "read by the **four** sites of gate_EXEC, gate_QA and gate_REVIEW". Desde o `0143fec` (CodeRabbit no #458) os sítios são três: `bin/sdd:1685`, `2030` e `2296`. O `grep -cE '^\s+(if )?test_cmd_red_why'` sobre o `git show <rev>:bin/sdd` dá 4 em `83b2b3e`/`d4c4e97` e 3 de `0143fec` até `ccacdc3` → chore: "three sites". | `bin/sdd:1003-1004` |
| 3 | LOW (prosa) | O `DECLARED LIMIT` novo atribui o corte só a "a long enough path of the kit copy". No mundo 126, a linha também leva o caminho do `noexec` sob o `TMPDIR` (`<kit>/bin/sdd: line N: <TMPDIR>/sdd-norun-…/noexec: Permission denied`, medido aqui), e o próprio relatório do lote do CodeRabbit nomeia os dois (`<ROOT>/bin/sdd: line N: <TMPDIR>/…/noexec`). A falha continua fechada, e só a causa ficou pela metade → chore: "of the kit copy or of TMPDIR". | `tests/check-gates.sh:369-371` |
| 4 | LOW (registro) | O diário e o handoff discordam na conta do lote do CodeRabbit. A linha de 16:19 diz "12 de 16 consertados com asserção e mutante", e o `handoff-L3.md` diz "13 consertados com asserção e mutante". O relatório do subagente (`cr458-relatorio.md`) tem 13 vereditos "válido", e a linha de 16:40 do próprio diário soma 13 (12 threads resolvidos pelo bot mais o `4654284445`), então o 12 está errado. As duas frases também afirmam "com asserção e mutante" para os 13, e três deles são de prosa, sem asserção nem mutante (`4654284452`, `4654284467`, `4654284471`): o lote fez 10 asserções novas e 9 mutantes. Por fim, o "15:2x" da linha de 15:24 e do handoff é uma hora sem medida, e o log da corrida a tem → chore: uma linha de correção no diário (append-only) e o handoff ajustado ("13 consertados, 10 com asserção e 9 mutantes novos"). | `docs/superpowers/campaigns/20261117-zerar-as-issues/journal.md:95`, `docs/superpowers/campaigns/20261117-zerar-as-issues/handoff-L3.md:12`, `handoff-L3.md:21-22` |
| 5 | LOW (prosa) | O chore reescreveu a parte do L3 na célula "Próximo passo" da F6, mas a célula ainda abre com "o chore de pós-merge do L1 (os 14 itens, a catraca e a prosa que a revisão deixou)". Esse chore entrou pelo #447 (`336640e`) em 2026-11-20 → chore: tirar a frase vencida da célula. | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:21` |
| 6 | LOW (registro) | Dois detalhes dos itens novos que o `check-todo.sh` não mede. (a) O item do `sdd approve` no placeholder (`TODO.md:707`) e o item aberto "O `sdd run` diz que commita na base quando a TICKET vai cortar o branch antes" (`TODO.md:443`) ancoram a mesma função (`warn_if_on_base_branch`) no mesmo mundo (`JIRA_ENABLED=true` e `branch:` no placeholder). As direções se completam: o `cmd_run` cala na base, e o approve avisa fora da base e cala nela. Nenhum dos dois nomeia o outro como vizinho, e o planner que pegar um mexe na função do outro. (b) O item do `blocked` (`TODO.md:507`) fecha com "achado … do CodeRabbit …, conferido na r3", sem o "descoberto por `<agente>`" do `templates/todo.pt-BR.md:19` → chore: "Vizinho de …" nos dois, e a atribuição na forma do template. | `TODO.md:443`, `TODO.md:707`, `TODO.md:507` |

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os seis achados são LOW, quatro de prosa e dois de registro. Nenhum é fail-open, e nenhum tem
consumidor fora da suíte que pague uma rodada (régua do dono e D15). Todos vão ao próximo chore.

## O que virou incremento

Não houve `R<n>` na r4. Os itens que a r3 e a r4 deixaram para este chore foram conferidos no head:

- **r4 #1 (o exemplo do `test_cmd_red_why`):** fechado em `bin/sdd`. O exemplo virou `echo x; no_such_cmd`, que dá
  duas linhas (medido: rc 127, `x` e a mensagem do shell). O `true; no_such_cmd` foi para o `DECLARED LIMITS`, que
  dá uma linha (medido). O gêmeo do sensor ficou (achado #1).
- **r4 #2 (a linha do journal):** fechado. Agora é `BLOCKED  EXEC  suite did not pass over a dirty working tree`.
  Nenhum leitor lê o texto antigo: fora o QA report de 2026-08, que é histórico, o `grep` em `bin/`, `tests/` e
  `docs/` só acha a linha nova.
- **r4 #3 (o escopo do `failure-modes.md`):** fechado. O Symptom e o "What you do" dizem `gate_EXEC` only. O
  `gate_QA` e o `gate_REVIEW` chamam `test_cmd_red_why` sem argumento (`bin/sdd:2030`, `2296`), e só o
  `cmd_run` lê o `GATE_EXEC_DIRTY` (`bin/sdd:10202`).
- **r4 #4 (o desvio do I1):** registrado nas Pendências do corpo do PR #460 e no `handoff-L3.md`.
- **r3 #3 e #4 (o wrapper de uma linha e o corte de 200 bytes):** declarados no comentário. A frase "which bash
  opens with the bin/sdd path" confere: um script de rascunho que faz `eval` de um comando ausente imprime
  `<$0>: line N: …`, com o caminho de invocação. O corte não muda a leitura, porque a classificação conta as
  linhas do log, não a linha cortada.
- **r3 #5 e r5 #10 do L2 (os contadores):**
  - `grep -c '^mut_'` dá 926 em `a0004df` e 954 em `86e16c0`. O
    `git diff a0004df..86e16c0 -- tests/check-mutation.sh | grep -cE '^\+mut_[A-Za-z0-9_]+\(\)'` dá 28, e o
    `grep -cE '^-mut_…'` dá 0.
  - Por commit: os 7 do plano somam 16, o `d4c4e97` traz 1 (`mut_PR_kit_lines_counted_in_fence`), o `0143fec`,
    o `e41809f` e o `bfbc460` somam 9 e o `3000409` traz 2.
  - As linhas `ok` medidas aqui sobre `git archive` dos dois commits: `check-hat` 143 → 152 e `check-templates`
    123 → 127, iguais ao `KAIZEN_LOG.md`.
  - `R1` é a única linha `R` nos checkpoints do L1, do L1b e do L2.
  - Os três mutantes que a anatomia cita existem.
- **r5 #8 e #9 do L2 (o `sdd-plan.md`):** fechados.
  - A skill `ticket` faz `git checkout ${BASE_BRANCH}`, `git pull origin ${BASE_BRANCH}` e
    `git checkout -b …` (`~/.claude/skills/ticket/references/start.md:137-139`).
  - O `cmd_approve` com o placeholder não troca de branch e só chama o `warn_if_on_base_branch`
    (`bin/sdd:9632-9639`), que avisa só no `DEFAULT_BRANCH` (`bin/sdd:6762-6767`).
  - A r5 do L2 existe e reproduz o caso.
  - As três frases que o `check-hat.sh` ancora no ramo do placeholder seguem no texto.

## Estado do `TODO.md`, da catraca e do diário

- **Os 13 que saíram:** cada `RESOLVED by` (`5da09d6` ×3, `b912a33`, `7be7b47`, `83b2b3e`, `c42fa76` ×2, `5e8b000` ×3,
  `45c8434`, `66a9bd0`) responde `git merge-base --is-ancestor <hash> 86e16c0` → rc 0. Todos vêm depois de `a0004df`,
  e cada um é um commit `fix(...)` do L3. No head nenhum item aberto carrega `RESOLVED by <hash>`
  (`grep -nE 'RESOLVED by [0-9a-f]{7}' TODO.md` → rc 1).
- **Os 3 que entraram:**
  - As âncoras estão na linha exata do símbolo: `bin/sdd:13434` é `review_head_ok()`, `9772` é
    `handoff_blocked_escalation()` e `6762` é `warn_if_on_base_branch()`.
  - Cada fato do corpo foi reproduzido. Um repo de rascunho no git 2.43.0 mostra que `git mv` some do
    `diff --name-only` e reaparece com `--no-renames` e com `diff-tree -r`. As portas do `blocked` ficam depois do
    `run_phase` (`bin/sdd:10462`, `10606`), e o `no_work_check` só compara voltas do mesmo processo. O approve
    avisa só na base.
  - A D15 vale nos três: o primeiro é fail-open de guarda, e os outros dois têm o humano como consumidor.
  - `check-todo.sh --check` → `81 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.
- **As `RECURRED`:** as 11 linhas são byte a byte as de `86e16c0` (`diff` vazio), e nenhum hunk do diff toca uma
  delas. Os hunks só removem os 13 blocos e acrescentam os 3, e a quebra de 120 colunas da skill não sobrou em
  lugar nenhum.
- **A catraca:** `tests/check-todo.sh --count TODO.md` → 81, e a linha é `todo-findings 81` (91 − 13 + 3).
- **O diário:** `git diff 86e16c0 HEAD -- journal.md` não tem nenhuma linha `-`. As 19 linhas novas estão em ordem
  de hora, de 03:12 a 17:42. As duas correções nomeiam a linha que corrigem e o valor certo:
  - a de 16:41 diz que o `allows review` rodou depois do ato;
  - a de 17:42 diz que o custo foi US$ 37,03 e não 34,24.
  - Medido no ledger: 15 sessões, `cost_usd` soma 37,0328 e `dur_s` soma 34 939. A EXEC soma 27,32, a REVIEW
    5,60, a DOCS 2,38 e a PR 0,55. As 13 primeiras somam 34,11, que é o número da gaveta.
  - O "campanha US$ 114,21" bate com o ledger: L1, L1b, L2 e L3 somam 114,20 na soma arredondada.
  - A exceção à concordância é o achado #4.

## O que foi refutado

Nada. A rodada não levantou nenhum achado acima de LOW, nem a refutar.

## O que não foi medido de novo

As linhas `ok` do `check-gates.sh` (515 → 551) e do `check-autonomy.sh` (503 → 505) no `KAIZEN_LOG.md` não foram
medidas de novo aqui: a suíte do L4 e a deste worktree rodavam ao mesmo tempo, e rodar esses dois sensores na mesma
máquina arriscava o prazo dos passos delas. O 551 já foi medido pela r4 em `3000409`, que tem o mesmo `tests/` de
`86e16c0`. O 505 vem do autor do chore. A soma de 1 284 → 1 335 confere com as quatro parcelas.

## Achados fora de escopo

Nenhum novo para o `TODO.md`. Os seis LOW acima são prosa ou registro deste mesmo artefato e vão ao próximo chore,
pela régua do dono.

## Pendências / Decisions for a Human

Nenhuma nova. As três do corpo do PR #460 continuam com o dono: o `⛔` da anatomia § 4, a inversão do I1 e o texto
do relay fora da base.
