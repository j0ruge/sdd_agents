---
missao: 20260815-ledger-sem-ponto-cego
atualizado: 2026-08-15 23:40
---

# Checkpoint — o ledger e o Jidoka param de mentir

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Jidoka do `blocked` com herestring, sem depender do buffer do pipe | `./tests/run-all.sh` → `suite green` com `score: 26 caught, 0 known gap(s), of 26` | pending | — |
| I2 | auto-degradação `review-to-draft` escreve no ledger e a série a reconhece | `./tests/run-all.sh` → `suite green` com `score: 27 caught, 0 known gap(s), of 27` | pending | — |
| I3 | escaladas do `sdd autonomy` agrupadas por `kit_sha`, como a série já faz | `./tests/run-all.sh` → `suite green` com `score: 28 caught, 0 known gap(s), of 28` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-15 23:40 · — · Missão nascida pelo laço kaizen (`sdd kaizen`), a partir do veredito
  `indeterminado` em `05-verdict.md` (série vazia, `guard.sufficient: false`) e da triagem do
  `TODO.md`. Baseline medida nesta sessão sobre o `HEAD` `90f9ce9`: suíte verde, mutação
  **23/23**, `KNOWN_GAPS` vazio, **37,4 s** no default de `SDD_MUTATION_JOBS`.
- 2026-08-15 23:40 · `I1` · Lembrete para a sessão EXEC: a asserção do checkpoint >64 KB **tem de
  ser observada vermelha** antes do herestring entrar. Se ela nascer verde, o fixture não alcançou
  o regime de falha — marcar `blocked` e aumentar o fixture, nunca relaxar a asserção.
- 2026-08-15 23:40 · `I2` · O `select` de `bin/sdd:1767` só aceita `session` e `blocked`. Escrever
  a linha `degraded` sem abrir esse filtro a manda para `excluded.unrecognized` — trocaria um
  ponto cego por outro. Os dois passos vão no mesmo incremento.
- 2026-08-15 23:40 · `I3` · Não tocar em `kaizen_series`: ela já agrupa escalada dentro da fatia
  de `kit_sha` (`bin/sdd:1774`). Só o `cmd_autonomy` está sem eixo.
- 2026-08-16 · — · O code review do I13.3 (pré-merge, duas rodadas) acrescentou a 24ª e a 25ª
  mutações (`KAIZEN_guard_ignored` — o gate cruza `guard.sufficient` com o veredito; e
  `KAIZEN_approved_bailout_dead` — aprovação preenchida nunca alcança sessão) e renomeou
  `SERIES_refez_dropped` → `RUN_refez_dropped` (contrato de prefixos do catálogo). A régua desta
  missão foi deslocada +2 (Checks agora 26 → 27 → 28) e a linha de baseline do `01-plano.md`
  atualizada de 23 para 25 — o número que a sessão EXEC verá de fato na abertura.

- 2026-08-16 · — · Revisão pré-run: os três defeitos re-conferidos vivos no `bin/sdd` de `main`
  (`fdf8708`); suíte re-medida verde, `score: 25 caught, 0 known gap(s), of 25` (52,6 s sob
  carga). Números defasados pela régua +2 corrigidos no `00-missao.md` (métrica 28/28, K2 25→28)
  e no `01-plano.md` (baseline `of 25`, e2e 25→28). Aprovação: `humano-2026-08-16`.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
