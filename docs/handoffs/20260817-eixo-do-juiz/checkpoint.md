---
missao: 20260817-eixo-do-juiz
atualizado: 2026-08-17 08:20
---

# Checkpoint — o eixo do juiz

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | ADR 0003: a pergunta que o juiz responde | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    adr 0003' <<< "$o"` → `2` | done | 3547a83 |
| I2 | o runner explica o `indeterminado` estrutural | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    degenerate axis' <<< "$o"` → `2` | pending | — |
| I3 | `--all-repos` nos três leitores | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    all-repos' <<< "$o"` → `2` | pending | — |
| I4 | identidade de repo sobrevive a worktree | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    worktree' <<< "$o"` → `2` | pending | — |
| I5 | linha sem `repo` ganha balde próprio | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    no-repo' <<< "$o"` → `2` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-17 00:20 · `PLAN` · os 5 Checks rodados contra o HEAD: todos `0` (vermelhos), com
  `tests/check-kaizen.sh` e `tests/check-autonomy.sh` rc `0` (verdes) — nenhum Check nasce verde.
- 2026-08-17 00:20 · `PLAN` · os prefixos de asserção são **contrato** com os Checks: `adr 0003`,
  `degenerate axis`, `all-repos`, `worktree`, `no-repo`. Nomear exatamente assim.
- 2026-08-17 00:20 · `PLAN` · **o I1 é um ADR e vem primeiro** — não é "documentação depois". O I2
  cita o número `0003` no código, e a segunda asserção do I1 cobra essa citação.
- 2026-08-17 00:20 · `PLAN` · baseline da mutação nesta branch: **55**; alvo ao fim da missão: 60,
  uma mutação por incremento.
- 2026-08-17 00:20 · `PLAN` · `excluded` e `guard` têm **dois** produtores da mesma shape (o
  programa `jq` e o literal do ledger vazio em `bin/sdd:2382`): campo novo entra nos dois no mesmo
  commit, senão `tests/check-kaizen.sh` reprova comparando-os como conjuntos de chave.
- 2026-08-17 · `EXEC I1` · suíte verde antes de começar, `score: 55`; ao fim, **56**, `sdd health`
  verde nos cinco. As 2 asserções nasceram **vermelhas** (rc 1, contagem 0) e ficaram verdes só
  depois do ADR + da citação.
- 2026-08-17 · `EXEC I1` · **a citação do ADR entrou no `bin/sdd` neste incremento**, não no I2: a
  segunda asserção do I1 cobra que o runner nomeie `ADR 0003`, então o I1 não fecharia sem ela. Ela
  é um comentário no programa `jq`, na linha do piso que o ADR governa. O I2 acrescenta a frase
  **impressa** ao humano — a mutação `KAIZEN_adr_0003_orphan` usa `sed …/g` justamente porque a
  citação passa a existir em mais de um sítio.
- 2026-08-17 · `EXEC I1` · **`docs/adr` entrou no `sandbox()` do `check-mutation.sh`.** Sem isso a
  asserção de forma do ADR morre dentro de todo mutante e o *control run* reprova com
  HARNESS-BROKEN — o comentário do próprio harness já avisava ("a future test reading agents/ or
  docs/"). Copia-se `docs/adr`, nunca `docs/`: os sensores que leem o resto (`check-todo.sh`,
  `check-checkpoint.sh`) são os que o `run-all.sh` guarda sob `SDD_MUTANT`.
- 2026-08-17 · `EXEC I1` · passada de sabotagem adversarial na asserção de forma: degradar o
  título, a linha de data/status e o heading `## Decision` deixa a contagem em **1** nos três
  casos — nenhuma das três regras é decoração. A asserção da citação é provada pelo catálogo.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
