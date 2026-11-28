---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: QA
status: done
sessao: 01a21ddc-2936-79b1-adc9-7b6cd0cdf804
data: 2026-11-27 13:56
gate: No SHA ada1e29, python3 tests/check-worker-ahead.py "$PWD" saiu 0 com três lotes até done e um relay por sucessor. python3 e2e/check-worker-lookahead-race.py "$PWD" imprimiu 1 com a trilha start, wait, status, wait. python3 e2e/check-worker-review-probe.py "$PWD" imprimiu 1 após 13 cenários e dois controles negativos. tests/run-all.sh saiu 0 com suite green em 21 etapas, 101 sondas do worker, 100 âncoras do TODO e 1.017 do catálogo. As sondas da suíte conservaram a causa original da parada e retiveram o merge sem local/ci no SHA testado ou com pendência de revisão.
---

# Handoff — QA — O worker e os verbos dele

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Repeti 3 jornadas CLI em `ada1e29` — planejamento e retomada, parada e revisão/merge.
Os 2 achados viraram 2 regressões CLI e 2 fixes verificados. F1 e F2 estão `done` e os dois Checks deram `1`.
A suíte padrão passou. Nenhum achado novo nem decisão humana em aberto. A próxima fase é REVIEW.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele`, sem upstream configurado. Ancestral comum com `origin/main` em `8a56249`.
- **Último commit avaliado:** `ada1e29` — `docs(exec): encerra o ciclo de correções da L5b`.
- **Working tree:** limpa durante o reteste. O fechamento altera apenas este handoff e acrescenta uma nota de execução.
- **Suíte:** `tests/run-all.sh` em `ada1e29` → `suite green`, rc 0. Foram 21 etapas, 101 sondas do worker, 100 âncoras do TODO e 1.017 do catálogo. A etapa Codex registrou 3 casos `skipped`.
- **E2E:** sem `E2E_CMD` ou `APP_URL`. As duas regressões são CLI e exercitam os procedimentos com Git local e serviços simulados.

## O que foi feito

- `97e5321` — Os dois sensores permanentes registraram as regressões que saíram 1 em `283b863`. O BUG-01 recusava a reserva válida na segunda retomada e não consultava `status`. O BUG-02 publicava verde depois de abortar 13 cenários com `kit: unbound variable`.
- `5ac9b42` e `6344f01` — F1 (BUG-01), planejamento e retomada. Em `ada1e29`, `python3 tests/check-worker-ahead.py "$PWD"` saiu 0. O runner ainda detinha o checkout quando o relay iniciou no worktree do sucessor, antes da espera. A retomada no grill recuperou a pergunta antes de existir `00-missao.md`. A fila simulada percorreu três lotes até `done`, sem disparo proibido e sem aprovar antes de verificar o merge, integrar a base e revalidar o plano, a delegação e o orçamento. `python3 e2e/check-worker-lookahead-race.py "$PWD"` imprimiu `1`. A retomada que estava na consulta de orçamento reutilizou a reserva já válida na trilha `start, wait, status, wait`, sem um segundo `start`. Branch sem reserva e checkout divergente continuaram recusados.
- `d7ca654`, `ac581c8`, `2e8bd53` e `1af340a` — Parada. As sondas executadas por `tests/run-all.sh` em `ada1e29` preservaram a primeira causa no journal e no pager, sem consultar de novo o ato que parou. Distinguiram teto de fase e de missão, recusaram aumento de teto e preflight sem a evidência exigida e só retomaram com o teto menor em nova invocação. O ledger atribuído contou uma só vez o gasto da missão removida.
- `9837b00` e `20ffaab` — F2 (BUG-02), seleção de revisão. `python3 e2e/check-worker-review-probe.py "$PWD"` em `ada1e29` imprimiu `1`. A sonda carregou `review_scope` e conferiu saída, rc e ordem das chamadas em 13 cenários. O PR mergeável preservou o delta, sem fetch nem merge. A integração só ocorreu na rota de conflito, com a base do PR, e a releitura no head integrado preservou `full` quando indicado. Os controles negativos distinguiram carregamento abortado com rc 0 e rodada `full` indevida.
- `6ed4ddc`, `2d81fe7`, `4edda89` e `f3b4056` — Revisão e merge. No mesmo `tests/run-all.sh` em `ada1e29`, o merge ficou retido sem `local/ci` no SHA testado, com achado sem disposição ou com pedido vigente de alteração mesmo sem comentário em linha. A sonda validou as escolhas do PR, exigiu novo aceite quando o head mudou e retomou a revisão pós-merge sem duplicar o PR de acompanhamento.
- Cruzei por título os 18 pares da matriz de `01-plano.md` com `bash tests/check-todo.sh --resolved TODO.md` em `ada1e29`. `git merge-base --is-ancestor` confirmou que todos os marcadores locais apontam para commits ancestrais do SHA testado. O marcador da #419 aponta para `2d81fe7`, complementado pela evidência de `local/ci` em `6ed4ddc`. Nenhuma issue mudou de estado nesta QA.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `checkpoint.md` | `F1` e `F2` em `done`, com Checks executáveis e commits `5ac9b42` e `9837b00`. |
| `checkpoint-notas.md` | Registro dos achados, correções e uma nota anexada com o reteste final. |
| `e2e/check-worker-lookahead-race.py` | Regressão CLI do BUG-01, compartilhada com a sonda do worker. |
| `e2e/check-worker-review-probe.py` | Regressão CLI do BUG-02 contra a sonda I11 do worker. |
| `tests/check-worker.sh` | Executa a corrida de F1 e os cenários e controles de F2 no `TEST_CMD`. |

Sem relatório Playwright ou registro novo em `docs/qa/`. O acervo histórico ficou intacto.

## Boot da próxima fase

REVIEW começa pelas linhas `F1` e `F2` de `checkpoint.md` e pelos commits `5ac9b42` e `9837b00`. Use os Checks dessas linhas para reproduzir o reteste e rode `tests/run-all.sh` no SHA que for revisar. Confira o dono do checkout antes do disparo, a reserva única e as recusas de orçamento e delegação. No PR, confira as escolhas do grill, as disposições dos 18 pares e o vínculo de `local/ci`, do tratamento de achados e do aceite de merge ao head. Uma mudança de head exige evidência correspondente ao novo SHA.

Para retomar `20261117-zerar-as-issues`, aponte com `ahead-request` para a instrução escrita original do dono no handoff de retomada. As [decisões 1 e 7 de `00-missao.md`](00-missao.md#decisões-do-grill-não-re-litigar) identificam o pedido (`8c5c30513c5c44c2b284fe2ecab9e63d` e `c5f0ad29961443e387457881b8556e7f`). Se a fonte original não puder ser recuperada, mantenha `ahead plan` como sugestão. Releia delegação e orçamento no primário a cada ato.

## Pendências / Decisions for a Human

- Nenhuma decisão humana em aberto nesta QA. A assinatura de novos termos, caso necessária, permanece com o dono.

## Riscos e não-feitos

- O runner, o relay, o pager e o GitHub foram simulados nas jornadas da campanha. Não houve campanha real, planner pago, publicação de status, resolução de thread ou merge real. As permissões do produtor de `local/ci` no GitHub não foram verificadas.
- A suíte verificou a aplicação das âncoras do catálogo. Não executou a mutação completa nem gerou carimbo com `sdd health`.

## Achados fora de escopo

- Nenhum achado novo fora do escopo. `TODO.md` não foi alterado no fechamento.
