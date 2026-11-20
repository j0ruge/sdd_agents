# Diário — campanha `20261117-zerar-as-issues`

Uma linha por evento, só acrescentada: `- <instante> · <lote> · <ato> · <desfecho>`, com o instante de
`date`. Escrito pela sessão orquestradora (`commands/sdd-worker.md`, passo 5 do laço). Enquanto um
`sdd run` vive, as linhas esperam fora do checkout principal do kit e entram depois, por branch e PR.

- 2026-11-19 16:00 · L1 · run · lançado (pid 3562081, BUDGET_MISSION_USD=60, EFFORT_EXEC/DOCS=medium, head ce96b6c)
- 2026-11-19 17:11 · L1b · plan · /sdd-plan aberto pelo dono (worktree ~/repos/sdd_agents-lote-aceleracao, só o #436)
- 2026-11-19 17:20 · L1 L1b · delegate · assinada pelo dono: level full, lots L1 L1b (ce7d609fb257), no branch chore/delegacao-full-l1-l1b
- 2026-11-19 17:22 · L1 L1b · delegate · PR #445 aberto (lote L1b + delegação + achado do TODO.md), merge do dono, pull só depois da corrida do L1
- 2026-11-19 17:56 · L1b · plan · relay da pergunta 10 do grill: ADR 0023, a recomendada (resposta do dono)
- 2026-11-19 17:58 · L1b · approve · allows rc 1 (needs full; L1b fora dos lots do principal até o #445); o dono deu o sim ("pode aprovar"), o ato roda quando o plano fechar
- 2026-11-19 18:27 · L1b · approve · aprovado (humano-2026-11-19, e5ceb46): --check ok, --red 5 de 5 vermelhos, 10 (recommended) of 10, ✗ só no b (K8, decisão 7), sim do dono já sabendo do ✗; ADR 0023 accepted
- 2026-11-19 18:30 · L1b · push · feat/l1b-a-rodada-delta empurrado (e5ceb46, sem PR), a pedido do dono
- 2026-11-19 22:22 · L1 · run · sdd run rc=2 (PR #446 aberto, só falta o carimbo; 15 sessões, QA ok, REVIEW r1 B → R1 → r2 A, DOCS com 1 ⛔ em bin/sdd)
- 2026-11-19 22:24 · L1 · pr · corpo do #446 ganhou as decisões 1 e 5 do grill para o aceite do dono; CodeRabbit 6 acionáveis, Copilot não revisou (cota), Codex no ato review
- 2026-11-19 23:07 · L1 · review · sim do dono ao review; 6 achados do CodeRabbit consertados em 729fbf6 (3 asserções novas, Red 3 FAIL → 0), suíte rc 0 no 729fbf6 (2185 ok, 0 FAIL); rodada delta r3 por subagente em voo (base 3f7ad8c)
- 2026-11-19 23:14 · L1 · review · r3 delta A em todo critério (4fc4ddd, reviewed_head 729fbf6), 5 LOW de prosa para a próxima leva ou o pós-merge; 6 threads do CodeRabbit resolvidos pelos ids lidos (0 abertos); @codex review pedido às 23:14 no 4fc4ddd
- 2026-11-19 23:17 · L1 · merge · recibo do Codex completed sem achado no 4fc4ddd (23:16); pr-ready: ready 4fc4ddd; allows merge rc 1 (needs merge, effective pr): proposto ao dono
- 2026-11-19 23:51 · L1 · merge · PR #446 mergeado (91a7524) no ready 4fc4ddd, com o sim do dono; local/ci success no 4fc4ddd (2185 ok); 3 Minor do CodeRabbit no 4fc4ddd respondidos e resolvidos com destino no pós-merge (decisão do dono); próximo: postmerge (allows rc 1, needs merge)
- 2026-11-20 00:01 · L1 · postmerge · sim do dono (mergeia o #445, depois o chore); worktree ~/.wt/sdd_agents-l1-pos-merge (chore/l1-pos-merge, de 91a7524); leva de prosa commitada (3 Minor do CodeRabbit + LOW da r3, 2 asserções Red→verde); TODO.md e catraca esperam o #445
- 2026-11-20 01:31 · L1 L1b · delegate · PR #445 mergeado pelo worker a pedido do dono ("se já puder dar merge, faça e o worker deve assumir"): a0b6fdb; level full até 2026-11-26 18:00
- 2026-11-20 01:32 · L1 · postmerge · main (a0b6fdb) trazida ao chore; 14 itens RESOLVED by apagados (todos ancestrais da main), item novo do turn_rule (sim do dono), catraca 104 → 91
- 2026-11-20 01:48 · L1 · postmerge · PR #447 aberto (chore/l1-pos-merge, 90b5906), suíte rc 0 (2186 ok), local/ci success; allows review e merge rc 0 (full); rodada r4 por subagente em voo
- 2026-11-20 01:56 · L1 · postmerge · r4 A em todo critério (e475346, reviewed_head 90b5906), 4 LOW; CodeRabbit 1 Minor (o LOW 4), Copilot sem cota; leva em 4622a6c (Red do mktemp -d); suíte no 4622a6c em voo, depois rodada delta r5
- 2026-11-20 02:12 · L1 · postmerge · suíte rc 0 no 4622a6c (2186 ok, local/ci), r5 delta (sonnet) A sem achado (a4315f5, reviewed_head 4622a6c); thread do CodeRabbit resolvido pelo id lido; @codex review às 02:12 no a4315f5
- 2026-11-20 02:15 · L1 · postmerge · recibo do Codex completed sem achado no a4315f5 (02:14); pr-ready ready a4315f5; allows merge rc 0 (full); PR #447 mergeado (336640e), primeiro merge delegado, autorizado pelo dono ("o worker deve assumir")
- 2026-11-20 02:17 · L1 · postmerge · espelho 91 ↔ 91: criadas #448 e #449, 14 órfãs fechadas como concluídas (fixed by), 4 âncoras; plano final create=0 update=0 orphans=0
- 2026-11-20 02:17 · L1b · run · next run L1b e allows run rc 0 (full), mas NÃO lançado: créditos da semana e EFFORT_* são do dono (o config do worktree não fixa effort, iria em xhigh); main (336640e) trazida ao branch (334e0d0), --check ok, --red em voo
- 2026-11-20 02:28 · L1b · run · --red 5 de 5 vermelhos no 334e0d0 (main trazida), --check ok; branch empurrado; parado antes do sdd run: créditos e EFFORT_* do dono
- 2026-11-20 08:29 · campanha · credits · o dono: os créditos viraram, restrição removida, worker full até zerar a catraca
- 2026-11-20 08:30 · L1b · run · lançado (pid 1492116, BUDGET_MISSION_USD=60, EFFORT_EXEC/DOCS=medium do config c59d1d3, head 334e0d0)
- 2026-11-20 08:30 · L2 · plan · allows rc 1 (L2 fora de lots: L1 L1b): proposto ao dono, nova assinatura
- 2026-11-20 08:35 · L2 · plan · sim do dono (planejar em paralelo ao L1b, grill pela recomendada); worktree ~/repos/sdd_agents-l2 (plan/l2-provisorio, de 336640e); planner (fable) em voo
- 2026-11-20 08:35 · campanha · delegate · branch chore/delegacao-todos-os-lotes (~/.wt/sdd_agents-delegacao-todos): lots all, teto US$ 500, lotes novos L5b (14) e L5c (7) antes do L6a; espera a assinatura do dono
- 2026-11-20 08:38 · L2 · plan · o planner rodava em opus (o chapéu não tem model:; o L1b também foi planejado em opus): parado sem escrita e relançado com model fable (17/17 mensagens claude-fable-5-2)
- 2026-11-20 08:38 · L2 · plan · grill P1 e P2 pela recomendada, delegadas (achado do modelo entra como 15º item; id 20261120-l2-o-sdd-plan-e-o-planner, branch fix/l2-o-sdd-plan-e-o-planner)
- 2026-11-20 08:39 · L2 · plan · grill P3 e P4 (◆ itens 4 e 5) pela recomendada, delegadas (comando ao lado do fato + amostra no aceite; ramo auto em prosa no passo 4)
- 2026-11-20 08:39 · L2 · plan · grill P5 (◆ item 13) e P6 (item 14) pela recomendada, delegadas (parágrafo da resposta delegada sem token novo; --red --list/--only com linha parcial distinta)
- 2026-11-20 08:40 · L2 · plan · grill P7 (itens 7, 8, 11) e P8 (item 12) pela recomendada, delegadas (passo de leitura com três saídas; o 20-handoff-exec só no plano executado fora do sdd run)
- 2026-11-20 08:41 · L2 · plan · grill P9 (6 incrementos por momento do /sdd-plan) e P10 (kaizen_log vazio) pela recomendada, delegadas; 10 de 10; o planner escreve os artefatos (~60 min)
- 2026-11-20 08:59 · campanha · delegate · assinada pelo worker por ordem escrita do dono ("Pode assinar, se precisar de mim para assinar sempre, atrapalha a autonomia"): level full, lots all, teto US$ 500, missão US$ 60, até 2026-11-26 18:00 (f76dad9d13d3); L2 approve: sim do dono ("O worker pode aprovar"); L2 EXEC em xhigh: sim do dono ao teste, medindo custo e tempo
