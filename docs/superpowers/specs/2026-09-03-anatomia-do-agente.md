# Auditoria — a anatomia do agente aplicada ao kit (2026-09-03)

> Escrita com o humano presente, numa sessão de brainstorming (Fable), depois do merge do PR #139
> do `sales_quote`. É o "o que este kit faz e não faz" que precede a publicação do kit para
> terceiros. A rule que a resume vive em
> [`.claude/rules/anatomia-do-agente.md`](../../../.claude/rules/anatomia-do-agente.md); quem fecha
> uma dívida atualiza os dois. Todo número aqui saiu de um comando, e o comando está ao lado.

## Por que agora — a missão que provou o número

`20260902-o-rascunho-legado-fala-cru` (SQ-115) rodou em 2026-09-02 das 18:22 às 23:43 e foi
mergeada em 2026-09-03 07:56. Medido em `~/repos/sales_quote/.sdd/logs/20260902-o-rascunho-legado-fala-cru/`:

| medido | valor | comando |
|---|---|---|
| custo total / régua do plano | **US$ 174,11** / US$ 150 | `jq -s 'map(.total_cost_usd)\|add' *.json` |
| sessões | 18 (9 EXEC, 4 REVIEW, 1 QA, 1 DOCS, 2 PR, 1 TICKET) | `ls *.json` |
| laço de revisão: 4 REVIEW + 6 EXEC de `R<n>` | **~US$ 133 (76%)**, zero achado funcional | `pipeline.log` + `checkpoint.md` (R1–R6 `done`) |
| motivo de cada bloqueio | `Documentation = B — the gate requires Grade A on every criterion` | `grep BLOCKED pipeline.log` |
| custo das quatro rodadas REVIEW | 18,52 → 18,21 → 23,73 → 27,83 | `pipeline.log` |
| artefatos que a sessão relê ao fim | 280 KB (checkpoint 67 KB, `20-handoff-exec` 46 KB, 4 reviews 87 KB) | `wc -c docs/handoffs/<missão>/*.md` |
| publisher | 2 sessões, US$ 2,71, as duas encerraram o turno "esperando background"; PR feito à mão | `50-pr.md § Esta fase foi executada à mão` |
| intervenções humanas | 3 (`--phase REVIEW`, DOCS/PR à mão, decisão de parar no platô) contra **0** linhas `- intervention:` | `grep -c '^- intervention:' checkpoint.md` |

O `KAIZEN_LOG.md` do alvo nomeia a classe: *"o laço de revisão pode entrar em platô de prosa sem
nenhum defeito funcional"* — cada conserto de prosa escreve afirmação nova para a rodada seguinte
medir, e o gate exige A em tudo.

## Os sete componentes — temos / falta

| # | Componente | O que já temos | O que falta (a dívida) |
|---|---|---|---|
| 1 | **System prompt** — caráter e restrições | Um agente por chapéu (`agents/*.md`, 97–237 linhas), carregado por `--agent` em `run_phase()`. `boot_prompt()` é **uma** definição: fase, missão, `OUTPUT_LANG`, ordem de leitura, tarefa, "sua resposta em texto não prova nada". Restrições por fase só para REVIEW e QA (`phase_extra()`). `bypassPermissions` recusado (`load_config`). | Restrição vive em **prosa e num agente só**: "nunca encerre o turno esperando background" existia em `sdd-reviewer.md` e em nenhum dos outros seis (`grep -il 'end the turn' agents/*.md` → 1 arquivo) — custou as duas sessões do publisher. "O revisor não toca código" é frase; o runner só **avisa** (`REVIEW-EDITED-CODE`). |
| 2 | **Ferramentas** — capacidades, não todas | `ALLOWED_TOOLS` e `PERMISSION_MODE` configuráveis; teto `acceptEdits`. | **Nenhum agente declara `tools:`** (`grep -n '^tools:' agents/*.md` → vazio) e todas as fases recebem o **mesmo** `--allowedTools "Bash"` + `acceptEdits` (`run_phase()`): o revisor read-only e o publisher têm o poder do executor. `--setting-sources user,project,local` carrega hooks e plugins **do humano** na sessão headless. |
| 3 | **Gestão de contexto** — o que o agente sabe agora | Estado em disco, sessão nova por fase e por incremento (princípio 3); o boot ordena o que ler; `--fork-session` no retry. | Sem dieta: a sessão lê o diretório inteiro da missão, que **só cresce** — 280 KB ontem. O custo do REVIEW subiu 18 → 28 US$ acompanhando o tamanho. Boot do executor medido em US$ 5,46 (handoff da janela 3). Nenhum resumo, nenhum corte, nenhuma ordem de "leia só as últimas N notas". |
| 4 | **Verificação** — como checa o próprio trabalho | O mais forte: `gate_<FASE>` por artefato (`TEST_CMD`, grep no checkpoint, `git log`, `gh pr view`); Check por incremento; 13 sensores; catálogo de mutação 227/227; carimbo no `sdd health`; guarda de kit. | Um gate lê **rótulo**: `gate_REVIEW` exige Grade A em **todos** os 7 critérios (`the gate requires Grade A on every criterion`), inclusive `Documentation` — nota que o próprio modelo escreve. Foi o que girou 4 rodadas. Âncoras 1–2 do `gate_QA` satisfeitas por relatório de **outra** missão (achado `kit:` no `50-pr.md`). |
| 5 | **Memória** — o que persiste | Handoffs, checkpoint, `TODO.md` com catraca, `KAIZEN_LOG.md`, `CONTEXT.md`, ADRs, ledger `~/.sdd/autonomy-log.jsonl`, logs JSON por sessão. | Memória é **prosa append-only sem rota nem recuperação**: `CLAUDE.md` em 491 linhas (já chegou a 861); 318 pendências em 82 handoffs, zero instrumentos (`CONTEXT.md`); 3 achados `kit:` esperando um humano transportá-los; a memória do harness não é do kit e ficou um dia atrasada hoje. |
| 6 | **Sandbox** — ambiente seguro | Branch de missão (`ensure_mission_branch`); guarda de kit em 4 portas; o catálogo de mutação roda numa cópia em `mktemp -d` (`tests/check-mutation.sh`). | As fases rodam **no checkout do humano**, com credenciais reais (`.env.idp`, Jira, push no GitHub). A guarda de kit é aviso (`KIT-TOUCHED`), não fronteira — furada em `2d28d13`. `run_phase()` **não limpava o env** do harness: `sdd run` lançado de dentro do Claude foi morto 2× (2026-08-30). Sem worktree, sem container. |
| 7 | **Hooks** — pontos de intervenção humana | `aprovacao:` + `sdd approve` (gate PLAN); rc 3 nas seis escaladas; `QA/REVIEW_MAX_ITER=3`; `--max-budget-usd` **por fase** (`phase_budget_usd`); merge do PR é humano; `sdd close`. | **Sem teto por missão** (174 vs 150 só em prosa). **Zero** sítios de notificação (`grep -c 'notify-send\|ntfy\|webhook' bin/sdd` → 0) — o humano vigia `tail -F`. `--phase X` força e o runner **segue** (a DOCS emendou sozinha); não há "pare depois desta fase". As linhas `- intervention:` existem no template e o runner as **lê** (`sdd autonomy --by-mission`) mas nunca as **escreve**, nem quando é ele que recebe o `--phase`. |

