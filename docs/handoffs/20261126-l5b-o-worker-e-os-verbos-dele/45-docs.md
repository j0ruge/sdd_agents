---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: DOCS
status: done
sessao: 01a220d2-7316-7b61-bcc8-94f050cd881b
data: 2026-11-28 03:43
gate: SDD_MUTATION_FIXTURE_ROOT="$PWD" tests/run-all.sh em a87547b3 → rc 0, 21 etapas, 114 sondas do worker e 3 casos Codex em skipped. bash tests/check-todo.sh --check TODO.md e bash tests/check-todo.sh --anchors TODO.md no conteúdo de a87547b3 → 104 itens e âncoras válidas.
---

# Handoff — DOCS — O worker e os verbos dele

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

A documentação descreve o planejamento antecipado, as escritas dos verbos de revisão e a
atribuição de gastos à campanha. A suíte passou nas 21 etapas e os 18 pares TODO/issue têm
prova local. A próxima fase parte do checkpoint e deste checklist. A proposta para o changelog
da skill não foi aplicada porque fica fora dos caminhos de escrita de DOCS.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele` — sem upstream configurado. Ancestral local com `origin/main` em `8a56249f`.
- **Último commit verificado pela suíte:** `a87547b3` — alinha o glossário e o pipeline às provas da campanha.
- **Working tree:** limpa no reteste. O commit de fechamento acrescenta apenas este handoff e uma nota.
- **Suíte:** `SDD_MUTATION_FIXTURE_ROOT="$PWD" tests/run-all.sh` em `a87547b3` → rc 0, 21 etapas, 114 sondas do worker e 3 casos Codex em `skipped`. As 1.017 âncoras do catálogo aplicam e deixam código válido.
- **E2E:** `E2E_CMD` não configurado. As jornadas CLI da suíte usam Git local e serviços simulados.

## O que foi feito

- `a87547b3` — Corrigiu o glossário e o manual que ainda descreviam a CLI como só consultiva, salvo a assinatura. Registrou a atribuição de gastos e o planejamento antecipado no glossário, sem duplicar o procedimento.
- `a87547b3` — Registrou o antes e o depois em `KAIZEN_LOG.md`. O guia do worker ocupa 507 linhas no manual. A proposta de separação ficou em `TODO.md`, com a catraca atualizada para 104 itens.
- `a87547b3` — Recruzou os 18 títulos do grill com `bash tests/check-todo.sh --resolved TODO.md`. Para cada marcador, `git merge-base --is-ancestor <hash> HEAD` retornou 0. Não houve consulta nova nem alteração de estado no GitHub.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/pipeline.md` | Contrato da CLI e procedimento operacional com links para a implementação. |
| `CONTEXT.md` | Glossário de campanha, worker e planejamento antecipado. |
| `KAIZEN_LOG.md` | Medidas de lançamento, retomada, revisão e leitura do pedido escrito. |
| `TODO.md` | Achados da missão, marcadores de resolução e proposta de separação do guia. |

## Boot da próxima fase

Leia `checkpoint.md`, a matriz de `01-plano.md`, as decisões do grill de `00-missao.md`
e o checklist abaixo. Use `bin/sdd why 20261126-l5b-o-worker-e-os-verbos-dele DOCS` para
conferir o gate local. Na publicação, leve as escolhas efetivas do grill, a disposição dos 18
pares e o texto proposto para o changelog. O ato autorizado de `review` publica `local/ci` no SHA
que testou. A prontidão e o consentimento de merge também precisam do SHA corrente.
Se o head de produto mudar, siga a orientação da REVIEW r9 e reavalie a partir de
`1446b62810107a9c0c12b61fa93e2bc8e71e3194`.

## Pendências / Decisions for a Human

- Aplicar a nota de versão em `skills/sdd-worker/CHANGELOG.md` pelo PR. O texto exato está abaixo.

## Riscos e não-feitos

- A fase não mesclou a base, não abriu PR e não alterou código ou termos da campanha.
- As fixtures não conferem permissões reais para publicar `local/ci` ou resolver threads. O catálogo completo e o carimbo de mutação não foram executados.
- Sem pedido escrito recuperável, `ahead plan` segue como sugestão. O caso de título ATX na própria linha do marcador permanece aberto no backlog.

## Achados fora de escopo

- Separar o guia do worker do manual do pipeline → `TODO.md` › Comentário e registro. O registro decidido sobre a fatia do ledger permanece intacto. A proposta nova trata apenas da seção do worker.

## Drift checklist

