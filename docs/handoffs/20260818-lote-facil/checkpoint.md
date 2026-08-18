---
missao: 20260818-lote-facil
atualizado: 2026-08-18 08:09
---

# Checkpoint — O `sdd health` para de morrer calado, e 18 achados baratos saem do backlog

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a próxima
> fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de uma célula.
> Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru.
> Check que precisaria de pipe vira herestring, como os cinco abaixo já fazem.
>
> ⚠️ **Check que lê saída de sensor ancora em `^  ok    ` — quatro espaços, com o `^`.** Grepar o
> texto solto devolve o mesmo número com a asserção verde e com ela vermelha.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | A família do aborto calado — 4 sítios do `cmd_health` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    abort: ' <<< "$o"` → `4` | pending | — |
| I2 | A família do `cd` relativo — 14 em `tests/` mais o `ledger_repo_root` | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    cdpath: ' <<< "$o"` → `3` | pending | — |
| I3 | Saída humana do runner — 3 números que contam a grandeza errada | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output: ' <<< "$o"` → `9` | pending | — |
| I4 | Cinco caminhos sem asserção ganham asserção e mutação | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    covered: ' <<< "$o"` → `5` | pending | — |
| I5 | Regras de sensor e o `templates/review.md` que falta | `o=$(bash tests/run-all.sh 2>&1); grep -c '^  ok    rule: ' <<< "$o"` → `5` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-18 08:09 · `planejamento` · **Os 5 Checks foram executados contra o HEAD (`9207b4d`) e
  registrados VERMELHOS**, para nenhum nascer verde: `abort:` deu **0** (alvo 4), `cdpath:` deu
  **2** (alvo 3), `output:` deu **6** (alvo 9), `covered:` deu **0** (alvo 5), `rule:` deu **0**
  (alvo 5). O `TODO.md` traz achado aberto sobre o gate PLAN-AUTO aceitar Check que já nasce verde.
- 2026-08-18 08:09 · `planejamento` · ⚠️ `cdpath:` e `output:` **não partem de zero**: já existem 2
  e 6 asserções desses prefixos em `tests/check-autonomy.sh`. As existentes têm de continuar verdes
  — no I2 elas são justamente as que provam que a troca do `ledger_repo_root` não regrediu nada.
- 2026-08-18 08:09 · `planejamento` · **A família do I1 foi reproduzida, não suposta.** Quatro
  sondas com o runner real num kit copiado (`SDD_HOME` é `readonly`, então não dá para apontá-lo
  por env), com controle verde `kit healthy` / rc 0 antes de cada sabotagem. Resultado: suíte
  vermelha → só o cabeçalho; `score:` ausente → morre após `suite green`; `plugins/cache` ausente →
  morre após o check de gates; baseline sem linha viva → morre após a proveniência. Sempre rc 1,
  sempre calado.
- 2026-08-18 08:09 · `planejamento` · **8 das 18 âncoras do `TODO.md` estavam podres** e foram
  re-derivadas contra `9207b4d`; a pior por **~615 linhas** (`--max-phases`, dizia `:1489-1498`,
  está em `:2104`/`:2281`). As linhas do `01-plano.md` são as boas — não confiar nas do `TODO.md`.
- 2026-08-18 08:09 · `planejamento` · ⚠️ `rc 1` sozinho **não** discrimina o defeito do I1: o
  `health_bad` também termina em rc 1. A asserção precisa exigir o texto do ramo certo **e** a
  presença de um check posterior. Sem a segunda metade ela passa igual com o defeito.
- 2026-08-18 08:09 · `planejamento` · O `check-autonomy.sh` é vermelho intermitente de causa
  desconhecida (não reproduziu em 152 runs). Se aparecer: registrar aqui e seguir. **Não**
  investigar — decisão 6 do `00-missao.md`.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para "Decisions for a
> Human" no handoff de QA.