Leitura: verificação e estado-em-disco são reais; o que falta é a **fronteira** (ferramentas por
chapéu, sandbox), a **dieta** (contexto) e as **portas do humano** (teto, aviso, pausa). Sem essas
três, o laço decide sozinho quando abrir a próxima rodada e quanto gastar nela.

## O lote 1 — o que esta auditoria fecha no mesmo PR

Ordem = custo que fecha, do barato ao que muda contrato. Cada item entra com Check, mutante no
catálogo e os N lugares do contrato editados no mesmo commit.

| # | Conserto | Fecha |
|---|---|---|
| L3 | a regra "nunca encerre o turno com trabalho em background" mora em `boot_prompt()`, para as sete fases; sai do `sdd-reviewer.md` | US$ 2,71 + uma fase PR à mão |
| L5 | `run_phase()` limpa o env do harness (`env -u CLAUDECODE …`) antes do `claude -p` | dois `sdd run` mortos em 2026-08-30 |
| L4 | o runner escreve `- intervention:` no checkpoint quando recebe `--phase`, `retry` ou `--budget-override` | "0 notas contra 3 lançamentos" |
| L6 | `ON_ESCALATION_CMD` roda em todo rc 3, com `SDD_PHASE`, `SDD_REASON`, `SDD_MISSION`, `SDD_GATE_WHY` | a vigília do `tail -F` |
| L2 | `BUDGET_MISSION_USD` (150): soma de `cost_usd=` do `pipeline.log` antes de cada fase; acima ⇒ `budget-exhausted`, rc 3; `--budget-override` fura e escreve `intervention:` | 174 contra 150 só em prosa |
| L1 | `gate_REVIEW` exige A só nos critérios com sensor (`REVIEW_GRADE_A_CRITERIA`) e tolera `REVIEW_GRADE_MIN_OTHERS=B` no resto; achado abaixo de A num critério tolerado vai para o `TODO_FILE`, não para `R<n>` | as quatro rodadas (~US$ 133) |

`sdd approve` **não** escreve `intervention:`, e o plano original o listava: o template define
intervenção como o humano **entrando na linha** depois que ela começou; aprovar o plano é o gate
desenhado para o humano, acontece antes de qualquer `run_id`, e contá-lo inflaria as notas em
relação aos lançamentos que o `sdd autonomy` conta.

## Dívidas que ficam declaradas (na rule), com dono

| Dívida | Por que não agora | Dono |
|---|---|---|
| ferramentas por fase (`tools:` no frontmatter + `--allowedTools` por chapéu) | muda 7 agentes e `run_phase`; pede medir qual mínimo cada gate exige antes de cortar | próxima missão de kit |
| dieta de contexto (digest de boot, teto nas notas do checkpoint) | pede medir quanto do custo é releitura — `turns` e cache-read já estão no ledger | próxima missão de kit |
| worktree/container por missão | o ledger carimba caminho e já confundiu identidade de repo num worktree | desenho próprio (ADR) |
| rota automática do achado `kit:` | é a triagem do `sdd kaizen`; o juiz só roda com 3 missões no mesmo sha | triagem do kaizen |
| `--phase` que **para** depois da fase | flag pequena, mas muda o contrato do `--phase` documentado em `docs/pipeline.md` | próxima missão de kit |
| Âncoras 1–2 do `gate_QA` satisfeitas por relatório de outra missão | achado `kit:` no `50-pr.md` da SQ-115; pede reprodução no kit | triagem do kaizen |

## A janela 3 recomeça

Qualquer commit no kit move o `kit_sha` (HEAD do `$SDD_HOME`), e a janela 3 tinha 1 missão de 3
em `2e48a87`. Este PR **parte a janela**: as próximas missões do alvo correm num sha novo e o piso
de 3 recomeça. Decisão humana desta sessão: medir por mais duas missões o laço que esta auditoria
já decidiu trocar seria medir uma régua abandonada. O `sdd kaizen` continua proibido até o piso
fechar no sha novo — ele commita na branch corrente.
