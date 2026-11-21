---
missao: 20261121-l3-gates-do-fim-da-linha
fase: EXEC
status: done
sessao: a51cbac1-a294-4256-8a6f-e0c09097bb07
data: 2026-11-21 13:47
gate: "`tests/run-all.sh` em d4c4e97 (R1) → rc 0, `suite green`, `grep -cE '^  FAIL'` → 0, `anchors: all 943 mutants still apply and leave valid code` (saída em /tmp/l3-r1-post.log, que não sobrevive à máquina; refaça o comando); o Check do R1 em d4c4e97 → `1 1 0 1 1`; `tests/check-mutation.sh --only PR_kit_lines_counted_in_fence check-gates.sh` em d4c4e97 → `PR_kit_lines_counted_in_fence — check-gates.sh dies (rc 1)`; `bash tests/check-todo.sh` em d4c4e97 → sem FAIL. Antes, no I9: `tests/run-all.sh` em e8d7f4b → rc 0, `91 finding(s), all within 8 lines`, `91 measured, 0 off target`, o Check do I9 → `13`"
---

# Handoff — EXEC — L3: gates do fim da linha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os nove incrementos estão `done`. Cinco gates (`gate_EXEC`, `gate_QA`, `gate_REVIEW`, `gate_DOCS`,
`gate_PR`) passaram a ler o que dizem ler, com 16 mutantes novos, e o publisher, o revisor e três
templates ganharam as regras que nenhum gate consegue cobrar. Os 13 itens do `TODO.md` levam
`RESOLVED by`. Suíte verde. A QA não usa navegador: é a jornada de terminal do § Verificação
end-to-end do `01-plano.md`, sobre a missão do L2, que já está mergeada.
Depois da r1 da REVIEW (nota B), o `R1` de lote fechou os achados #1–#5 em `d4c4e97`; o #2
se mostrou refutado no código (o `load_config` já normaliza a barra), e ficou só o probe.

## Estado do repo

- **Branch:** `fix/l3-gates-do-fim-da-linha`, só local (nunca empurrada; o push é da fase PR)
- **Último commit:** o commit deste handoff, sobre `e8d7f4b` `chore(todo): RESOLVED by nos 13 itens do L3 (I9)`
- **Base:** merge-base com `origin/main` em `a0004df` (a pendência 1 do `00-missao.md` foi cumprida em `e422f8f`)
- **Working tree:** limpa
- **Suíte:** `tests/run-all.sh` → verde (ver `gate:`)
- **E2E:** sem `E2E_CMD`; o kit não tem interface

## O que foi feito

- `83b2b3e` — I1 (item 5): um `TEST_CMD` que sai 126 ou 127 tem motivo próprio nos gates EXEC, QA e REVIEW, numa definição só, e cita a última linha não vazia do log
- `c42fa76` — I2 (itens 6 e 7): o `status: blocked` do `50-pr.md` e da rodada arma o `GATE_HANDOFF_BLOCKED`; a saída de um conflito é `git merge` da base, nunca um rebase
- `5da09d6` — I3 (itens 1, 2 e 13): o `gate_PR` compara o `headRefOid` com `mission_tip` e confere o `verified_head:`; o corpo do PR se edita pelo PATCH da REST
- `7be7b47` — I4 (item 4): código commitado depois da rodada reabre a REVIEW; não reabrem os commits do que os chapéus REVIEW e DOCS escrevem, o merge da base, a missão já mergeada e a rodada sem `reviewed_head`
- `66a9bd0` — I5 (item 11): o K8 mede o branch que a missão declara, e o intervalo fica vazio quando o branch sumiu ou já está na base
- `45c8434` — I6 (item 10): o e2e vermelho diz quantas vezes cada caso já caiu nos logs `gate-qa-e2e` anteriores
- `5e8b000` — I7 (itens 8, 9 e 12): o corpo do PR leva as linhas `kit:` dos handoffs (o `gate_PR` as conta, menos as que estão numa citação ou numa cerca), um "Como verificar" que a shell do leitor roda e a pendência respondida
- `b912a33` — I8 (item 3): o `gate:` do `handoff.md` e do `review.md` só cita medida com o comando e o sha, ou a saída que está no caminho
- `e8d7f4b` — I9: `RESOLVED by` nos 13 itens; seis corpos refeitos para o token caber nos 120 caracteres

## Rodada r1 da REVIEW — o R1

