---
missao: 20260816-runner-sem-dividas
atualizado: 2026-08-16 09:30
---

# Checkpoint — a seção "Runner — defeitos e dívidas" do TODO.md é eliminada

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Triagem por artefato: gate_DOCS obsoleto sai | `grep -c 'gate_DOCS reprova' TODO.md` → `0`, commit cita hash provado por merge-base | pending | — |
| I2 | latest_matching ordena por versão | `bash tests/check-gates.sh` → verde com asserção r1/r2/r10 escolhendo r10; mutação RUN_sort_lexi no catálogo | pending | — |
| I3 | sdd install morre alto sem starter | `bash tests/check-preflight.sh` → verde com asserção "sem starter: rc≠0 e config ausente"; mutação RUN_install_no_guard | pending | — |
| I4 | bad_rows sai; comentário do slice honesto | `grep -c bad_rows bin/sdd` → `0` e `grep -c 'CHARACTER slice' bin/sdd` → `0`; suíte verde | pending | — |
| I5 | printf-grep-q sai da suíte, sensor impede volta | `bash tests/run-all.sh` → verde; ocorrência reintroduzida em tests/ → passo novo vermelho | pending | — |
| I6 | lint cobre tests/ | `shellcheck -S warning bin/sdd tests/*.sh` → rc 0; run-all roda o passo estendido | pending | — |
| I7 | uma definição de comparabilidade | `bash tests/check-autonomy.sh` → verde com asserção diferencial kit_dirty null + sha; mutação RUN_on_axis_forked | pending | — |
| I8 | guard.sufficient conta sessão comparável | `bash tests/check-kaizen.sh` → verde: só-escalada dá sufficient false, com-sessão dá true; mutação KAIZEN_guard_counts_escalations | pending | — |
| I9 | giro REVIEW-PR-REVIEW pós-degradação acaba | `bash tests/check-autonomy.sh` → verde: ramo 1x, rc 3, 1 degraded + 1 blocked; mutação RUN_degraded_spins | pending | — |
| I10 | sessão de fase loga stream | `bash tests/run-all.sh` → verde; run stub produz *.stream.jsonl com ≥2 linhas e ledger com mesmos campos | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 09:30 · plano · nasce com 10 incrementos; ordem é risco-crescente (triagem → consertos pontuais → suíte → leitores do ledger → laço → observabilidade)

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
