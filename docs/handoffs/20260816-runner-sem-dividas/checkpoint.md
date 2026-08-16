---
missao: 20260816-runner-sem-dividas
atualizado: 2026-08-16 12:40
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
| I1 | Triagem por artefato: gate_DOCS obsoleto sai | `grep -c 'gate_DOCS reprova' TODO.md` → `0`, commit cita hash provado por merge-base | done | 238497f |
| I2 | latest_matching ordena por versão | `bash tests/check-gates.sh` → verde com asserção r1/r2/r10 escolhendo r10; mutação RUN_sort_lexi no catálogo | done | 6c7b1df |
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
- 2026-08-16 · I1 · ⚠️ o Check literal do I1 é VÁCUO: o título no TODO.md traz crases entre `gate_DOCS` e `reprova`, então `grep -c 'gate_DOCS reprova'` já dava `0` antes da remoção. Usado o reforçado `grep -c 'gate_DOCS' TODO.md`, observado `1` → `0`. Achado registrado no TODO.md (seção "Sensores que faltam") como defeito do gate PLAN-AUTO, em `caf6e3b`
- 2026-08-16 · I1 · triagem completa: dos 11 itens, só o do `gate_DOCS` estava resolvido (`0f50fad`, ancestral de `main`, com sensor em check-gates.sh e mutação `DOCS_pending_status`). Os outros 10 re-verificados um a um contra o HEAD — **todos ainda vivos**. Nenhum incremento vira no-op
- 2026-08-16 · I1 · âncoras reais no HEAD para os próximos incrementos (as do TODO.md driftaram): I2 `bin/sdd:224`; I3 `:1015`; I4 `:276,300` e `:821,850`; I7 `:1735,1742`; I8 `:1854`; I9 `:1566`; I10 `:897`
- 2026-08-16 · I1 · três desvios do "Contexto verificado" do 01-plano.md, medidos hoje: (a) I6 — `shellcheck -S warning tests/*.sh` reprova com **1×SC2318** em `check-mutation.sh:369`, não 2×; (b) I2 — além de `bin/sdd:1334`, o comentário de `bin/sdd:1892` também cita o defeito como vivo e precisa sair junto; (c) I7 — há uma **terceira** cópia inline do mesmo predicado em `kaizen_series` (`bin/sdd:1846`), que o plano não menciona
- 2026-08-16 · I2 · vermelho observado e pelo motivo certo: as 3 asserções novas falharam com `got: REVIEW: 40-review-r3.md all Grade A` — o runner literalmente lia r3. Suíte 30/30 → 31/31, 31,6 s → 32,0 s; `sdd health` verde nos 5 checks
- 2026-08-16 · I2 · desvio do plano (ampliação, não corte): o plano pedia fixture `r1/r2/r10`, mas o `r3` que já existia no check-gates.sh é o pivô — é ele que o `sort` lexicográfico escolhe. Fixture ficou `r1/r2/r3/r10` com **r10 reprovado**, para que a ordem errada FALHE ABERTA (avança para DOCS) em vez de só escolher outro arquivo
- 2026-08-16 · I2 · nasce o helper `assert_why_absent` em check-gates.sh (metade negativa que a regra da casa cobra). Já entra com herestring — os próximos incrementos podem copiá-lo; não repetir o `printf | grep -q` do `assert_why` vizinho, que é alvo do I5
- 2026-08-16 · I2 · ⚠️ para o I6: o SC2318 do `check-mutation.sh` **desceu para a linha 382** (era 369) porque este commit inseriu 13 linhas acima dele. Continua sendo 1× e o único achado de `shellcheck -S warning tests/*.sh` neste arquivo
- 2026-08-16 · I2 · para o I10: `sdd preflight` (`bin/sdd:1082`) já sonda `sort -V` como parte do userland GNU — nenhuma dependência nova entrou com este conserto
- 2026-08-16 · I1 · I3 nasce com risco de vácuo: sob `set -euo pipefail` o `sed` sem `starter.conf` já aborta, então a metade "rc≠0" pode passar HOJE. A asserção tem de pesar nas outras duas metades (mensagem nomeia o arquivo E `$CONFIG_FILE` ausente) para ser vermelha pelo motivo certo

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