- `d4c4e97` — R1 (achados #1–#5 de `40-review-r1.md`):
  - #1: um rc 126/127 cujo log tem mais de uma linha não vazia não diz mais "the suite never
    started": ganha a frase `TEST_CMD stopped on a command it could not start (…) after it printed
    output`, estável (sem citar o log) e antes do ramo da árvore suja, como a outra;
  - #2: **refutado no código** — o `load_config` tira a barra final do `HANDOFF_DIR` e recusa `\`
    (`adr_dir_ok`), então o `mdir_rel` do `gate_PR` nunca leva `//`. O probe novo do `check-gates.sh`
    nasceu verde e ficou como regressão; a sabotagem do strip da barra no `load_config` o deixa
    vermelho. Nenhuma mudança no `gate_PR`;
  - #3: sai o comentário falso do `review_later_code_ok`; a rodada que entrou por merge virou limite
    declarado no próprio comentário;
  - #4: mutante `mut_PR_kit_lines_counted_in_fence`, pego pelo `check-gates.sh`;
  - #5: a asserção do `pr-body.md` lê ``a linha do gate é `sdd preflight` ``, não o comando solto
    (sabotado: sem a frase no template, a asserção nova reprova e a antiga passava).
- Sabotagem em cópias isoladas, sob `timeout 900` e `RLIMIT_AS` de 4 GiB, controle verde: as cinco
  linhas de código do #1 e o strip da barra, todas pegas (notas do checkpoint).
- 53 âncoras `bin/sdd:N` do `TODO.md` deslocadas pelos hunks do diff.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md` | a decisão (emenda a ADR 0023) |
| `docs/handoffs/20261121-l3-gates-do-fim-da-linha/checkpoint.md` | os nove incrementos, todos `done`, com os hashes |
| `docs/handoffs/20261121-l3-gates-do-fim-da-linha/checkpoint-notas.md` | uma nota por incremento: os mutantes pegos e os desvios do plano |

## Boot da próxima fase

A QA deste kit roda no terminal, no worktree da missão (`/home/joruge/repos/sdd_agents-l3`), pelo
`./bin/sdd` deste worktree, nunca pelo `sdd` do PATH, que é o checkout principal e ainda tem os
gates de antes. O que o usuário vê mudou em cinco motivos de gate (`GATE_WHY`, o que o `sdd status`
e o `sdd why` imprimem):

- EXEC, QA e REVIEW: `TEST_CMD did not run (rc <n>: <última linha do log>) …` no lugar de `TEST_CMD failed` (I1);
- PR: o PR num head que não é o da missão, o `verified_head:` que não cobre o head e o head que não
  se lê ganham motivo próprio (I3); o corpo com menos linhas `kit:` que os handoffs (I7);
- REVIEW: o commit de código posterior à rodada, com o commit e o caminho nomeados (I4);
- DOCS: o K8 nomeia o branch declarado (I5);
- QA: o histórico de cada caso e2e vermelho entra antes do `See <log>` (I6).

A jornada é o passo 5 do § Verificação end-to-end do `01-plano.md`, sobre a missão mergeada
`20261120-l2-o-sdd-plan-e-o-planner`, para provar que o lote não reabre o que já fechou:

1. `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner DOCS` → `DOCS: drift checklist complete`, rc 0;
2. `./bin/sdd why 20261120-l2-o-sdd-plan-e-o-planner PR` → o motivo do carimbo (`no green mutation
   catalogue for this content …`), sem `is at`, `verified_head` nem `kit:` (o PR #456 está `MERGED`,
   então nem o head nem o corpo são lidos; o comando chama o `gh`);
3. `./bin/sdd review-base 20261120-l2-o-sdd-plan-e-o-planner` → uma linha `base=…` ou `full …`, rc 0.

Não rode `./bin/sdd why … EXEC`, `… QA` nem `… REVIEW`: cada um roda a suíte inteira (uns 16 min
nesta máquina, medido nesta sessão) e segura o checkout. Os passos 1 a 4 do § Verificação
end-to-end estão no `gate:` acima.

## Pendências / Decisions for a Human

- As pendências 3 a 9 do `00-missao.md` continuam valendo, e nenhuma é desta fase: aceitar as
  escolhas sob delegação (3), o custo da rodada delta no fluxo dos bots (4), as regras que só valem
  depois do merge (5), o chore pós-merge, com o PR mergeado por **merge commit** (6), o carimbo (7),
  o `agent … stale` do preflight do PATH (8) e o `⛔` da rule da anatomia (9).

## Riscos e não-feitos

- O catálogo de mutação inteiro (`./bin/sdd health`) não rodou, por decisão do plano. Os 16
  mutantes novos foram provados um a um com `--only` (uma nota por incremento), e o `--anchors` da
  suíte diz que todos os 942 se aplicam.
- A linha-modelo `- kit:` do `templates/pr-body.md` é nua, como o plano pede: um publisher que a
  deixe no corpo infla a conta do `gate_PR` em 1 (nota do I7).
- As referências `arquivo:linha` do `TODO.md` foram deslocadas por script e à mão a cada
  incremento; o `--anchors` diz `0 off target`, mas uma referência cruzada que não é âncora (a que
  aponta para outro item) não é medida.

## Achados fora de escopo

- Nenhum nesta sessão.
