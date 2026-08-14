---
missao: 20260814-dry-run-completo
atualizado: 2026-08-14 03:05
---

# Checkpoint — dry-run mostra o pipeline inteiro

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo. Não mude as colunas,
> não mude os tokens de status, não quebre linhas dentro de uma célula.
>
> Atualizar o checkpoint é o **último ato** do incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | dry-run projeta todas as fases pendentes | `tests/run-all.sh` → exit 0 (com check-dry-run.sh incluído) | pending | — |

## Notas de execução

- 2026-08-14 03:05 · — · missão-fixture do incremento I6 do plano do kit: plano escrito à mão
  para exercitar a fase EXEC headless pela primeira vez.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado, com ID `F<n>` e Check incluindo
> regression test + re-walk da jornada impactada.