| Área tocada no diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| Inventário NUL e PR entre forks em `bin/sdd-worker` (I1, I6) | `README.md`, `docs/pipeline.md` | ✅ | Requisito local de Git e recusa de inventário ou paginação incompleta em `064098ed` e `9ce1943d`. O piso geral de Git não mudou. |
| Autoridade efetiva e teto em `bin/sdd-worker`, `bin/sdd` (I2, I4) | `docs/pipeline.md`, `config/schema.md`, `templates/delegation.md`, `.claude/rules/anatomia-do-agente.md` | ✅ | Validade na concessão e teto exportado em `d1e8d0f7`. Recarga Claude, parada Codex e nova invocação para redução verificada em `ac581c8c`. |
| Ledger e orçamento em `bin/sdd`, `bin/sdd-worker` (I3) | `docs/pipeline.md`, `templates/delegation.md`, `docs/adr/0022-the-worker-is-a-session-orchestrator.md`, `CONTEXT.md` | ✅ | Identidade da campanha, gasto de missão removida e limite de registros legados já documentados em `1af340af`. Glossário alinhado em `a87547b3`. |
| Parada do runner e escalada do comando (I5) | `commands/sdd-worker.md`, `docs/pipeline.md`, `.claude/rules/anatomia-do-agente.md` | ✅ | `d7ca6544` documenta a saída original, o pager único e a distinção de tetos. A regra reservada já foi atualizada no EXEC. |
| Suíte no head, achados, grill e aceite do merge (I8–I10, R1, R4) | `README.md`, `commands/sdd-worker.md`, `docs/pipeline.md`, `CONTEXT.md`, `docs/adr/0027-worker-campaign-evidence.md` | ✅ | Contrato documentado em `6ed4ddcf`, `2d81fe7f`, `4edda894`, `297f0722`, `4d5bdb4d` e `a3786a4b`. A distinção entre CLI e sessão passou ao glossário e ao manual em `a87547b3`. |
| Escopo de revisão com ou sem conflito (I11, F2) | `commands/sdd-worker.md`, `docs/pipeline.md` | ✅ | `20ffaabf` documenta o delta elegível e a releitura após integrar a base do PR. F2 corrige o sensor, sem mudar o procedimento. |
| Fila assinada e retomada de pós-merge (I12) | `commands/sdd-worker.md`, `docs/pipeline.md` | ✅ | `f3b4056f` documenta publicação conjunta de fila e assinatura, entrada no diário e recuperação do PR de acompanhamento. |
| Pré-voo e lançamento dos dois engines (I13) | `commands/sdd-worker.md`, `docs/pipeline.md`, `skills/sdd-worker/SKILL.md` | ✅ | `2e8bd531` faz do pré-voo no worktree da missão condição explícita do lançamento. |
| Planejamento antecipado em `bin/sdd-worker-ahead`, `bin/sdd-plan-codex` e no comando (I14, F1, R2–R3, R5–R12) | `commands/sdd-worker.md`, `docs/pipeline.md`, `skills/sdd-worker/SKILL.md`, `docs/adr/0027-worker-campaign-evidence.md`, `CONTEXT.md` | ✅ | Reserva e revalidação em `6344f01d` e `5ac9b422`, fila e fonte do pedido em `a83df3e2` e `9b0e168e`. O limite final de parágrafo e HTML consta de `8b093116`. Glossário em `a87547b3`. |
| Estado da frente do worker | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | `6344f01d` distingue a entrega comprovada em fixture do trabalho de campanha ainda não executado. |
| `tests/check-worker.sh`, `tests/check-worker-ahead.py`, `tests/check-worker-lookahead-race.py` e `e2e/check-worker-*.py` | `KAIZEN_LOG.md`, `30-handoff-qa.md`, `checkpoint.md` | ✅ | `a87547b3` registra as medidas de F1, F2 e R12. Os comandos e as jornadas estão no checkpoint e na QA fechada em `27c94acb`. |
| `tests/check-autonomy.sh` e `tests/check-codex-runner.sh` | `docs/pipeline.md`, `config/schema.md` | ✅ | As sondas medem o ledger e as fronteiras de orçamento já documentadas em `1af340af` e `ac581c8c`, sem interface nova de testes. |
| `tests/check-mutation.sh` (I7) | — | n/a | Âncoras e testemunhas do catálogo mudaram, não o uso do catálogo. O Check I7 vincula as recusas distintas a `f7b80710` e a suíte em `a87547b3` confirmou 1.017 âncoras. |
| `tests/check-lang.sh` | `CLAUDE.md` | n/a | O censo passa a incluir o leitor e as sondas novas. A divisão entre superfície em inglês e artefatos da missão em português já é a convenção e não mudou. |
| `TODO.md` e `tests/health-baseline.txt` | `TODO.md` | ✅ | Os três achados novos da REVIEW seguem abertos. Os 18 marcadores e o ajuste de catraca em `a87547b3` foram conferidos sem baixar a exigência de âncora. |
| Missão, plano, aceite, checkpoint, notas e handoffs EXEC/QA/REVIEW | — | n/a | Artefatos históricos guardam a intenção, a ordem e o resultado dos Checks. Não duplicam o procedimento vivo e não foram reescritos nesta fase. |
| Mudanças visíveis na skill do worker | `skills/sdd-worker/CHANGELOG.md` | ⛔ | Inserir a nova entrada antes das anteriores. O changelog fica fora de `writes:`. Texto exato abaixo. |

## Texto proposto
<!-- sdd:proposed -->

Em `skills/sdd-worker/CHANGELOG.md`, inserir após `# Changelog` e antes da primeira entrada existente

> ## 2026-11-28
>
> - Run preflight in the mission worktree before launching the runner. In an authorized Codex
>   campaign with a recoverable written owner request, start one successor plan in a separate
>   worktree before waiting for the runner. Resume the same relay and revalidate after merge
>   before approving the draft.
> - Require the suite result on the tested PR head and verified review dispositions before
>   merge. Preserve campaign spend attributed to missions whose worktrees were removed.

## Achados do TODO conferidos

- REVIEW r2 — `TEST_CMD` com apenas espaços ainda pode publicar falso verde. Item aberto com a evidência no handoff da rodada.
- REVIEW r6 — a saída por sabotagem do EXEC de R8 não está vinculada à contagem. Item aberto com a evidência no handoff da rodada.
- REVIEW r7 — título ATX na própria linha do marcador de lista não entra na contagem. Item aberto com a evidência no handoff da rodada.
- DOCS — separar o guia do worker do manual. Item aberto com âncora na seção que começa em `docs/pipeline.md:1964`.
- Os 18 pares da matriz do plano conservam os marcadores até a limpeza pós-merge. O marcador de #419 aponta para `2d81fe7`, com evidência de `local/ci` em `6ed4ddc`. Não se antecipou a limpeza nem o fechamento das issues.
